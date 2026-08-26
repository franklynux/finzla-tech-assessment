variable "service_name" {
  description = "Name of the ECS service being monitored."
  type        = string
}

variable "alb_arn_suffix" {
  description = "Application Load Balancer ARN suffix used in CloudWatch metric dimensions."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "Target group ARN suffix used in CloudWatch metric dimensions."
  type        = string
}

variable "alarm_actions" {
  description = "SNS topic ARNs or other alarm action ARNs notified when alarms enter ALARM state."
  type        = list(string)
  default     = []
}

variable "http_5xx_threshold" {
  description = "Target 5xx count threshold over the evaluation window."
  type        = number
  default     = 5
}

variable "latency_threshold_seconds" {
  description = "Average target response time threshold in seconds."
  type        = number
  default     = 1
}

variable "unhealthy_target_threshold" {
  description = "Unhealthy target count threshold."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags applied to monitoring resources."
  type        = map(string)
  default     = {}
}
