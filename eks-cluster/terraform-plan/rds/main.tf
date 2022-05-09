resource "random_string" "db_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "random_string" "root_username" {
  length  = 12
  special = false
  upper   = true
}

resource "random_password" "root_password" {
  length  = 12
  special = true
  upper   = true
}

resource "aws_db_instance" "postgresql" {

  # Engine options
  engine         = "postgres"
  engine_version = "12.8"

  # Settings
  name       = "postgresql${var.env}"
  identifier = "postgresql-${var.env}"

  # Credentials Settings
  username = "u${random_string.root_username.result}"
  password = "p${random_password.root_password.result}"

  # DB instance size
  instance_class = "db.m5.large"

  # Storage
  storage_type          = "gp2"
  allocated_storage     = 100
  max_allocated_storage = 200

  # Availability & durability
  multi_az = true

  # Connectivity
  db_subnet_group_name = aws_db_subnet_group.sg.id

  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.sg.id]
  port                   = var.rds_port

  # Database authentication
  iam_database_authentication_enabled = true

  # Additional configuration
  parameter_group_name = "default.postgres12"

  # Backup
  backup_retention_period   = 14
  backup_window             = "03:00-04:00"
  final_snapshot_identifier = "postgresql-final-snapshot-${random_string.db_suffix.result}"
  delete_automated_backups  = true
  skip_final_snapshot       = false

  # Encryption
  storage_encrypted = true

  # Maintenance
  auto_minor_version_upgrade = true
  maintenance_window         = "Sat:00:00-Sat:02:00"

  # Deletion protection
  deletion_protection = false

  tags = {
    Environment = var.env
  }
}
