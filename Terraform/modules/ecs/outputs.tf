output "ecs_cluster_name" {
  value = aws_ecs_cluster.this.name
}

output "ecs_service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.this.name
}

output "log_group_name" {
  description = "CloudWatch log group containing application logs."
  value       = aws_cloudwatch_log_group.http_service.name
}
