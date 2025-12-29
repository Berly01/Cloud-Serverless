# IoT Core - Data Ingestion from BPM Devices

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

# IoT Thing Type - BPM Device

resource "aws_iot_thing_type" "bpm_device" {
  name = "${var.name_prefix}-bpm-device"

  properties {
    description           = "BPM monitoring device type"
    searchable_attributes = ["device_model", "firmware_version"]
  }

  tags = var.tags
}

# IoT Policy - Device Connection Policy

resource "aws_iot_policy" "bpm_device_policy" {
  name = "${var.name_prefix}-device-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iot:Connect"
        ]
        Resource = "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:client/$${iot:Connection.Thing.ThingName}"
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Publish"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/bpm/+/+/measurements",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/bpm/+/+/status"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Subscribe"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/bpm/+/+/commands",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topicfilter/bpm/+/+/config"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iot:Receive"
        ]
        Resource = [
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/bpm/+/+/commands",
          "arn:aws:iot:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:topic/bpm/+/+/config"
        ]
      }
    ]
  })

  tags = var.tags
}

# IoT Topic Rule - Process BPM Measurements

resource "aws_iot_topic_rule" "bpm_measurements" {
  name        = replace("${var.name_prefix}_bpm_measurements", "-", "_")
  description = "Route BPM measurements to Lambda for processing"
  enabled     = true
  sql         = "SELECT * FROM 'bpm/+/+/measurements'"
  sql_version = "2016-03-23"

  lambda {
    function_arn = var.lambda_function_arn
  }

  # Error action - log to CloudWatch
  error_action {
    cloudwatch_logs {
      log_group_name = aws_cloudwatch_log_group.iot_errors.name
      role_arn       = aws_iam_role.iot_rule_role.arn
    }
  }

  tags = var.tags
}

# CloudWatch Log Group for IoT Errors

resource "aws_cloudwatch_log_group" "iot_errors" {
  name              = "/aws/iot/${var.name_prefix}/errors"
  retention_in_days = 30

  tags = var.tags
}

# IAM Role for IoT Topic Rule

resource "aws_iam_role" "iot_rule_role" {
  name = "${var.name_prefix}-iot-rule-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "iot_rule_lambda" {
  name = "${var.name_prefix}-iot-lambda-policy"
  role = aws_iam_role.iot_rule_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:InvokeFunction"
        Resource = var.lambda_function_arn
      }
    ]
  })
}

resource "aws_iam_role_policy" "iot_rule_logs" {
  name = "${var.name_prefix}-iot-logs-policy"
  role = aws_iam_role.iot_rule_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.iot_errors.arn}:*"
      }
    ]
  })
}

# IoT Logging Configuration

resource "aws_iot_logging_options" "main" {
  default_log_level = "WARN"
  role_arn          = aws_iam_role.iot_logging_role.arn
}

resource "aws_iam_role" "iot_logging_role" {
  name = "${var.name_prefix}-iot-logging-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "iot_logging" {
  name = "${var.name_prefix}-iot-logging-policy"
  role = aws_iam_role.iot_logging_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutMetricFilter",
          "logs:PutRetentionPolicy"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:*"
      }
    ]
  })
}

# Get IoT Endpoint

data "aws_iot_endpoint" "main" {
  endpoint_type = "iot:Data-ATS"
}
