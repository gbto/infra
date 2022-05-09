# Create the S3 bucket where to write the lambda output
resource "aws_s3_bucket" "lambda_bucket" {
  bucket        = "${var.project_name}-${var.function_name}-${var.env_name}"
  force_destroy = true # Force bucket destroy even if non-empty
  tags = {
    Name        = "${var.project_name}-${var.function_name}-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_s3_bucket_acl" "lambda_bucket" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}
