# DynamoDB Tables for Screenshots Service

# Screenshots Results Table (Main table used by backend service)
# This table structure matches the LocalStack configuration in:
# screenshot-service-be/scripts/init-awslocal.sh
resource "aws_dynamodb_table" "screenshot_results" {
  name         = "screenshot-results-${var.env}"
  billing_mode = var.dynamodb_billing_mode
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "createdAt"
    type = "S"
  }

  # Global Secondary Index for querying by status and createdAt
  # Used by backend service's queryScreenshotsByStatus method
  # Matches LocalStack GSI: "status-createdAt-index"
  global_secondary_index {
    name            = "status-createdAt-index"
    hash_key        = "status"
    range_key       = "createdAt"
    projection_type = "ALL"

    # Conditional throughput settings for compatibility with LocalStack
    read_capacity  = var.dynamodb_billing_mode == "PROVISIONED" ? 5 : null
    write_capacity = var.dynamodb_billing_mode == "PROVISIONED" ? 5 : null
  }

  # Conditional read/write capacity for table (when using PROVISIONED mode)
  read_capacity  = var.dynamodb_billing_mode == "PROVISIONED" ? 5 : null
  write_capacity = var.dynamodb_billing_mode == "PROVISIONED" ? 5 : null

  # Enable point-in-time recovery
  point_in_time_recovery {
    enabled = var.enable_dynamodb_backup
  }

  # Server-side encryption with Customer Managed Key (CMK)
  server_side_encryption {
    enabled     = true
    kms_key_arn = data.terraform_remote_state.general.outputs.dynamodb_kms_key_arn
  }

  tags = {
    Name        = "screenshot-results-${var.env}"
    Environment = var.env
    Project     = var.project
    Purpose     = "Store screenshot processing results and status"
  }
}
