# IAM Role for Lambda functions
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project}-${var.env}-lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.env}-lambda-execution-role"
    Environment = var.env
    Project     = var.project
  }
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Custom policy for Lambda functions
resource "aws_iam_role_policy" "lambda_custom_policy" {
  name = "${var.project}-${var.env}-lambda-custom-policy"
  role = aws_iam_role.lambda_execution_role.id

  policy = templatefile("${path.module}/../../../../templates/lambda-custom-policy.json", {
    env        = var.env
    region     = local.aws_region
    account_id = local.aws_account_id
    project    = var.project
  })
}

# Lambda Functions - Created dynamically from config
resource "aws_lambda_function" "functions" {
  for_each = local.lambda_functions

  function_name = "${var.project}-${var.env}-${each.key}"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = each.value.handler
  runtime       = each.value.runtime
  timeout       = each.value.timeout
  memory_size   = each.value.memory_size
  description   = each.value.description

  # Placeholder for deployment package - replace with actual deployment
  filename         = "${path.module}/lambda-placeholder.zip"
  source_code_hash = fileexists("${path.module}/lambda-placeholder.zip") ? filebase64sha256("${path.module}/lambda-placeholder.zip") : null

  environment {
    variables = merge(
      each.value.environment,
      {
        ENV     = var.env
        PROJECT = var.project
        REGION  = local.aws_region
      }
    )
  }

  tracing_config {
    mode = "Active"
  }

  tags = {
    Name        = "${var.project}-${var.env}-${each.key}"
    Environment = var.env
    Project     = var.project
    ManagedBy   = "Terraform"
  }

  lifecycle {
    ignore_changes = [
      filename,
      source_code_hash
    ]
  }
}

# Lambda Permissions for API Gateway
resource "aws_lambda_permission" "api_gateway_invoke" {
  for_each = {
    for name, config in local.lambda_functions :
    name => config
    if config.enable_api_gateway
  }

  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.functions[each.key].function_name
  principal     = "apigateway.amazonaws.com"

  # Allow invocation from any method/path in this API
  source_arn = "${module.rest_apigateway.api_gateway_execution_arn}/*/*/*"
}

# CloudWatch Log Groups for Lambda functions
resource "aws_cloudwatch_log_group" "lambda_logs" {
  for_each = local.lambda_functions

  name              = "/aws/lambda/${var.project}-${var.env}-${each.key}"
  retention_in_days = 7
  kms_key_id        = local.cloudwatch_logs_kms_key_arn

  tags = {
    Name        = "${var.project}-${var.env}-${each.key}-logs"
    Environment = var.env
    Project     = var.project
  }
}
