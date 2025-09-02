# Primary Account Resources (globomantics-tacowagon)

# Data source to reference the existing IAM user
data "aws_iam_user" "existing_vpc_peering_user" {
  provider  = aws.primary
  user_name = var.primary_user_name
}

# IAM policy for the user to assume the cross-account role
data "aws_iam_policy_document" "assume_cross_account_role_policy" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.secondary.account_id}:role/${var.cross_account_role_name}"
    ]
  }
}

resource "aws_iam_policy" "assume_cross_account_role" {
  provider    = aws.primary
  name        = "AssumeVPCPeeringCrossAccountRole"
  description = "Policy to allow assuming the VPC peering cross-account role"
  policy      = data.aws_iam_policy_document.assume_cross_account_role_policy.json

  tags = merge(var.tags, {
    Name        = "AssumeVPCPeeringCrossAccountRole"
    Account     = "primary"
    Description = "Policy for assuming cross-account VPC peering role"
  })
}

# Attach the policy to the existing user
resource "aws_iam_user_policy_attachment" "vpc_peering_user_assume_role" {
  provider   = aws.primary
  user       = data.aws_iam_user.existing_vpc_peering_user.user_name
  policy_arn = aws_iam_policy.assume_cross_account_role.arn
}
