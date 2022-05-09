## Define the EKS Cluster IAM role
resource "aws_iam_role" "eks" {
  name = "${var.eks_cluster_name}-${var.env}"

  assume_role_policy = data.aws_iam_policy_document.eks-AssumeRole.json

}

data "aws_iam_policy_document" "eks-AssumeRole" {
    statement {
        effect = "Allow"
        principals {
            identifiers = ["eks.amazonaws.com"]
            type= "Service"
        }
        actions = ["sts:AssumeRole"]
    }
}
# Attach other EKS cluster AWS managed policies
resource "aws_iam_role_policy_attachment" "eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks.name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks.name
}

## Define the node group IAM role
resource "aws_iam_role" "node-group" {
  name = "eks-node-group-role-${var.env}"

  assume_role_policy = data.aws_iam_policy_document.node-group-AssumeRole.json
  inline_policy {
      name = "node-group-ClusterAutoscalerPolicy"
      policy = data.aws_iam_policy_document.node-group-ClusterAutoscalerPolicy.json
  }
}

# Define the role assumption
data "aws_iam_policy_document" "node-group-AssumeRole" {
    statement {
        effect = "Allow"
        principals {
            identifiers = ["ec2.amazonaws.com"]
            type= "Service"
        }
        actions = ["sts:AssumeRole"]
    }
}
# Define auto-scaling policy
data "aws_iam_policy_document" "node-group-ClusterAutoscalerPolicy" {
    statement {
        effect   = "Allow"
        actions = [
            "autoscaling:DescribeAutoScalingGroups",
            "autoscaling:DescribeAutoScalingInstances",
            "autoscaling:DescribeLaunchConfigurations",
            "autoscaling:DescribeTags",
            "autoscaling:SetDesiredCapacity",
            "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
        resources = ["*"]
      }
}
# Attach other node groups AWS managed policies
resource "aws_iam_role_policy_attachment" "node-group-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node-group.name
}

resource "aws_iam_role_policy_attachment" "node-group-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node-group.name
}

resource "aws_iam_role_policy_attachment" "node-group-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node-group.name
}

# Enable IAM roles for Service Account in order to use IAM roles at the pod level (we combine the
# OpenID Connect (OIDC) identity provider and Kubernetes service account annotations). With this configuration
# EKS's admission controller will inject AWS session credentials into pods respectively of the roles based on the
# annotation on the Service Account used by the pod.
# The credentials will get exposed by AWS_ROLE_ARN & AWS_WEB_IDENTITY_TOKEN_FILE environment variables.
# https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html

data "tls_certificate" "cert" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "openid" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cert.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "web_identity_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.openid.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:metabase:metabase"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.openid.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.openid.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "web_identity_role" {
  assume_role_policy = data.aws_iam_policy_document.web_identity_assume_role_policy.json
  name               = "web-identity-role-${var.env}"

}


# Create policy that allows access to rds from the pods
resource "aws_iam_role_policy" "rds_access_from_k8s_pods" {
  name = "rds-access-from-k8s-pods-${var.env}"
  role = aws_iam_role.web_identity_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds-db:connect",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:rds-db:${var.region}:${var.aws_caller_identity}:dbuser:${var.aws_db_instance}/metabase"
      }
    ]
  })
}

# Add managed policy to enable pod security groups
resource "aws_iam_role_policy_attachment" "eks-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks.name
}
