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

# VPC Subnet Outputs
output "private_subnet_ids" {
  value       = module.vpc.subnet_private_id
  description = "List of private subnet IDs"
}

output "public_subnet_ids" {
  value       = module.vpc.subnet_public_id
  description = "List of public subnet IDs"
}

# VPC Endpoints Outputs
output "dynamodb_vpc_endpoint_id" {
  value       = aws_vpc_endpoint.dynamodb.id
  description = "ID of the DynamoDB VPC endpoint"
}

output "s3_vpc_endpoint_id" {
  value       = aws_vpc_endpoint.s3.id
  description = "ID of the S3 VPC endpoint"
}

output "sqs_vpc_endpoint_id" {
  value       = aws_vpc_endpoint.sqs.id
  description = "ID of the SQS VPC endpoint"
}

output "ecr_api_vpc_endpoint_id" {
  value       = aws_vpc_endpoint.ecr_api.id
  description = "ID of the ECR API VPC endpoint"
}

output "ecr_dkr_vpc_endpoint_id" {
  value       = aws_vpc_endpoint.ecr_dkr.id
  description = "ID of the ECR Docker VPC endpoint"
}

output "logs_vpc_endpoint_id" {
  value       = aws_vpc_endpoint.logs.id
  description = "ID of the CloudWatch Logs VPC endpoint"
}

output "vpc_endpoints_security_group_id" {
  value       = aws_security_group.vpc_endpoints.id
  description = "ID of the VPC endpoints security group"
}

# S3 Bucket Outputs
output "screenshots_bucket_name" {
  value       = module.screenshots_bucket.bucket_id
  description = "Name of the screenshots S3 bucket"
}

output "screenshots_bucket_arn" {
  value       = module.screenshots_bucket.bucket_arn
  description = "ARN of the screenshots S3 bucket"
}

output "screenshots_bucket_domain_name" {
  value       = module.screenshots_bucket.bucket_domain_name
  description = "Domain name of the screenshots S3 bucket"
}

output "screenshots_bucket_regional_domain_name" {
  value       = module.screenshots_bucket.bucket_regional_domain_name
  description = "Regional domain name of the screenshots S3 bucket"
}

# SQS Queue Outputs
output "screenshot_queue_url" {
  value       = module.screenshot_queue.queue_id
  description = "URL of the main screenshot processing queue"
}

output "screenshot_queue_arn" {
  value       = module.screenshot_queue.queue_arn
  description = "ARN of the main screenshot processing queue"
}

output "screenshot_dlq_url" {
  value       = module.screenshot_dlq.queue_id
  description = "URL of the screenshot dead letter queue"
}

output "screenshot_dlq_arn" {
  value       = module.screenshot_dlq.queue_arn
  description = "ARN of the screenshot dead letter queue"
}

output "screenshot_priority_queue_url" {
  value       = module.screenshot_priority_queue.queue_id
  description = "URL of the priority screenshot processing queue"
}

output "screenshot_priority_queue_arn" {
  value       = module.screenshot_priority_queue.queue_arn
  description = "ARN of the priority screenshot processing queue"
}

output "screenshot_fifo_queue_url" {
  value       = var.env == "prd" ? module.screenshot_fifo_queue[0].queue_id : null
  description = "URL of the FIFO screenshot processing queue (production only)"
}

output "screenshot_fifo_queue_arn" {
  value       = var.env == "prd" ? module.screenshot_fifo_queue[0].queue_arn : null
  description = "ARN of the FIFO screenshot processing queue (production only)"
}
