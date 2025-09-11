## Networking Resources

## Networking Resources
module "prod_vpc" {
  source      = "./modules/vpc"
  environment = var.environment
  region      = var.prod_region
  network_info = var.prod_network_info
}

module "dr_vpc" {
  source      = "./modules/vpc"
  environment = var.environment
  region      = var.dr_region
  network_info = var.dr_network_info

  providers = {
    aws = aws.dr
  }
}

# Enable Flow Logs for the VPC
resource "random_string" "bucket_suffix" {
  length = 12
  special = false
  upper = false
}

module "s3_bucket" {
  source = "../vpc_flow_logs"
  vpc_id = module.prod_vpc.vpc_id
  naming_prefix = "sopes-saloon"
  iam_role_arn = var.security_role_arn
  bucket_id_suffix = random_string.bucket_suffix.result

  providers = {
    aws.vpc_account = aws
    aws = aws.security
  }
}