# Lambda function
resource "aws_lambda_function" "lambda" {
  function_name = "${var.project_name}-${var.function_name}-${var.env_name}"
  image_uri     = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.project_name}-${var.function_name}-${var.env_name}:latest"
  package_type  = "Image"
  architectures = ["x86_64"]
  role          = aws_iam_role.lambda.arn
  memory_size   = var.memory_size
  timeout       = var.timeout
  depends_on = [
    aws_secretsmanager_secret_version.id,
    aws_s3_bucket.lambda_bucket.bucket
  ]
  environment {
    variables = {
      bucket_name        = aws_s3_bucket.lambda_bucket.bucket
      aws_region         = var.aws_region
      secrets_config_arn = aws_secretsmanager_secret.redshift_config.arn
    }
  }
  tags = {
    Name        = "${var.project_name}-${var.function_name}-role-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
# Credentials
resource "aws_secretsmanager_secret" "redshift_config" {
  name                    = "${var.project_name}-${var.function_name}-config"
  recovery_window_in_days = 0
}
resource "aws_secretsmanager_secret_version" "redshift_config" {
  secret_id     = aws_secretsmanager_secret.redshift_config.id
  secret_string = jsonencode(var.redshift_config)
}
