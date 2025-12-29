
# DynamoDB Table - BPM Measurements

# Schema Design:
# - Partition Key: user_id (String) - Enables data isolation per user
# - Sort Key: timestamp#device_id (String) - Enables time-based queries per device


resource "aws_dynamodb_table" "bpm_measurements" {
  name         = "${var.name_prefix}-bpm-measurements"
  billing_mode = var.billing_mode

  # Capacity (only used when billing_mode is PROVISIONED)
  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # Primary key
  hash_key  = "user_id"
  range_key = "timestamp_device"

  # Attribute definitions
  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "timestamp_device"
    type = "S"
  }

  attribute {
    name = "device_id"
    type = "S"
  }

  attribute {
    name = "measurement_date"
    type = "S"
  }

  # Global Secondary Index - Query by device
  global_secondary_index {
    name            = "device-index"
    hash_key        = "device_id"
    range_key       = "timestamp_device"
    projection_type = "ALL"

    read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
    write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
  }

  # Global Secondary Index - Query by date (for historical analysis)
  global_secondary_index {
    name            = "date-index"
    hash_key        = "user_id"
    range_key       = "measurement_date"
    projection_type = "ALL"

    read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
    write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  # TTL for automatic data expiration (optional - 90 days retention)
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-bpm-measurements"
  })
}


# DynamoDB Table - User State (Current Status)


resource "aws_dynamodb_table" "user_state" {
  name         = "${var.name_prefix}-user-state"
  billing_mode = var.billing_mode

  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # Primary key
  hash_key = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-user-state"
  })
}


# DynamoDB Table - Device Registry


resource "aws_dynamodb_table" "devices" {
  name         = "${var.name_prefix}-devices"
  billing_mode = var.billing_mode

  read_capacity  = var.billing_mode == "PROVISIONED" ? var.read_capacity : null
  write_capacity = var.billing_mode == "PROVISIONED" ? var.write_capacity : null

  # Primary key
  hash_key  = "user_id"
  range_key = "device_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "device_id"
    type = "S"
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Server-side encryption
  server_side_encryption {
    enabled = true
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-devices"
  })
}
