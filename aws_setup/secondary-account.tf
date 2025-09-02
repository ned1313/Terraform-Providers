# Secondary Account Resources (globomantics-security)

# Trust policy for the cross-account role
data "aws_iam_policy_document" "cross_account_role_trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.primary.account_id}:user/${var.primary_user_name}"
      ]
    }

    actions = ["sts:AssumeRole"]

  }
}

# Cross-account role that can be assumed from the primary account
resource "aws_iam_role" "cross_account_vpc_peering_role" {
  provider             = aws.secondary
  name                 = var.cross_account_role_name
  assume_role_policy   = data.aws_iam_policy_document.cross_account_role_trust_policy.json
  description          = "Cross-account role for VPC peering operations"
  max_session_duration = 3600 # 1 hour

  tags = merge(var.tags, {
    Name        = var.cross_account_role_name
    Account     = "secondary"
    Description = "Cross-account role for VPC peering from primary account"
  })
}

# Policy document for VPC peering permissions in the secondary account
data "aws_iam_policy_document" "vpc_peering_permissions" {
  # VPC peering connection permissions
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateVpcPeeringConnection",
      "ec2:AcceptVpcPeeringConnection",
      "ec2:RejectVpcPeeringConnection",
      "ec2:DeleteVpcPeeringConnection",
      "ec2:ModifyVpcPeeringConnectionOptions"
    ]

    resources = [
      "arn:aws:ec2:*:${data.aws_caller_identity.secondary.account_id}:vpc/*",
      "arn:aws:ec2:*:${data.aws_caller_identity.secondary.account_id}:vpc-peering-connection/*"
    ]
  }

  # Read-only permissions for VPCs and peering connections
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeRouteTables",
      "ec2:DescribeNetworkAcls",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeRegions"
    ]

    resources = ["*"]
  }

  # Route table modification permissions for peering
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateRoute",
      "ec2:DeleteRoute",
      "ec2:ReplaceRoute"
    ]

    resources = [
      "arn:aws:ec2:*:${data.aws_caller_identity.secondary.account_id}:route-table/*"
    ]
  }

  # Network ACL permissions (if needed for peering)
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateNetworkAclEntry",
      "ec2:DeleteNetworkAclEntry",
      "ec2:ReplaceNetworkAclEntry"
    ]

    resources = [
      "arn:aws:ec2:*:${data.aws_caller_identity.secondary.account_id}:network-acl/*"
    ]
  }

  # Tag management for created resources
  statement {
    effect = "Allow"

    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]

    resources = [
      "arn:aws:ec2:*:${data.aws_caller_identity.secondary.account_id}:vpc-peering-connection/*",
      "arn:aws:ec2:*:${data.aws_caller_identity.secondary.account_id}:route-table/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values = [
        "CreateVpcPeeringConnection",
        "AcceptVpcPeeringConnection",
        "CreateRoute"
      ]
    }
  }
}

# IAM policy for VPC peering permissions
resource "aws_iam_policy" "vpc_peering_permissions" {
  provider    = aws.secondary
  name        = "VPCPeeringCrossAccountPermissions"
  description = "Permissions for cross-account VPC peering operations"
  policy      = data.aws_iam_policy_document.vpc_peering_permissions.json

  tags = merge(var.tags, {
    Name        = "VPCPeeringCrossAccountPermissions"
    Account     = "secondary"
    Description = "VPC peering permissions for cross-account access"
  })
}

# Attach the VPC peering policy to the cross-account role
resource "aws_iam_role_policy_attachment" "cross_account_vpc_peering_permissions" {
  provider   = aws.secondary
  role       = aws_iam_role.cross_account_vpc_peering_role.name
  policy_arn = aws_iam_policy.vpc_peering_permissions.arn
}

# Optional: CloudWatch Logs permissions for monitoring
data "aws_iam_policy_document" "cloudwatch_logs_permissions" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]

    resources = [
      "arn:aws:logs:*:${data.aws_caller_identity.secondary.account_id}:log-group:/aws/vpc-peering/*"
    ]
  }
}

resource "aws_iam_policy" "cloudwatch_logs_permissions" {
  provider    = aws.secondary
  name        = "VPCPeeringCloudWatchLogs"
  description = "CloudWatch Logs permissions for VPC peering operations"
  policy      = data.aws_iam_policy_document.cloudwatch_logs_permissions.json

  tags = merge(var.tags, {
    Name        = "VPCPeeringCloudWatchLogs"
    Account     = "secondary"
    Description = "CloudWatch Logs permissions for VPC peering monitoring"
  })
}

# Attach CloudWatch Logs policy to the cross-account role
resource "aws_iam_role_policy_attachment" "cross_account_cloudwatch_logs" {
  provider   = aws.secondary
  role       = aws_iam_role.cross_account_vpc_peering_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs_permissions.arn
}
