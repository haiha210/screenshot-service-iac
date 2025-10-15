#modules/vpc/_variables.tf
#basic
variable "env" {
  description = "Name of project environment"
  type        = string
}
variable "project" {
  description = "Name of project"
  type        = string
}
variable "region" {
  description = "Region of environment"
  type        = string
}

#vpc
variable "vpc_cidr" {
  description = "CIDR of VPC"
  type        = string
}

#subnet
variable "private_cidrs" {
  description = "A list of private subnets CIDRs inside the VPC"
  type        = list(string)
  default     = null #Default: Don't have private subnet
}
variable "public_cidrs" {
  description = "A list of public subnets CIDRs inside the VPC"
  type        = list(string)
}
variable "only_one_nat_gateway" {
  description = "Choose to create only one NAT Gateway for all private subnets or multiple NAT Gateways by AZ number"
  type        = bool
  default     = true #Default: Using only one NAT Gateway for all private subnets
}

#vpc-peering-connection
variable "vpc_peering_connections" {
  description = "Create VPC Peering Connections between VPCs"
  type = list(object({
    peer_owner_id = number #The account ID of target VPC owner.
    peer_vpc_id   = string #The ID of the VPC you want to Peering.
    peer_vpc_cidr = string #The CIDR of the VPC you want to Peering.
  }))
  default = [] #Default: Don't create VPC Peering Connection
}

#vpc-flow-log
variable "vpc_flow_logs" {
  description = "Create VPC Flow Logs for tracking log of VPC"
  type = map(object({
    log_destination_arn  = string #The ARN of the logging destination.
    log_destination_type = string #The type of the logging destination. Valid values: cloud-watch-logs, s3, kinesis-data-firehose
    traffic_type         = string #The type of traffic to capture. Valid values: ACCEPT,REJECT, ALL.
  }))
  default = {} #Default: Don't create VPC Flow Log
}
