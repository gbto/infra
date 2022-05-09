# Create IAM role for the lambda function
resource "aws_iam_role" "lambda" {
  name               = "lambda-function"
  assume_role_policy = data.aws_iam_policy_document.policy_lambda_execution.json

  inline_policy {
    name   = "policy-lambda-log-group"
    policy = data.aws_iam_policy_document.policy_lambda_log_group.json
  }
  inline_policy {
    name   = "policy-lambda-ecr"
    policy = data.aws_iam_policy_document.policy_lambda_ecr.json
  }
  inline_policy {
    name   = "policy-lambda-s3"
    policy = data.aws_iam_policy_document.policy_lambda_s3.json
  }
  tags = {
    Name        = "${var.project_name}-${var.function_name}-role-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}

# Create the policy allowing execution of the lambda function
data "aws_iam_policy_document" "policy_lambda_execution" {
  statement {
    sid    = "all"
    effect = "Allow"

    principals {
      identifiers = ["lambda.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

# Create the policy allowing the lambda to create log group and log streams
data "aws_iam_policy_document" "policy_lambda_log_group" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:*:*:*",
      "*"
    ]
  }
}
# Create the policy allowing the lambda to interact with ECR repository
data "aws_iam_policy_document" "policy_lambda_ecr" {
  statement {
    actions = [
      "ecr:SetRepositoryPolicy",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImages",
      "ecr:DescribeRepositories",
      "ecr:UploadLayerPart",
      "ecr:ListImages",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetRepositoryPolicy",
      "ecr:PutImage"
    ]
    resources = [
      "arn:aws:logs:*:*:*",
      "*"
    ]
  }
}
# Create the policy allowing the lambda to read write S3 buckets
data "aws_iam_policy_document" "policy_lambda_s3" {
  statement {
    actions = [
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.lambda_bucket.arn
    ]
  }
  statement {
    actions = [
      "s3:GetObject",
      "s3:CopyObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:HeadObject"
    ]
    resources = [
      "${aws_s3_bucket.lambda_bucket.arn}/*"
    ]
  }
}
