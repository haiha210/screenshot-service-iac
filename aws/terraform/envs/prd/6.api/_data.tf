# Data sources for API module

# AWS context
data "aws_region" "current" {}

# Get outputs from 1.general module
data "terraform_remote_state" "general" {
  backend = "s3"
  config = {
    bucket = "screenshot-service-prd-iac-state"
    key    = "general/terraform.prd.tfstate"
    region = "ap-southeast-1"
  }
}

# Get outputs from 3.databases module
data "terraform_remote_state" "databases" {
  backend = "s3"
  config = {
    bucket = "screenshot-service-prd-iac-state"
    key    = "databases/terraform.prd.tfstate"
    region = "ap-southeast-1"
  }
}

# Lambda configuration from template
locals {
  # Load lambda config from YAML template
  lambda_template = yamldecode(file("${path.module}/../../../../templates/lambda-config.yaml"))

  # Merge template functions with custom overrides
  lambda_functions_merged = merge(
    # Convert template functions to our format
    {
      for func in local.lambda_template.functions : func.name => {
        filename                       = "${func.name}.zip"
        handler                        = func.handler
        runtime                        = func.runtime
        timeout                        = try(func.timeout, 30)
        memory_size                    = try(func.memory_size, 128)
        reserved_concurrent_executions = try(func.reserved_concurrent_executions, null)
        description                    = func.description
        api_path                       = try(func.api_path, null)
        http_method                    = try(func.http_method, "GET")
        environment                    = try(func.environment, {})
      }
    },
  )

  # Get artifacts bucket info from general module
  # artifacts_bucket_name = data.terraform_remote_state.general.outputs.artifacts_bucket_name
}

# # Data sources for Lambda deployment packages from S3
# data "aws_s3_object" "lambda_zips" {
#   for_each = local.lambda_functions_merged

#   bucket = local.artifacts_bucket_name
#   key    = "lambda/${each.value.filename}"
# }

# # Data source to read Swagger/OpenAPI specification (optional)
# data "aws_s3_object" "api_swagger" {
#   bucket = local.artifacts_bucket_name
#   key    = "swagger/api-spec.yaml"

#   # This will be used by API Gateway resource if needed
# }
