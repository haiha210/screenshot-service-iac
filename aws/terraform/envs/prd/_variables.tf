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

variable "lambda_functions" {
  description = "Map of all Lambda functions configuration"
  type = map(object({
    handler             = string
    runtime             = string
    timeout             = optional(number, 30)
    memory_size         = optional(number, 128)
    environment         = optional(map(string), {})
    description         = optional(string, "")
    api_path            = optional(string, null)
    http_method         = optional(string, "GET")
    enable_api_gateway  = optional(bool, true)
  }))
  default = {}
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
