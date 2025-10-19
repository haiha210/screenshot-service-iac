# SQS Queues for Screenshot Processing using reusable module

# Dead Letter Queue for failed messages
module "screenshot_dlq" {
  source = "../../../modules/sqs"

  queue_name = "screenshot-queue-dlq"
  env        = var.env
  project    = var.project
  purpose    = "Dead letter queue for failed screenshot processing messages"

  # Queue configuration
  is_fifo                    = false
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 1209600 # 14 days
  receive_wait_time_seconds  = 0
  visibility_timeout_seconds = 300

  # No redrive policy for DLQ
  redrive_policy = {
    enabled = false
  }

  # Disable CloudWatch alarms for DLQ
  cloudwatch_alarms = {
    enabled = false
  }

  additional_tags = {}
}

# Main SQS Queue for screenshot processing
module "screenshot_queue" {
  source = "../../../modules/sqs"

  queue_name = "screenshot-queue"
  env        = var.env
  project    = var.project
  purpose    = "Main queue for screenshot processing requests from Lambda to ECS"

  # Queue configuration
  is_fifo                    = false
  delay_seconds              = 0
  max_message_size           = 262144  # 256 KB
  message_retention_seconds  = 1209600 # 14 days
  receive_wait_time_seconds  = 20      # Long polling
  visibility_timeout_seconds = 300     # 5 minutes

  # Dead letter queue configuration
  redrive_policy = {
    enabled                = true
    dead_letter_target_arn = module.screenshot_dlq.queue_arn
    max_receive_count      = 3
  }

  # CloudWatch monitoring
  cloudwatch_alarms = {
    enabled = true
    high_messages = {
      threshold          = 100
      evaluation_periods = 2
      period             = 300
      alarm_actions      = [] # Add SNS topic ARN here for notifications
    }
    dlq_messages = {
      threshold          = 0
      evaluation_periods = 1
      period             = 300
      alarm_actions      = [] # Add SNS topic ARN here for notifications
    }
  }

  # Custom queue policy allowing Lambda and ECS access
  queue_policy = jsonencode({
    Version = "2012-10-17"
    Id      = "screenshot-queue-policy"
    Statement = [
      {
        Sid    = "AllowLambdaSendMessage"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.lambda_execution_role.arn
        }
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowECSReceiveMessage"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.ecs_task_role.arn
        }
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = "*"
      }
    ]
  })

  additional_tags = {}
}

# SQS Queue for high-priority screenshot requests
module "screenshot_priority_queue" {
  source = "../../../modules/sqs"

  queue_name = "screenshot-priority-queue"
  env        = var.env
  project    = var.project
  purpose    = "High-priority queue for urgent screenshot processing"

  # Queue configuration
  is_fifo                    = false
  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 1209600
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 300

  # Same DLQ for priority queue
  redrive_policy = {
    enabled                = true
    dead_letter_target_arn = module.screenshot_dlq.queue_arn
    max_receive_count      = 3
  }

  # CloudWatch monitoring with lower threshold for priority
  cloudwatch_alarms = {
    enabled = true
    high_messages = {
      threshold          = 50
      evaluation_periods = 2
      period             = 300
      alarm_actions      = []
    }
    dlq_messages = {
      threshold          = 0
      evaluation_periods = 1
      period             = 300
      alarm_actions      = []
    }
  }

  additional_tags = {}
}

# FIFO Dead Letter Queue
module "screenshot_fifo_dlq" {
  count  = var.env == "prd" ? 1 : 0
  source = "../../../modules/sqs"

  queue_name = "screenshot-fifo-dlq"
  env        = var.env
  project    = var.project
  purpose    = "FIFO dead letter queue for failed ordered processing"

  # FIFO configuration
  is_fifo                     = true
  content_based_deduplication = false
  delay_seconds               = 0
  max_message_size            = 262144
  message_retention_seconds   = 1209600
  receive_wait_time_seconds   = 0
  visibility_timeout_seconds  = 300

  # No redrive policy for DLQ
  redrive_policy = {
    enabled = false
  }

  cloudwatch_alarms = {
    enabled = false
  }

  additional_tags = {}
}

# FIFO Queue for ordered processing (if needed)
module "screenshot_fifo_queue" {
  count  = var.env == "prd" ? 1 : 0
  source = "../../../modules/sqs"

  queue_name = "screenshot-fifo-queue"
  env        = var.env
  project    = var.project
  purpose    = "FIFO queue for ordered screenshot processing"

  # FIFO configuration
  is_fifo                     = true
  content_based_deduplication = true
  delay_seconds               = 0
  max_message_size            = 262144
  message_retention_seconds   = 1209600
  receive_wait_time_seconds   = 20
  visibility_timeout_seconds  = 300

  # FIFO DLQ
  redrive_policy = {
    enabled                = true
    dead_letter_target_arn = module.screenshot_fifo_dlq[0].queue_arn
    max_receive_count      = 3
  }

  # CloudWatch monitoring
  cloudwatch_alarms = {
    enabled = true
    high_messages = {
      threshold          = 100
      evaluation_periods = 2
      period             = 300
      alarm_actions      = []
    }
    dlq_messages = {
      threshold          = 0
      evaluation_periods = 1
      period             = 300
      alarm_actions      = []
    }
  }

  additional_tags = {}
}