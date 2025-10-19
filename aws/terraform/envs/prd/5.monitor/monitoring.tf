# CloudWatch Dashboard for ECS Auto Scaling Monitoring

resource "aws_cloudwatch_dashboard" "ecs_autoscaling" {
  dashboard_name = "${var.project}-${var.env}-ecs-autoscaling"

  dashboard_body = jsonencode({
    widgets = [
      # ECS Task Count
      {
        type = "metric"
        properties = {
          metrics = [
            ["ECS/ContainerInsights", "RunningTaskCount", "ServiceName", data.terraform_remote_state.backend.outputs.ecs_service_name, "ClusterName", data.terraform_remote_state.backend.outputs.ecs_cluster_name, { stat = "Average", label = "Running Tasks" }],
            [".", "DesiredTaskCount", ".", ".", ".", ".", { stat = "Average", label = "Desired Tasks" }]
          ]
          period = 60
          stat   = "Average"
          region = var.region
          title  = "ECS Task Count"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
        width  = 12
        height = 6
        x      = 0
        y      = 0
      },

      # SQS Queue Depth
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", split("/", data.terraform_remote_state.general.outputs.screenshot_queue_url)[4], { stat = "Average", label = "Messages in Queue" }],
            [".", "ApproximateNumberOfMessagesNotVisible", ".", ".", { stat = "Average", label = "Messages in Flight" }]
          ]
          period = 60
          stat   = "Average"
          region = var.region
          title  = "SQS Queue Metrics"
          yAxis = {
            left = {
              min = 0
            }
          }
        }
        width  = 12
        height = 6
        x      = 12
        y      = 0
      },

      # CPU Utilization
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", data.terraform_remote_state.backend.outputs.ecs_service_name, "ClusterName", data.terraform_remote_state.backend.outputs.ecs_cluster_name, { stat = "Average", label = "CPU Utilization" }]
          ]
          period = 60
          stat   = "Average"
          region = var.region
          title  = "ECS CPU Utilization"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
          annotations = {
            horizontal = [
              {
                value = var.ecs_autoscale_cpu_target
                label = "Target"
                color = "#ff7f0e"
              }
            ]
          }
        }
        width  = 12
        height = 6
        x      = 0
        y      = 6
      },

      # Memory Utilization
      {
        type = "metric"
        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ServiceName", data.terraform_remote_state.backend.outputs.ecs_service_name, "ClusterName", data.terraform_remote_state.backend.outputs.ecs_cluster_name, { stat = "Average", label = "Memory Utilization" }]
          ]
          period = 60
          stat   = "Average"
          region = var.region
          title  = "ECS Memory Utilization"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
          annotations = {
            horizontal = [
              {
                value = var.ecs_autoscale_memory_target
                label = "Target"
                color = "#ff7f0e"
              }
            ]
          }
        }
        width  = 12
        height = 6
        x      = 12
        y      = 6
      },

      # Messages Per Task (Custom Metric)
      {
        type = "metric"
        properties = {
          metrics = [
            [{ expression = "m1 / GREATEST(m2, 1)", label = "Messages Per Task", id = "e1" }],
            ["AWS/SQS", "ApproximateNumberOfMessagesVisible", "QueueName", split("/", data.terraform_remote_state.general.outputs.screenshot_queue_url)[4], { stat = "Average", id = "m1", visible = false }],
            ["ECS/ContainerInsights", "RunningTaskCount", "ServiceName", data.terraform_remote_state.backend.outputs.ecs_service_name, "ClusterName", data.terraform_remote_state.backend.outputs.ecs_cluster_name, { stat = "Average", id = "m2", visible = false }]
          ]
          period = 60
          stat   = "Average"
          region = var.region
          title  = "Messages Per Task"
          yAxis = {
            left = {
              min = 0
            }
          }
          annotations = {
            horizontal = [
              {
                value = var.ecs_autoscale_sqs_messages_per_task
                label = "Target"
                color = "#ff7f0e"
              }
            ]
          }
        }
        width  = 12
        height = 6
        x      = 0
        y      = 12
      },

      # Scaling Activity
      {
        type = "log"
        properties = {
          query   = <<-EOT
            SOURCE '/aws/ecs/${var.project}-${var.env}-${var.ecs_service_name}'
            | fields @timestamp, @message
            | filter @message like /scale/
            | sort @timestamp desc
            | limit 20
          EOT
          region  = var.region
          title   = "Recent Scaling Events"
          stacked = false
        }
        width  = 12
        height = 6
        x      = 12
        y      = 12
      }
    ]
  })
}

# Output dashboard URL
output "cloudwatch_dashboard_url" {
  description = "CloudWatch Dashboard URL for ECS Auto Scaling monitoring"
  value       = "https://console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.ecs_autoscaling.dashboard_name}"
}
