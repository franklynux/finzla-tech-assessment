output "alb_arn" {
    value = aws_lb.app_lb.arn
    description = "Application Load Balancer ARN"
}

output "alb_dns_name" {
    value = aws_lb.app_lb.dns_name
    description = "Application Load Balancer DNS name"
}

output "target_group_arn" {
    value = aws_lb_target_group.alb_tg.arn
    description = "Target Group ARN"
}

output "alb_sg_id" {
    value = aws_security_group.alb_sg.id
    description = "Application Load Balancer Security Group ID"
}