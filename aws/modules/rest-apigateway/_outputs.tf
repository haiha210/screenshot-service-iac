output "api_gateway_execution_arn" {
  description = "Execution ARN part to be used in lambda_permission's source_arn when allowing API Gateway to invoke a Lambda function."
  value       = var.rest_api != null ? aws_api_gateway_rest_api.rest_api[0].execution_arn : null
}
output "api_gateway_id" {
  description = "ID of the REST API"
  value       = var.rest_api != null ? aws_api_gateway_rest_api.rest_api[0].id : null
}
output "api_gateway_name" {
  description = "Name of the REST API"
  value       = var.rest_api != null ? aws_api_gateway_rest_api.rest_api[0].name : null
}
output "api_stage_arn" {
  description = "ARN of the REST API stage"
  value       = var.rest_api != null ? aws_api_gateway_stage.rest_api_stage[0].arn : null
}
output "api_deployment_invoke_url" {
  description = "Invoke url of REST API Deployment"
  value       = var.rest_api != null ? aws_api_gateway_stage.rest_api_stage[0].invoke_url : null
}
output "regional_domain_name" {
  description = "Hostname for the custom domain's regional endpoint"
  value       = var.custom_domain != null ? aws_api_gateway_domain_name.custom_domain[0].regional_domain_name : null
}
output "regional_zone_id" {
  description = "Hosted zone ID for the regional endpoint"
  value       = var.custom_domain != null ? aws_api_gateway_domain_name.custom_domain[0].regional_zone_id : null
}
output "vpc_link_id" {
  description = "Identifier of the VpcLink"
  value       = var.vpc_link != null ? aws_api_gateway_vpc_link.vpc_link[0].id : null
}
