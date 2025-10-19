# SQS Module Variables

variable "queue_name" {
  description = "Name of the SQS queue"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "project" {
  description = "Project name"
  type        = string
}

variable "purpose" {
  description = "Purpose of the queue"
  type        = string
}

variable "is_fifo" {
  description = "Whether the queue is FIFO queue"
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication for FIFO queues"
  type        = bool
  default     = false
}

variable "delay_seconds" {
  description = "Delay seconds for message delivery"
  type        = number
  default     = 0
  
  validation {
    condition     = var.delay_seconds >= 0 && var.delay_seconds <= 900
    error_message = "Delay seconds must be between 0 and 900."
  }
}

variable "max_message_size" {
  description = "Maximum message size in bytes"
  type        = number
  default     = 262144  # 256 KB
  
  validation {
    condition     = var.max_message_size >= 1024 && var.max_message_size <= 262144
    error_message = "Max message size must be between 1024 and 262144 bytes."
  }
}

variable "message_retention_seconds" {
  description = "Message retention period in seconds"
  type        = number
  default     = 1209600  # 14 days
  
  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "Message retention must be between 60 and 1209600 seconds."
  }
}

variable "receive_wait_time_seconds" {
  description = "Long polling wait time in seconds"
  type        = number
  default     = 0
  
  validation {
    condition     = var.receive_wait_time_seconds >= 0 && var.receive_wait_time_seconds <= 20
    error_message = "Receive wait time must be between 0 and 20 seconds."
  }
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout in seconds"
  type        = number
  default     = 30
  
  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200
    error_message = "Visibility timeout must be between 0 and 43200 seconds."
  }
}

variable "redrive_policy" {
  description = "Dead letter queue redrive policy"
  type = object({
    enabled                = bool
    dead_letter_target_arn = optional(string, null)
    max_receive_count      = optional(number, 3)
  })
  default = {
    enabled = false
  }
}

variable "kms_master_key_id" {
  description = "KMS key ID for encryption"
  type        = string
  default     = null
}

variable "kms_data_key_reuse_period_seconds" {
  description = "KMS data key reuse period"
  type        = number
  default     = 300
}

variable "queue_policy" {
  description = "Queue policy document"
  type        = string
  default     = null
}

variable "cloudwatch_alarms" {
  description = "CloudWatch alarms configuration"
  type = object({
    enabled = bool
    high_messages = optional(object({
      threshold           = optional(number, 100)
      evaluation_periods  = optional(number, 2)
      period             = optional(number, 300)
      alarm_actions      = optional(list(string), [])
    }), {})
    dlq_messages = optional(object({
      threshold           = optional(number, 0)
      evaluation_periods  = optional(number, 1)
      period             = optional(number, 300)
      alarm_actions      = optional(list(string), [])
    }), {})
  })
  default = {
    enabled = false
  }
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}