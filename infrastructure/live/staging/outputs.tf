output "ssh_command" {
  description = "SSH command to connect to master node"
  value       = "ssh -i ${module.key_pair.private_key_path} ubuntu@${module.compute_ec2.master_public_ips[0]}"
}

output "master_ips" {
  description = "Master node public IPs"
  value       = module.compute_ec2.master_public_ips
}

output "worker_ips" {
  description = "Worker node public IPs"
  value       = module.compute_ec2.worker_public_ips
}

