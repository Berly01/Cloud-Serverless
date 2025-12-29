output "bucket_name" {
  description = "S3 bucket name for historical data"
  value       = aws_s3_bucket.bpm_historical.id
}

output "bucket_arn" {
  description = "S3 bucket ARN for historical data"
  value       = aws_s3_bucket.bpm_historical.arn
}

output "bucket_domain_name" {
  description = "S3 bucket domain name"
  value       = aws_s3_bucket.bpm_historical.bucket_domain_name
}

output "lambda_artifacts_bucket_name" {
  description = "S3 bucket name for Lambda artifacts"
  value       = aws_s3_bucket.lambda_artifacts.id
}

output "lambda_artifacts_bucket_arn" {
  description = "S3 bucket ARN for Lambda artifacts"
  value       = aws_s3_bucket.lambda_artifacts.arn
}
