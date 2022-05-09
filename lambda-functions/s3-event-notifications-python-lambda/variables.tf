variable "aws_region" {
  description = "The AWS region where to instantiate the AWS resources"
  type        = string
  default     = "us-east-1"
}
variable "aws_profile" {
  description = "The AWS local configuration that will be used"
  type        = string
  default     = "default"
}
variable "env_name" {
  description = "The environment the resources belongs to"
  type        = string
  default     = "dev"
}
variable "project_name" {
  description = "The project name that will be used to create resources"
  type        = string
  default     = "gbto"
}
variable "function_name" {
  description = "The name of the file that contains the lambda handler"
  type        = string
  default     = "lambda_function"
}
variable "memory_size" {
  description = "The size in MB of Lambda function memory allocation"
  type        = number
  default     = 256
}
variable "timeout" {
  description = "The Lambda function timeout in seconds"
  type        = number
  default     = 60
}
variable "concurrent_executions" {
  description = "The maximum concurrent execution per second"
  type        = number
  default     = 5
}
variable "desktop_bucket_id" {
  description = "The ID of the bucket where the desktop logs are written"
  type        = string
  default     = "segment-analytics-desktop-dev"
}
variable "mobile_bucket_id" {
  description = "The ID of the bucket where segment write the mobile logs"
  type        = string
  default     = "segment-analytics-mobile-dev"
}
