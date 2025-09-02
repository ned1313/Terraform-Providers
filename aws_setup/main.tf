# Configure the AWS Provider for both accounts
provider "aws" {
  alias   = "primary"
  profile = "globomantics-tacowagon"
  region  = "us-east-1"

  default_tags {
    tags = var.tags
  }
}

provider "aws" {
  alias   = "secondary"
  profile = "globomantics-security"
  region  = "us-east-1"

  default_tags {
    tags = var.tags
  }
}

# Data sources to get current account information
data "aws_caller_identity" "primary" {
  provider = aws.primary
}

data "aws_caller_identity" "secondary" {
  provider = aws.secondary
}