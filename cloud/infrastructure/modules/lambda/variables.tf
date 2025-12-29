# Lambda Module - Data Processing Functions

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

variable "memory_size" {
  description = "Lambda memory size in MB"
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Lambda timeout in seconds"
  type        = number
  default     = 30
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for BPM measurements"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "DynamoDB table ARN"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for historical data"
  type        = string
}

variable "s3_bucket_arn" {
  description = "S3 bucket ARN"
  type        = string
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  type        = string
}

variable "bpm_critical_low" {
  description = "BPM threshold for critical low"
  type        = number
  default     = 40
}

variable "bpm_warning_low" {
  description = "BPM threshold for warning low"
  type        = number
  default     = 50
}

variable "bpm_warning_high" {
  description = "BPM threshold for warning high"
  type        = number
  default     = 100
}

variable "bpm_critical_high" {
  description = "BPM threshold for critical high"
  type        = number
  default     = 150
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
