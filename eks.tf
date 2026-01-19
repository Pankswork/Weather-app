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
    subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  }

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

# This allows YOUR user to see pods in the AWS Console
# Add this so your ROOT account can also see the pods
resource "aws_eks_access_entry" "root_user" {
  cluster_name  = aws_eks_cluster.weather_cluster.name
  principal_arn = "arn:aws:iam::668227158023:root" # The 'root' principal
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "root_admin" {
  cluster_name  = aws_eks_cluster.weather_cluster.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = "arn:aws:iam::668227158023:root"

  access_scope {
    type = "cluster"
  }
}
