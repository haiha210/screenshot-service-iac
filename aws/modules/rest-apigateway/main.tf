# Create Rest API Gateway
resource "aws_api_gateway_rest_api" "rest_api" {
  count = var.rest_api != null ? 1 : 0

  name = "${var.project}-${var.env}-${var.rest_api.name}-rest-api-gateway"
  body = var.rest_api.body

  endpoint_configuration {
    types            = [var.rest_api.endpoint_type]
    vpc_endpoint_ids = var.rest_api.vpc_endpoint_ids
  }

  tags = {
    Name = "${var.project}-${var.env}-${var.rest_api.name}-rest-api-gateway"
  }
}

resource "aws_api_gateway_deployment" "rest_api_deployment" {
  count = var.rest_api != null ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id

  triggers = {
    redeployment = sha1(jsonencode(aws_api_gateway_rest_api.rest_api[0].body))
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_api_gateway_rest_api_policy.rest_api_policy]
}

resource "aws_api_gateway_stage" "rest_api_stage" {
  count = var.rest_api != null ? 1 : 0

  deployment_id        = aws_api_gateway_deployment.rest_api_deployment[0].id
  rest_api_id          = aws_api_gateway_rest_api.rest_api[0].id
  stage_name           = var.rest_api.stage_name != null ? var.rest_api.stage_name : "${var.project}-${var.env}-${var.rest_api.name}"
  xray_tracing_enabled = true

  # Enable caching for improved performance
  cache_cluster_enabled = var.rest_api.cache_cluster_enabled != null ? var.rest_api.cache_cluster_enabled : false
  cache_cluster_size    = var.rest_api.cache_cluster_size != null ? var.rest_api.cache_cluster_size : "0.5"

  dynamic "access_log_settings" {
    for_each = var.rest_api.access_log_settings != null ? [1] : []

    content {
      destination_arn = var.rest_api.access_log_settings.log_group_arn
      format          = replace(var.rest_api.access_log_settings.format, "\n", "")
    }
  }

  tags = {
    Name = "${var.project}-${var.env}-${var.rest_api.name}"
  }

  lifecycle {
    ignore_changes = [
      deployment_id,
      stage_name
    ]
  }
}

resource "aws_api_gateway_method_settings" "api_gateway_method_settings" {
  count = var.rest_api != null ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  stage_name  = aws_api_gateway_stage.rest_api_stage[0].stage_name
  method_path = "*/*"

  settings {
    metrics_enabled        = true
    logging_level          = "INFO"
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000

    # Cache settings for improved performance and reduced Lambda invocations
    caching_enabled      = var.rest_api.cache_cluster_enabled != null ? var.rest_api.cache_cluster_enabled : false
    cache_ttl_in_seconds = var.rest_api.cache_ttl_in_seconds != null ? var.rest_api.cache_ttl_in_seconds : 300
    cache_data_encrypted = true
  }
}

resource "aws_api_gateway_rest_api_policy" "rest_api_policy" {
  count = var.rest_api.policy != null ? 1 : 0

  rest_api_id = aws_api_gateway_rest_api.rest_api[0].id
  policy      = var.rest_api.policy.template
}

resource "aws_api_gateway_domain_name" "custom_domain" {
  count = var.custom_domain != null ? 1 : 0

  domain_name = var.custom_domain.name
  endpoint_configuration {
    types = [var.custom_domain.types]
  }
  regional_certificate_arn = var.custom_domain.regional_cert
}

resource "aws_api_gateway_base_path_mapping" "path_mapping" {
  count = var.custom_domain != null ? 1 : 0

  api_id      = aws_api_gateway_rest_api.rest_api[0].id
  stage_name  = aws_api_gateway_stage.rest_api_stage[0].stage_name
  domain_name = aws_api_gateway_domain_name.custom_domain[0].domain_name
}

resource "aws_api_gateway_vpc_link" "vpc_link" {
  count = var.vpc_link != null ? 1 : 0

  name        = "${var.project}-${var.env}-${var.vpc_link.name}-vpclink"
  target_arns = [var.vpc_link.target_arns]
}
