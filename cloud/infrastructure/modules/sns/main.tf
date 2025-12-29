# SNS Topic - Critical Alerts

resource "aws_sns_topic" "critical_alerts" {
  name         = "${var.name_prefix}-critical-alerts"
  display_name = "BPM Critical Alerts"

  # Enable server-side encryption
  kms_master_key_id = "alias/aws/sns"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-critical-alerts"
  })
}

# SNS Topic - Warning Alerts

resource "aws_sns_topic" "warning_alerts" {
  name         = "${var.name_prefix}-warning-alerts"
  display_name = "BPM Warning Alerts"

  kms_master_key_id = "alias/aws/sns"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-warning-alerts"
  })
}

# SNS Topic Policy - Critical Alerts

resource "aws_sns_topic_policy" "critical_alerts" {
  arn = aws_sns_topic.critical_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaPublish"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.critical_alerts.arn
      },
      {
        Sid    = "AllowIoTPublish"
        Effect = "Allow"
        Principal = {
          Service = "iot.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.critical_alerts.arn
      }
    ]
  })
}

# SNS Topic Policy - Warning Alerts

resource "aws_sns_topic_policy" "warning_alerts" {
  arn = aws_sns_topic.warning_alerts.arn

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLambdaPublish"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action   = "sns:Publish"
        Resource = aws_sns_topic.warning_alerts.arn
      }
    ]
  })
}

# Email Subscription (if provided)

resource "aws_sns_topic_subscription" "email_critical" {
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

resource "aws_sns_topic_subscription" "email_warning" {
  count = var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.warning_alerts.arn
  protocol  = "email"
  endpoint  = var.alert_email
}

# SMS Subscription (if provided)

resource "aws_sns_topic_subscription" "sms_critical" {
  count = var.alert_phone != "" ? 1 : 0

  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "sms"
  endpoint  = var.alert_phone
}
