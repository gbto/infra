provider "archive" {}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/${var.function_name}.py"
  output_path = "${path.module}/lambda/${var.function_name}.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name = "${var.project_name}-${var.function_name}-${var.env_name}"

  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256

  role    = aws_iam_role.lambda.arn
  handler = "${var.function_name}.lambda_handler"
  runtime = "python3.9"

  memory_size                    = var.memory_size
  timeout                        = var.timeout
  reserved_concurrent_executions = var.concurrent_executions

  tags = {
    Name        = "${var.project_name}-${var.function_name}-desktop-bucket-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 14
}
