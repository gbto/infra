
# Redshift cluster IAM
data "aws_iam_policy_document" "policy_redshift" {
  statement {
    sid    = ""
    effect = "Allow"

    principals {
      identifiers = ["redshift.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}
data "aws_iam_policy_document" "policy_redshift_s3" {
  statement {
    actions = [
      "s3:*"
    ]
    resources = [
      "*"
    ]
  }
}
resource "aws_iam_role" "redshift_iam_role" {
  name = "${var.project_name}-redshift-iam-role"

  assume_role_policy = data.aws_iam_policy_document.policy_redshift.json
  inline_policy {
    name   = "policy-redshift-s3"
    policy = data.aws_iam_policy_document.policy_redshift_s3.json
  }
  tags = {
    Name = "${var.project_name}-redshift-iam-role"
  }
}
