output "kubernetes_sg_id" {
  description = "ID of the Kubernetes security group"
  value       = aws_security_group.kubernetes.id
}
