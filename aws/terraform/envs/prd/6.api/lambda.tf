# Lambda Functions for Screenshot Service
# Configuration loaded from _data.tf

# IAM Role for Lambda
resource "aws_iam_role" "lambda_execution" {
  name               = "screenshot-lambda-execution-${var.env}"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# IAM Policy for Lambda: DynamoDB, S3, SQS
resource "aws_iam_policy" "lambda_policy" {
  name        = "screenshot-lambda-policy-${var.env}"
  description = "Allow Lambda to access DynamoDB, S3, SQS"
  policy      = data.aws_iam_policy_document.lambda_policy.json
}

data "aws_iam_policy_document" "lambda_policy" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [
      data.terraform_remote_state.databases.outputs.screenshot_results_table_arn,
      "${data.terraform_remote_state.databases.outputs.screenshot_results_table_arn}/*"
    ]
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "${data.terraform_remote_state.general.outputs.screenshots_bucket_arn}/*"
    ]
  }
  statement {
    actions = [
      "sqs:SendMessage",
      "sqs:GetQueueAttributes"
    ]
    resources = [
      data.terraform_remote_state.general.outputs.screenshot_queue_arn
    ]
  }
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Manage all Lambda functions dynamically from the lambda_functions map
resource "aws_lambda_function" "functions" {
  for_each = local.lambda_functions

  function_name     = "${each.key}-${var.env}"
  s3_bucket         = data.aws_s3_object.lambda_zips[each.key].bucket
  s3_key            = data.aws_s3_object.lambda_zips[each.key].key
  s3_object_version = data.aws_s3_object.lambda_zips[each.key].version_id
  source_code_hash  = data.aws_s3_object.lambda_zips[each.key].etag

  handler     = each.value.handler
  runtime     = each.value.runtime
  timeout     = try(each.value.timeout, 30)
  memory_size = try(each.value.memory_size, 128)

  role = aws_iam_role.lambda_execution.arn

  environment {
    variables = merge(
      try(each.value.environment, {}),
      {
        DYNAMODB_TABLE_NAME = data.terraform_remote_state.databases.outputs.screenshot_results_table_name
        S3_BUCKET_NAME      = data.terraform_remote_state.general.outputs.screenshots_bucket_name
        SQS_QUEUE_URL       = data.terraform_remote_state.general.outputs.screenshot_queue_url
      }
    )
  }

  description = try(each.value.description, "")

  # Reserved concurrent executions if specified
  reserved_concurrent_executions = try(each.value.reserved_concurrent_executions, null)

  tags = {
    Name        = "${each.key}-${var.env}"
    Environment = var.env
    Project     = var.project
  }
}

# Lambda permissions for API Gateway to invoke functions
resource "aws_lambda_permission" "api_gateway" {
  for_each = local.lambda_functions

  statement_id  = "AllowAPIGatewayInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.functions[each.key].function_name
  principal     = "apigateway.amazonaws.com"

  # Allow invocation from the API Gateway REST API
  source_arn = "${module.rest_apigateway.api_gateway_execution_arn}/*/*"
}

