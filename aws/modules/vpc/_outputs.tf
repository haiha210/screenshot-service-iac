#modules/vpc/_outputs.tf
#VPC
output "vpc_id" {
  value       = aws_vpc.vpc.id
  description = "ID of VPC"
}

#Subnet
output "subnet_private_id" {
  value       = var.private_cidrs != null ? aws_subnet.subnet_private[*].id : []
  description = "ID of Private Subnet"
}
output "subnet_public_id" {
  value       = aws_subnet.subnet_public[*].id
  description = "ID of Public Subnet"
}

#Gateway
output "nat_gateway_public_ip" {
  value       = var.private_cidrs != null ? aws_nat_gateway.nat_gateway[*].public_ip : []
  description = "Public IP of NAT Gateway"
}
output "internet_gateway_id" {
  value       = aws_internet_gateway.internet_gateway.id
  description = "ID of Internet Gateway"
}

#VPC Peering Connection
output "vpc_peering_connection_id" {
  value       = { for key, value in aws_vpc_peering_connection.vpc_peering_connection : key => value.id }
  description = "ID of VPC Peering Connection"
}

#VPC-Flow-Log
output "vpc_flow_log_id" {
  value       = { for key, value in aws_flow_log.vpc_flow_log : key => value.id }
  description = "ID of VPC Flow Log"
}
