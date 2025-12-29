# API Gateway Module - REST API Exposure

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN for authorization"
  type        = string
}

variable "lambda_api_handler_arn" {
  description = "Lambda API Handler function ARN"
  type        = string
}

variable "lambda_api_handler_name" {
  description = "Lambda API Handler function name"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
