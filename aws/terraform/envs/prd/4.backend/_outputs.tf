output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = module.rest_apigateway.api_deployment_invoke_url
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = module.rest_apigateway.api_gateway_id
}

output "lambda_functions" {
  description = "Map of Lambda function names and ARNs"
  value = {
    for name, fn in aws_lambda_function.functions : name => {
      arn           = fn.arn
      function_name = fn.function_name
      invoke_arn    = fn.invoke_arn
    }
  }
}

output "lambda_function_names" {
  description = "List of Lambda function names"
  value       = [for name, fn in aws_lambda_function.functions : fn.function_name]
}
