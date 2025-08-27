output "master_instances" {
  description = "Master node instances"
  value       = aws_instance.master
}

output "worker_instances" {
  description = "Worker node instances"
  value       = aws_instance.worker
}

output "master_instance_ids" {
  description = "IDs of master instances"
  value       = aws_instance.master[*].id
}

output "worker_instance_ids" {
  description = "IDs of worker instances"
  value       = aws_instance.worker[*].id
}

output "master_private_ips" {
  description = "Private IP addresses of master nodes"
  value       = aws_instance.master[*].private_ip
}

output "worker_private_ips" {
  description = "Private IP addresses of worker nodes"
  value       = aws_instance.worker[*].private_ip
}

output "master_public_ips" {
  description = "Public IP addresses of master nodes"
  value       = aws_instance.master[*].public_ip
}

output "worker_public_ips" {
  description = "Public IP addresses of worker nodes"
  value       = aws_instance.worker[*].public_ip
}
