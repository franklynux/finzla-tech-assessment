locals {
  common_tags = merge(
    {
      ManagedBy = "terraform"
      Component = "monitoring"
      Service   = var.service_name
    },
    var.tags
  )

  alb_target_dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.target_group_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "http_5xx" {
  alarm_name          = "${var.service_name}-http-5xx"
  alarm_description   = "Triggers when the ALB target group returns too many HTTP 5xx responses."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 5
  threshold           = var.http_5xx_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = local.alb_target_dimensions
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  tags                = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "target_response_time" {
  alarm_name          = "${var.service_name}-target-response-time"
  alarm_description   = "Triggers when average target response time is above the expected threshold."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "TargetResponseTime"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  threshold           = var.latency_threshold_seconds
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = local.alb_target_dimensions
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  tags                = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_targets" {
  alarm_name          = "${var.service_name}-unhealthy-targets"
  alarm_description   = "Triggers when one or more targets in the ALB target group are unhealthy."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  threshold           = var.unhealthy_target_threshold
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"
  dimensions          = local.alb_target_dimensions
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  tags                = local.common_tags
}
