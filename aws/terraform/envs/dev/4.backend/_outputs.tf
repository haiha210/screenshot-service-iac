# ECS Cluster Outputs
output "ecs_cluster_name" {
  description = "Name of the ECS cluster"
  value       = aws_ecs_cluster.main.name
}

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.main.arn
}

output "ecs_cluster_id" {
  description = "ID of the ECS cluster"
  value       = aws_ecs_cluster.main.id
}

# ECS Service Outputs
output "ecs_service_name" {
  description = "Name of the ECS service"
  value       = aws_ecs_service.main.name
}

output "ecs_service_id" {
  description = "ID of the ECS service"
  value       = aws_ecs_service.main.id
}

output "ecs_task_definition_arn" {
  description = "ARN of the ECS task definition"
  value       = aws_ecs_task_definition.main.arn
}

output "ecs_task_definition_family" {
  description = "Family of the ECS task definition"
  value       = aws_ecs_task_definition.main.family
}

output "ecs_task_definition_revision" {
  description = "Revision of the ECS task definition"
  value       = aws_ecs_task_definition.main.revision
}

# Security Group Outputs
output "ecs_tasks_security_group_id" {
  description = "ID of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.id
}

output "ecs_tasks_security_group_arn" {
  description = "ARN of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.arn
}

# Summary Output
output "ecs_deployment_info" {
  description = "Summary of ECS deployment configuration"
  value       = <<-EOT

  ECS Deployment Configuration:
    Cluster: ${aws_ecs_cluster.main.name}
    Service: ${aws_ecs_service.main.name}
    Task Family: ${aws_ecs_task_definition.main.family}
    Task Revision: ${aws_ecs_task_definition.main.revision}

    Auto Scaling: ${var.ecs_autoscaling_enabled ? "Enabled" : "Disabled"}
    Min Capacity: ${var.ecs_min_capacity}
    Max Capacity: ${var.ecs_max_capacity}

    CPU Target: ${var.ecs_autoscale_cpu_target}%
    Memory Target: ${var.ecs_autoscale_memory_target}%
    SQS Messages Per Task: ${var.ecs_autoscale_sqs_messages_per_task}

    Scale In Cooldown: ${var.ecs_scale_in_cooldown}s
    Scale Out Cooldown: ${var.ecs_scale_out_cooldown}s
  EOT
}
