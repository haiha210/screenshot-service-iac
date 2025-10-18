resource "aws_subnet" "subnet_private" {
  count = var.private_cidrs != null ? length(var.private_cidrs) : 0

  availability_zone = data.aws_availability_zones.available.names[count.index]
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_cidrs[count.index]

  tags = {
    Name = "${var.project}-${var.env}-subnet-private-${substr(data.aws_availability_zones.available.names[count.index], -2, -1)}"
  }
}

resource "aws_route_table" "route_private" {
  count = var.private_cidrs != null ? (var.only_one_nat_gateway == true ? 1 : length(var.private_cidrs)) : 0

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }

  dynamic "route" {
    for_each = { for value in var.vpc_peering_connections : value.peer_vpc_cidr => value }
    content {
      vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering_connection[route.key].id
      cidr_block                = route.value.peer_vpc_cidr
    }
  }

  lifecycle {
    ignore_changes = [
      route #ignore change for vpc peering connection
    ]
  }

  tags = {
    Name = "${var.project}-${var.env}-route-private-${substr(data.aws_availability_zones.available.names[count.index], -2, -1)}"
  }
}

resource "aws_main_route_table_association" "main_route" {
  vpc_id         = aws_vpc.vpc.id
  route_table_id = var.private_cidrs != null ? aws_route_table.route_private[0].id : aws_route_table.route_public.id
}

resource "aws_route_table_association" "private" {
  count = var.private_cidrs != null ? length(aws_subnet.subnet_private) : 0

  subnet_id      = aws_subnet.subnet_private[count.index].id
  route_table_id = var.only_one_nat_gateway == true ? aws_route_table.route_private[0].id : aws_route_table.route_private[count.index].id
}
