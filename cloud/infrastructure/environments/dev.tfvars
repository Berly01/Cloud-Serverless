# Development Environment Configuration

aws_region  = "us-east-1"
environment = "dev"
project_name = "bpm-monitoring"

# Cognito
cognito_password_min_length = 8
cognito_mfa_configuration   = "OPTIONAL"

# DynamoDB
dynamodb_billing_mode = "PAY_PER_REQUEST"

# Lambda
lambda_runtime     = "python3.11"
lambda_memory_size = 256
lambda_timeout     = 30

# Alerts (configure with real values)
alert_email = ""
alert_phone = ""

# BPM Thresholds
bpm_critical_low  = 40
bpm_warning_low   = 50
bpm_warning_high  = 100
bpm_critical_high = 150
