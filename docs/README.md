# NAAS Production Infrastructure Documentation

Complete documentation for the NAAS Production Infrastructure project - a Terraform-based Kubernetes cluster deployment on AWS.

## 📚 Documentation Index

- [Architecture Overview](architecture.md)
- [Getting Started](getting-started.md)
- [Configuration Guide](configuration.md)
- [Deployment Guide](deployment.md)
- [Budget Management](budget-overview.md) ⭐
- [Cost Management](cost-management.md)
- [Module Reference](modules/README.md)
- [Troubleshooting](troubleshooting.md)
- [Security](security.md)

## 🏗️ Project Structure

```
naas-prod/
├── infrastructure/
│   ├── global/           # Global Terraform configuration
│   ├── live/            # Environment-specific deployments
│   │   ├── staging/     # Staging environment
│   │   └── prod/        # Production environment
│   └── modules/         # Reusable Terraform modules
├── scripts/             # Deployment and utility scripts
├── docs/               # Project documentation
└── README.md           # Main project README
```

## 🚀 Quick Start

1. **Prerequisites**: AWS CLI, Terraform >= 1.0
2. **Configure**: Copy and edit `terraform.tfvars.example`
3. **Set Budget**: Configure `budget_limit` and `alert_emails` in terraform.tfvars
4. **Deploy**: Run `terraform apply` in staging directory
5. **Access**: SSH to instances and configure Kubernetes

## 📋 What This Project Provides

- **Infrastructure**: VPC, EC2 instances, security groups, IAM roles
- **Kubernetes Ready**: Pre-installed kubelet, kubeadm, kubectl, containerd
- **Budget Management**: AWS Budget alerts with email notifications at 80% threshold
- **Cost Monitoring**: Monthly budget limits ($50 default) with forecasting
- **Security**: Encrypted storage, proper IAM, security groups
- **Multi-Environment**: Separate staging and production configurations

## 🎯 Use Cases

- Kubernetes cluster deployment on AWS
- Container orchestration infrastructure
- Development and production environments
- Cost-controlled cloud infrastructure
- Learning Kubernetes and Terraform

## 📞 Support

For issues and questions:
1. Check [Troubleshooting Guide](troubleshooting.md)
2. Review [Configuration Guide](configuration.md)
3. Examine Terraform logs and AWS CloudTrail