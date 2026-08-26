output "http_5xx_alarm_name" {
  description = "Name of the HTTP 5xx CloudWatch alarm."
  value       = aws_cloudwatch_metric_alarm.http_5xx.alarm_name
}

output "target_response_time_alarm_name" {
  description = "Name of the target response time CloudWatch alarm."
  value       = aws_cloudwatch_metric_alarm.target_response_time.alarm_name
}

output "unhealthy_targets_alarm_name" {
  description = "Name of the unhealthy targets CloudWatch alarm."
  value       = aws_cloudwatch_metric_alarm.unhealthy_targets.alarm_name
}
