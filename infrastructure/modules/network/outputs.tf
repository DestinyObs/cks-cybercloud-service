output "vpc_id" {
  description = "ID of the VPC"
  value       = data.aws_vpc.default.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = data.aws_vpc.default.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = data.aws_subnets.default.ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = data.aws_subnets.default.ids
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = data.aws_internet_gateway.default.id
}


