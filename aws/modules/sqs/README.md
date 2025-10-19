# SQS Module

This is a reusable Terraform module for creating Amazon SQS queues with comprehensive configuration options, including FIFO support, dead letter queues, CloudWatch monitoring, and custom queue policies.

## Features

- **Standard and FIFO Queue Support**: Create both standard and FIFO queues
- **Dead Letter Queue Integration**: Configurable redrive policy with DLQ support
- **CloudWatch Monitoring**: Automatic CloudWatch alarms for queue metrics
- **Flexible Configuration**: Extensive queue configuration options
- **Custom Queue Policies**: Support for custom IAM policies
- **Encryption Support**: KMS encryption configuration
- **Tagging**: Comprehensive tagging strategy

## Usage

### Basic Standard Queue

```terraform
module "basic_queue" {
  source = "../../../modules/sqs"

  queue_name = "my-basic-queue"
  env        = "prd"
  project    = "my-project"
  purpose    = "Basic message processing queue"

  redrive_policy = {
    enabled = false
  }

  cloudwatch_alarms = {
    enabled = false
  }
}
```

### Queue with Dead Letter Queue

```terraform
# Create DLQ first
module "my_dlq" {
  source = "../../../modules/sqs"

  queue_name = "my-queue-dlq"
  env        = var.env
  project    = var.project
  purpose    = "Dead letter queue for failed messages"

  redrive_policy = {
    enabled = false
  }

  cloudwatch_alarms = {
    enabled = false
  }
}

# Main queue with DLQ
module "my_main_queue" {
  source = "../../../modules/sqs"

  queue_name = "my-main-queue"
  env        = var.env
  project    = var.project
  purpose    = "Main processing queue"

  # Dead letter queue configuration
  redrive_policy = {
    enabled                 = true
    dead_letter_target_arn  = module.my_dlq.queue_arn
    max_receive_count       = 3
  }

  # CloudWatch monitoring
  cloudwatch_alarms = {
    enabled = true
    high_messages = {
      threshold           = 100
      evaluation_periods  = 2
      period             = 300
      alarm_actions      = ["arn:aws:sns:region:account:topic"]
    }
    dlq_messages = {
      threshold           = 0
      evaluation_periods  = 1
      period             = 300
      alarm_actions      = ["arn:aws:sns:region:account:topic"]
    }
  }
}
```

### FIFO Queue

```terraform
module "fifo_queue" {
  source = "../../../modules/sqs"

  queue_name = "my-fifo-queue"
  env        = var.env
  project    = var.project
  purpose    = "FIFO queue for ordered processing"

  # FIFO configuration
  is_fifo                     = true
  content_based_deduplication = true
  visibility_timeout_seconds  = 300

  redrive_policy = {
    enabled = false
  }

  cloudwatch_alarms = {
    enabled = true
    high_messages = {
      threshold           = 50
      evaluation_periods  = 2
      period             = 300
      alarm_actions      = []
    }
  }
}
```

### Queue with Custom Policy

```terraform
module "queue_with_policy" {
  source = "../../../modules/sqs"

  queue_name = "my-protected-queue"
  env        = var.env
  project    = var.project
  purpose    = "Queue with custom access policy"

  # Custom queue policy
  queue_policy = jsonencode({
    Version = "2012-10-17"
    Id      = "my-queue-policy"
    Statement = [
      {
        Sid    = "AllowLambdaAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::account:role/lambda-role"
        }
        Action = [
          "sqs:SendMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = "*"
      }
    ]
  })

  redrive_policy = {
    enabled = false
  }

  cloudwatch_alarms = {
    enabled = false
  }
}
```

## Input Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `queue_name` | `string` | - | Base name of the queue (will be suffixed with env) |
| `env` | `string` | - | Environment (dev, stg, prd) |
| `project` | `string` | - | Project name for tagging |
| `purpose` | `string` | - | Purpose description for the queue |
| `is_fifo` | `bool` | `false` | Whether to create a FIFO queue |
| `content_based_deduplication` | `bool` | `false` | Enable content-based deduplication for FIFO |
| `delay_seconds` | `number` | `0` | Delay seconds for message delivery |
| `max_message_size` | `number` | `262144` | Maximum message size in bytes |
| `message_retention_seconds` | `number` | `1209600` | Message retention period (14 days) |
| `receive_wait_time_seconds` | `number` | `0` | Long polling wait time |
| `visibility_timeout_seconds` | `number` | `30` | Visibility timeout for messages |
| `kms_master_key_id` | `string` | `null` | KMS key for encryption |
| `kms_data_key_reuse_period_seconds` | `number` | `300` | KMS data key reuse period |
| `redrive_policy` | `object` | See below | Dead letter queue configuration |
| `cloudwatch_alarms` | `object` | See below | CloudWatch alarm configuration |
| `queue_policy` | `string` | `null` | Custom queue policy JSON |
| `additional_tags` | `map(string)` | `{}` | Additional tags |

### Redrive Policy Object

```terraform
redrive_policy = {
  enabled                 = bool    # Enable/disable DLQ
  dead_letter_target_arn  = string  # DLQ ARN (required if enabled)
  max_receive_count       = number  # Max receive count before moving to DLQ
}
```

### CloudWatch Alarms Object

```terraform
cloudwatch_alarms = {
  enabled = bool
  high_messages = {
    threshold           = number
    evaluation_periods  = number
    period             = number
    alarm_actions      = list(string)  # SNS topic ARNs
  }
  dlq_messages = {
    threshold           = number
    evaluation_periods  = number
    period             = number
    alarm_actions      = list(string)
  }
}
```

## Outputs

| Output | Description |
|--------|-------------|
| `queue_id` | The URL for the created SQS queue |
| `queue_arn` | The ARN of the SQS queue |
| `queue_name` | The name of the SQS queue |
| `queue_url` | Same as queue_id |
| `queue_attributes` | All queue attributes |
| `cloudwatch_alarms` | CloudWatch alarm ARNs if created |

## Queue Naming Convention

The module automatically handles queue naming:
- Standard queues: `{queue_name}-{env}`
- FIFO queues: `{queue_name}-{env}.fifo`

## Best Practices

1. **Create DLQ First**: Always create dead letter queues before main queues when using redrive policies
2. **Monitor DLQs**: Set up CloudWatch alarms for dead letter queues to detect failures
3. **Use Long Polling**: Set `receive_wait_time_seconds > 0` for cost optimization
4. **Appropriate Visibility Timeout**: Set based on your processing time requirements
5. **Encryption**: Use KMS encryption for sensitive data
6. **Tagging**: Use consistent tagging for resource management

## Examples

See the `sqs.tf` file in the general module for comprehensive examples of how this module is used in the screenshot service infrastructure.