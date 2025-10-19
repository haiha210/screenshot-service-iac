###################
# General Initialization
###################
terraform {
  required_version = ">= 1.3.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    template = "~> 2.0"
  }
  backend "s3" {
    bucket         = "screenshot-service-dev-iac-state"
    key            = "general/terraform.dev.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    kms_key_id     = "alias/screenshot-service-dev-iac"
    dynamodb_table = "screenshot-service-dev-terraform-state-lock"
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.env
    }
  }
}
data "aws_caller_identity" "current" {}
