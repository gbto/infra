
variable "env" {
  description = "Environment the ressources are instantiated in"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region in which to instantiate the resources"
  type        = string
  default     = "eu-west-1"
}

variable "az" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "vpc_cidr_block" {
  description = "CIDR range for the VPC"
  type        = string
}

variable "internal_ip_range" {
  description = "Internal IP range of the resources within the VPC"
  type        = string
}

variable "rds_port" {
  description = "Port on which the RDS instance communicates"
  type        = number
  default     = 5432
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-cluster"
}
