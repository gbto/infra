# Redshift cluster credentials
resource "random_string" "root_username" {
  length  = 12
  special = false
  upper   = false
}
resource "random_password" "root_password" {
  length      = 12
  special     = false
  upper       = true
  min_numeric = 2
}
resource "aws_secretsmanager_secret" "redshift_credentials" {
  name                    = "${var.project_name}-redshift-credentials-${var.env_name}"
  recovery_window_in_days = 0
}
resource "aws_secretsmanager_secret_version" "redshift_credentials" {
  secret_id     = aws_secretsmanager_secret.redshift_credentials.id
  secret_string = <<EOF
{
  "username": "${aws_redshift_cluster.redshift_cluster.master_username}",
  "password": "${random_password.root_password.result}",
  "database": "${var.database_name}",
  "host": "${aws_redshift_cluster.redshift_cluster.endpoint}",
  "port": ${aws_redshift_cluster.redshift_cluster.port},
  "dbClusterIdentifier": "${aws_redshift_cluster.redshift_cluster.cluster_identifier}"
}
EOF
}

# Redshift cluster
resource "aws_redshift_cluster" "redshift_cluster" {

  cluster_identifier        = "${var.project_name}-redshift-cluster-${var.env_name}"
  database_name             = var.database_name
  master_username           = "u${random_string.root_username.result}"
  master_password           = "p${random_password.root_password.result}"
  node_type                 = "dc2.large"
  cluster_type              = "single-node"
  cluster_subnet_group_name = aws_redshift_subnet_group.redshift_subnet_group.name
  iam_roles                 = ["${aws_iam_role.redshift_iam_role.arn}"]

  skip_final_snapshot = true
  publicly_accessible = true

  depends_on = [
    aws_internet_gateway.redshift_internet_gateway,
    aws_vpc.redshift_vpc,
    aws_subnet.redshift_subnet
  ]
}
