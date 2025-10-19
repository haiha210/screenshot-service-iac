# ECS Auto Scaling Configuration

# Register ECS service as scalable target
resource "aws_appautoscaling_target" "ecs_target" {
  count = var.ecs_autoscaling_enabled ? 1 : 0

  max_capacity       = var.ecs_max_capacity
  min_capacity       = var.ecs_min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = {
    Name        = "${var.project}-${var.env}-ecs-autoscaling-target"
    Environment = var.env
    Project     = var.project
  }
}

# Auto Scaling Policy - CPU Based
resource "aws_appautoscaling_policy" "ecs_cpu" {
  count = var.ecs_autoscaling_enabled ? 1 : 0

  name               = "${var.project}-${var.env}-ecs-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.ecs_autoscale_cpu_target
    scale_in_cooldown  = var.ecs_scale_in_cooldown
    scale_out_cooldown = var.ecs_scale_out_cooldown

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

# Auto Scaling Policy - Memory Based
resource "aws_appautoscaling_policy" "ecs_memory" {
  count = var.ecs_autoscaling_enabled ? 1 : 0

  name               = "${var.project}-${var.env}-ecs-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.ecs_autoscale_memory_target
    scale_in_cooldown  = var.ecs_scale_in_cooldown
    scale_out_cooldown = var.ecs_scale_out_cooldown

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

# Auto Scaling Policy - SQS Queue Depth Based (Step Scaling)
# Using Step Scaling instead of Target Tracking for better control
resource "aws_appautoscaling_policy" "ecs_sqs_scale_up" {
  count = var.ecs_autoscaling_enabled ? 1 : 0

  name               = "${var.project}-${var.env}-ecs-sqs-scale-up"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.ecs_scale_out_cooldown
    metric_aggregation_type = "Average"

    # Scale up by 1 when queue has 5-10 messages
    step_adjustment {
      metric_interval_lower_bound = 0
      metric_interval_upper_bound = 10
      scaling_adjustment          = 1
    }

    # Scale up by 3 when queue has 10-30 messages
    step_adjustment {
      metric_interval_lower_bound = 10
      metric_interval_upper_bound = 30
      scaling_adjustment          = 3
    }

    # Scale up by 5 when queue has 30+ messages
    step_adjustment {
      metric_interval_lower_bound = 30
      scaling_adjustment          = 5
    }
  }
}

resource "aws_appautoscaling_policy" "ecs_sqs_scale_down" {
  count = var.ecs_autoscaling_enabled ? 1 : 0

  name               = "${var.project}-${var.env}-ecs-sqs-scale-down"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target[0].resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target[0].service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = var.ecs_scale_in_cooldown
    metric_aggregation_type = "Average"

    # Scale down by 1 when queue is empty
    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

# CloudWatch Alarm - SQS Queue Depth High (Trigger Scale Up)
resource "aws_cloudwatch_metric_alarm" "sqs_high" {
  count = var.ecs_autoscaling_enabled ? 1 : 0

  alarm_name          = "${var.project}-${var.env}-sqs-queue-depth-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Average"
  threshold           = var.ecs_autoscale_sqs_messages_per_task
  alarm_description   = "Trigger scale up when SQS queue depth is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = local.sqs_queue_name
  }

  alarm_actions = [aws_appautoscaling_policy.ecs_sqs_scale_up[0].arn]

  tags = {
    Name        = "${var.project}-${var.env}-sqs-high-alarm"
    Environment = var.env
    Project     = var.project
  }
}

# CloudWatch Alarm - SQS Queue Depth Low (Trigger Scale Down)
resource "aws_cloudwatch_metric_alarm" "sqs_low" {
  count = var.ecs_autoscaling_enabled ? 1 : 0

  alarm_name          = "${var.project}-${var.env}-sqs-queue-depth-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 3
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Trigger scale down when SQS queue is empty"
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = local.sqs_queue_name
  }

  alarm_actions = [aws_appautoscaling_policy.ecs_sqs_scale_down[0].arn]

  tags = {
    Name        = "${var.project}-${var.env}-sqs-low-alarm"
    Environment = var.env
    Project     = var.project
  }
}

# CloudWatch Alarm - ECS CPU High
resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  count = var.ecs_autoscaling_enabled ? 1 : 0

  alarm_name          = "${var.project}-${var.env}-ecs-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.ecs_autoscale_cpu_target
  alarm_description   = "Alert when ECS CPU utilization is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = aws_ecs_service.main.name
    ClusterName = aws_ecs_cluster.main.name
  }

  tags = {
    Name        = "${var.project}-${var.env}-ecs-cpu-high-alarm"
    Environment = var.env
    Project     = var.project
  }
}

# CloudWatch Alarm - ECS Memory High
resource "aws_cloudwatch_metric_alarm" "ecs_memory_high" {
  count = var.ecs_autoscaling_enabled ? 1 : 0

  alarm_name          = "${var.project}-${var.env}-ecs-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = var.ecs_autoscale_memory_target
  alarm_description   = "Alert when ECS memory utilization is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ServiceName = aws_ecs_service.main.name
    ClusterName = aws_ecs_cluster.main.name
  }

  tags = {
    Name        = "${var.project}-${var.env}-ecs-memory-high-alarm"
    Environment = var.env
    Project     = var.project
  }
}

# Outputs
output "autoscaling_target_arn" {
  description = "ARN of the Auto Scaling target"
  value       = var.ecs_autoscaling_enabled ? aws_appautoscaling_target.ecs_target[0].arn : null
}

output "autoscaling_policy_cpu_arn" {
  description = "ARN of the CPU-based Auto Scaling policy"
  value       = var.ecs_autoscaling_enabled ? aws_appautoscaling_policy.ecs_cpu[0].arn : null
}

output "autoscaling_policy_memory_arn" {
  description = "ARN of the Memory-based Auto Scaling policy"
  value       = var.ecs_autoscaling_enabled ? aws_appautoscaling_policy.ecs_memory[0].arn : null
}

output "autoscaling_policy_sqs_scale_up_arn" {
  description = "ARN of the SQS-based scale up policy"
  value       = var.ecs_autoscaling_enabled ? aws_appautoscaling_policy.ecs_sqs_scale_up[0].arn : null
}

output "autoscaling_policy_sqs_scale_down_arn" {
  description = "ARN of the SQS-based scale down policy"
  value       = var.ecs_autoscaling_enabled ? aws_appautoscaling_policy.ecs_sqs_scale_down[0].arn : null
}
