provider "aws" {
  region = var.prod_region
}

provider "aws" {
  alias = "dr"
  region = var.dr_region
}

provider "aws" {
  alias = "security"
  region = var.prod_region
  assume_role {
    role_arn = var.security_role_arn
  }
}