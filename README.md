# NAAS Production Infrastructure

Terraform infrastructure for deploying Kubernetes cluster on AWS with automated dependency installation.

## Architecture

- **Master Node**: 1x t3.medium instance
- **Worker Nodes**: 2x t3.small instances  
- **Network**: Default VPC with public subnets
- **Container Runtime**: containerd
- **Kubernetes**: v1.28

## Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- SSH key pair for instance access

## Quick Start

1. **Clone repository**
```bash
git clone <repository-url>
cd naas-prod
```

2. **Configure variables**
```bash
cp infrastructure/live/staging/terraform.tfvars.example infrastructure/live/staging/terraform.tfvars
# Edit terraform.tfvars with your settings
```

3. **Deploy infrastructure**
```bash
cd infrastructure/live/staging
terraform init
terraform plan
terraform apply
```

4. **Access cluster**
```bash
# SSH to master node
ssh -i ./naas-prod-staging-key.pem ubuntu@<master-ip>

# Check installations
kubectl version --client
kubeadm version
sudo systemctl status containerd
```

## Configuration

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `aws_region` | AWS region | `us-west-2` |
| `environment` | Environment name | `staging` |
| `project_name` | Project identifier | `naas-prod` |
| `alert_emails` | Budget alert emails | `["admin@example.com"]` |

### Instance Configuration

- **Master**: t3.medium (2 vCPU, 4GB RAM)
- **Workers**: t3.small (2 vCPU, 2GB RAM)
- **Storage**: 20GB GP3 encrypted

## Components

### Infrastructure Modules

- **Network**: VPC, subnets, security groups
- **Compute**: EC2 instances with user_data
- **IAM**: Instance profiles and roles
- **Key Pair**: SSH key generation
- **Budget**: Cost monitoring and alerts

### Installed Software

All dependencies installed via user_data during boot:
- containerd (container runtime)
- kubelet (Kubernetes node agent)
- kubeadm (cluster management)
- kubectl (CLI tool)

## Outputs

- `ssh_command`: SSH command for master node
- `master_ips`: Master node public IPs
- `worker_ips`: Worker node public IPs

## Cost Management

- Budget alerts at 80% threshold
- Monthly budget limit: $50 (configurable)
- Email notifications for cost overruns

## Security

- All instances in public subnets with security groups
- SSH access via generated key pairs
- Encrypted EBS volumes
- IAM instance profiles for AWS API access

## Cleanup

```bash
terraform destroy
```

## Troubleshooting

### Check Installation Status
```bash
# SSH to instance
ssh -i ./naas-prod-staging-key.pem ubuntu@<instance-ip>

# Check cloud-init logs
sudo tail -f /var/log/cloud-init-output.log

# Verify services
sudo systemctl status containerd kubelet
```

### Common Issues

1. **Dependencies not installed**: Check cloud-init logs
2. **SSH connection failed**: Verify security group rules
3. **Budget alerts not working**: Check email addresses in terraform.tfvars

## License

MIT License