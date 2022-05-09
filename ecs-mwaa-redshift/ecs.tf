resource "aws_ecs_cluster" "ecs_cluster" {
  name = "${var.project_name}-ecs-cluster-${var.env_name}"
  tags = {
    Name        = "${var.project_name}-ecs-cluster-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "/ecs/${var.project_name}-airflow-ecs-operator-${var.env_name}"
}

