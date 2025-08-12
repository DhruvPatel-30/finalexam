
# TODO: Complete/Correct outputs as part of the exam

output "alb_dns" {
  description = "DNS name for the ALB"
  value       = aws_lb.app.dns_name
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.assets.bucket
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = module.network.vpc_id
}
