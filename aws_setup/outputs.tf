# Outputs for important resource information

output "vpc_peering_user_name" {
  description = "Name of the existing IAM user in the primary account"
  value       = data.aws_iam_user.existing_vpc_peering_user.user_name
}

output "vpc_peering_user_arn" {
  description = "ARN of the existing IAM user in the primary account"
  value       = data.aws_iam_user.existing_vpc_peering_user.arn
}

output "cross_account_role_name" {
  description = "Name of the cross-account role in the secondary account"
  value       = aws_iam_role.cross_account_vpc_peering_role.name
}

output "cross_account_role_arn" {
  description = "ARN of the cross-account role in the secondary account"
  value       = aws_iam_role.cross_account_vpc_peering_role.arn
}
