output "rds-username" {
  value = module.rds.rds-username
}

output "rds-password" {
  value     = module.rds.rds-password
  sensitive = true
}

output "private-rds-endpoint" {
  value = module.rds.private-rds-endpoint
}

output "public-rds-endpoint" {
  value = module.rds.public-rds-endpoint
}

output "sg-rds-access" {
  value = module.eks.sg_rds_access
}

output "sg-eks-cluster" {
  value = module.eks.sg-eks-cluster
}

output "rds-access-role-arn" {
  value = module.eks.rds-access-role-arn
}
