# General Outputs

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

# Cognito Outputs

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.cognito.user_pool_id
}

output "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = module.cognito.user_pool_arn
}

output "cognito_client_id" {
  description = "Cognito App Client ID"
  value       = module.cognito.client_id
}

output "cognito_domain" {
  description = "Cognito domain URL"
  value       = module.cognito.domain
}

# IoT Core Outputs

output "iot_endpoint" {
  description = "IoT Core endpoint for device connections"
  value       = module.iot_core.iot_endpoint
}

output "iot_topic_rule_arn" {
  description = "IoT Topic Rule ARN"
  value       = module.iot_core.topic_rule_arn
}

# DynamoDB Outputs

output "dynamodb_table_name" {
  description = "DynamoDB table name for BPM measurements"
  value       = module.dynamodb.table_name
}

output "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  value       = module.dynamodb.table_arn
}

# S3 Outputs

output "s3_bucket_name" {
  description = "S3 bucket name for historical data"
  value       = module.s3.bucket_name
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN"
  value       = module.s3.bucket_arn
}

# SNS Outputs

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = module.sns.topic_arn
}

# Lambda Outputs

output "lambda_processor_arn" {
  description = "BPM Processor Lambda function ARN"
  value       = module.lambda.processor_function_arn
}

output "lambda_api_handler_arn" {
  description = "API Handler Lambda function ARN"
  value       = module.lambda.api_handler_function_arn
}

# API Gateway Outputs

output "api_gateway_url" {
  description = "API Gateway base URL"
  value       = module.api_gateway.api_url
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = module.api_gateway.api_id
}

output "api_gateway_stage" {
  description = "API Gateway stage name"
  value       = module.api_gateway.stage_name
}

# Dashboard Outputs

output "dashboard_url" {
  description = "Dashboard URL (CloudFront)"
  value       = module.dashboard.dashboard_url
}

output "dashboard_bucket_name" {
  description = "S3 bucket for dashboard files"
  value       = module.dashboard.s3_bucket_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = module.dashboard.cloudfront_distribution_id
}
