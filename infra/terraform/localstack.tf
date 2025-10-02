# Cloud CV - LocalStack Terraform Configuration
# SRE/DevOps Engineer Portfolio - Local Development

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# LocalStack Provider Configuration
provider "aws" {
  region                      = var.aws_region
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  
  endpoints {
    s3             = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    apigateway     = "http://localhost:4566"
    iam            = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    logs           = "http://localhost:4566"
    route53        = "http://localhost:4566"
    acm            = "http://localhost:4566"
    cloudfront     = "http://localhost:4566"
  }
}

# Variables for LocalStack
variable "aws_region" {
  description = "AWS region for LocalStack"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "local"
}

variable "bucket_name" {
  description = "S3 bucket name for LocalStack"
  type        = string
  default     = "cloud-cv-local"
}

variable "table_name" {
  description = "DynamoDB table name"
  type        = string
  default     = "cloud-cv-visitor-counter"
}

variable "function_name" {
  description = "Lambda function name"
  type        = string
  default     = "cloud-cv-visitor-counter"
}

# Local values
locals {
  common_tags = {
    Project     = "Cloud-CV"
    Environment = var.environment
    Owner       = "SRE-DevOps-Engineer"
    ManagedBy   = "Terraform"
    Purpose     = "Local-Development"
  }
}

# S3 Bucket for static website hosting
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name
  
  tags = merge(local.common_tags, {
    Name = "Cloud-CV-Local-Website-Bucket"
  })
}

# S3 Bucket website configuration
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# S3 Bucket public access (LocalStack only - not for production)
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# S3 Bucket policy for public read access (LocalStack only)
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

# DynamoDB table for visitor counter
resource "aws_dynamodb_table" "visitor_counter" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = merge(local.common_tags, {
    Name = "Cloud-CV-Local-Visitor-Counter"
  })
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "cloud-cv-lambda-role-local"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name = "cloud-cv-lambda-policy-local"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.visitor_counter.arn
      }
    ]
  })
}

# Lambda function for visitor counter
resource "aws_lambda_function" "visitor_counter" {
  filename         = "../lambda/visitor_counter.zip"
  function_name    = var.function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime         = "python3.11"
  timeout         = 30

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.visitor_counter.name
    }
  }

  tags = merge(local.common_tags, {
    Name = "Cloud-CV-Local-Visitor-Counter"
  })
}

# Lambda function code archive
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "../lambda/lambda_function.py"
  output_path = "../lambda/visitor_counter.zip"
}

# API Gateway for Lambda
resource "aws_api_gateway_rest_api" "visitor_counter" {
  name        = "cloud-cv-visitor-counter-api-local"
  description = "API Gateway for Cloud CV visitor counter (LocalStack)"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = local.common_tags
}

# API Gateway resource
resource "aws_api_gateway_resource" "visitor_counter" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter.id
  parent_id   = aws_api_gateway_rest_api.visitor_counter.root_resource_id
  path_part   = "visitor-count"
}

# API Gateway method
resource "aws_api_gateway_method" "visitor_counter" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_counter.id
  resource_id   = aws_api_gateway_resource.visitor_counter.id
  http_method   = "GET"
  authorization = "NONE"
}

# API Gateway integration
resource "aws_api_gateway_integration" "visitor_counter" {
  rest_api_id = aws_api_gateway_rest_api.visitor_counter.id
  resource_id = aws_api_gateway_resource.visitor_counter.id
  http_method = aws_api_gateway_method.visitor_counter.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.visitor_counter.invoke_arn
}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.visitor_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.visitor_counter.execution_arn}/*/*"
}

# API Gateway deployment
resource "aws_api_gateway_deployment" "visitor_counter" {
  depends_on = [
    aws_api_gateway_integration.visitor_counter,
  ]

  rest_api_id = aws_api_gateway_rest_api.visitor_counter.id
  stage_name  = "prod"

  lifecycle {
    create_before_destroy = true
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.visitor_counter.function_name}"
  retention_in_days = 1  # Short retention for local development

  tags = local.common_tags
}

# Outputs
output "bucket_name" {
  description = "Name of the S3 bucket"
  value       = aws_s3_bucket.website.bucket
}

output "bucket_website_endpoint" {
  description = "Website endpoint of the S3 bucket"
  value       = aws_s3_bucket_website_configuration.website.website_endpoint
}

output "api_gateway_url" {
  description = "URL of the API Gateway"
  value       = "${aws_api_gateway_deployment.visitor_counter.invoke_url}/visitor-count"
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table"
  value       = aws_dynamodb_table.visitor_counter.name
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.visitor_counter.function_name
}

output "localstack_endpoint" {
  description = "LocalStack endpoint URL"
  value       = "http://localhost:4566"
}

output "s3_website_url" {
  description = "S3 website URL"
  value       = "http://localhost:4566/${aws_s3_bucket.website.bucket}/index.html"
}
