// Expose the repository name for downstream references.
output "repository_name" {
  description = "Name of the ECR repository."
  value       = aws_ecr_repository.this.name
}

// Expose the repository ARN for IAM and policy integrations.
output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = aws_ecr_repository.this.arn
}

// Expose the registry URL used by CI/CD systems and workloads.
output "repository_url" {
  description = "Repository URL used for image pushes and pulls."
  value       = aws_ecr_repository.this.repository_url
}
