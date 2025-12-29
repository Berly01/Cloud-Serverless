output "topic_arn" {
  description = "SNS topic ARN for critical alerts"
  value       = aws_sns_topic.critical_alerts.arn
}

output "topic_name" {
  description = "SNS topic name for critical alerts"
  value       = aws_sns_topic.critical_alerts.name
}

output "warning_topic_arn" {
  description = "SNS topic ARN for warning alerts"
  value       = aws_sns_topic.warning_alerts.arn
}

output "warning_topic_name" {
  description = "SNS topic name for warning alerts"
  value       = aws_sns_topic.warning_alerts.name
}
