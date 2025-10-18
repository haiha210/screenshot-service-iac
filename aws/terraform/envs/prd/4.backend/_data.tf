data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get outputs from 1.general
data "terraform_remote_state" "general" {
  backend = "s3"
  config = {
    bucket = "screenshot-service-prd-iac-state"
    key    = "general/terraform.prod.tfstate"
    region = "ap-southeast-1"
  }
}
