variable "aws_account_id" {
  description = "The AWS account id"
  type        = string
  default     = "895539818407"
}
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
  default     = "lambda-dockerfile"
}
variable "memory_size" {
  description = "The size in MB of Lambda function memory allocationn"
  type        = string
  default     = 128
}
variable "timeout" {
  description = "The timeout in seconds for Lambda function timeout"
  type        = string
  default     = 60
}
