# BPM Monitoring - Main Infrastructure Configuration

locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "OpenTofu"
  }
}

# Random suffix for globally unique resource names
resource "random_id" "suffix" {
  byte_length = 4
}


# Module: Cognito (Identity and Access Management)


module "cognito" {
  source = "./modules/cognito"

  name_prefix          = local.name_prefix
  environment          = var.environment
  password_min_length  = var.cognito_password_min_length
  mfa_configuration    = var.cognito_mfa_configuration
  
  tags = local.common_tags
}


# Module: DynamoDB (Real-time Storage)


module "dynamodb" {
  source = "./modules/dynamodb"

  name_prefix    = local.name_prefix
  billing_mode   = var.dynamodb_billing_mode
  read_capacity  = var.dynamodb_read_capacity
  write_capacity = var.dynamodb_write_capacity
  
  tags = local.common_tags
}


# Module: S3 (Historical Storage)


module "s3" {
  source = "./modules/s3"

  name_prefix   = local.name_prefix
  random_suffix = random_id.suffix.hex
  environment   = var.environment
  
  tags = local.common_tags
}


# Module: SNS (Alert System)


module "sns" {
  source = "./modules/sns"

  name_prefix = local.name_prefix
  alert_email = var.alert_email
  alert_phone = var.alert_phone
  
  tags = local.common_tags
}


# Module: Lambda (Data Processing)


module "lambda" {
  source = "./modules/lambda"

  name_prefix     = local.name_prefix
  runtime         = var.lambda_runtime
  memory_size     = var.lambda_memory_size
  timeout         = var.lambda_timeout
  
  # Dependencies
  dynamodb_table_name = module.dynamodb.table_name
  dynamodb_table_arn  = module.dynamodb.table_arn
  s3_bucket_name      = module.s3.bucket_name
  s3_bucket_arn       = module.s3.bucket_arn
  sns_topic_arn       = module.sns.topic_arn
  
  # BPM Thresholds
  bpm_critical_low  = var.bpm_critical_low
  bpm_warning_low   = var.bpm_warning_low
  bpm_warning_high  = var.bpm_warning_high
  bpm_critical_high = var.bpm_critical_high
  
  tags = local.common_tags
}


# Module: IoT Core (Data Ingestion)


module "iot_core" {
  source = "./modules/iot_core"

  name_prefix         = local.name_prefix
  lambda_function_arn = module.lambda.processor_function_arn
  
  tags = local.common_tags
}


# Module: API Gateway (REST API Exposure)


module "api_gateway" {
  source = "./modules/api_gateway"

  name_prefix             = local.name_prefix
  environment             = var.environment
  cognito_user_pool_arn   = module.cognito.user_pool_arn
  lambda_api_handler_arn  = module.lambda.api_handler_function_arn
  lambda_api_handler_name = module.lambda.api_handler_function_name
  aws_region              = var.aws_region
  
  tags = local.common_tags
}


# Module: Dashboard (Frontend Hosting)


module "dashboard" {
  source = "./modules/dashboard"

  name_prefix          = local.name_prefix
  environment          = var.environment
  api_gateway_url      = module.api_gateway.api_url
  cognito_user_pool_id = module.cognito.user_pool_id
  cognito_client_id    = module.cognito.client_id
  cognito_domain       = module.cognito.domain
  
  tags = local.common_tags
}
