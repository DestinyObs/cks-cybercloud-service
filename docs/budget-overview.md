# Budget Management Overview

## 💰 Built-in Budget Controls

The NAAS Production Infrastructure includes comprehensive budget management to prevent unexpected AWS costs.

## 🎯 Budget Features

### Automatic Budget Creation
- **Monthly Budget**: Configurable limit (default: $50 USD)
- **Email Alerts**: Notifications at 80% threshold
- **Forecasting**: Predictive alerts for projected overages
- **Cost Tracking**: Project-specific cost allocation via tags

### Budget Configuration
```hcl
# In terraform.tfvars
budget_limit    = 50                    # Monthly limit in USD
alert_threshold = 80                    # Alert at 80% of limit
alert_emails    = ["admin@example.com"] # Notification recipients
```

## 📊 Cost Breakdown (Monthly Estimates)

| Component | Instance Type | Quantity | Cost |
|-----------|---------------|----------|------|
| Master Node | t3.medium | 1 | ~$30 |
| Worker Nodes | t3.small | 2 | ~$30 |
| EBS Storage | 20GB GP3 | 3 | ~$2 |
| **Total** | | | **~$62** |

## 🚨 Alert System

### Alert Levels
1. **80% Threshold**: Warning email sent
2. **100% Actual**: Critical alert when budget exceeded
3. **Forecasted Overage**: Predictive alert based on usage trends

### Sample Alert Email
```
Subject: AWS Budget Alert - naas-prod-staging-budget

Your AWS budget "naas-prod-staging-budget" has exceeded 80% of your $50.00 budget.
Current spend: $40.50
Forecasted spend: $52.30

Take action to avoid unexpected charges.
```

## 🔧 Budget Management

### View Current Spend
```bash
# Check budget status
aws budgets describe-budgets --account-id $(aws sts get-caller-identity --query Account --output text)

# View detailed costs
aws ce get-cost-and-usage \
  --time-period Start=2024-01-01,End=2024-01-31 \
  --granularity MONTHLY \
  --metrics BlendedCost
```

### Modify Budget Limits
```bash
# Update terraform.tfvars
budget_limit = 100  # Increase to $100

# Apply changes
terraform apply
```

## 💡 Cost Optimization Tips

### Reduce Costs
- Use smaller instance types for development
- Stop instances during off-hours
- Consider Reserved Instances for long-term use

### Monitor Usage
- Check AWS Cost Explorer weekly
- Review budget alert emails promptly
- Use CloudWatch metrics for resource utilization

## 🚨 Emergency Cost Controls

### Immediate Actions
```bash
# Stop all instances (preserves data)
terraform output -raw ssh_command
# SSH to instances and shut down services

# Complete infrastructure destruction
terraform destroy
```

## 📋 Budget Best Practices

1. **Set Conservative Limits**: Start with lower budgets
2. **Multiple Recipients**: Add team members to alert emails
3. **Regular Reviews**: Check costs weekly
4. **Environment-Specific**: Different budgets per environment
5. **Forecasting**: Monitor projected costs, not just actual

For detailed cost management strategies, see [Cost Management Guide](cost-management.md).