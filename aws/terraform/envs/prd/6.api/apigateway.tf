# CloudWatch Log Group for API Gateway
# Access logging is mandatory for security and compliance
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.project}-${var.env}-screenshots-api"
  retention_in_days = 7
  kms_key_id        = local.cloudwatch_logs_kms_key_arn

  tags = {
    Name        = "${var.project}-${var.env}-api-gateway-logs"
    Environment = var.env
    Project     = var.project
  }
}

# API Gateway REST API using module
module "rest_apigateway" {
  source = "../../../../modules/rest-apigateway"

  project = var.project
  env     = var.env

  rest_api = {
    name                         = "screenshots-api"
    stage_name                   = var.api_stage_name
    endpoint_type                = "REGIONAL"
    disable_execute_api_endpoint = false

    body = jsonencode(local.api_spec)

    # Cache configuration for improved performance
    cache_cluster_enabled = var.enable_api_cache
    cache_cluster_size    = var.api_cache_size
    cache_ttl_in_seconds  = var.api_cache_ttl

    # Access logging configuration - REQUIRED for security and compliance
    access_log_settings = {
      log_group_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
      format = jsonencode({
        requestTime              = "$context.requestTime"
        requestId                = "$context.requestId"
        httpMethod               = "$context.httpMethod"
        path                     = "$context.path"
        resourcePath             = "$context.resourcePath"
        status                   = "$context.status"
        responseLatency          = "$context.responseLatency"
        xrayTraceId              = "$context.xrayTraceId"
        integrationRequestId     = "$context.integration.requestId"
        functionResponseStatus   = "$context.integration.status"
        integrationLatency       = "$context.integration.latency"
        integrationServiceStatus = "$context.integration.integrationStatus"
        ip                       = "$context.identity.sourceIp"
        userAgent                = "$context.identity.userAgent"
        principalId              = "$context.authorizer.principalId"
      })
    }
  }
}

# API Gateway Usage Plan (Optional)
resource "aws_api_gateway_usage_plan" "main" {
  name        = "${var.project}-${var.env}-usage-plan"
  description = "Usage plan for ${var.project} ${var.env} environment"

  api_stages {
    api_id = module.rest_apigateway.api_gateway_id
    stage  = var.api_stage_name
  }

  quota_settings {
    limit  = 10000
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 200
    rate_limit  = 100
  }

  tags = {
    Name        = "${var.project}-${var.env}-usage-plan"
    Environment = var.env
    Project     = var.project
  }
}
