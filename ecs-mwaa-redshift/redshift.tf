resource "aws_vpc" "redshift_vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name        = "${var.project_name}-redshift-vpc-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_subnet" "redshift_subnet" {
  cidr_block = "10.1.1.0/24"
  vpc_id     = aws_vpc.redshift_vpc.id
  tags = {
    Name        = "${var.project_name}-redshift-subnet-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_internet_gateway" "redshift_internet_gateway" {
  vpc_id = aws_vpc.redshift_vpc.id
  tags = {
    Name        = "${var.project_name}-redshift-internet-gateway-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.redshift_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.redshift_internet_gateway.id
  }
  tags = {
    Name        = "${var.project_name}-redshift-route-table-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_route_table_association" "public_association" {
  subnet_id      = aws_subnet.redshift_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_redshift_subnet_group" "redshift_subnet_group" {
  name       = "${var.project_name}-redshift-subnet-group-${var.env_name}"
  subnet_ids = [aws_subnet.redshift_subnet.id]
  tags = {
    Name        = "${var.project_name}-redshift-subnet-group-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_security_group" "redshift_sg" {
  name   = "${var.project_name}-redshift-security-group-${var.env_name}"
  vpc_id = aws_vpc.redshift_vpc.id
  ingress {
    from_port   = 5349
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.project_name}-redshift-security-group-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_redshift_cluster" "redshift_cluster" {
  cluster_identifier                  = "${var.project_name}-ledger-redshift-cluster-${var.env_name}"
  database_name                       = "sandbox"
  master_username                     = "admin"
  master_password                     = "R3dshiftLedg3r"
  node_type                           = "dc2.large"
  cluster_type                        = "single-node"
  cluster_subnet_group_name           = aws_redshift_subnet_group.redshift_subnet_group.name
  automated_snapshot_retention_period = 0
  skip_final_snapshot                 = true
  iam_roles                           = [aws_iam_role.spectrum_role.arn]
  vpc_security_group_ids              = [aws_security_group.redshift_sg.id]

  depends_on = [
    aws_internet_gateway.redshift_internet_gateway
  ]
  tags = {
    Name        = "${var.project_name}-redshift-cluster-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
