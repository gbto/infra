# Lambda function
resource "aws_lambda_function" "lambda" {
  function_name = "${var.project_name}-${var.function_name}-${var.env_name}"
  image_uri     = "${var.aws_account_id}.dkr.ecr.eu-west-3.amazonaws.com/${var.project_name}-${var.function_name}-${var.env_name}:latest"
  package_type  = "Image"
  architectures = ["x86_64"]
  role          = aws_iam_role.lambda.arn
  memory_size   = var.memory_size
  timeout       = var.timeout

  environment {
    variables = {
      bucket_name = aws_s3_bucket.lambda_bucket.bucket
    }
  }
  tags = {
    Name        = "${var.project_name}-${var.function_name}-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_cloudwatch_log_group" "loggroup" {
  name              = "/aws/lambda/${aws_lambda_function.lambda.function_name}"
  retention_in_days = 14
}

# Scheduling with cloudwatch event rule
resource "aws_cloudwatch_event_rule" "every_minutes" {
  name                = "${var.project_name}-${var.function_name}-every-minutes"
  description         = "Fires every minutes"
  schedule_expression = "rate(1 minute)"
  tags = {
    Name        = "${var.project_name}-${var.function_name}-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_cloudwatch_event_target" "every_minutes" {
  rule      = aws_cloudwatch_event_rule.every_minutes.name
  target_id = "lambda"
  arn       = aws_lambda_function.lambda.arn

  tags = {
    Name        = "${var.project_name}-${var.function_name}-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_minutes.arn
}
