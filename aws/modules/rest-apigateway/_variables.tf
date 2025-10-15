variable "project" {
  description = "Name of project"
  type        = string
}
variable "env" {
  description = "Name of project environment"
  type        = string
}

#rest-apigateway
variable "rest_api" {
  description = "All configuration for REST APIs"
  type = object({
    name                         = string
    stage_name                   = optional(string, null)
    disable_execute_api_endpoint = optional(bool, false)
    endpoint_type                = optional(string, "EDGE")
    vpc_endpoint_ids             = optional(list(string), null)
    body                         = string
    access_log_settings = optional(object({
      log_group_arn = string
      format = optional(string,
        <<EOF
  {
	"requestTime": "$context.requestTime",
	"requestId": "$context.requestId",
	"httpMethod": "$context.httpMethod",
	"path": "$context.path",
	"resourcePath": "$context.resourcePath",
	"status": $context.status,
	"responseLatency": $context.responseLatency,
  "xrayTraceId": "$context.xrayTraceId",
  "integrationRequestId": "$context.integration.requestId",
	"functionResponseStatus": "$context.integration.status",
  "integrationLatency": "$context.integration.latency",
	"integrationServiceStatus": "$context.integration.integrationStatus",
  "authorizeResultStatus": "$context.authorize.status",
	"authorizerServiceStatus": "$context.authorizer.status",
	"authorizerLatency": "$context.authorizer.latency",
	"authorizerRequestId": "$context.authorizer.requestId",
  "ip": "$context.identity.sourceIp",
	"userAgent": "$context.identity.userAgent",
	"principalId": "$context.authorizer.principalId",
	"cognitoUser": "$context.identity.cognitoIdentityId",
  "user": "$context.identity.user"
}
EOF
    ) }), null)
    policy = optional(object({
      template = string
    }), null)
  })
}

variable "custom_domain" {
  description = "Custom Domain Name"
  default     = null

  type = object({
    name          = string
    types         = optional(string, "REGIONAL")
    regional_cert = string
  })
}

variable "vpc_link" {
  description = "VPC Link"
  default     = null

  type = object({
    name        = string
    target_arns = string
  })
}
