resource "aws_vpc" "mwaa_vpc" {
  cidr_block = "10.192.0.0/16"

  tags = {
    Name        = "${var.project_name}-airflow-vpc-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_internet_gateway" "mwaa_igw" {
  vpc_id = aws_vpc.mwaa_vpc.id

  tags = {
    Name        = "${var.project_name}-airflow-igw-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_subnet" "mwaa_public_subnet_1" {
  vpc_id                  = aws_vpc.mwaa_vpc.id
  cidr_block              = "10.192.10.0/24"
  availability_zone       = var.aws_az_1
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-airflow-subnet-public-1-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_subnet" "mwaa_public_subnet_2" {
  vpc_id                  = aws_vpc.mwaa_vpc.id
  cidr_block              = "10.192.11.0/24"
  availability_zone       = var.aws_az_2
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-airflow-subnet-public-2-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_subnet" "mwaa_private_subnet_1" {
  vpc_id                  = aws_vpc.mwaa_vpc.id
  cidr_block              = "10.192.20.0/24"
  availability_zone       = var.aws_az_1
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-airflow-subnet-private-1-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_subnet" "mwaa_private_subnet_2" {
  vpc_id                  = aws_vpc.mwaa_vpc.id
  cidr_block              = "10.192.21.0/24"
  availability_zone       = var.aws_az_2
  map_public_ip_on_launch = false

  tags = {
    Name        = "${var.project_name}-airflow-subnet-private-2-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_eip" "nat_gateway_1_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.mwaa_igw]
}
resource "aws_eip" "nat_gateway_2_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.mwaa_igw]
}
resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_gateway_1_eip.id
  subnet_id     = aws_subnet.mwaa_public_subnet_1.id
  depends_on    = [aws_internet_gateway.mwaa_igw]
}
resource "aws_nat_gateway" "nat_gateway_2" {
  allocation_id = aws_eip.nat_gateway_2_eip.id
  subnet_id     = aws_subnet.mwaa_public_subnet_2.id
  depends_on    = [aws_internet_gateway.mwaa_igw]
}
resource "aws_route_table" "mwaa_public_route_table" {
  vpc_id = aws_vpc.mwaa_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mwaa_igw.id
  }

  tags = {
    Name        = "${var.project_name}-airflow-route-table-public-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_route_table_association" "public_subnet_1_route_table_association" {
  subnet_id      = aws_subnet.mwaa_public_subnet_1.id
  route_table_id = aws_route_table.mwaa_public_route_table.id
}
resource "aws_route_table_association" "public_subnet_2_route_table_association" {
  subnet_id      = aws_subnet.mwaa_public_subnet_2.id
  route_table_id = aws_route_table.mwaa_public_route_table.id
}
resource "aws_route_table" "private_route_table_1" {
  vpc_id = aws_vpc.mwaa_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_1.id
  }

  tags = {
    Name        = "${var.project_name}-airflow-route-table-private-1-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_route_table" "private_route_table_2" {
  vpc_id = aws_vpc.mwaa_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway_2.id
  }
  tags = {
    Name        = "${var.project_name}-airflow-route-table-private-2-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_route_table_association" "private_subnet_1_route_table_association" {
  subnet_id      = aws_subnet.mwaa_private_subnet_1.id
  route_table_id = aws_route_table.private_route_table_1.id
}
resource "aws_route_table_association" "private_subnet_2_route_table_association" {
  subnet_id      = aws_subnet.mwaa_private_subnet_2.id
  route_table_id = aws_route_table.private_route_table_2.id
}
resource "aws_security_group" "mwaa_security_group" {
  name        = "${var.project_name}-airflow-security-group-${var.env_name}"
  description = "Security group with a self-referencing inbound rule."
  vpc_id      = aws_vpc.mwaa_vpc.id
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name        = "${var.project_name}-airflow-security-group-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_mwaa_environment" "mwaa_environment" {
  name                  = "${var.project_name}-airflow-${var.env_name}"
  source_bucket_arn     = aws_s3_bucket.mwaa_bucket.arn
  execution_role_arn    = aws_iam_role.mwaa_execution_role.arn
  dag_s3_path           = "dags/"
  webserver_access_mode = "PUBLIC_ONLY"
  max_workers           = 2
  network_configuration {
    security_group_ids = [aws_security_group.mwaa_security_group.id]
    subnet_ids = [
      aws_subnet.mwaa_private_subnet_1.id,
      aws_subnet.mwaa_private_subnet_2.id
    ]
  }
  logging_configuration {
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }
    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }
    task_logs {
      enabled   = true
      log_level = "INFO"
    }
    worker_logs {
      enabled   = true
      log_level = "INFO"
    }
    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }
  }
}
