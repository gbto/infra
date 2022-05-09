variable "env_name" {
    description = "Environment the ressources are instantiated in"
    type = string
    default = "dev"
}

variable "aws_region" {
  description = "AWS region in which to instantiate the resources"
  type = string
  default = "eu-west-1"
}

variable "vpc_cidr_block" {
  description = "CIDR range for the VPC"
  type = string
}

variable "internal_ip_range" {
  description =  "Internal IP range of the resources within the VPC"
  type = string
}

variable "rds_port" {
  description = "Port on which the RDS instance communicates"
  type    = number
  default = 5432
}

variable "private_network_config" {
  description = "Configuration of the private subnets of the VPC"
  type = map(object({
    cidr_block               = string
    az                       = string
    associated_public_subnet = string
    eks                      = bool
  }))

  default = {
    "private-eks-1" = {
      cidr_block               = "10.0.0.0/23"
      az                       = "eu-west-1a"
      associated_public_subnet = "public-eks-1"
      eks                      = true
    },
    "private-eks-2" = {
      cidr_block               = "10.0.2.0/23"
      az                       = "eu-west-1b"
      associated_public_subnet = "public-eks-2"
      eks                      = true
    },
    "private-rds-1" = {
      cidr_block               = "10.0.4.0/24"
      az                       = "eu-west-1a"
      associated_public_subnet = ""
      eks                      = false
    },
    "private-rds-2" = {
      cidr_block               = "10.0.5.0/24"
      az                       = "eu-west-1b"
      associated_public_subnet = ""
      eks                      = false
    }
  }
}

locals {
  private_nested_config = flatten([
    for name, config in var.private_network_config : [
      {
        name                     = name
        cidr_block               = config.cidr_block
        az                       = config.az
        associated_public_subnet = config.associated_public_subnet
        eks                      = config.eks
      }
    ]
  ])
}

variable "public_network_config" {
  description = "Configuration of the public subnets of the VPC"
  type = map(object({
    cidr_block = string
    az         = string
    nat_gw     = bool
    eks        = bool
  }))

  default = {
    "public-eks-1" = {
      cidr_block = "10.0.6.0/23"
      az         = "eu-west-1a"
      nat_gw     = true
      eks        = true
    },
    "public-eks-2" = {
      cidr_block = "10.0.8.0/23"
      az         = "eu-west-1b"
      nat_gw     = true
      eks        = true
    },
    "public-rds-1" = {
      cidr_block = "10.0.10.0/24"
      az         = "eu-west-1a"
      nat_gw     = false
      eks        = false
    },
    "public-rds-2" = {
      cidr_block = "10.0.11.0/24"
      az         = "eu-west-1b"
      nat_gw     = false
      eks        = false
    }
  }
}

locals {
  public_nested_config = flatten([
    for name, config in var.public_network_config : [
      {
        name       = name
        cidr_block = config.cidr_block
        az         = config.az
        nat_gw     = config.nat_gw
        eks        = config.eks
      }
    ]
  ])
}
