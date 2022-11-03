
module "s3-bucket" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_prefix       = "s3-bucket"
  replication_enabled = false

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags
}


data "aws_iam_policy_document" "cross-account-s3" {
  statement {
    sid = "cross-account-s3-access-for-image-builder"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3:ListBucket"

    ]

    resources = ["${module.image-builder-bucket.bucket.arn}/*",
    module.image-builder-bucket.bucket.arn, ]
    principals {
      type = "AWS"
      identifiers = sort([ # sort to avoid plan changes
        "arn:aws:iam::${local.account_id}:root",
        "arn:aws:iam::${local.environment_management.account_ids["core-shared-services-production"]}:root"
      ])
    }
  }
}

module "image-builder-bucket" {
  source = "git::https://github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=v6.2.0"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_prefix       = "ec2-image-builder-${local.application_name}"
  replication_enabled = false

  bucket_policy = [data.aws_iam_policy_document.cross-account-s3.json]

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "Enabled"
      }

      transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
        }
      ]

      expiration = {
        days = 730
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags

}
