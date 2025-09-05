data "aws_caller_identity" "current" {}

locals {
  bucket_name = "${var.naming_prefix}-vpc-flow-logs-${var.bucket_id_suffix}"

  common_tags = merge(
    {
      Name      = "${var.naming_prefix}-vpc-flow-logs"
      Module    = "vpc_flow_logs"
      VpcId     = var.vpc_id
      ManagedBy = "Terraform"
    },
    var.tags
  )
}

# S3 bucket for storing VPC flow logs
resource "aws_s3_bucket" "vpc_flow_logs" {
  bucket        = local.bucket_name
  force_destroy = var.s3_bucket_force_destroy

  tags = merge(local.common_tags, {
    Name        = local.bucket_name
    Description = "S3 bucket for VPC flow logs storage"
  })
}

# S3 bucket versioning
resource "aws_s3_bucket_versioning" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# S3 bucket server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_id != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_id
    }
    bucket_key_enabled = var.kms_key_id != null ? true : false
  }
}

# S3 bucket public access block
resource "aws_s3_bucket_public_access_block" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id

  rule {
    id     = "flow_logs_lifecycle"
    status = "Enabled"
    filter {}

    # Transition to IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Transition to Deep Archive after 365 days
    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    # Delete objects after 7 years (compliance requirement)
    expiration {
      days = 2555 # 7 years
    }

    # Clean up incomplete multipart uploads after 7 days
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# S3 bucket policy to allow VPC Flow Logs service to write to the bucket
data "aws_iam_policy_document" "vpc_flow_logs_bucket_policy" {
  statement {
    sid    = "AWSLogDeliveryWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      "${aws_s3_bucket.vpc_flow_logs.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }

  statement {
    sid    = "AWSLogDeliveryAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.vpc_flow_logs.arn
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs.id
  policy = data.aws_iam_policy_document.vpc_flow_logs_bucket_policy.json
}

# VPC Flow Logs
resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn             = aws_iam_role.flow_log_role.arn
  log_destination          = aws_s3_bucket.vpc_flow_logs.arn
  log_destination_type     = "s3"
  traffic_type             = var.traffic_type
  vpc_id                   = var.vpc_id
  log_format               = var.flow_log_format
  max_aggregation_interval = var.max_aggregation_interval

  tags = merge(local.common_tags, {
    Name        = "${var.naming_prefix}-vpc-flow-logs"
    Description = "VPC Flow Logs for VPC ${var.vpc_id}"
  })
}

# IAM role for VPC Flow Logs (required even for S3 destination)
data "aws_iam_policy_document" "flow_log_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "flow_log_role" {
  name               = "${var.naming_prefix}-vpc-flow-logs-role"
  assume_role_policy = data.aws_iam_policy_document.flow_log_assume_role.json

  tags = merge(local.common_tags, {
    Name        = "${var.naming_prefix}-vpc-flow-logs-role"
    Description = "IAM role for VPC Flow Logs"
  })
}

# IAM policy for the flow logs role
data "aws_iam_policy_document" "flow_log_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]

    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:GetBucketAcl",
      "s3:ListBucket"
    ]

    resources = [aws_s3_bucket.vpc_flow_logs.arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "s3:PutObject"
    ]

    resources = ["${aws_s3_bucket.vpc_flow_logs.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_iam_role_policy" "flow_log_policy" {
  name   = "${var.naming_prefix}-vpc-flow-logs-policy"
  role   = aws_iam_role.flow_log_role.id
  policy = data.aws_iam_policy_document.flow_log_policy.json
}
