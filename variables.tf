variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "weather-app-eks"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "docker_hub_image" {
  type    = string
  default = "your_username/weather_app:latest"
}

variable "secret_name" {
  type        = string
  description = "The name of the secret in AWS Secrets Manager"
  default     = "weather-app-secrets"
}

# RDS Specific Variables
variable "mysql_username" {
  type      = string
  default   = "admin"
  sensitive = true
}

variable "mysql_password" {
  type      = string
  sensitive = true
}
