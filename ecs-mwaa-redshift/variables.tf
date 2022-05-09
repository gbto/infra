variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "gbto"
}
variable "env_name" {
  description = "Environment the ressources are instantiated in"
  type        = string
  default     = "dev"
}
variable "aws_profile" {
  description = "The name of the project"
  type        = string
  default     = "default"
}
variable "aws_region" {
  description = "AWS region in which to instantiate the resources"
  type        = string
  default     = "us-east-1"
}
variable "aws_az_1" {
  description = "The first availability zone"
  type        = string
  default     = "us-east-1a"
}
variable "aws_az_2" {
  description = "The second availability zone"
  type        = string
  default     = "us-east-1b"
}
