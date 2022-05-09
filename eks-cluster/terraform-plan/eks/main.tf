# EKS CLUSTER DECLARATION
resource "aws_eks_cluster" "eks" {
  name     = "${var.eks_cluster_name}-${var.env}"
  role_arn = aws_iam_role.eks.arn

  vpc_config {
    security_group_ids      = [aws_security_group.eks_cluster.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = ["0.0.0.0/0"]
    subnet_ids              = [var.aws_subnet_private["private-eks-1"].id, var.aws_subnet_private["private-eks-2"].id, var.aws_subnet_public["public-eks-1"].id, var.aws_subnet_public["public-eks-2"].id]
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks-AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.eks-AmazonEC2ContainerRegistryReadOnly
  ]

  tags = {
    Environment = var.env
  }
}
