# S3 Buckets using reusable module

# Screenshots S3 Bucket
module "screenshots_bucket" {
  source = "../../../../modules/s3"

  bucket_name        = "screenshot-bucket"
  env                = var.env
  project            = var.project
  purpose            = "Store screenshot images from backend service"
  versioning_enabled = true

  lifecycle_rules = [{
    id     = "screenshot_lifecycle"
    status = "Enabled"

    transitions = [
      {
        days          = 30
        storage_class = "STANDARD_IA"
      },
      {
        days          = 90
        storage_class = "GLACIER"
      }
    ]

    noncurrent_expiration_days = 365
    incomplete_multipart_days  = 7
  }]

  cors_configuration = {
    enabled         = true
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "POST", "DELETE", "HEAD"]
    allowed_origins = var.env == "prd" ? ["https://yourdomain.com"] : ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }

  access_logging = {
    enabled       = var.env == "prd" ? true : false
    target_bucket = var.env == "prd" ? module.access_logs_bucket[0].bucket_id : null
    target_prefix = "screenshots-access-logs/"
  }
}

# Access Logs S3 Bucket (Production only)
module "access_logs_bucket" {
  count  = var.env == "prd" ? 1 : 0
  source = "../../../../modules/s3"

  bucket_name        = "screenshot-access-logs"
  env                = var.env
  project            = var.project
  purpose            = "Store S3 access logs for screenshot bucket"
  versioning_enabled = true

  lifecycle_rules = [{
    id                         = "access_logs_lifecycle"
    status                     = "Enabled"
    expiration_days            = 90
    noncurrent_expiration_days = 30
    incomplete_multipart_days  = 7
  }]
}
