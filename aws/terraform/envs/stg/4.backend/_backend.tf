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
    bucket         = "screenshot-service-stg-iac-state"
    key            = "backend/terraform.stg.tfstate"
    region         = "ap-southeast-1"
    encrypt        = true
    kms_key_id     = "alias/screenshot-service-stg-iac"
    dynamodb_table = "screenshot-service-stg-terraform-state-lock"
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.env
    }
  }
}
