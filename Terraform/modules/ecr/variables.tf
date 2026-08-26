// Set the repository name used by pushes, pulls, and image references.
variable "repository_name" {
  description = "Name of the ECR repository."
  type        = string
}

// Control whether existing tags can be overwritten by later pushes.
variable "image_tag_mutability" {
  description = "Whether image tags can be overwritten."
  type        = string
  default     = "MUTABLE"

  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

// Enable or disable automatic image scanning on every push.
variable "scan_on_push" {
  description = "Enable ECR image scanning whenever an image is pushed."
  type        = bool
  default     = true
}

// Optionally provide a customer-managed KMS key for repository encryption.
variable "kms_key_arn" {
  description = "Optional KMS key ARN for repository encryption. Defaults to AES256 when unset."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags applied to ECR resources."
  type        = map(string)
  default     = {}
}

