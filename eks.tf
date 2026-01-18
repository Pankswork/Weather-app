# --- 1. EKS Cluster Configuration ---
resource "aws_eks_cluster" "weather_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    # Ensure these match the subnet resource names in your vpc.tf
    subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  }

  # Ensure the IAM role is ready before the cluster starts
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
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
    max_size     = 3 # Extra room for rolling updates
  }

  update_config {
    max_unavailable = 1
  }

  # Ensure the Node Role has the required policies before nodes join
  depends_on = [
    aws_iam_role_policy_attachment.node_attachments
  ]
}
