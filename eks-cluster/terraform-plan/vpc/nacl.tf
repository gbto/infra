# Define network access control list for EKS in the public subnets
resource "aws_network_acl" "eks-external-zone" {
  vpc_id = aws_vpc.main.id

  subnet_ids = [aws_subnet.public["public-eks-1"].id, aws_subnet.public["public-eks-2"].id]

  tags = {
    Name        = "eks-external-zone-${var.env_name}"
    Environment = var.env_name
  }
}

resource "aws_network_acl_rule" "eks-ingress-external-zone-rules" {
  network_acl_id = aws_network_acl.eks-external-zone.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "eks-egress-external-zone-rules" {
  network_acl_id = aws_network_acl.eks-external-zone.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
# Define network access control list for EKS in the private subnets
resource "aws_network_acl" "eks-internal-zone" {
  vpc_id = aws_vpc.main.id

  subnet_ids = [aws_subnet.private["private-eks-1"].id, aws_subnet.private["private-eks-2"].id]

  tags = {
    Name        = "eks-internal-zone-${var.env_name}"
    Environment = var.env_name
  }
}

resource "aws_network_acl_rule" "ingress-internal-zone-rules" {
  network_acl_id = aws_network_acl.eks-internal-zone.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "egress-internal-zone-rules" {
  network_acl_id = aws_network_acl.eks-internal-zone.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}

# Define network access control list for RDS in the public subnets
resource "aws_network_acl" "rds-external-zone" {
  vpc_id = aws_vpc.main.id

  subnet_ids = [aws_subnet.public["public-rds-1"].id, aws_subnet.public["public-rds-2"].id]

  tags = {
    Name        = "rds-external-zone-${var.env_name}"
    Environment = var.env_name
  }
}

locals {
  nacl_ingress_rds_external_zone_infos = flatten([{
    cidr_block = var.internal_ip_range
    priority   = 100
    from_port  = var.rds_port
    to_port    = var.rds_port
    }, {
    cidr_block = aws_subnet.private["private-rds-1"].cidr_block
    priority   = 101
    from_port  = 0
    to_port    = 65535
    }, {
    cidr_block = aws_subnet.private["private-rds-2"].cidr_block
    priority   = 102
    from_port  = 0
    to_port    = 65535
    }, {
    cidr_block = aws_subnet.public["public-rds-1"].cidr_block
    priority   = 103
    from_port  = 0
    to_port    = 65535
    }, {
    cidr_block = aws_subnet.public["public-rds-2"].cidr_block
    priority   = 104
    from_port  = 0
    to_port    = 65535
  }])
}
resource "aws_network_acl_rule" "rds-ingress-external-zone-rules" {
  for_each = {
    for subnet in local.nacl_ingress_rds_external_zone_infos : "${subnet.priority}" => subnet
  }

  network_acl_id = aws_network_acl.rds-external-zone.id
  rule_number    = each.value.priority
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
}

resource "aws_network_acl_rule" "rds-egress-external-zone-rules" {
  network_acl_id = aws_network_acl.rds-external-zone.id
  rule_number    = 100
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 65535
}

# Define network access control list for RDS in the private subnets
resource "aws_network_acl" "rds-secure-zone" {
  vpc_id = aws_vpc.main.id

  subnet_ids = [aws_subnet.private["private-rds-1"].id, aws_subnet.private["private-rds-2"].id]

  tags = {
    Name        = "rds-secure-zone-${var.env_name}"
    Environment = var.env_name
  }
}

locals {
  nacl_secure_ingress_egress_infos = flatten([{
    cidr_block = aws_subnet.private["private-eks-1"].cidr_block
    priority   = 101
    from_port  = var.rds_port
    to_port    = var.rds_port
    }, {
    cidr_block = aws_subnet.private["private-eks-2"].cidr_block
    priority   = 102
    from_port  = var.rds_port
    to_port    = var.rds_port
    }, {
    cidr_block = aws_subnet.private["private-rds-1"].cidr_block
    priority   = 103
    from_port  = 0
    to_port    = 65535
    }, {
    cidr_block = aws_subnet.private["private-rds-2"].cidr_block
    priority   = 104
    from_port  = 0
    to_port    = 65535
    }, {
    cidr_block = aws_subnet.public["public-rds-1"].cidr_block
    priority   = 105
    from_port  = 0
    to_port    = 65535
    }, {
    cidr_block = aws_subnet.public["public-rds-2"].cidr_block
    priority   = 106
    from_port  = 0
    to_port    = 65535
  }])
}

resource "aws_network_acl_rule" "ingress-secure-zone-rules" {
  for_each = {
    for subnet in local.nacl_secure_ingress_egress_infos : "${subnet.priority}" => subnet
  }

  network_acl_id = aws_network_acl.rds-secure-zone.id
  rule_number    = each.value.priority
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value.cidr_block
  from_port      = each.value.from_port
  to_port        = each.value.to_port
}

resource "aws_network_acl_rule" "egress-secure-zone-rules" {
  for_each = {
    for subnet in local.nacl_secure_ingress_egress_infos : "${subnet.priority}" => subnet
  }
  network_acl_id = aws_network_acl.rds-secure-zone.id
  rule_number    = each.value.priority
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = each.value.cidr_block
  from_port      = 0
  to_port        = 65535
}
