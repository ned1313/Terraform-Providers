output "prod_public_subnet_ids" {
  description = "The list of IDs for the public subnets created in the production VPC"
  value       = module.prod_vpc.public_subnet_ids
}

output "prod_vpc_id" {
  description = "The ID of the production VPC created"
  value       = module.prod_vpc.vpc_id
}

output "dr_public_subnet_ids" {
  description = "The list of IDs for the public subnets created in the DR VPC"
  value       = module.dr_vpc.public_subnet_ids
}

output "dr_vpc_id" {
  description = "The ID of the DR VPC created"
  value       = module.dr_vpc.vpc_id
}
