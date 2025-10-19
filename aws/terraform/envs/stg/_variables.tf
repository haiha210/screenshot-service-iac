# ECS Configuration Variables
variable "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "screenshots-ecs-cluster"
}

variable "ecs_task_definition_family" {
  description = "ECS task definition family name"
  type        = string
  default     = "screenshots-task"
}

variable "ecs_service_name" {
  description = "Name of the ECS service"
  type        = string
  default     = "screenshots-service"
}

variable "ecs_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

variable "ecs_task_cpu" {
  description = "CPU units for ECS task"
  type        = number
  default     = 512
}

variable "ecs_task_memory" {
  description = "Memory (MB) for ECS task"
  type        = number
  default     = 1024
}

variable "ecs_container_image" {
  description = "Docker image for ECS container. Leave empty to auto-use ECR repository URL"
  type        = string
  default     = ""
}

variable "ecs_container_port" {
  description = "Port exposed by ECS container"
  type        = number
  default     = 8080
}

# ECS Auto Scaling Configuration Variables
variable "ecs_autoscaling_enabled" {
  description = "Enable Auto Scaling for ECS service"
  type        = bool
  default     = true
}

variable "ecs_min_capacity" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 1
}

variable "ecs_max_capacity" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 10
}

variable "ecs_autoscale_cpu_target" {
  description = "Target CPU utilization percentage for Auto Scaling"
  type        = number
  default     = 70
}

variable "ecs_autoscale_memory_target" {
  description = "Target memory utilization percentage for Auto Scaling"
  type        = number
  default     = 80
}

variable "ecs_autoscale_sqs_messages_per_task" {
  description = "Target number of SQS messages per ECS task for scaling"
  type        = number
  default     = 5
}

variable "ecs_scale_in_cooldown" {
  description = "Cooldown period (seconds) for scale-in operations"
  type        = number
  default     = 300
}

variable "ecs_scale_out_cooldown" {
  description = "Cooldown period (seconds) for scale-out operations"
  type        = number
  default     = 60
}

# Project Configuration Variables
variable "project" {
  description = "Name of project"
  type        = string
}

variable "env" {
  description = "Name of project environment"
  type        = string
}

variable "region" {
  description = "Region of environment"
  type        = string
}

variable "api_stage_name" {
  description = "API Gateway stage name"
  type        = string
  default     = "v1"
}

variable "enable_api_cache" {
  description = "Enable API Gateway caching for improved performance"
  type        = bool
  default     = true
}

variable "api_cache_size" {
  description = "API Gateway cache cluster size in GB (0.5, 1.6, 6.1, 13.5, 28.4, 58.2, 118, 237)"
  type        = string
  default     = "0.5"
}

variable "api_cache_ttl" {
  description = "API Gateway cache TTL in seconds"
  type        = number
  default     = 300
}

# DynamoDB Configuration Variables
variable "enable_dynamodb_backup" {
  description = "Enable point-in-time recovery for DynamoDB tables"
  type        = bool
  default     = true
}

variable "analytics_data_ttl_days" {
  description = "Number of days to retain analytics data (TTL)"
  type        = number
  default     = 90
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode (PROVISIONED or PAY_PER_REQUEST)"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PROVISIONED", "PAY_PER_REQUEST"], var.dynamodb_billing_mode)
    error_message = "Billing mode must be either PROVISIONED or PAY_PER_REQUEST."
  }
}

