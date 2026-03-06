# --- 1. EKS Cluster Configuration ---
resource "aws_eks_cluster" "weather_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  # ADD THIS BLOCK HERE
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  vpc_config {
    subnet_ids              = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    #tfsec:ignore:aws-eks-no-public-cluster-access
    #checkov:skip=CKV_AWS_39: "Public endpoint access required for GitHub Actions runners to connect and deploy Helm charts"
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  # Enable Control Plane Logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  # KMS Encryption for K8s Secrets
  encryption_config {
    resources = ["secrets"]
    provider {
      key_arn = aws_kms_key.eks_key.arn
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# KMS Key for EKS Secret Encryption
resource "aws_kms_key" "eks_key" {
  #checkov:skip=CKV2_AWS_64: "KMS Key policy is managed by default AWS KMS behavior for this simple project"
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

# --- 2. OIDC Provider Logic (The "Handshake") ---
# This allows IAM to trust your Kubernetes pods
data "tls_certificate" "eks" {
  url = aws_eks_cluster.weather_cluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.weather_cluster.identity[0].oidc[0].issuer
}

# --- 3. Managed Node Group ---
resource "aws_eks_node_group" "weather_nodes" {
  cluster_name    = aws_eks_cluster.weather_cluster.name
  node_group_name = "weather-app-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  # Cost-optimization: Flex instances on SPOT
  instance_types = ["c7i-flex.large"]
  capacity_type  = "SPOT"
  disk_size      = 30

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.node_attachments
  ]
}

