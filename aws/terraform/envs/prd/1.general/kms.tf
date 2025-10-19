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
