# Redshift IAM role and policies
data "aws_iam_policy_document" "spectrum_role_policy" {
  statement {
    sid     = ""
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["redshift.amazonaws.com"]
    }
  }
}
resource "aws_iam_role_policy_attachment" "s3_read_only_access" {
  role       = aws_iam_role.spectrum_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "glue_console_full_access" {
  role       = aws_iam_role.spectrum_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess"
}
resource "aws_iam_role" "spectrum_role" {
  name               = "${var.project_name}-spectrum-role-${var.env_name}"
  assume_role_policy = data.aws_iam_policy_document.spectrum_role_policy.json
  tags = {
    Name        = "${var.project_name}-redshift-spectrum-role-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}

# MWAA IAM role and policies
data "aws_iam_policy_document" "mwaa_trust_policy_document" {
  statement {
    sid     = ""
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["airflow.amazonaws.com", "airflow-env.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "mwaa_execution_role_policy_document" {
  statement {
    actions   = ["airflow:PublishMetrics"]
    resources = ["arn:aws:airflow:${var.aws_region}:${data.aws_caller_identity.current.account_id}:environment/${var.project_name}-mwaa-environment-${var.env_name}"]
  }

  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "s3:ListAllMyBuckets",
    ]
    resources = [
      aws_s3_bucket.mwaa_bucket.arn,
      "${aws_s3_bucket.mwaa_bucket.arn}/*"
    ]
  }

  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "s3:GetObject*",
      "s3:GetBucket*",
      "s3:List*",
    ]
    resources = [
      aws_s3_bucket.mwaa_bucket.arn,
      "${aws_s3_bucket.mwaa_bucket.arn}/*"
    ]
  }

  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "logs:DescribeLogGroups",
    ]
    resources = ["*"]
  }

  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:CreateLogGroup",
      "logs:PutLogEvents",
      "logs:GetLogEvents",
      "logs:GetLogRecord",
      "logs:GetLogGroupFields",
      "logs:GetQueryResults",
      "logs:DescribeLogGroups",
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:airflow-ledger-data*",
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}-airflow-ecs-operator-${var.env_name}:*",
    ]
  }

  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "cloudwatch:PutMetricData",
    ]
    resources = ["*"]
  }

  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "sqs:ChangeMessageVisibility",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ReceiveMessage",
      "sqs:SendMessage",
    ]
    resources = ["arn:aws:sqs:${var.aws_region}:*:airflow-celery-*"]
  }

  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
    ]
    not_resources = ["arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*"]

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["sqs.${var.aws_region}.amazonaws.com"]
    }
  }
}
resource "aws_iam_policy" "mwaa_execution_role_policy" {
  name   = "${var.project_name}-airflow-execution-role-policy-${var.env_name}"
  policy = data.aws_iam_policy_document.mwaa_execution_role_policy_document.json
}
resource "aws_iam_role" "mwaa_execution_role" {
  name               = "${var.project_name}-airflow-execution-role-${var.env_name}"
  path               = "/service-role/"
  assume_role_policy = data.aws_iam_policy_document.mwaa_trust_policy_document.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonECS_FullAccess",
    aws_iam_policy.mwaa_execution_role_policy.arn
  ]
  tags = {
    Name        = "${var.project_name}-airflow-execution-iam-role-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}

# ECS IAM role and policies
data "aws_iam_policy_document" "ecs_assume_role_policy_document" {
  statement {
    sid     = ""
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}
data "aws_iam_policy_document" "ecs_task_secret_access_policy_document" {
  statement {
    sid    = ""
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue"
    ]
    resources = ["arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:data-engineering-*"]
  }
}
resource "aws_iam_policy" "ecs_task_secret_access_policy" {
  name   = "${var.project_name}-ecs-secret-access-policy-${var.env_name}"
  policy = data.aws_iam_policy_document.ecs_task_secret_access_policy_document.json
}
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-ecs-task-execution-role-${var.env_name}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy_document.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    aws_iam_policy.ecs_task_secret_access_policy.arn
  ]
}
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.project_name}-ecs-task-role-${var.env_name}"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role_policy_document.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess",
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
  ]
}
