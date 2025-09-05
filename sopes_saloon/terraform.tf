terraform {
  required_version = ">= 1.11"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=6.12.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 2.0"
    }
  }
}