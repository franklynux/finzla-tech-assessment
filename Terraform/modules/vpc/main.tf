resource "aws_vpc" "finzla_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = var.vpc_name
  }
}

# Get list of Availability Zones in a selected region
data "aws_availability_zones" "AZs" {
  state = "available" # Filter for available availability zones
}

# Flexible AZ selection logic
locals {
  # Use provided AZs or auto-select from available ones
  selected_azs = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.AZs.names, 0, min(length(data.aws_availability_zones.AZs.names), var.max_azs))
}

# Create Subnets in selected Availability Zones
resource "aws_subnet" "public_subnets" {
  count                   = var.public_subnet_count
  vpc_id                  = aws_vpc.finzla_vpc.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = local.selected_azs[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.vpc_name}-public-subnet-${count.index + 1}"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.finzla_vpc.id
  tags = {
    Name = "${var.vpc_name}-igw"
  }
}

# Create a Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.finzla_vpc.id
  tags = {
    Name = "${var.vpc_name}-public-rt"
  }
}

# Create a route in the public route table to direct internet-bound traffic to the Internet Gateway
resource "aws_route" "igw_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public_rt_assoc" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public_rt.id
}


# Create Private Subnets 
resource "aws_subnet" "app_private_subnets" {
  count                   = var.app_private_subnet_count
  vpc_id                  = aws_vpc.finzla_vpc.id
  cidr_block              = var.app_private_subnet_cidrs[count.index]
  availability_zone       = local.selected_azs[count.index % length(local.selected_azs)]
  map_public_ip_on_launch = false
  tags = {
    Name = "${var.vpc_name}-private_subnet_${count.index + 1}"
  }
}

# Create Elastic IPs for NAT Gateways
resource "aws_eip" "nat_eip" {
  count  = 1
  domain = "vpc" # Specify that the Elastic IP is for a VPC
  tags = {
    Name = "${var.vpc_name}-nat_eip_${count.index + 1}"
  }
}

# Create NAT Gateways in public subnets
resource "aws_nat_gateway" "private_subnets_natGW" {
  count         = 1
  allocation_id = aws_eip.nat_eip[count.index].id
  subnet_id     = aws_subnet.public_subnets[count.index].id
  tags = {
    Name = "${var.vpc_name}-private_natGW_${count.index + 1}"
  }
}

# Create Route Tables for Private Subnets
resource "aws_route_table" "app_private_route_table" {
  count  = 2
  vpc_id = aws_vpc.finzla_vpc.id
  tags = {
    Name = "${var.vpc_name}-private_rt_${count.index + 1}"
  }
}

# Create Routes for Private Route Tables to use NAT Gateways
resource "aws_route" "nat_route" {
  count                  = 2
  route_table_id         = aws_route_table.app_private_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.private_subnets_natGW[0].id
}

# Associate Private Subnets with their respective Route Tables
resource "aws_route_table_association" "private_rt_assoc" {
  count          = var.app_private_subnet_count
  subnet_id      = aws_subnet.app_private_subnets[count.index].id
  route_table_id = aws_route_table.app_private_route_table[count.index].id
}