# Declare a security group for the EKS cluster, i.e. control plane
resource "aws_security_group" "eks_cluster" {
  name        = "${var.eks_cluster_name}-${var.env}/ControlPlaneSecurityGroup"
  description = "Communication between the control plane and worker nodegroups"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.eks_cluster_name}-${var.env}/ControlPlaneSecurityGroup"
    Environment = var.env
  }
}


# Declare a security group for the EKS nodes group, i.e. data plane
resource "aws_security_group" "eks_nodes" {
  name        = "${var.eks_cluster_name}-${var.env}/DataPlaneSecurityGroup"
  description = "Communication between all nodes in the cluster"
  vpc_id      = var.vpc_id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.eks_cluster_name}-${var.env}/DataPlaneSecurityGroup"
    Environment = var.env
  }
}

resource "aws_security_group_rule" "cluster_inbound" {
  description              = "Allow unmanaged nodes to communicate with control plane (all ports)"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 0
  type                     = "ingress"
}

# Declare a security group for the pods that needs access to the RDS instance
resource "aws_security_group" "rds_access" {
    name        = "rds-access-from-pod-${var.env}"
    description = "Allow RDS Access from Kubernetes Pods"
    vpc_id      = var.vpc_id

    ingress {
        from_port = 0
        to_port   = 0
        protocol  = "-1"
        self      = true
    }

    ingress {
        from_port       = 53
        to_port         = 53
        protocol        = "tcp"
        security_groups = [aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id]
    }

    ingress {
        from_port       = 53
        to_port         = 53
        protocol        = "udp"
        security_groups = [aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name        = "rds-access-from-pod-${var.env}"
        Environment = var.env
    }
}
