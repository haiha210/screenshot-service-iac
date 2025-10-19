# SQS Queue Outputs

output "queue_id" {
  description = "The URL for the created Amazon SQS queue"
  value       = aws_sqs_queue.queue.id
}

output "queue_arn" {
  description = "The ARN of the SQS queue"
  value       = aws_sqs_queue.queue.arn
}

output "queue_name" {
  description = "The name of the SQS queue"
  value       = aws_sqs_queue.queue.name
}

output "queue_url" {
  description = "Same as queue_id: The URL for the created Amazon SQS queue"
  value       = aws_sqs_queue.queue.url
}

output "queue_attributes" {
  description = "All attributes of the created SQS queue"
  value = {
    fifo_queue                  = aws_sqs_queue.queue.fifo_queue
    content_based_deduplication = aws_sqs_queue.queue.content_based_deduplication
    delay_seconds               = aws_sqs_queue.queue.delay_seconds
    max_message_size           = aws_sqs_queue.queue.max_message_size
    message_retention_seconds   = aws_sqs_queue.queue.message_retention_seconds
    receive_wait_time_seconds   = aws_sqs_queue.queue.receive_wait_time_seconds
    visibility_timeout_seconds  = aws_sqs_queue.queue.visibility_timeout_seconds
  }
}

output "cloudwatch_alarms" {
  description = "CloudWatch alarm ARNs if created"
  value = {
    high_messages_alarm_arn = var.cloudwatch_alarms.enabled ? aws_cloudwatch_metric_alarm.high_messages[0].arn : null
    dlq_messages_alarm_arn  = var.cloudwatch_alarms.enabled && var.redrive_policy.enabled ? aws_cloudwatch_metric_alarm.dlq_messages[0].arn : null
  }
}