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
  value       = data.terraform_remote_state.general.outputs.vpc_id
  description = "ID of VPC"
}

output "cloudwatch_logs_kms_key_arn" {
  value       = data.terraform_remote_state.general.outputs.cloudwatch_logs_kms_key_arn
  description = "ARN of KMS key for CloudWatch Logs encryption"
}

output "cloudwatch_logs_kms_key_id" {
  value       = data.terraform_remote_state.general.outputs.cloudwatch_logs_kms_key_id
  description = "ID of KMS key for CloudWatch Logs encryption"
}

# DynamoDB Table Outputs
output "screenshot_results_table_name" {
  value       = aws_dynamodb_table.screenshot_results.name
  description = "Name of the screenshot results DynamoDB table"
}

output "screenshot_results_table_arn" {
  value       = aws_dynamodb_table.screenshot_results.arn
  description = "ARN of the screenshot results DynamoDB table"
}

output "screenshot_results_gsi_name" {
  value       = "status-createdAt-index"
  description = "Name of the Global Secondary Index for screenshot results table"
}

output "screenshot_results_table_id" {
  value       = aws_dynamodb_table.screenshot_results.id
  description = "ID of the screenshot results DynamoDB table"
}

output "screenshot_results_table_stream_arn" {
  value       = aws_dynamodb_table.screenshot_results.stream_arn
  description = "ARN of the DynamoDB table stream (if enabled)"
}

output "screenshot_results_table_stream_label" {
  value       = aws_dynamodb_table.screenshot_results.stream_label
  description = "Timestamp of the DynamoDB table stream (if enabled)"
}
