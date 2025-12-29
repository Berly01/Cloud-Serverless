output "table_name" {
  description = "DynamoDB BPM measurements table name"
  value       = aws_dynamodb_table.bpm_measurements.name
}

output "table_arn" {
  description = "DynamoDB BPM measurements table ARN"
  value       = aws_dynamodb_table.bpm_measurements.arn
}

output "user_state_table_name" {
  description = "DynamoDB user state table name"
  value       = aws_dynamodb_table.user_state.name
}

output "user_state_table_arn" {
  description = "DynamoDB user state table ARN"
  value       = aws_dynamodb_table.user_state.arn
}

output "devices_table_name" {
  description = "DynamoDB devices table name"
  value       = aws_dynamodb_table.devices.name
}

output "devices_table_arn" {
  description = "DynamoDB devices table ARN"
  value       = aws_dynamodb_table.devices.arn
}
