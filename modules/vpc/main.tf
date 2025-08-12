

variable "name_prefix" { type = string }
variable "cidr_block" { type = string }
variable "availability_zones" { type = list(string) }

variable "enable_nat_gateway" { type = bool }

variable "public_subnet_bits" { type = number }
variable "private_subnet_bits" { type = number }

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_map = { for idx, az in var.availability_zones : idx => az }
}
resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = { Name = "${var.name_prefix}" }
}

resource "aws_subnet" "public" {
  for_each = local.az_map
  vpc_id = aws_vpc.this.id
  cidr_block = cidrsubnet(var.cidr_block, var.public_subnet_bits, each.key)
  availability_zone = each.value
  map_public_ip_on_launch = true
  tags = { Name = "${var.name_prefix}-public-${each.value}" }
}

resource "aws_subnet" "private" {
  for_each = local.az_map
  vpc_id = aws_vpc.this.id
  cidr_block = cidrsubnet(var.cidr_block, var.private_subnet_bits, each.key + length(var.availability_zones))
  availability_zone = each.value
  tags = { Name = "${var.name_prefix}-private-${each.value}" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
  tags   = { Name = "${var.name_prefix}-igw" }
}

resource "aws_eip" "nat" { vpc = true }

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = element(aws_subnet.public.*.id, 0)
  depends_on    = [aws_internet_gateway.igw]
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.name_prefix}-rt-public" }
}

resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

