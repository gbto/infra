# DESKTOP BUCKET
# Create the bucket ACL
resource "aws_s3_bucket" "desktop" {
  bucket        = var.desktop_bucket_id
  force_destroy = true
  tags = {
    Name        = "${var.namespace}-${var.function_name}-desktop-bucket-${var.environment}"
    Environment = var.environment
    Project     = var.namespace
  }
}
resource "aws_s3_bucket_acl" "desktop" {
  bucket = aws_s3_bucket.desktop.id
  acl    = "private"
}
# Grant the permission to execute lambda from S3 event notification
resource "aws_lambda_permission" "allow_desktop_bucket" {
  statement_id  = "AllowExecutionFromSegmentDesktopS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.desktop.arn
}
# Create the S3 event notifications
resource "aws_s3_bucket_notification" "desktop" {
  bucket = aws_s3_bucket.desktop.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".gz"
  }
  depends_on = [aws_lambda_permission.allow_desktop_bucket]
}

# MOBILE BUCKET
resource "aws_s3_bucket" "mobile" {
  bucket        = var.mobile_bucket_id
  force_destroy = true
  tags = {
    Name        = "${var.namespace}-${var.function_name}-mobile-bucket-${var.environment}"
    Environment = var.environment
    Project     = var.namespace
  }
}
# Create the bucket ACL
resource "aws_s3_bucket_acl" "mobile" {
  bucket = aws_s3_bucket.mobile.id
  acl    = "private"
}
# Grant the permission to execute lambda from S3 event notification
resource "aws_lambda_permission" "allow_mobile_bucket" {
  statement_id  = "AllowExecutionFromSegmentMobileS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.mobile.arn
}
# Create the S3 event notifications
resource "aws_s3_bucket_notification" "mobile" {
  bucket = aws_s3_bucket.mobile.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".gz"
  }
  depends_on = [aws_lambda_permission.allow_mobile_bucket]
}
