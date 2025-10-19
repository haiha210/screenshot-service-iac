# Reusable S3 Bucket Module

# Random suffix for bucket name uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Main S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.bucket_name}-${var.env}-${random_id.bucket_suffix.hex}"

  tags = merge({
    Name        = "${var.bucket_name}-${var.env}"
    Environment = var.env
    Project     = var.project
    Purpose     = var.purpose
  }, var.additional_tags)
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.encryption_algorithm
      kms_master_key_id = var.encryption_algorithm == "aws:kms" ? var.kms_key_id : null
    }
    bucket_key_enabled = true
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = var.block_public_access.block_public_acls
  block_public_policy     = var.block_public_access.block_public_policy
  ignore_public_acls      = var.block_public_access.ignore_public_acls
  restrict_public_buckets = var.block_public_access.restrict_public_buckets
}

# S3 Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "bucket" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0
  
  bucket = aws_s3_bucket.bucket.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      # Transitions
      dynamic "transition" {
        for_each = rule.value.transitions
        content {
          days          = transition.value.days
          storage_class = transition.value.storage_class
        }
      }

      # Non-current version transitions
      dynamic "noncurrent_version_transition" {
        for_each = rule.value.noncurrent_transitions
        content {
          noncurrent_days = noncurrent_version_transition.value.days
          storage_class   = noncurrent_version_transition.value.storage_class
        }
      }

      # Expiration
      dynamic "expiration" {
        for_each = rule.value.expiration_days != null ? [1] : []
        content {
          days = rule.value.expiration_days
        }
      }

      # Non-current version expiration
      dynamic "noncurrent_version_expiration" {
        for_each = rule.value.noncurrent_expiration_days != null ? [1] : []
        content {
          noncurrent_days = rule.value.noncurrent_expiration_days
        }
      }

      # Abort incomplete multipart uploads
      abort_incomplete_multipart_upload {
        days_after_initiation = rule.value.incomplete_multipart_days
      }
    }
  }
}

# S3 Bucket CORS Configuration
resource "aws_s3_bucket_cors_configuration" "bucket" {
  count = var.cors_configuration.enabled ? 1 : 0
  
  bucket = aws_s3_bucket.bucket.id

  cors_rule {
    allowed_headers = var.cors_configuration.allowed_headers
    allowed_methods = var.cors_configuration.allowed_methods
    allowed_origins = var.cors_configuration.allowed_origins
    expose_headers  = var.cors_configuration.expose_headers
    max_age_seconds = var.cors_configuration.max_age_seconds
  }
}

# S3 Bucket Logging
resource "aws_s3_bucket_logging" "bucket" {
  count = var.access_logging.enabled ? 1 : 0
  
  bucket = aws_s3_bucket.bucket.id

  target_bucket = var.access_logging.target_bucket
  target_prefix = var.access_logging.target_prefix
}