# S3 bucket for the data lake
resource "aws_s3_bucket" "s3_data_lake" {
  bucket        = "${var.project_name}-data-lake-${var.env_name}"
  force_destroy = true
  tags = {
    Name        = "${var.project_name}-data-lake-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
# S3 bucket for MWAA
resource "aws_s3_bucket" "mwaa_bucket" {
  bucket = "${var.project_name}-airflow-${var.env_name}"
  tags = {
    Name        = "${var.project_name}-airflow-${var.env_name}"
    Environment = var.env_name
    Project     = var.project_name
  }
}
resource "aws_s3_bucket_versioning" "mwaa_bucket_versioning" {
  bucket = aws_s3_bucket.mwaa_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_public_access_block" "mwaa_bucket_access" {
  bucket                  = aws_s3_bucket.mwaa_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
