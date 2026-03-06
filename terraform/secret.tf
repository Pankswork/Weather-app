#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "weather_api_key" {
    #checkov:skip=CKV_AWS_149: "Default AWS managed KMS key is sufficient for this project"
    #checkov:skip=CKV2_AWS_57: "Automatic secret rotation not required for dev setting"
    name                    = "weather-api-key-secret"
    description             = "Weather App API Key"
    recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "weather_api_key" {
    secret_id = aws_secretsmanager_secret.weather_api_key.id
    secret_string = jsonencode({
        weather_api_key = var.weather_api_key
    })
}