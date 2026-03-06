# --- 1. ALB SECURITY GROUP (Public Facing) ---
resource "aws_security_group" "alb_sg" {
  name        = "weather-alb-sg"
  description = "Public web traffic for Weather App"
  vpc_id      = aws_vpc.weather_vpc.id

  #tfsec:ignore:aws-ec2-no-public-ingress-sgr
  #checkov:skip=CKV_AWS_260: "intentional public ingress"
  #checkov:skip=CKV_AWS_24: "intentional port 80"
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # More restricted, adjust if public access is strictly needed
  }

  # RECOMMENDED: Add port 443 if you plan to use SSL/HTTPS
  #tfsec:ignore:aws-ec2-no-public-ingress-sgr
  #checkov:skip=CKV_AWS_260: "intentional public ingress"
  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # More restricted
  }

  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  #checkov:skip=CKV_AWS_23: "intentional public egress"
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr] # More restricted
  }
}

# --- 2. EKS NODE SECURITY GROUP ---
resource "aws_security_group" "eks_nodes_sg" {
  name        = "weather-eks-nodes-sg"
  description = "EKS Worker Node communication"
  vpc_id      = aws_vpc.weather_vpc.id

  # Rule A: Corrected to allow VPC traffic to the Python App
  ingress {
    description = "Allow VPC traffic to Python App"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Rule B: Allow nodes to talk to each other (K8s Networking)
  ingress {
    description = "Allow nodes to talk to each other"
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # Allow the EKS Control Plane to talk to the Webhook on port 9443
  ingress {
    description = "Allow Webhook from Control Plane"
    from_port   = 9443
    to_port     = 9443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  #checkov:skip=CKV_AWS_23: "intentional public egress"
  egress {
    description = "Allow all outbound so nodes can pull Docker images"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr] # Consider VPC endpoints or NAT gateway if 0.0.0.0/0 was for internet
  }
}

# --- 3. DATABASE SG ---
resource "aws_security_group" "db_sg" {
  name_prefix = "weather-db-sg-"
  description = "Allow internal VPC traffic to RDS"
  vpc_id      = aws_vpc.weather_vpc.id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    description = "Allow MySQL traffic from VPC"
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    # This CIDR rule is our 'universal key' to fix the pod connection
    cidr_blocks = [aws_vpc.weather_vpc.cidr_block]
  }

  egress {
    description = "Restrict outbound from DB to only the VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.weather_vpc.cidr_block]
  }
}
