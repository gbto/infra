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

  role        = aws_iam_role.lambda.arn
  handler     = "${var.function_name}.lambda_handler"
  runtime     = "python3.6"
  memory_size = var.memory_size
  timeout     = var.timeout
  environment {
    variables = {
      bucket_name = var.bucket_name
    }
  }
}

resource "aws_cloudwatch_log_group" "loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 14
}

# Scheduling with cloudwatch event rule
resource "aws_cloudwatch_event_rule" "every_minutes" {
  name                = "every-one-minute"
  description         = "Fires every one minutes"
  schedule_expression = "rate(1 minute)"
  tags = {
    Name        = "A CloudWatch event rule for triggering lambda function every minutes."
    Environment = var.env_name
  }
}

resource "aws_cloudwatch_event_target" "every_minutes" {
  rule      = aws_cloudwatch_event_rule.every_minutes.name
  target_id = "lambda"
  arn       = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_minutes.arn
}

