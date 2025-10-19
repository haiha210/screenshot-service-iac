locals {
  # AWS context
  vpc_id                      = data.terraform_remote_state.general.outputs.vpc_id
  lambda_role_arn             = try(data.terraform_remote_state.general.outputs.iam_role_lambda_example_arn, null)
  cloudwatch_logs_kms_key_arn = data.terraform_remote_state.general.outputs.cloudwatch_logs_kms_key_arn
  aws_account_id              = data.aws_caller_identity.current.account_id
  aws_region                  = data.aws_region.current.id

  # Lambda functions configuration now loaded from _data.tf
  lambda_functions = local.lambda_functions_merged

  # Generate API Gateway paths dynamically
  # First, group functions by api_path
  functions_by_path = {
    for fn_name, fn_config in local.lambda_functions :
    fn_config.api_path => fn_name...
    if fn_config.api_path != null
  }

  # Then create api_paths with all HTTP methods for each path
  api_paths = {
    for path, fn_names in local.functions_by_path :
    path => {
      for fn_name in fn_names :
      lower(local.lambda_functions[fn_name].http_method) => {
        summary     = local.lambda_functions[fn_name].description
        description = local.lambda_functions[fn_name].description
        responses = {
          "200" = {
            description = "Successful response"
            content = {
              "application/json" = {
                schema = {
                  type = "object"
                }
              }
            }
          }
          "400" = {
            description = "Bad request"
          }
          "500" = {
            description = "Internal server error"
          }
        }
        x-amazon-apigateway-integration = {
          uri                 = "arn:aws:apigateway:${local.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.functions[fn_name].arn}/invocations"
          httpMethod          = "POST"
          type                = "aws_proxy"
          passthroughBehavior = "when_no_match"
          contentHandling     = "CONVERT_TO_TEXT"
          timeoutInMillis     = local.lambda_functions[fn_name].timeout * 1000
        }
      }
    }
  }

  # Generate OpenAPI specification
  api_spec = {
    openapi = "3.0.1"
    info = {
      title       = "${var.project}-${var.env}-screenshots-api"
      description = "Screenshots Service REST API"
      version     = "1.0.0"
    }
    paths = local.api_paths
  }
}
