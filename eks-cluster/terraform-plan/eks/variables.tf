variable "eks_cluster_name" {
  type = string
}

variable "env" {
    type = string
    default = "dev"
}

variable "region" {
    type = string
    default = "eu-west-1"
}

variable "vpc_id" {
    type = string
}

variable "aws_subnet_private" {
    type = map
}

variable "aws_subnet_public" {
    type = map
}

variable "aws_caller_identity" {
    type = string
}

variable "aws_db_instance" {
    type = string
}
