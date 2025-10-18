###################
# Create VPC and only one Nat Gateway for all AZs
###################
module "vpc" {
  source = "../../../../modules/vpc"
  #basic
  env     = var.env
  project = var.project
  region  = var.region

  #vpc
  vpc_cidr      = "10.0.0.0/16"
  public_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]

  # NAT Gateway configuration - use only one NAT Gateway for all AZs
  only_one_nat_gateway = true

  # VPC Flow Logs - capture rejected traffic for security monitoring
  vpc_flow_logs = {
    cloudwatch = {
      log_destination_arn  = aws_cloudwatch_log_group.vpc_flow_logs.arn
      log_destination_type = "cloud-watch-logs"
      traffic_type         = "REJECT"  # Capture only rejected traffic for security analysis
      iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
    }
  }
}