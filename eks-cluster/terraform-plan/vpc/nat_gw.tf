# Create elastic ip to associate with the network address translation gateways
resource "aws_eip" "nat" {
  for_each = {
    for subnet in local.public_nested_config : "${subnet.name}" => subnet
    if subnet.nat_gw == true
  }

  vpc = true

  tags = {
    Environment = var.env_name
    Name        = "eip-${each.value.name}-${var.env_name}"
  }
}

# Create NAT Gateways on the public subnets used by EKS
resource "aws_nat_gateway" "nat-gw" {
  for_each = {
    for subnet in local.public_nested_config : "${subnet.name}" => subnet
    if subnet.nat_gw == true
  }

  allocation_id = aws_eip.nat[each.value.name].id
  subnet_id     = aws_subnet.public[each.value.name].id

  tags = {
    Environment = var.env_name
    Name        = "nat-${each.value.name}-${var.env_name}"
  }
}

# Associate NAT Gateways with private subnets using route tables
resource "aws_route_table" "private" {
  for_each = {
    for subnet in local.public_nested_config : "${subnet.name}" => subnet
    if subnet.nat_gw == true
  }

  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-gw[each.value.name].id
  }

  tags = {
    Environment = var.env_name
    Name        = "rt-${each.value.name}-${var.env_name}"
  }
}

resource "aws_route_table_association" "private" {

  for_each = {
    for subnet in local.private_nested_config : "${subnet.name}" => subnet
    if subnet.associated_public_subnet != ""
  }

  subnet_id      = aws_subnet.private[each.value.name].id
  route_table_id = aws_route_table.private[each.value.associated_public_subnet].id
}
