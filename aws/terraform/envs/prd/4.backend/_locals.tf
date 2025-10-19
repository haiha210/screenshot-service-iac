# Local values for backend (ECS) configuration

locals {
  # VPC Configuration
  vpc_id             = data.terraform_remote_state.general.outputs.vpc_id
  private_subnet_ids = data.terraform_remote_state.general.outputs.private_subnet_ids
  public_subnet_ids  = data.terraform_remote_state.general.outputs.public_subnet_ids

  # SQS Queue Name from URL
  sqs_queue_name = split("/", data.terraform_remote_state.general.outputs.screenshot_queue_url)[4]

  # ECR Configuration
  ecr_repository_url = data.terraform_remote_state.general.outputs.ecr_repository_url
  container_image    = var.ecs_container_image != "" ? var.ecs_container_image : "${local.ecr_repository_url}:latest"
}
