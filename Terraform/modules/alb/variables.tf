variable "public_subnet_ids" {
    type = list(string)
    description = "List of Public subnets for Application Load Balancer"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}