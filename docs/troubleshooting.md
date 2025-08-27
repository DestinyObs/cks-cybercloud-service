# Troubleshooting Guide

## 🚨 Common Issues and Solutions

## 🔧 Terraform Issues

### Issue: Terraform Init Fails
**Symptoms:**
```
Error: Failed to install provider
Error: Could not retrieve the list of available versions
```

**Solutions:**
```bash
# Clear Terraform cache
rm -rf .terraform .terraform.lock.hcl

# Reinitialize
terraform init

# If behind corporate firewall
terraform init -upgrade
```

### Issue: AWS Credentials Not Found
**Symptoms:**
```
Error: No valid credential sources found for AWS Provider
```

**Solutions:**
```bash
# Configure AWS CLI
aws configure

# Verify credentials
aws sts get-caller-identity

# Check environment variables
echo $AWS_ACCESS_KEY_ID
echo $AWS_SECRET_ACCESS_KEY
```

### Issue: Insufficient Permissions
**Symptoms:**
```
Error: UnauthorizedOperation: You are not authorized to perform this operation
```

**Solutions:**
```bash
# Check current permissions
aws iam get-user

# Required permissions for deployment:
# - EC2: Full access
# - IAM: Create roles and policies
# - Budgets: Create and manage budgets
# - VPC: Network operations
```

### Issue: Resource Already Exists
**Symptoms:**
```
Error: InvalidKeyPair.Duplicate: The keypair already exists
```

**Solutions:**
```bash
# Import existing resource
terraform import aws_key_pair.main naas-prod-staging-key

# Or delete existing resource
aws ec2 delete-key-pair --key-name naas-prod-staging-key
```

## 🖥️ EC2 Instance Issues

### Issue: SSH Connection Refused
**Symptoms:**
```bash
ssh: connect to host <ip> port 22: Connection refused
```

**Solutions:**
```bash
# Check instance status
aws ec2 describe-instances --instance-ids <instance-id>

# Verify security group allows SSH
aws ec2 describe-security-groups --group-ids <sg-id>

# Check key file permissions
chmod 400 *.pem

# Wait for instance initialization (2-3 minutes)
```

### Issue: SSH Permission Denied
**Symptoms:**
```bash
Permission denied (publickey)
```

**Solutions:**
```bash
# Use correct username (ubuntu for Ubuntu AMI)
ssh -i key.pem ubuntu@<ip>

# Verify key file
ssh-keygen -l -f key.pem

# Check key pair in AWS
aws ec2 describe-key-pairs --key-names naas-prod-staging-key
```

### Issue: Cloud-init Still Running
**Symptoms:**
- SSH works but commands fail
- Software not installed yet

**Solutions:**
```bash
# Check cloud-init status
sudo cloud-init status

# Wait for completion
sudo cloud-init status --wait

# View progress
sudo tail -f /var/log/cloud-init-output.log

# Check for errors
sudo journalctl -u cloud-init
```

## ☸️ Kubernetes Issues

### Issue: kubeadm Init Fails
**Symptoms:**
```
[ERROR Port-6443]: Port 6443 is in use
[ERROR Swap]: running with swap on is not supported
```

**Solutions:**
```bash
# Check if already initialized
sudo kubectl get nodes

# Reset if needed
sudo kubeadm reset

# Ensure swap is disabled
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# Check port usage
sudo netstat -tlnp | grep :6443

# Reinitialize
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

### Issue: Nodes Not Ready
**Symptoms:**
```bash
kubectl get nodes
NAME     STATUS     ROLES    AGE   VERSION
master   NotReady   master   5m    v1.28.0
```

**Solutions:**
```bash
# Check node conditions
kubectl describe node <node-name>

# Install CNI plugin
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Check CNI pods
kubectl get pods -n kube-flannel

# Restart kubelet if needed
sudo systemctl restart kubelet
```

### Issue: Worker Node Join Fails
**Symptoms:**
```
[ERROR FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables does not exist
```

**Solutions:**
```bash
# Load required kernel modules
sudo modprobe br_netfilter
sudo modprobe overlay

# Verify modules loaded
lsmod | grep br_netfilter

# Check sysctl settings
sudo sysctl net.bridge.bridge-nf-call-iptables

# Generate new join token
kubeadm token create --print-join-command
```

### Issue: Pod Network Issues
**Symptoms:**
- Pods can't communicate
- DNS resolution fails
- Services unreachable

**Solutions:**
```bash
# Check CNI installation
kubectl get pods -n kube-flannel

# Verify network configuration
kubectl get configmap -n kube-flannel

# Check pod CIDR
kubectl cluster-info dump | grep -i cidr

# Restart CNI pods
kubectl delete pods -n kube-flannel -l app=flannel
```

## 💰 Budget and Billing Issues

### Issue: Budget Alerts Not Working
**Symptoms:**
- No email notifications received
- Budget exists but no alerts

**Solutions:**
```bash
# Verify budget exists
aws budgets describe-budgets --account-id $(aws sts get-caller-identity --query Account --output text)

# Check email addresses
aws budgets describe-budget --account-id <account-id> --budget-name <budget-name>

# Verify email subscription
# Check spam folder
# Confirm email addresses are correct
```

### Issue: Unexpected Costs
**Symptoms:**
- Higher than expected AWS bill
- Resources running when not needed

**Solutions:**
```bash
# Check running instances
aws ec2 describe-instances --query 'Reservations[].Instances[?State.Name==`running`]'

# Review cost breakdown
# AWS Console > Billing & Cost Management > Cost Explorer

# Stop unused instances
aws ec2 stop-instances --instance-ids <instance-id>

# Terminate if not needed
terraform destroy
```

## 🔍 Diagnostic Commands

### Infrastructure Health Check
```bash
# Terraform state
terraform show

# AWS resources
aws ec2 describe-instances --filters "Name=tag:Project,Values=naas-prod"

# Security groups
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=naas-prod"

# Key pairs
aws ec2 describe-key-pairs --key-names naas-prod-staging-key
```

### Instance Health Check
```bash
# System status
sudo systemctl status containerd kubelet

# Disk space
df -h

# Memory usage
free -h

# Network connectivity
ping 8.8.8.8

# DNS resolution
nslookup kubernetes.default.svc.cluster.local
```

### Kubernetes Health Check
```bash
# Cluster status
kubectl cluster-info

# Node status
kubectl get nodes -o wide

# System pods
kubectl get pods -n kube-system

# Events
kubectl get events --sort-by=.metadata.creationTimestamp

# Logs
kubectl logs -n kube-system -l component=kube-apiserver
```

## 🔧 Recovery Procedures

### Complete Infrastructure Reset
```bash
# Destroy everything
terraform destroy

# Clean local state
rm -rf .terraform terraform.tfstate*

# Redeploy
terraform init
terraform apply
```

### Kubernetes Cluster Reset
```bash
# On all nodes
sudo kubeadm reset

# Clean up
sudo rm -rf /etc/kubernetes/
sudo rm -rf ~/.kube/

# Reinitialize master
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Rejoin workers
# (Get new join command from master)
```

### Partial Recovery
```bash
# Reset specific node
kubectl drain <node-name> --ignore-daemonsets
kubectl delete node <node-name>

# On the node
sudo kubeadm reset

# Rejoin
sudo <join-command>
```

## 📞 Getting Help

### Log Collection
```bash
# Terraform logs
export TF_LOG=DEBUG
terraform apply

# Cloud-init logs
sudo cat /var/log/cloud-init-output.log

# Kubernetes logs
kubectl logs -n kube-system --previous <pod-name>

# System logs
sudo journalctl -u kubelet -f
```

### Useful Resources
- **AWS Documentation**: https://docs.aws.amazon.com/
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Terraform Documentation**: https://registry.terraform.io/providers/hashicorp/aws/
- **Ubuntu Cloud-init**: https://cloudinit.readthedocs.io/

### Support Channels
1. Check project documentation
2. Review AWS CloudTrail logs
3. Examine Terraform state files
4. Consult community forums
5. Contact AWS support if needed