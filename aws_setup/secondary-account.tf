# Secondary Account Resources (security)

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
resource "aws_iam_role" "cross_account_s3_role" {
  provider             = aws.secondary
  name                 = var.cross_account_role_name
  assume_role_policy   = data.aws_iam_policy_document.cross_account_role_trust_policy.json
  description          = "Cross-account role for S3 bucket creation from primary account"
  max_session_duration = 3600 # 1 hour

  tags = merge(var.tags, {
    Name        = var.cross_account_role_name
    Account     = "secondary"
    Description = "Cross-account role for S3 bucket creation from primary account"
  })
}

# Policy document for S3 bucket creation and management permissions in the secondary account
data "aws_iam_policy_document" "s3_bucket_permissions" {
  # Allow creating S3 buckets
  statement {
    effect = "Allow"

    actions = [
      "s3:CreateBucket"
    ]

    resources = ["*"]

    # Ensure buckets are created with specific tags to identify the creator
    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-bucket-tagging"
      values   = ["CreatedBy=${aws_iam_role.cross_account_s3_role.arn}"]
    }
  }

  # Allow listing all buckets (needed for AWS CLI and console operations)
  statement {
    effect = "Allow"

    actions = [
      "s3:ListAllMyBuckets",
      "s3:GetBucketLocation"
    ]

    resources = ["*"]
  }

  # Allow full bucket management operations, but only on buckets created by this role
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucket*",
      "s3:PutBucket*",
      "s3:DeleteBucket*",
      "s3:ListBucket*"
    ]

    resources = ["arn:aws:s3:::*"]

    # Only allow operations on buckets tagged with this role as creator
    condition {
      test     = "StringEquals"
      variable = "s3:ExistingBucketTag/CreatedBy"
      values   = ["${aws_iam_role.cross_account_s3_role.arn}"]
    }
  }

  # Allow object management operations, but only in buckets created by this role
  statement {
    effect = "Allow"

    actions = [
      "s3:GetObject*",
      "s3:PutObject*",
      "s3:DeleteObject*",
      "s3:RestoreObject",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload"
    ]

    resources = ["arn:aws:s3:::*/*"]

    # Only allow operations on objects in buckets tagged with this role as creator
    condition {
      test     = "StringEquals"
      variable = "s3:ExistingBucketTag/CreatedBy"
      values   = ["${aws_iam_role.cross_account_s3_role.arn}"]
    }
  }

  # Allow bucket policy management, but only on buckets created by this role
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:DeleteBucketPolicy"
    ]

    resources = ["arn:aws:s3:::*"]

    condition {
      test     = "StringEquals"
      variable = "s3:ExistingBucketTag/CreatedBy"
      values   = ["${aws_iam_role.cross_account_s3_role.arn}"]
    }
  }

  # Allow lifecycle configuration management on buckets created by this role
  statement {
    effect = "Allow"

    actions = [
      "s3:GetLifecycleConfiguration",
      "s3:PutLifecycleConfiguration"
    ]

    resources = ["arn:aws:s3:::*"]

    condition {
      test     = "StringEquals"
      variable = "s3:ExistingBucketTag/CreatedBy"
      values   = ["${aws_iam_role.cross_account_s3_role.arn}"]
    }
  }

  # Allow tagging operations (needed for initial bucket creation and ongoing management)
  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketTagging",
      "s3:PutBucketTagging",
      "s3:TagResource",
      "s3:UntagResource"
    ]

    resources = ["arn:aws:s3:::*"]

    # Allow tagging on buckets created by this role OR during bucket creation
    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "s3:ExistingBucketTag/CreatedBy"
      values   = ["${aws_iam_role.cross_account_s3_role.arn}", ""]
    }
  }
}

# IAM policy for S3 bucket permissions
resource "aws_iam_policy" "s3_bucket_permissions" {
  provider    = aws.secondary
  name        = "S3BucketCreationAndManagement"
  description = "Permissions for S3 bucket creation and management by cross-account role"
  policy      = data.aws_iam_policy_document.s3_bucket_permissions.json

  tags = merge(var.tags, {
    Name        = "S3BucketCreationAndManagement"
    Account     = "secondary"
    Description = "S3 bucket permissions for cross-account role"
  })
}

# Attach the S3 bucket policy to the cross-account role
resource "aws_iam_role_policy_attachment" "cross_account_s3_permissions" {
  provider   = aws.secondary
  role       = aws_iam_role.cross_account_s3_role.name
  policy_arn = aws_iam_policy.s3_bucket_permissions.arn
}