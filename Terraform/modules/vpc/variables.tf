variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default     = "finzla"
}

variable "availability_zones" {
  description = "List of Availability Zones to use for the VPC"
  type        = list(string)
  default     = []
}

variable "max_azs" {
  description = "Maximum number of Availability Zones to use if none are specified"
  type        = number
  default     = 2
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_count" {
  description = "Number of public subnets to create"
  type        = number
  default     = 2
}

variable "app_private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.8.0/22", "10.0.12.0/22"]
}

variable "app_private_subnet_count" {
  description = "Number of private subnets"
  type        = number
  default     = 2
}