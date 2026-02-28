# --- 1. ALB SECURITY GROUP (Public Facing) ---
resource "aws_security_group" "alb_sg" {
  name        = "weather-alb-sg"
  description = "Public web traffic for Weather App"
  vpc_id      = aws_vpc.weather_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # RECOMMENDED: Add port 443 if you plan to use SSL/HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- 2. EKS NODE SECURITY GROUP ---
resource "aws_security_group" "eks_nodes_sg" {
  name        = "weather-eks-nodes-sg"
  description = "EKS Worker Node communication"
  vpc_id      = aws_vpc.weather_vpc.id

  # Rule A: Corrected to allow VPC traffic to the Python App
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Rule B: Allow nodes to talk to each other (K8s Networking)
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # Allow the EKS Control Plane to talk to the Webhook on port 9443
  ingress {
    from_port   = 9443
    to_port     = 9443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
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
    from_port = 3306
    to_port   = 3306
    protocol  = "tcp"
    # This CIDR rule is our 'universal key' to fix the pod connection
    cidr_blocks = [aws_vpc.weather_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
