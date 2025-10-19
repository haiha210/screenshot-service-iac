# Reusable SQS Queue Module

locals {
  queue_name = var.is_fifo ? "${var.queue_name}-${var.env}.fifo" : "${var.queue_name}-${var.env}"
}

# Main SQS Queue
resource "aws_sqs_queue" "queue" {
  name = local.queue_name
  
  # Queue configuration
  fifo_queue                  = var.is_fifo
  content_based_deduplication = var.is_fifo ? var.content_based_deduplication : null
  delay_seconds              = var.delay_seconds
  max_message_size           = var.max_message_size
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds
  
  # Encryption
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = var.kms_master_key_id != null ? var.kms_data_key_reuse_period_seconds : null
  
  # Dead Letter Queue redrive policy
  redrive_policy = var.redrive_policy.enabled ? jsonencode({
    deadLetterTargetArn = var.redrive_policy.dead_letter_target_arn
    maxReceiveCount     = var.redrive_policy.max_receive_count
  }) : null

  tags = merge({
    Name        = local.queue_name
    Environment = var.env
    Project     = var.project
    Purpose     = var.purpose
  }, var.additional_tags)
}

# Queue Policy
resource "aws_sqs_queue_policy" "queue_policy" {
  count = var.queue_policy != null ? 1 : 0
  
  queue_url = aws_sqs_queue.queue.id
  policy    = var.queue_policy
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "high_messages" {
  count = var.cloudwatch_alarms.enabled ? 1 : 0
  
  alarm_name          = "${local.queue_name}-high-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cloudwatch_alarms.high_messages.evaluation_periods
  metric_name         = "ApproximateNumberOfVisibleMessages"
  namespace           = "AWS/SQS"
  period              = var.cloudwatch_alarms.high_messages.period
  statistic           = "Average"
  threshold           = var.cloudwatch_alarms.high_messages.threshold
  alarm_description   = "This metric monitors ${local.queue_name} message count"
  alarm_actions       = var.cloudwatch_alarms.high_messages.alarm_actions

  dimensions = {
    QueueName = aws_sqs_queue.queue.name
  }

  tags = merge({
    Name        = "${local.queue_name}-high-messages"
    Environment = var.env
    Project     = var.project
  }, var.additional_tags)
}

resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  count = var.cloudwatch_alarms.enabled && var.redrive_policy.enabled ? 1 : 0
  
  alarm_name          = "${local.queue_name}-dlq-messages"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.cloudwatch_alarms.dlq_messages.evaluation_periods
  metric_name         = "ApproximateNumberOfVisibleMessages"
  namespace           = "AWS/SQS"
  period              = var.cloudwatch_alarms.dlq_messages.period
  statistic           = "Average"
  threshold           = var.cloudwatch_alarms.dlq_messages.threshold
  alarm_description   = "This metric monitors ${local.queue_name} dead letter queue messages"
  alarm_actions       = var.cloudwatch_alarms.dlq_messages.alarm_actions

  dimensions = {
    QueueName = aws_sqs_queue.queue.name
  }

  tags = merge({
    Name        = "${local.queue_name}-dlq-messages"
    Environment = var.env
    Project     = var.project
  }, var.additional_tags)
}