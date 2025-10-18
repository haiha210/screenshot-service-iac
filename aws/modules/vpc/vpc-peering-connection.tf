resource "aws_vpc_peering_connection" "vpc_peering_connection" {
  for_each = { for value in var.vpc_peering_connections : value.peer_vpc_cidr => value }

  vpc_id        = aws_vpc.vpc.id
  peer_owner_id = each.value.peer_owner_id
  peer_vpc_id   = each.value.peer_vpc_id

  tags = {
    Name = "${var.project}-${var.env}-vpc-peering-connection-${each.value.peer_owner_id}-${each.value.peer_vpc_id}"
  }
}
