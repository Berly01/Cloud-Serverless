
# Cognito User Pool - Main Authentication Service

resource "aws_cognito_user_pool" "main" {
  name = "${var.name_prefix}-user-pool"

  # Username configuration
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Password policy
  password_policy {
    minimum_length                   = var.password_min_length
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  # MFA configuration
  mfa_configuration = var.mfa_configuration

  software_token_mfa_configuration {
    enabled = var.mfa_configuration != "OFF"
  }

  # Account recovery
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # User attribute schema
  schema {
    name                     = "email"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = true

    string_attribute_constraints {
      min_length = 5
      max_length = 256
    }
  }

  schema {
    name                     = "name"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 256
    }
  }

  schema {
    name                     = "role"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = false

    string_attribute_constraints {
      min_length = 1
      max_length = 50
    }
  }

  # Email configuration
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Verification message
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_subject        = "BPM Monitoring - Verification Code"
    email_message        = "Your verification code is {####}"
  }

  # Admin create user config
  admin_create_user_config {
    allow_admin_create_user_only = false

    invite_message_template {
      email_subject = "BPM Monitoring - Your Temporary Password"
      email_message = "Your username is {username} and temporary password is {####}"
      sms_message   = "Your username is {username} and temporary password is {####}"
    }
  }

  tags = var.tags
}

# Cognito User Pool Groups (RBAC)

resource "aws_cognito_user_group" "patients" {
  name         = "patients"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Group for patient users"
  precedence   = 3
}

resource "aws_cognito_user_group" "doctors" {
  name         = "doctors"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Group for doctor users"
  precedence   = 2
}

resource "aws_cognito_user_group" "administrators" {
  name         = "administrators"
  user_pool_id = aws_cognito_user_pool.main.id
  description  = "Group for administrator users"
  precedence   = 1
}

# Cognito User Pool Client

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.name_prefix}-client"
  user_pool_id = aws_cognito_user_pool.main.id

  # Token configuration
  access_token_validity  = 1  # hours
  id_token_validity      = 1  # hours
  refresh_token_validity = 30 # days

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # OAuth configuration
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  callback_urls                        = ["https://localhost:3000/callback"]
  logout_urls                          = ["https://localhost:3000/logout"]
  supported_identity_providers         = ["COGNITO"]

  # Security settings
  prevent_user_existence_errors = "ENABLED"
  generate_secret               = false

  # Auth flows
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  # Read/write attributes
  read_attributes = [
    "email",
    "email_verified",
    "name",
    "custom:role"
  ]

  write_attributes = [
    "email",
    "name",
    "custom:role"
  ]
}

# Cognito User Pool Domain

resource "random_string" "cognito_domain_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.name_prefix}-${random_string.cognito_domain_suffix.result}"
  user_pool_id = aws_cognito_user_pool.main.id
}
