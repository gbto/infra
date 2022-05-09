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
variable "vpc_cidr_block" {
  description = "CIDR range for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}
variable "subnet_cidr_block" {
  description = "CIDR range for the Redshift subnet"
  type        = string
  default     = "10.0.0.0/24"
}
variable "database_name" {
  description = "The name of the PostgreSQL database"
  type        = string
  default     = "gbto"
}

