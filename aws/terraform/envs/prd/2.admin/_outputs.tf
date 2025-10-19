# Outputs

output "deploy_user_name" {
  description = "IAM user name for deployment"
  value       = aws_iam_user.deploy.name
}

output "deploy_user_arn" {
  description = "ARN of deployment user"
  value       = aws_iam_user.deploy.arn
}

output "deploy_access_key_id" {
  description = "Access key ID for deployment user"
  value       = aws_iam_access_key.deploy.id
  sensitive   = true
}

output "deploy_secret_access_key" {
  description = "Secret access key for deployment user"
  value       = aws_iam_access_key.deploy.secret
  sensitive   = true
}
