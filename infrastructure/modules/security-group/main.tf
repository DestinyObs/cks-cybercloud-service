resource "aws_security_group" "kubernetes" {
  name_prefix = "${var.project_name}-${var.environment}-k8s-"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kubernetes API server
  ingress {
    from_port = 6443
    to_port   = 6443
    protocol  = "tcp"
    self      = true
  }

  # etcd server client API
  ingress {
    from_port = 2379
    to_port   = 2380
    protocol  = "tcp"
    self      = true
  }

  # Kubelet API
  ingress {
    from_port = 10250
    to_port   = 10250
    protocol  = "tcp"
    self      = true
  }

  # kube-scheduler
  ingress {
    from_port = 10259
    to_port   = 10259
    protocol  = "tcp"
    self      = true
  }

  # kube-controller-manager
  ingress {
    from_port = 10257
    to_port   = 10257
    protocol  = "tcp"
    self      = true
  }

  # NodePort Services
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Calico networking (BGP)
  ingress {
    from_port = 179
    to_port   = 179
    protocol  = "tcp"
    self      = true
  }

  # Calico networking (IP-in-IP)
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "4"
    self      = true
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-kubernetes-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}
