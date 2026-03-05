resource "aws_secretsmanager_secret" "weather_api_key" {
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