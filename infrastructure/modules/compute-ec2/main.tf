data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "master" {
  count = var.master_count

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.master_instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  user_data = file("${path.module}/master-userdata.sh")

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-master-${count.index + 1}"
    Role = "master"
    Type = "kubernetes-master"
  })
}

resource "aws_instance" "worker" {
  count = var.worker_count

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.worker_instance_type
  key_name                    = var.key_pair_name
  subnet_id                   = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  vpc_security_group_ids      = var.security_group_ids
  iam_instance_profile        = var.instance_profile_name
  associate_public_ip_address = true

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  user_data = file("${path.module}/worker-userdata.sh")

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-worker-${count.index + 1}"
    Role = "worker"
    Type = "kubernetes-worker"
  })
}