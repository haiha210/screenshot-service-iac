# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = var.ecs_cluster_name

  # Enable CloudWatch Container Insights for monitoring
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project}-${var.env}-${var.ecs_cluster_name}"
    Environment = var.env
    Project     = var.project
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = var.ecs_task_definition_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_cpu
  memory                   = var.ecs_task_memory
  execution_role_arn       = data.terraform_remote_state.general.outputs.ecs_task_execution_role_arn
  task_role_arn            = data.terraform_remote_state.general.outputs.ecs_task_role_arn

  container_definitions = templatefile("${path.module}/../../../../templates/ecs-task-definition.json", {
    task_family          = var.ecs_task_definition_family
    task_cpu             = var.ecs_task_cpu
    task_memory          = var.ecs_task_memory
    execution_role_arn   = data.terraform_remote_state.general.outputs.ecs_task_execution_role_arn
    task_role_arn        = data.terraform_remote_state.general.outputs.ecs_task_role_arn
    service_name         = var.ecs_service_name
    container_image      = local.container_image
    container_port       = var.ecs_container_port
    project              = var.project
    env                  = var.env
    region               = var.region
    sqs_queue_url        = data.terraform_remote_state.general.outputs.screenshot_queue_url
    dynamodb_table_name  = data.terraform_remote_state.databases.outputs.screenshot_results_table_name
    s3_bucket_name       = data.terraform_remote_state.general.outputs.screenshots_bucket_name
  })

  tags = {
    Name        = "${var.project}-${var.env}-${var.ecs_task_definition_family}"
    Environment = var.env
    Project     = var.project
  }
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  # Enable CloudWatch Container Insights
  enable_execute_command = true

  network_configuration {
    subnets          = local.private_subnet_ids
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  # Deployment configuration
  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 100

  # Lifecycle: Ignore desired_count changes (managed by Auto Scaling)
  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    Name        = "${var.project}-${var.env}-${var.ecs_service_name}"
    Environment = var.env
    Project     = var.project
  }

  depends_on = [aws_ecs_task_definition.main]
}

# Security Group for ECS Tasks
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.project}-${var.env}-ecs-tasks-sg"
  description = "Security group for ECS tasks"
  vpc_id      = local.vpc_id

  # Allow outbound HTTPS traffic to VPC endpoints (SQS, DynamoDB, S3, ECR, CloudWatch)
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
    description = "HTTPS to AWS services via VPC endpoints"
  }

  tags = {
    Name        = "${var.project}-${var.env}-ecs-tasks-sg"
    Environment = var.env
    Project     = var.project
  }
}
