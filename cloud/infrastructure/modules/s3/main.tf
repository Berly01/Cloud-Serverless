
# S3 Bucket - Historical BPM Data Storage

# Organization structure:
# s3://bucket/user_id/device_id/year/month/day/data.json


resource "aws_s3_bucket" "bpm_historical" {
  bucket = "${var.name_prefix}-historical-${var.random_suffix}"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-historical"
  })
}


# Bucket Versioning


resource "aws_s3_bucket_versioning" "bpm_historical" {
  bucket = aws_s3_bucket.bpm_historical.id

  versioning_configuration {
    status = "Enabled"
  }
}


# Server-Side Encryption


resource "aws_s3_bucket_server_side_encryption_configuration" "bpm_historical" {
  bucket = aws_s3_bucket.bpm_historical.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}


# Block Public Access


resource "aws_s3_bucket_public_access_block" "bpm_historical" {
  bucket = aws_s3_bucket.bpm_historical.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# Lifecycle Rules


resource "aws_s3_bucket_lifecycle_configuration" "bpm_historical" {
  bucket = aws_s3_bucket.bpm_historical.id

  # Rule 1: Transition to Intelligent-Tiering after 30 days
  rule {
    id     = "transition-to-intelligent-tiering"
    status = "Enabled"

    filter {}

    transition {
      days          = 30
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  # Rule 2: Move to Glacier after 1 year
  rule {
    id     = "archive-to-glacier"
    status = "Enabled"

    filter {}

    transition {
      days          = 365
      storage_class = "GLACIER"
    }
  }

  # Rule 3: Delete old versions after 90 days
  rule {
    id     = "delete-old-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  # Rule 4: Abort incomplete multipart uploads
  rule {
    id     = "abort-incomplete-uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}


# Bucket Policy - Enforce HTTPS


resource "aws_s3_bucket_policy" "bpm_historical" {
  bucket = aws_s3_bucket.bpm_historical.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceHTTPS"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.bpm_historical.arn,
          "${aws_s3_bucket.bpm_historical.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.bpm_historical]
}


# S3 Bucket - Lambda Deployment Artifacts


resource "aws_s3_bucket" "lambda_artifacts" {
  bucket = "${var.name_prefix}-lambda-artifacts-${var.random_suffix}"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-lambda-artifacts"
  })
}

resource "aws_s3_bucket_versioning" "lambda_artifacts" {
  bucket = aws_s3_bucket.lambda_artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lambda_artifacts" {
  bucket = aws_s3_bucket.lambda_artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "lambda_artifacts" {
  bucket = aws_s3_bucket.lambda_artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
