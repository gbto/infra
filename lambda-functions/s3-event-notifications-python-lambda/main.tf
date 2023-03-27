provider "archive" {}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/${var.function_name}.py"
  output_path = "${path.module}/lambda/${var.function_name}.zip"
}

resource "aws_lambda_function" "lambda" {
  function_name = "${var.namespace}-${var.function_name}-${var.environment}"

  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256

  role    = aws_iam_role.lambda.arn
  handler = "${var.function_name}.lambda_handler"
  runtime = "python3.9"

  memory_size                    = var.memory_size
  timeout                        = var.timeout
  # reserved_concurrent_executions = var.concurrent_executions

  tags = {
    Name        = "${var.namespace}-${var.function_name}-desktop-bucket-${var.environment}"
    Environment = var.environment
    Project     = var.namespace
  }
}

resource "aws_cloudwatch_log_group" "loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 14
}
