variable "aws_region" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "docker_hub_image" {
  type = string
}

variable "secret_name" {
  type = string
}

# RDS Specific Variables
variable "mysql_username" {
  type      = string
  sensitive = true
}

variable "mysql_password" {
  type      = string
  sensitive = true
}
