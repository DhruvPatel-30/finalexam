
# Terraform AWS Final Exam – 

This repository is intentionally **broken**. Your job is to fix it and complete the staging deployment.

## What you must deploy
- VPC with 2 public + 2 private subnets across 2 Availabilty Zones, Internet Gateway, 
**NAT** for private egress, correct routes
- ALB in public subnets forwarding to EC2 instances 
- S3 bucket with versioning (name must be unique, passed via variable)
- RDS Postgres in private subnets (no public access)
- CloudWatch alarm on EC2 CPU > 75% 
- GitHub Actions CI: fmt, validate on PR; plan on PR; apply on main

## Constraints
- Edit only existing files if possible.
- Use naming format: `<studentname>-<studentnumber>-<resource>-staging`.
- Use functions like `cidrsubnet()` and for_each/count where appropriate.


Good luck. You have 2 hours.

name: Terraform CI/CD

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
  workflow_dispatch:

jobs:
  terraform:
    name: Terraform
    runs-on: ubuntu-latest

    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_SESSION_TOKEN: ${{ secrets.AWS_SESSION_TOKEN }}

    steps:
    - name: Checkout repository
      uses: actions/checkout@v2

    - name: Set up Terraform
      uses: hashicorp/setup-terraform@v1
      with:
        terraform_version: 1.3.5

    - name: Initialize Terraform
      run: terraform init

    - name: Validate Terraform
      run: terraform validate

    - name: Terraform Plan
      id: plan
      run: terraform plan -var="core_count=1" -var="thread_count=2"

    - name: Apply Terraform (on push to main)
      if: github.event_name == 'push' && github.ref == 'refs/heads/main'
      run: terraform apply -var="core_count=1" -var="thread_count=2" -auto-approve

  destroy:
    name: Terraform Destroy
    runs-on: ubuntu-latest

    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_SESSION_TOKEN: ${{ secrets.AWS_SESSION_TOKEN }}

    steps:
    - name: Checkout repository
      uses: actions/checkout@v2

    - name: Set up Terraform
      uses: hashicorp/setup-terraform@v1
      with:
        terraform_version: 1.3.5

    - name: Initialize Terraform
      run: terraform init

    - name: Terraform Destroy
      run: terraform destroy -var="core_count=1" -var="thread_count=2" -auto-approve