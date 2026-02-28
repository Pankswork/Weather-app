terraform {
  required_version = ">= 1.5.7"

  backend "s3" {
    bucket         = "weather-app-panks-bucket"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
