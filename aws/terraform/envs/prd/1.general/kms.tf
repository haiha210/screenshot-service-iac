# KMS Key for CloudWatch Logs encryption
resource "aws_kms_key" "cloudwatch_logs" {
  description             = "KMS key for encrypting CloudWatch Logs for ${var.project}-${var.env}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = templatefile("${path.module}/../../../../templates/kms-cloudwatch-logs-policy.json", {
    account_id = local.aws_account_id
    region     = local.aws_region
  })

  tags = {
    Name        = "${var.project}-${var.env}-cloudwatch-logs-kms"
    Environment = var.env
    Project     = var.project
    Purpose     = "CloudWatch Logs Encryption"
  }
}

resource "aws_kms_alias" "cloudwatch_logs" {
  name          = "alias/${var.project}-${var.env}-cloudwatch-logs"
  target_key_id = aws_kms_key.cloudwatch_logs.key_id
}

# KMS Key for DynamoDB encryption
resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for encrypting DynamoDB tables for ${var.project}-${var.env}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = templatefile("${path.module}/../../../../templates/kms-dynamodb-policy.json", {
    account_id = local.aws_account_id
    region     = local.aws_region
  })

  tags = {
    Name        = "${var.project}-${var.env}-dynamodb-kms"
    Environment = var.env
    Project     = var.project
    Purpose     = "DynamoDB Encryption"
  }
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${var.project}-${var.env}-dynamodb"
  target_key_id = aws_kms_key.dynamodb.key_id
}

# KMS Key for ECR encryption
resource "aws_kms_key" "ecr" {
  description             = "KMS key for encrypting ECR repositories for ${var.project}-${var.env}"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  policy = templatefile("${path.module}/../../../../templates/kms-ecr-policy.json", {
    account_id = local.aws_account_id
    region     = local.aws_region
  })

  tags = {
    Name        = "${var.project}-${var.env}-ecr-kms"
    Environment = var.env
    Project     = var.project
    Purpose     = "ECR Repository Encryption"
  }
}

resource "aws_kms_alias" "ecr" {
  name          = "alias/${var.project}-${var.env}-ecr"
  target_key_id = aws_kms_key.ecr.key_id
}
