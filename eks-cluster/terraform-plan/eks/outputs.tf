output "eks-endpoint" {
    value = aws_eks_cluster.eks.endpoint
}

output "kubeconfig-certificate-authority-data" {
    value = aws_eks_cluster.eks.certificate_authority[0].data
}

output "sg-eks-cluster" {
    value = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
}

output "sg_rds_access" {
    value = aws_security_group.rds_access.id
}

output "rds-access-role-arn" {
    value = aws_iam_role.web_identity_role.arn
}
