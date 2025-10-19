# Remote state references
data "terraform_remote_state" "general" {
  backend = "s3"
  config = {
    bucket = "screenshot-service-dev-iac-state"
    key    = "general/terraform.dev.tfstate"
    region = var.region
  }
}

# Data sources
data "aws_region" "current" {}

# Local values
locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region     = data.aws_region.current.id
}
