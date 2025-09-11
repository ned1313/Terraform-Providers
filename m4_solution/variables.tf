variable "prod_region" {
  default = "us-west-2"
}

variable "dr_region" {
  default = "us-east-2"
}

variable "environment" {
  default = "dev"
}

variable "prod_network_info" {
  description = "A map of networking configuration values for the VPC and subnets"
  type = object({
    vpc_name             = string
    vpc_cidr             = string
    public_subnets       = map(string)
    map_public_ip        = optional(bool, true)
    enable_dns_hostnames = optional(bool, true)
    enable_dns_support   = optional(bool, true)
  })
}

variable "dr_network_info" {
  description = "A map of networking configuration values for the VPC and subnets"
  type = object({
    vpc_name             = string
    vpc_cidr             = string
    public_subnets       = map(string)
    map_public_ip        = optional(bool, true)
    enable_dns_hostnames = optional(bool, true)
    enable_dns_support   = optional(bool, true)
  })
  
}

variable "security_role_arn" {
  description = "The ARN of the IAM role to assume for S3 creation in the security account"
  type        = string
  
}
