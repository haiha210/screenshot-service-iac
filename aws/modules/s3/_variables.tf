# S3 Bucket Module Variables

variable "bucket_name" {
  description = "Name of the S3 bucket"
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
  description = "Purpose of the bucket"
  type        = string
}

variable "versioning_enabled" {
  description = "Enable versioning on the bucket"
  type        = bool
  default     = false
}

variable "lifecycle_rules" {
  description = "Lifecycle configuration rules"
  type = list(object({
    id     = string
    status = string
    
    # Transitions
    transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    
    # Non-current version transitions
    noncurrent_transitions = optional(list(object({
      days          = number
      storage_class = string
    })), [])
    
    # Expiration
    expiration_days = optional(number, null)
    noncurrent_expiration_days = optional(number, null)
    incomplete_multipart_days = optional(number, 7)
  }))
  default = []
}

variable "cors_configuration" {
  description = "CORS configuration"
  type = object({
    enabled         = bool
    allowed_headers = optional(list(string), ["*"])
    allowed_methods = optional(list(string), ["GET", "PUT", "POST", "DELETE", "HEAD"])
    allowed_origins = optional(list(string), ["*"])
    expose_headers  = optional(list(string), ["ETag"])
    max_age_seconds = optional(number, 3000)
  })
  default = {
    enabled = false
  }
}

variable "access_logging" {
  description = "Access logging configuration"
  type = object({
    enabled       = bool
    target_bucket = optional(string, null)
    target_prefix = optional(string, "access-logs/")
  })
  default = {
    enabled = false
  }
}

variable "encryption_algorithm" {
  description = "Server-side encryption algorithm"
  type        = string
  default     = "AES256"
  
  validation {
    condition     = contains(["AES256", "aws:kms"], var.encryption_algorithm)
    error_message = "Encryption algorithm must be either AES256 or aws:kms."
  }
}

variable "kms_key_id" {
  description = "KMS key ID for encryption (required if encryption_algorithm is aws:kms)"
  type        = string
  default     = null
}

variable "block_public_access" {
  description = "Block public access configuration"
  type = object({
    block_public_acls       = optional(bool, true)
    block_public_policy     = optional(bool, true)
    ignore_public_acls      = optional(bool, true)
    restrict_public_buckets = optional(bool, true)
  })
  default = {
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
  }
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}