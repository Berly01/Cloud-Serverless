# IAM Role for Lambda Functions

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_iam_role" "lambda_execution" {
  name = "${var.name_prefix}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# IAM Policy - CloudWatch Logs

resource "aws_iam_role_policy" "lambda_logs" {
  name = "${var.name_prefix}-lambda-logs-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
      }
    ]
  })
}

# IAM Policy - DynamoDB Access

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name = "${var.name_prefix}-lambda-dynamodb-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem",
          "dynamodb:BatchGetItem"
        ]
        Resource = [
          var.dynamodb_table_arn,
          "${var.dynamodb_table_arn}/index/*"
        ]
      }
    ]
  })
}

# IAM Policy - S3 Access

resource "aws_iam_role_policy" "lambda_s3" {
  name = "${var.name_prefix}-lambda-s3-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.s3_bucket_arn,
          "${var.s3_bucket_arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy - SNS Publish

resource "aws_iam_role_policy" "lambda_sns" {
  name = "${var.name_prefix}-lambda-sns-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sns:Publish"
        Resource = var.sns_topic_arn
      }
    ]
  })
}

# Lambda Function - BPM Processor
# This function processes incoming BPM measurements from IoT Core

data "archive_file" "bpm_processor" {
  type        = "zip"
  output_path = "${path.module}/files/bpm_processor.zip"

  source {
    content  = file("${path.module}/src/bpm_processor.py")
    filename = "bpm_processor.py"
  }
}

resource "aws_lambda_function" "bpm_processor" {
  function_name = "${var.name_prefix}-bpm-processor"
  description   = "Processes BPM measurements from IoT devices"

  filename         = data.archive_file.bpm_processor.output_path
  source_code_hash = data.archive_file.bpm_processor.output_base64sha256

  handler = "bpm_processor.lambda_handler"
  runtime = var.runtime

  role        = aws_iam_role.lambda_execution.arn
  memory_size = var.memory_size
  timeout     = var.timeout

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      S3_BUCKET_NAME      = var.s3_bucket_name
      SNS_TOPIC_ARN       = var.sns_topic_arn
      BPM_CRITICAL_LOW    = tostring(var.bpm_critical_low)
      BPM_WARNING_LOW     = tostring(var.bpm_warning_low)
      BPM_WARNING_HIGH    = tostring(var.bpm_warning_high)
      BPM_CRITICAL_HIGH   = tostring(var.bpm_critical_high)
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bpm-processor"
  })
}

# CloudWatch Log Group for BPM Processor
resource "aws_cloudwatch_log_group" "bpm_processor" {
  name              = "/aws/lambda/${aws_lambda_function.bpm_processor.function_name}"
  retention_in_days = 30

  tags = var.tags
}

# Lambda Function - API Handler
# This function handles REST API requests via API Gateway

data "archive_file" "api_handler" {
  type        = "zip"
  output_path = "${path.module}/files/api_handler.zip"

  source {
    content  = file("${path.module}/src/api_handler.py")
    filename = "api_handler.py"
  }
}

resource "aws_lambda_function" "api_handler" {
  function_name = "${var.name_prefix}-api-handler"
  description   = "Handles REST API requests for BPM data"

  filename         = data.archive_file.api_handler.output_path
  source_code_hash = data.archive_file.api_handler.output_base64sha256

  handler = "api_handler.lambda_handler"
  runtime = var.runtime

  role        = aws_iam_role.lambda_execution.arn
  memory_size = var.memory_size
  timeout     = var.timeout

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      S3_BUCKET_NAME      = var.s3_bucket_name
    }
  }

  tracing_config {
    mode = "Active"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-api-handler"
  })
}

# CloudWatch Log Group for API Handler
resource "aws_cloudwatch_log_group" "api_handler" {
  name              = "/aws/lambda/${aws_lambda_function.api_handler.function_name}"
  retention_in_days = 30

  tags = var.tags
}

# Lambda Permission for IoT Core

resource "aws_lambda_permission" "iot_invoke" {
  statement_id  = "AllowIoTInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.bpm_processor.function_name
  principal     = "iot.amazonaws.com"
}

# Lambda Permission for X-Ray

resource "aws_iam_role_policy" "lambda_xray" {
  name = "${var.name_prefix}-lambda-xray-policy"
  role = aws_iam_role.lambda_execution.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      }
    ]
  })
}
