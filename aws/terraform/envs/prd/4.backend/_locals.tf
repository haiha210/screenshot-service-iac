# Local values for backend (ECS) configuration

locals {
  # VPC Configuration
  vpc_id             = data.terraform_remote_state.general.outputs.vpc_id
  vpc_cidr           = data.terraform_remote_state.general.outputs.vpc_cidr
  private_subnet_ids = data.terraform_remote_state.general.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.general.outputs.public_subnet_ids

  # SQS Queue Name from URL
  sqs_queue_name = split("/", data.terraform_remote_state.general.outputs.screenshot_queue_url)[4]

  # ECR Configuration (ECR repository is created in this module)
  ecr_repository_url = aws_ecr_repository.screenshot_service.repository_url
  container_image    = var.ecs_container_image != "" ? var.ecs_container_image : "${aws_ecr_repository.screenshot_service.repository_url}:latest"
}
