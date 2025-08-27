# Configuration Guide

## 📝 Configuration Overview

This guide covers all configurable aspects of the NAAS Production Infrastructure project.

## 🔧 Terraform Variables

### Required Variables

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `aws_region` | string | AWS region for deployment | `"us-west-2"` |
| `environment` | string | Environment name | `"staging"` |
| `project_name` | string | Project identifier | `"naas-prod"` |
| `alert_emails` | list(string) | Budget alert recipients | `["admin@example.com"]` |

### Network Configuration

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `vpc_cidr` | string | VPC CIDR block | `"172.31.0.0/16"` |
| `availability_zones` | list(string) | AZs for deployment | `["us-west-2a", "us-west-2b"]` |
| `public_subnet_cidrs` | list(string) | Public subnet CIDRs | `["172.31.100.0/24", "172.31.101.0/24"]` |
| `private_subnet_cidrs` | list(string) | Private subnet CIDRs | `["172.31.110.0/24", "172.31.111.0/24"]` |

### Compute Configuration

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `master_instance_type` | string | Master node instance type | `"t3.medium"` |
| `worker_instance_type` | string | Worker node instance type | `"t3.small"` |
| `master_count` | number | Number of master nodes | `1` |
| `worker_count` | number | Number of worker nodes | `2` |

### Budget Configuration

| Variable | Type | Description | Default |
|----------|------|-------------|---------|
| `budget_limit` | number | Monthly budget limit (USD) | `50` |
| `alert_threshold` | number | Alert threshold percentage | `80` |

## 📁 File Structure

### Environment-Specific Configuration

```
infrastructure/live/
├── staging/
│   ├── terraform.tfvars     # Staging configuration
│   ├── backend.tf          # State backend config
│   ├── main.tf             # Module calls
│   ├── variables.tf        # Variable definitions
│   └── outputs.tf          # Output definitions
└── prod/
    ├── terraform.tfvars     # Production configuration
    ├── backend.tf          # State backend config
    ├── main.tf             # Module calls
    ├── variables.tf        # Variable definitions
    └── outputs.tf          # Output definitions
```

## 🔐 Backend Configuration

### Local State (Default)
```hcl
# No backend configuration needed
# State stored locally in .terraform/
```

### S3 Backend (Recommended for Production)
```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "naas-prod/staging/terraform.tfstate"
    region = "us-west-2"
    
    # Optional: State locking
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

## 🌍 Multi-Region Deployment

### Region-Specific Variables
```hcl
# us-east-1 configuration
aws_region = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]

# eu-west-1 configuration  
aws_region = "eu-west-1"
availability_zones = ["eu-west-1a", "eu-west-1b"]
```

### AMI Considerations
- Ubuntu AMIs are region-specific
- Module automatically selects latest Ubuntu 22.04 AMI
- No manual AMI ID configuration needed

## 🏗️ Instance Type Selection

### Master Node Sizing
| Instance Type | vCPU | Memory | Network | Use Case |
|---------------|------|--------|---------|----------|
| `t3.small` | 2 | 2GB | Low-Moderate | Development |
| `t3.medium` | 2 | 4GB | Low-Moderate | **Recommended** |
| `t3.large` | 2 | 8GB | Low-Moderate | High workload |
| `m5.large` | 2 | 8GB | Up to 10Gbps | Production |

### Worker Node Sizing
| Instance Type | vCPU | Memory | Network | Use Case |
|---------------|------|--------|---------|----------|
| `t3.micro` | 2 | 1GB | Low-Moderate | Minimal testing |
| `t3.small` | 2 | 2GB | Low-Moderate | **Recommended** |
| `t3.medium` | 2 | 4GB | Low-Moderate | Medium workload |
| `m5.large` | 2 | 8GB | Up to 10Gbps | Production |

## 💰 Cost Optimization

### Budget Alerts Configuration
```hcl
# Conservative budget
budget_limit = 25
alert_threshold = 70
alert_emails = ["finance@company.com", "devops@company.com"]

# Development budget
budget_limit = 50
alert_threshold = 80
alert_emails = ["developer@company.com"]

# Production budget
budget_limit = 200
alert_threshold = 90
alert_emails = ["ops-team@company.com"]
```

### Instance Optimization
```hcl
# Minimal cost setup
master_instance_type = "t3.small"
worker_instance_type = "t3.micro"
worker_count = 1

# Balanced setup (recommended)
master_instance_type = "t3.medium"
worker_instance_type = "t3.small"
worker_count = 2

# Performance setup
master_instance_type = "m5.large"
worker_instance_type = "m5.large"
worker_count = 3
```

## 🔒 Security Configuration

### Security Group Customization
Default ports opened:
- SSH (22): 0.0.0.0/0
- Kubernetes API (6443): Internal
- kubelet (10250): Internal
- NodePort range (30000-32767): Internal

### IAM Role Permissions
Current permissions:
- EC2 basic operations
- CloudWatch logging
- Systems Manager (optional)

## 🌐 Network Configuration

### Default VPC Usage
```hcl
# Uses AWS Default VPC
# Automatically discovers subnets
# Creates security groups
```

### Custom VPC (Future Enhancement)
```hcl
# Would require additional network module
vpc_cidr = "10.0.0.0/16"
create_vpc = true
enable_nat_gateway = true
```

## 📊 Monitoring Configuration

### CloudWatch Integration
- Instance metrics automatically collected
- Custom metrics can be added
- Log groups created for application logs

### Budget Monitoring
- Monthly budget tracking
- Email alerts at threshold
- Cost anomaly detection available

## 🔄 Environment Promotion

### Staging to Production
1. Copy `staging/terraform.tfvars` to `prod/terraform.tfvars`
2. Update environment-specific values:
   ```hcl
   environment = "prod"
   budget_limit = 200
   master_instance_type = "m5.large"
   worker_count = 3
   ```
3. Configure separate state backend
4. Deploy with `terraform apply`

## 🛠️ Advanced Configuration

### Custom User Data
Modify user data scripts in modules:
- `modules/compute-ec2/master-userdata.sh`
- `modules/compute-ec2/worker-userdata.sh`

### Additional Software Installation
Add to user data scripts:
```bash
# Install monitoring agent
curl -sSL https://agent.example.com/install.sh | bash

# Configure custom settings
echo "custom_setting=value" >> /etc/app/config
```

### Kubernetes Version
Currently pinned to v1.28:
```bash
# In user data scripts
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' > /etc/apt/sources.list.d/kubernetes.list
```

To change version, update all user data scripts with new version path.