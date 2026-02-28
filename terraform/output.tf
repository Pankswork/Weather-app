output "cluster_name" {
  value = aws_eks_cluster.weather_cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.weather_cluster.endpoint
}

output "rds_endpoint" {
  value = aws_db_instance.weather_db.address
}
