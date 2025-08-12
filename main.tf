

provider "aws" {
  region = var.aws_region
}


module "network" {
  source = "./modules/vpc"

  name_prefix = "${var.student_name}-${var.student_number}-vpc-staging"
  cidr_block  = var.vpc_cidr

  availability_zones = var.azs

  public_subnet_bits  = 2
  private_subnet_bits = 2

  enable_nat_gateway = "true"


  
}


resource "aws_s3_bucket" "assets" {
  bucket        = var.s3_bucket_name
  force_destroy = false
  tags = {
    Name = "${var.student_name}-${var.student_number}-s3-staging"
  }
}

resource "aws_s3_bucket_versioning" "assets" {
  bucket = aws_s3_bucket.assets.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_security_group" "alb_sg" {
  name        = "${var.student_name}-${var.student_number}-alb-staging"
  description = "ALB security group"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  name        = "${var.student_name}-${var.student_number}-app-staging"
  description = "App server SG"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "app" {
  name               = "${var.student_name}-${var.student_number}-alb-staging"
  load_balancer_type = "application"
  subnets            = module.network.public_subnet_ids
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "app_tg" {
  name     = "${var.student_name}-${var.student_number}-tg-staging"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id

  health_check {
    path                = "/"
    matcher             = "200-399"
    interval            = 15
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "app" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = element(module.network.private_subnet_ids, count.index)
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  count                  = 2

  user_data = <<-EOF
              #!/bin/bash
              yum install -y nginx
              systemctl enable nginx
              systemctl start nginx
              echo "Hello from ${var.student_name}" > /usr/share/nginx/html/index.html
              EOF

  tags = {
    Name = "${var.student_name}-${var.student_number}-app-staging"
  }
}

resource "aws_db_subnet_group" "db" {
  name       = "${var.student_name}-${var.student_number}-dbsubnet-staging"
  subnet_ids = module.network.public_subnet_ids
}

resource "aws_db_instance" "postgres" {
  identifier             = "${var.student_name}-mysql-staging"
  engine                 = "postgres"
  engine_version         = "15.5"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.db.name
  publicly_accessible    = true
  skip_final_snapshot    = true
  vpc_security_group_ids = []
}


resource "aws_sns_topic" "alerts" {
  name = "${var.student_name}-alerts-staging"
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.student_name}-cpu75-staging"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 75

  alarm_actions = [aws_sns_topic.alerts.arn]

}


output "alb_dns" {
  value = aws_lb.app.dns_name
}

output "bucket_name" {
  value = aws_s3_bucket.assets.bucket
}

output "vpc_id" {
  value = module.network.vpc
}
