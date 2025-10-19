data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get outputs from 1.general (VPC, SQS, IAM roles)
data "terraform_remote_state" "general" {
  backend = "s3"
  config = {
    bucket = "screenshot-service-prd-iac-state"
    key    = "general/terraform.prd.tfstate"
    region = "ap-southeast-1"
  }
}

# Get outputs from 3.databases (DynamoDB tables)
data "terraform_remote_state" "databases" {
  backend = "s3"
  config = {
    bucket = "screenshot-service-prd-iac-state"
    key    = "databases/terraform.prd.tfstate"
    region = "ap-southeast-1"
  }
}
