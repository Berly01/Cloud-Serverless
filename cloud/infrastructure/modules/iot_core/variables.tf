# IoT Core Module - Data Ingestion

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to invoke"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
