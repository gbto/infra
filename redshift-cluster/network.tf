# VPC, subnet and subnet groups for the Redshift cluster
resource "aws_vpc" "redshift_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = "${var.project_name}-redshift-vpc-${var.env_name}"
  }
}
resource "aws_subnet" "redshift_subnet" {
  vpc_id                  = aws_vpc.redshift_vpc.id
  cidr_block              = var.subnet_cidr_block
  map_public_ip_on_launch = "true"

  depends_on = [
    aws_vpc.redshift_vpc
  ]
  tags = {
    Name = "${var.project_name}-redshift-subnet-${var.env_name}"
  }
}
resource "aws_redshift_subnet_group" "redshift_subnet_group" {
  name       = "${var.project_name}-redshift-subnet-group-${var.env_name}"
  subnet_ids = [aws_subnet.redshift_subnet.id]

  tags = {
    environment = var.env_name
    Name        = "${var.project_name}-redshift-subnet-group"
  }
}
resource "aws_internet_gateway" "redshift_internet_gateway" {
  vpc_id = aws_vpc.redshift_vpc.id
  tags = {
    Name = "${var.project_name}-redshift-internet-gateway-${var.env_name}"
  }
  depends_on = [
    aws_vpc.redshift_vpc
  ]
}

resource "aws_default_security_group" "redshift_security_group" {
  vpc_id = aws_vpc.redshift_vpc.id
  ingress {
    from_port   = 0
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "redshift-sg"
  }
  depends_on = [
    "aws_vpc.redshift_vpc"
  ]
}

# Create route table to allow access from outside the VPC
resource "aws_route_table" "redshift_route_table" {
  vpc_id = aws_vpc.redshift_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.redshift_internet_gateway.id
  }
  tags = {
    Name = "${var.project_name}-redshift-route-table"
  }
}
resource "aws_route_table_association" "redshift_subnet" {
  subnet_id      = aws_subnet.redshift_subnet.id
  route_table_id = aws_route_table.redshift_route_table.id
}
