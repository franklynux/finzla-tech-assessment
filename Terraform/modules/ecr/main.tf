// Declare the AWS provider used by this module.
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

// Apply standard module tags and allow callers to append their own.
locals {
  common_tags = merge(
    {
      ManagedBy = "terraform"
      Component = "ecr"
    },
    var.tags
  )
}

// Create the private container registry that stores service images.
resource "aws_ecr_repository" "this" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  // Scan newly pushed images for known vulnerabilities.
  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  // Fall back to AWS-managed encryption when no customer KMS key is supplied.
  dynamic "encryption_configuration" {
    for_each = var.kms_key_arn == null ? [1] : []

    content {
      encryption_type = "AES256"
    }
  }

  // Use a customer-managed KMS key when one is explicitly provided.
  dynamic "encryption_configuration" {
    for_each = var.kms_key_arn == null ? [] : [1]

    content {
      encryption_type = "KMS"
      kms_key         = var.kms_key_arn
    }
  }

  tags = local.common_tags
}
