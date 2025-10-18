output "aws_account_id" {
  value       = <<VALUE

  Check AWS Env:
    Project : "${var.project}" | Env: "${var.env}"
    AWS Account ID: "${data.aws_caller_identity.current.account_id}"
    AWS Account ARN: "${data.aws_caller_identity.current.arn}"
  VALUE
  description = "Show information about project, environment and account"
}

#Output modules
output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "ID of VPC"
}

output "cloudwatch_logs_kms_key_arn" {
  value       = aws_kms_key.cloudwatch_logs.arn
  description = "ARN of KMS key for CloudWatch Logs encryption"
}

output "cloudwatch_logs_kms_key_id" {
  value       = aws_kms_key.cloudwatch_logs.key_id
  description = "ID of KMS key for CloudWatch Logs encryption"
}
