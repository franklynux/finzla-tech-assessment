output "repository_name" {
  description = "Name of the ECR repository."
  value       = module.ecr.repository_name
}

output "repository_arn" {
  description = "ARN of the ECR repository."
  value       = module.ecr.repository_arn
}

output "repository_url" {
  description = "Repository URL used for image pushes and pulls."
  value       = module.ecr.repository_url
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.alb.alb_dns_name
}
