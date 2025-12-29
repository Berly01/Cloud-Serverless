output "dashboard_url" {
  description = "Dashboard CloudFront URL"
  value       = "https://${aws_cloudfront_distribution.dashboard.domain_name}"
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.dashboard.id
}

output "s3_bucket_name" {
  description = "S3 bucket name for dashboard files"
  value       = aws_s3_bucket.dashboard.id
}

output "s3_bucket_arn" {
  description = "S3 bucket ARN for dashboard files"
  value       = aws_s3_bucket.dashboard.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront domain name"
  value       = aws_cloudfront_distribution.dashboard.domain_name
}
