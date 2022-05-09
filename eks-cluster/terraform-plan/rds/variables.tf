# RDS DB VARIABLES
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

variable "rds_port" {
  type    = number
  default = 5432
}

variable "aws_subnet_private" {
    type = map
}

variable "aws_subnet_public" {
    type = map
}

variable "sg_rds_access" {
    description = ""
    type = string
}
