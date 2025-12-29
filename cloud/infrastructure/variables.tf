# General Variables

variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "bpm-monitoring"
}

# Cognito Variables

variable "cognito_password_min_length" {
  description = "Minimum password length for Cognito users"
  type        = number
  default     = 8
}

variable "cognito_mfa_configuration" {
  description = "MFA configuration for Cognito (OFF, ON, OPTIONAL)"
  type        = string
  default     = "OPTIONAL"
}

# DynamoDB Variables

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dynamodb_read_capacity" {
  description = "DynamoDB read capacity units (only for PROVISIONED mode)"
  type        = number
  default     = 5
}

variable "dynamodb_write_capacity" {
  description = "DynamoDB write capacity units (only for PROVISIONED mode)"
  type        = number
  default     = 5
}

# Lambda Variables

variable "lambda_runtime" {
  description = "Lambda runtime environment"
  type        = string
  default     = "python3.11"
}

variable "lambda_memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

# SNS Variables

variable "alert_email" {
  description = "Email address for receiving critical alerts"
  type        = string
  default     = ""
}

variable "alert_phone" {
  description = "Phone number for receiving SMS alerts (E.164 format)"
  type        = string
  default     = ""
}

# BPM Threshold Variables

variable "bpm_critical_low" {
  description = "BPM threshold for critical low alert"
  type        = number
  default     = 40
}

variable "bpm_warning_low" {
  description = "BPM threshold for warning low alert"
  type        = number
  default     = 50
}

variable "bpm_warning_high" {
  description = "BPM threshold for warning high alert"
  type        = number
  default     = 100
}

variable "bpm_critical_high" {
  description = "BPM threshold for critical high alert"
  type        = number
  default     = 150
}
