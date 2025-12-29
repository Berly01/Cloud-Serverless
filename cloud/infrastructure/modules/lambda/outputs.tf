output "processor_function_arn" {
  description = "BPM Processor Lambda function ARN"
  value       = aws_lambda_function.bpm_processor.arn
}

output "processor_function_name" {
  description = "BPM Processor Lambda function name"
  value       = aws_lambda_function.bpm_processor.function_name
}

output "api_handler_function_arn" {
  description = "API Handler Lambda function ARN"
  value       = aws_lambda_function.api_handler.arn
}

output "api_handler_function_name" {
  description = "API Handler Lambda function name"
  value       = aws_lambda_function.api_handler.function_name
}

output "lambda_execution_role_arn" {
  description = "Lambda execution role ARN"
  value       = aws_iam_role.lambda_execution.arn
}
