# Data sources
data "aws_region" "current" {}

# Remote state data sources
data "terraform_remote_state" "general" {
  backend = "s3"
  config = {
    bucket = "screenshot-service-prd-iac-state"
    key    = "general/terraform.prd.tfstate"
    region = "ap-southeast-1"
  }
}

# Local values
locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region     = data.aws_region.current.id
}
