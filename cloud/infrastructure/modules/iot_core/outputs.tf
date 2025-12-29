output "iot_endpoint" {
  description = "IoT Core endpoint for device connections"
  value       = data.aws_iot_endpoint.main.endpoint_address
}

output "topic_rule_arn" {
  description = "IoT Topic Rule ARN"
  value       = aws_iot_topic_rule.bpm_measurements.arn
}

output "thing_type_name" {
  description = "IoT Thing Type name for BPM devices"
  value       = aws_iot_thing_type.bpm_device.name
}

output "device_policy_name" {
  description = "IoT Policy name for device connections"
  value       = aws_iot_policy.bpm_device_policy.name
}

output "device_policy_arn" {
  description = "IoT Policy ARN for device connections"
  value       = aws_iot_policy.bpm_device_policy.arn
}
