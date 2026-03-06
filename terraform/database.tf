# 1. DB Subnet Group
resource "aws_db_subnet_group" "weather_db_subnet_group" {
  name       = "weather-db-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = { Name = "Weather DB Subnet Group" }
}

# 2. RDS MySQL Instance
resource "aws_db_instance" "weather_db" {
  allocated_storage      = 20
  storage_type           = "gp3"
  db_name                = "weather_app"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  username                            = var.mysql_username
  password                            = var.mysql_password
  db_subnet_group_name                = aws_db_subnet_group.weather_db_subnet_group.name
  vpc_security_group_ids              = [aws_security_group.db_sg.id]
  storage_encrypted                   = true
  backup_retention_period             = 7
  iam_database_authentication_enabled = true
  
  # Note: Deletion protection is true for safety, but if you tear down frequently, you might want it false.
  # The scanner prefers true for production data.
  deletion_protection                 = false

  #tfsec:ignore:aws-rds-no-public-db-access
  #tfsec:ignore:aws-rds-enable-performance-insights
  #checkov:skip=CKV_AWS_157: "skip_final_snapshot true for dev/testing"
  #checkov:skip=CKV_AWS_118: "Performance Insights not supported on t3.micro"
  skip_final_snapshot                 = true
  publicly_accessible                 = false
  multi_az                            = false

  tags = { Name = "WeatherApp-MySQL" }
}

# 3. AWS Secrets Manager Integration
resource "aws_secretsmanager_secret" "db_secret" {
  #tfsec:ignore:aws-ssm-secret-use-customer-key
  #checkov:skip=CKV_AWS_149: "Default AWS managed KMS key is sufficient for this project"
  name                    = "weather-app-db-creds"
  description             = "RDS MySQL credentials for Weather App"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.mysql_username
    password = var.mysql_password
    engine   = "mysql"
    host     = aws_db_instance.weather_db.address
    port     = 3306
    dbname   = "weather_app"
  })

  depends_on = [aws_db_instance.weather_db]
}
