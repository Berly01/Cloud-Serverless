# API Gateway - REST API for BPM Monitoring

data "aws_caller_identity" "current" {}

# IAM Role for API Gateway CloudWatch Logs

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${var.name_prefix}-api-gateway-cloudwatch-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "api_gateway_cloudwatch" {
  name = "${var.name_prefix}-api-gateway-cloudwatch-policy"
  role = aws_iam_role.api_gateway_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# Configure API Gateway account settings for CloudWatch logging
resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

# REST API

resource "aws_api_gateway_rest_api" "main" {
  name        = "${var.name_prefix}-api"
  description = "BPM Monitoring REST API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-api"
  })
}

# Cognito Authorizer

resource "aws_api_gateway_authorizer" "cognito" {
  name          = "${var.name_prefix}-cognito-authorizer"
  rest_api_id   = aws_api_gateway_rest_api.main.id
  type          = "COGNITO_USER_POOLS"
  provider_arns = [var.cognito_user_pool_arn]

  identity_source = "method.request.header.Authorization"
}

# API Resources

# /health - Health check endpoint (no auth required)
resource "aws_api_gateway_resource" "health" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "health"
}

# /bpm - BPM data endpoints
resource "aws_api_gateway_resource" "bpm" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "bpm"
}

# /bpm/history
resource "aws_api_gateway_resource" "bpm_history" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.bpm.id
  path_part   = "history"
}

# /bpm/current
resource "aws_api_gateway_resource" "bpm_current" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.bpm.id
  path_part   = "current"
}

# /bpm/statistics
resource "aws_api_gateway_resource" "bpm_statistics" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.bpm.id
  path_part   = "statistics"
}

# /devices
resource "aws_api_gateway_resource" "devices" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "devices"
}

# /user
resource "aws_api_gateway_resource" "user" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "user"
}

# /user/profile
resource "aws_api_gateway_resource" "user_profile" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_resource.user.id
  path_part   = "profile"
}

# Health Check Method (No Auth)

resource "aws_api_gateway_method" "health_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.health.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "health_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.health.id
  http_method             = aws_api_gateway_method.health_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_api_handler_arn}/invocations"
}

# BPM History Methods

resource "aws_api_gateway_method" "bpm_history_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.bpm_history.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.querystring.device_id"  = false
    "method.request.querystring.start_date" = false
    "method.request.querystring.end_date"   = false
    "method.request.querystring.limit"      = false
  }
}

resource "aws_api_gateway_integration" "bpm_history_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.bpm_history.id
  http_method             = aws_api_gateway_method.bpm_history_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_api_handler_arn}/invocations"
}

# BPM Current Methods

resource "aws_api_gateway_method" "bpm_current_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.bpm_current.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "bpm_current_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.bpm_current.id
  http_method             = aws_api_gateway_method.bpm_current_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_api_handler_arn}/invocations"
}

# BPM Statistics Methods

resource "aws_api_gateway_method" "bpm_statistics_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.bpm_statistics.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.querystring.period" = false
  }
}

resource "aws_api_gateway_integration" "bpm_statistics_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.bpm_statistics.id
  http_method             = aws_api_gateway_method.bpm_statistics_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_api_handler_arn}/invocations"
}

# Devices Methods

resource "aws_api_gateway_method" "devices_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.devices.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "devices_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.devices.id
  http_method             = aws_api_gateway_method.devices_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_api_handler_arn}/invocations"
}

# User Profile Methods

resource "aws_api_gateway_method" "user_profile_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.user_profile.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

resource "aws_api_gateway_integration" "user_profile_get" {
  rest_api_id             = aws_api_gateway_rest_api.main.id
  resource_id             = aws_api_gateway_resource.user_profile.id
  http_method             = aws_api_gateway_method.user_profile_get.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_api_handler_arn}/invocations"
}

# CORS Configuration

# CORS for /bpm/history
resource "aws_api_gateway_method" "bpm_history_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.bpm_history.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "bpm_history_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.bpm_history.id
  http_method = aws_api_gateway_method.bpm_history_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "bpm_history_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.bpm_history.id
  http_method = aws_api_gateway_method.bpm_history_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "bpm_history_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.bpm_history.id
  http_method = aws_api_gateway_method.bpm_history_options.http_method
  status_code = aws_api_gateway_method_response.bpm_history_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.bpm_history_options]
}

# CORS for /bpm/current
resource "aws_api_gateway_method" "bpm_current_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.bpm_current.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "bpm_current_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.bpm_current.id
  http_method = aws_api_gateway_method.bpm_current_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "bpm_current_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.bpm_current.id
  http_method = aws_api_gateway_method.bpm_current_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "bpm_current_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.bpm_current.id
  http_method = aws_api_gateway_method.bpm_current_options.http_method
  status_code = aws_api_gateway_method_response.bpm_current_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.bpm_current_options]
}

# CORS for /bpm/statistics
resource "aws_api_gateway_method" "bpm_statistics_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.bpm_statistics.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "bpm_statistics_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.bpm_statistics.id
  http_method = aws_api_gateway_method.bpm_statistics_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "bpm_statistics_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.bpm_statistics.id
  http_method = aws_api_gateway_method.bpm_statistics_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "bpm_statistics_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.bpm_statistics.id
  http_method = aws_api_gateway_method.bpm_statistics_options.http_method
  status_code = aws_api_gateway_method_response.bpm_statistics_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.bpm_statistics_options]
}

# CORS for /devices
resource "aws_api_gateway_method" "devices_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.devices.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "devices_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.devices.id
  http_method = aws_api_gateway_method.devices_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "devices_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.devices.id
  http_method = aws_api_gateway_method.devices_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "devices_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.devices.id
  http_method = aws_api_gateway_method.devices_options.http_method
  status_code = aws_api_gateway_method_response.devices_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.devices_options]
}

# CORS for /user/profile
resource "aws_api_gateway_method" "user_profile_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.user_profile.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "user_profile_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.user_profile.id
  http_method = aws_api_gateway_method.user_profile_options.http_method
  type        = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "user_profile_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.user_profile.id
  http_method = aws_api_gateway_method.user_profile_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "user_profile_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.user_profile.id
  http_method = aws_api_gateway_method.user_profile_options.http_method
  status_code = aws_api_gateway_method_response.user_profile_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [aws_api_gateway_integration.user_profile_options]
}

# Lambda Permission for API Gateway

resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_api_handler_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# API Deployment

resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.health.id,
      aws_api_gateway_resource.bpm.id,
      aws_api_gateway_resource.bpm_history.id,
      aws_api_gateway_resource.bpm_current.id,
      aws_api_gateway_resource.bpm_statistics.id,
      aws_api_gateway_resource.devices.id,
      aws_api_gateway_resource.user_profile.id,
      aws_api_gateway_method.health_get.id,
      aws_api_gateway_method.bpm_history_get.id,
      aws_api_gateway_method.bpm_current_get.id,
      aws_api_gateway_method.bpm_statistics_get.id,
      aws_api_gateway_method.devices_get.id,
      aws_api_gateway_method.user_profile_get.id,
      aws_api_gateway_integration.health_get.id,
      aws_api_gateway_integration.bpm_history_get.id,
      aws_api_gateway_integration.bpm_current_get.id,
      aws_api_gateway_integration.bpm_statistics_get.id,
      aws_api_gateway_integration.devices_get.id,
      aws_api_gateway_integration.user_profile_get.id,
      # CORS OPTIONS methods
      aws_api_gateway_method.bpm_history_options.id,
      aws_api_gateway_method.bpm_current_options.id,
      aws_api_gateway_method.bpm_statistics_options.id,
      aws_api_gateway_method.devices_options.id,
      aws_api_gateway_method.user_profile_options.id,
      aws_api_gateway_integration.bpm_history_options.id,
      aws_api_gateway_integration.bpm_current_options.id,
      aws_api_gateway_integration.bpm_statistics_options.id,
      aws_api_gateway_integration.devices_options.id,
      aws_api_gateway_integration.user_profile_options.id,
      # Force redeploy
      timestamp(),
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Stage

resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn
    format = jsonencode({
      requestId         = "$context.requestId"
      ip                = "$context.identity.sourceIp"
      caller            = "$context.identity.caller"
      user              = "$context.identity.user"
      requestTime       = "$context.requestTime"
      httpMethod        = "$context.httpMethod"
      resourcePath      = "$context.resourcePath"
      status            = "$context.status"
      protocol          = "$context.protocol"
      responseLength    = "$context.responseLength"
      integrationError  = "$context.integrationErrorMessage"
    })
  }

  xray_tracing_enabled = true

  tags = var.tags

  depends_on = [aws_api_gateway_account.main]
}

# CloudWatch Log Group for API Gateway

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/apigateway/${var.name_prefix}"
  retention_in_days = 30

  tags = var.tags
}

# API Gateway Method Settings (Throttling)

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = aws_api_gateway_stage.main.stage_name
  method_path = "*/*"

  settings {
    throttling_burst_limit = 100
    throttling_rate_limit  = 50
    metrics_enabled        = true
    logging_level          = "INFO"
    data_trace_enabled     = true
  }
}
