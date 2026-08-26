variable "service_name" {
    type = string 
    default = "Python-HTTP-service"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "vpc_id" {
  description = "Finzla-Tech VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs (for the ALB)"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "Private subnet IDs (for the ECS tasks)"
  type        = list(string)
}

variable "container_port" {
  type    = number
  default = 8000
}

variable "target_group_arn" {
    type = string
    description = "Target group ARN of ALB"
}

variable "alb_sg_id" {
  description = "Security group ID for the ALB"
  type        = string
}

variable "container_image" {
  description = "Docker image used by the ECS task"
  type        = string
}