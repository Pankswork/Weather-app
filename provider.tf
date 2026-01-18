terraform {
  required_version = ">= 1.5.7"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "weather-app-panks-bucket"
    key     = "dev/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    # use_lockfile requires Terraform 1.10+. If using older, use dynamodb_table for locking.
    # dynamodb_table = "terraform-lock" 
  }
}

provider "aws" {
  region = var.aws_region
}

