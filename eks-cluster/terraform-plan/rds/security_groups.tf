# RDS DB SECURITY GROUP
resource "aws_security_group" "sg" {
  name        = "postgresql-${var.env}"
  description = "Allow inbound/outbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    security_groups = [var.sg_rds_access]
  }

  ingress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    cidr_blocks     = [var.aws_subnet_private["private-rds-1"].cidr_block]
  }

  ingress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    cidr_blocks     = [var.aws_subnet_private["private-rds-2"].cidr_block]
  }

  ingress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    cidr_blocks     = [var.aws_subnet_public["public-rds-1"].cidr_block]
  }

  ingress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    cidr_blocks     = [var.aws_subnet_public["public-rds-2"].cidr_block]
  }

  egress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [var.sg_rds_access]
  }

  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = [var.aws_subnet_private["private-rds-1"].cidr_block]
  }

  egress {
    from_port       = 0
    to_port         = 65535
    protocol        = "tcp"
    cidr_blocks     = [var.aws_subnet_private["private-rds-2"].cidr_block]
  }

  egress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    cidr_blocks     = [var.aws_subnet_public["public-rds-1"].cidr_block]
  }

  egress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    cidr_blocks     = [var.aws_subnet_public["public-rds-2"].cidr_block]
  }

  # Allows pod security group as source of traffic on the RDS port
  ingress {
    from_port       = var.rds_port
    to_port         = var.rds_port
    protocol        = "tcp"
    security_groups = [var.sg_rds_access]
  }

  egress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [var.sg_rds_access]
  }


    # Allows node groups pods to acces RDS
    ingress {
        from_port       = var.rds_port
        to_port         = var.rds_port
        protocol        = "tcp"
        security_groups = [var.sg_rds_access]
    }

    egress {
        from_port       = 1025
        to_port         = 65535
        protocol        = "tcp"
        security_groups = [var.sg_rds_access]
    }


  tags = {
    Name        = "postgresql-${var.env}"
    Environment = var.env
  }
}

# RDS DB SUBNET GROUP
resource "aws_db_subnet_group" "sg" {
  name       = "postgresql-${var.env}"
  subnet_ids = [var.aws_subnet_private["private-rds-1"].id, var.aws_subnet_private["private-rds-2"].id]

  tags = {
    Environment = var.env
    Name        = "postgresql-${var.env}"
  }
}


