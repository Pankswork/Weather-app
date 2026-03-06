output "cluster_name" {
  value = aws_eks_cluster.weather_cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.weather_cluster.endpoint
}

output "rds_endpoint" {
  value = aws_db_instance.weather_db.address
}

output "vpc_id" {
  value       = aws_vpc.weather_vpc.id
  description = "The ID of the VPC"
}

output "lbc_role_arn" {
  value       = aws_iam_role.lbc_role.arn
  description = "The ARN of the IAM role for the AWS Load Balancer Controller"
}
