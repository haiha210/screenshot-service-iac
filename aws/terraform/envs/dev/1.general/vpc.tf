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
  vpc_cidr      = "10.2.0.0/16"
  public_cidrs  = ["10.2.1.0/24", "10.2.2.0/24"]
  private_cidrs = ["10.2.3.0/24", "10.2.4.0/24"]

  # NAT Gateway configuration - use only one NAT Gateway for all AZs
  only_one_nat_gateway = true

  # VPC Flow Logs - capture rejected traffic for security monitoring
  vpc_flow_logs = {
    cloudwatch = {
      log_destination_arn  = aws_cloudwatch_log_group.vpc_flow_logs.arn
      log_destination_type = "cloud-watch-logs"
      traffic_type         = "REJECT" # Capture only rejected traffic for security analysis
      iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
    }
  }
}

# VPC Endpoint for DynamoDB (Gateway endpoint - no additional charges)
resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name        = "${var.project}-${var.env}-dynamodb-endpoint"
    Environment = var.env
    Project     = var.project
    Purpose     = "Enable private access to DynamoDB from VPC"
  }
}

# VPC Endpoint for S3 (Gateway endpoint - no additional charges)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name        = "${var.project}-${var.env}-s3-endpoint"
    Environment = var.env
    Project     = var.project
    Purpose     = "Enable private access to S3 from VPC"
  }
}

# Security Group for Interface VPC Endpoints
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.project}-${var.env}-vpc-endpoints-sg"
  description = "Security group for VPC interface endpoints"
  vpc_id      = module.vpc.vpc_id

  # Allow HTTPS traffic from VPC
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.2.0.0/16"] # VPC CIDR block
    description = "HTTPS access from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name        = "${var.project}-${var.env}-vpc-endpoints-sg"
    Environment = var.env
    Project     = var.project
    Purpose     = "Security group for VPC interface endpoints"
  }
}

# VPC Endpoint for SQS (Interface endpoint)
resource "aws_vpc_endpoint" "sqs" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.region}.sqs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.subnet_private_id
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  # Enable private DNS resolution
  private_dns_enabled = true

  tags = {
    Name        = "${var.project}-${var.env}-sqs-endpoint"
    Environment = var.env
    Project     = var.project
    Purpose     = "Enable private access to SQS from VPC"
  }
}

# VPC Endpoint for ECR API (Interface endpoint - required for ECS)
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.subnet_private_id
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = {
    Name        = "${var.project}-${var.env}-ecr-api-endpoint"
    Environment = var.env
    Project     = var.project
    Purpose     = "Enable ECS tasks to pull images from ECR (API calls)"
  }
}

# VPC Endpoint for ECR Docker Registry (Interface endpoint - required for ECS)
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.subnet_private_id
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = {
    Name        = "${var.project}-${var.env}-ecr-dkr-endpoint"
    Environment = var.env
    Project     = var.project
    Purpose     = "Enable ECS tasks to pull Docker images from ECR"
  }
}

# VPC Endpoint for CloudWatch Logs (Interface endpoint - required for ECS logging)
resource "aws_vpc_endpoint" "logs" {
  vpc_id             = module.vpc.vpc_id
  service_name       = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = module.vpc.subnet_private_id
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = {
    Name        = "${var.project}-${var.env}-logs-endpoint"
    Environment = var.env
    Project     = var.project
    Purpose     = "Enable ECS tasks to send logs to CloudWatch"
  }
}
