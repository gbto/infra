data "aws_caller_identity" "current" {}

module "vpc" {
  source            = "./vpc"
  vpc_cidr_block    = var.vpc_cidr_block
  internal_ip_range = var.internal_ip_range
  aws_region        = var.aws_region
  env_name          = var.env
}

module "rds" {
  source             = "./rds"
  vpc_id             = module.vpc.vpc_id
  aws_subnet_public  = module.vpc.aws_subnet_public
  aws_subnet_private = module.vpc.aws_subnet_private
  sg_rds_access      = module.eks.sg_rds_access
}

module "eks" {
  source              = "./eks"
  region              = var.aws_region
  eks_cluster_name    = var.eks_cluster_name
  vpc_id              = module.vpc.vpc_id
  aws_subnet_public   = module.vpc.aws_subnet_public
  aws_subnet_private  = module.vpc.aws_subnet_private
  aws_caller_identity = data.aws_caller_identity.current.account_id
  aws_db_instance     = module.rds.aws_db_instance
}

