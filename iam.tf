# --- EKS CLUSTER ROLE ---
resource "aws_iam_role" "eks_cluster_role" {
  name = "weather-app-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# --- EKS NODE GROUP ROLE ---
resource "aws_iam_role" "eks_node_role" {
  name = "weather-app-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_attachments" {
  for_each = toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  ])
  policy_arn = each.value
  role       = aws_iam_role.eks_node_role.name
}

# --- APP POD ROLE (IRSA) ---
resource "aws_iam_role" "app_irsa_role" {
  name = "weather-app-pod-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" : "system:serviceaccount:pythonapp-dev:weather-app-sa"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "app_secrets_policy" {
  name = "WeatherAppSecretsAccess"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
      Effect   = "Allow"
      Resource = ["${aws_secretsmanager_secret.db_secret.arn}*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_app_secrets" {
  role       = aws_iam_role.app_irsa_role.name
  policy_arn = aws_iam_policy.app_secrets_policy.arn
}

# 1. The Role (Correct)
resource "aws_iam_role" "lbc_role" {
  name = "aws-load-balancer-controller-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRoleWithWebIdentity"
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.eks.arn }
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

# 2. The Custom Policy (Correct)
resource "aws_iam_policy" "lbc_iam_policy" {
  name = "AWSLoadBalancerControllerIAMPolicy"
  # Match the description exactly or remove it if AWS shows it as empty
  description = "Permissions for the AWS Load Balancer Controller"
  policy      = file("${path.module}/lbc_iam_policy.json")

  lifecycle {
    ignore_changes = [description]
  }
}

# 3. The Attachment (Only ONE block allowed)
resource "aws_iam_role_policy_attachment" "lbc_policy_attach" {
  role       = aws_iam_role.lbc_role.name
  policy_arn = aws_iam_policy.lbc_iam_policy.arn
}
