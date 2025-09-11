prod_region = "us-west-2"
prod_network_info = {
  vpc_name = "sopes-saloon-prod"
  vpc_cidr = "10.0.0.0/16"
  public_subnets = {
    subnet_1 = "10.0.0.0/24"
  }
}

dr_region = "us-east-2"
dr_network_info = {
  vpc_name = "sopes-saloon-dr"
  vpc_cidr = "10.0.0.0/16"
  public_subnets = {
    subnet_1 = "10.0.0.0/24"
  }
}

security_role_arn = "UPDATE_WITH_VALUE"