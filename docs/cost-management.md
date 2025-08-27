# Cost Management Guide

## 💰 Cost Overview

This guide helps you understand, monitor, and optimize costs for the NAAS Production Infrastructure.

## 📊 Cost Breakdown

### Monthly Cost Estimates (us-west-2)

| Component | Instance Type | Quantity | Monthly Cost* |
|-----------|---------------|----------|---------------|
| Master Node | t3.medium | 1 | ~$30.37 |
| Worker Nodes | t3.small | 2 | ~$30.37 |
| EBS Storage | gp3 20GB | 3 | ~$2.40 |
| Data Transfer | Minimal | - | ~$1.00 |
| **Total** | | | **~$64.14** |

*Prices based on On-Demand rates, may vary by region

### Cost Factors
- **Instance Hours**: Primary cost driver
- **Storage**: EBS volumes (20GB each)
- **Data Transfer**: Minimal for internal traffic
- **Elastic IPs**: Not used (public IPs change on restart)

## 🎯 Budget Configuration

### Default Budget Settings
```hcl
budget_limit = 50        # Monthly limit in USD
alert_threshold = 80     # Alert at 80% of limit
alert_emails = ["admin@example.com"]
```

### Budget Tiers

#### Development/Testing
```hcl
budget_limit = 25
alert_threshold = 70
alert_emails = ["developer@company.com"]

# Minimal setup
master_instance_type = "t3.small"
worker_instance_type = "t3.micro"
worker_count = 1
```

#### Staging
```hcl
budget_limit = 50
alert_threshold = 80
alert_emails = ["devops@company.com"]

# Balanced setup
master_instance_type = "t3.medium"
worker_instance_type = "t3.small"
worker_count = 2
```

#### Production
```hcl
budget_limit = 200
alert_threshold = 90
alert_emails = ["ops-team@company.com", "finance@company.com"]

# Performance setup
master_instance_type = "m5.large"
worker_instance_type = "m5.large"
worker_count = 3
```

## 📈 Cost Monitoring

### AWS Budget Alerts
Automatic alerts configured for:
- **80% threshold**: Warning notification
- **100% threshold**: Critical notification
- **Forecasted overage**: Predictive alerts

### Monitoring Tools

#### AWS Cost Explorer
```bash
# Access via AWS Console
# Billing & Cost Management > Cost Explorer

# Key metrics to monitor:
# - Daily costs by service
# - Monthly trends
# - Cost by resource tags
```

#### AWS CLI Cost Queries
```bash
# Get current month costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost

# Get costs by service
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE
```

#### Terraform Cost Estimation
```bash
# Use terraform plan with cost estimation
terraform plan

# Third-party tools
# - Infracost: https://www.infracost.io/
# - Terraform Cloud: Built-in cost estimation
```

## 💡 Cost Optimization Strategies

### 1. Right-Sizing Instances

#### Monitor Resource Usage
```bash
# Check CPU and memory usage
kubectl top nodes

# Monitor over time
watch kubectl top nodes

# AWS CloudWatch metrics
# - CPUUtilization
# - MemoryUtilization
# - NetworkIn/Out
```

#### Instance Type Optimization
```hcl
# Over-provisioned (high cost, low utilization)
master_instance_type = "m5.large"   # 2 vCPU, 8GB RAM
worker_instance_type = "m5.large"   # 2 vCPU, 8GB RAM

# Right-sized (balanced cost/performance)
master_instance_type = "t3.medium"  # 2 vCPU, 4GB RAM
worker_instance_type = "t3.small"   # 2 vCPU, 2GB RAM

# Under-provisioned (low cost, potential performance issues)
master_instance_type = "t3.small"   # 2 vCPU, 2GB RAM
worker_instance_type = "t3.micro"   # 2 vCPU, 1GB RAM
```

### 2. Scheduling and Automation

#### Development Environment Automation
```bash
# Stop instances during off-hours
# Create Lambda function or use AWS Instance Scheduler

# Example: Stop at 6 PM, start at 8 AM weekdays
aws ec2 stop-instances --instance-ids $(terraform output -raw master_instance_ids)
aws ec2 stop-instances --instance-ids $(terraform output -raw worker_instance_ids)
```

#### Weekend Shutdown
```bash
# Friday evening shutdown script
#!/bin/bash
cd infrastructure/live/staging
terraform destroy -auto-approve

# Monday morning startup script
#!/bin/bash
cd infrastructure/live/staging
terraform apply -auto-approve
```

### 3. Reserved Instances (Long-term)

#### When to Consider Reserved Instances
- **Stable workloads**: Running 24/7 for 1+ years
- **Predictable usage**: Consistent instance types
- **Cost savings**: Up to 75% discount vs On-Demand

#### Reserved Instance Strategy
```bash
# For production environments
# 1-year term, no upfront payment
# Covers: 1x t3.medium, 2x t3.small

# Estimated savings: ~40% vs On-Demand
# Monthly cost: ~$38 vs ~$64
```

### 4. Spot Instances (Advanced)

#### Spot Instance Considerations
- **Cost savings**: Up to 90% discount
- **Interruption risk**: Instances can be terminated
- **Use cases**: Development, testing, fault-tolerant workloads

#### Implementation (Future Enhancement)
```hcl
# Not currently implemented
# Would require additional Terraform configuration
resource "aws_spot_instance_request" "worker" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.small"
  spot_price    = "0.01"  # Maximum price per hour
}
```

## 🔍 Cost Analysis

### Daily Cost Tracking
```bash
# Create cost tracking script
#!/bin/bash
DATE=$(date +%Y-%m-%d)
COST=$(aws ce get-cost-and-usage \
  --time-period Start=$DATE,End=$DATE \
  --granularity DAILY \
  --metrics BlendedCost \
  --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
  --output text)

echo "Daily cost: $COST USD"
```

### Resource Tagging for Cost Allocation
```hcl
# Consistent tagging strategy
locals {
  common_tags = {
    Project     = "naas-prod"
    Environment = var.environment
    Owner       = "devops-team"
    CostCenter  = "engineering"
    ManagedBy   = "terraform"
  }
}
```

### Cost by Environment
```bash
# Filter costs by environment tag
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=TAG,Key=Environment
```

## ⚠️ Cost Alerts and Thresholds

### Multi-Level Alerting
```hcl
# Budget configuration with multiple thresholds
resource "aws_budgets_budget" "main" {
  name         = "${var.project_name}-${var.environment}-budget"
  budget_type  = "COST"
  limit_amount = var.budget_limit
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filters = {
    Tag = {
      "Project" = [var.project_name]
    }
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 50
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_email_addresses = var.alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.alert_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.alert_emails
  }
}
```

### Custom CloudWatch Alarms
```bash
# Create custom billing alarm
aws cloudwatch put-metric-alarm \
  --alarm-name "NAAS-Daily-Cost-Alarm" \
  --alarm-description "Daily cost exceeds threshold" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold
```

## 🛠️ Cost Optimization Tools

### Third-Party Tools
- **Infracost**: Terraform cost estimation
- **CloudHealth**: Multi-cloud cost management
- **Cloudability**: Cost optimization recommendations
- **AWS Trusted Advisor**: Built-in optimization suggestions

### Native AWS Tools
- **Cost Explorer**: Historical cost analysis
- **AWS Budgets**: Proactive cost control
- **Cost Anomaly Detection**: Unusual spending alerts
- **Reserved Instance Recommendations**: Savings opportunities

## 📋 Cost Management Checklist

### Weekly Tasks
- [ ] Review AWS billing dashboard
- [ ] Check budget alert emails
- [ ] Monitor resource utilization
- [ ] Identify unused resources

### Monthly Tasks
- [ ] Analyze cost trends
- [ ] Review instance right-sizing opportunities
- [ ] Evaluate Reserved Instance options
- [ ] Update budget forecasts

### Quarterly Tasks
- [ ] Comprehensive cost review
- [ ] Architecture optimization assessment
- [ ] Reserved Instance planning
- [ ] Cost allocation review

## 🚨 Emergency Cost Controls

### Immediate Cost Reduction
```bash
# Stop all instances (preserves data)
aws ec2 stop-instances --instance-ids $(terraform output -raw all_instance_ids)

# Terminate specific instances
aws ec2 terminate-instances --instance-ids <instance-id>

# Complete infrastructure destruction
terraform destroy
```

### Gradual Scale-Down
```bash
# Reduce worker nodes
# Update terraform.tfvars
worker_count = 1

# Apply changes
terraform apply

# Downgrade instance types
master_instance_type = "t3.small"
worker_instance_type = "t3.micro"
terraform apply
```

## 📊 ROI Considerations

### Infrastructure Investment
- **Setup time**: 2-4 hours initial deployment
- **Learning curve**: Kubernetes and Terraform knowledge
- **Maintenance**: Ongoing updates and monitoring

### Benefits
- **Scalable platform**: Easy horizontal scaling
- **Cost predictability**: Budget controls and monitoring
- **Automation**: Infrastructure as Code
- **Flexibility**: Multi-environment support