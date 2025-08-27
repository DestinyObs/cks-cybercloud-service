# Deployment Guide

## 🚀 Deployment Overview

This guide covers the complete deployment process from infrastructure provisioning to a working Kubernetes cluster.

## 📋 Pre-Deployment Checklist

### ✅ Prerequisites Verified
- [ ] AWS CLI configured and tested
- [ ] Terraform installed (>= 1.0)
- [ ] SSH client available
- [ ] Required AWS permissions granted
- [ ] Budget alerts email configured

### ✅ Configuration Ready
- [ ] `terraform.tfvars` file created and reviewed
- [ ] AWS region and availability zones confirmed
- [ ] Instance types selected based on requirements
- [ ] Budget limits set appropriately

## 🏗️ Infrastructure Deployment

### Step 1: Initialize Terraform
```bash
cd infrastructure/live/staging
terraform init
```

**Expected Output:**
```
Initializing modules...
Initializing the backend...
Initializing provider plugins...
Terraform has been successfully initialized!
```

### Step 2: Plan Deployment
```bash
terraform plan -out=tfplan
```

**Review the plan for:**
- ✅ Correct number of instances
- ✅ Proper instance types
- ✅ Security group rules
- ✅ Budget configuration
- ✅ No unexpected changes

### Step 3: Apply Infrastructure
```bash
terraform apply tfplan
```

**Deployment Time:** ~5-10 minutes

**Expected Resources Created:**
- EC2 instances (1 master, 2 workers)
- Security groups
- Key pair
- IAM roles and instance profiles
- Budget alerts

### Step 4: Verify Deployment
```bash
# Check outputs
terraform output

# Verify instances are running
aws ec2 describe-instances --filters "Name=tag:Project,Values=naas-prod" --query 'Reservations[].Instances[].State.Name'
```

## 🔧 Post-Deployment Configuration

### Step 1: Wait for Initialization
```bash
# Wait 3-5 minutes for cloud-init to complete
# Check initialization status
ssh -i ./naas-prod-staging-key.pem ubuntu@<master-ip> "sudo cloud-init status"
```

### Step 2: Verify Software Installation
```bash
# SSH to master node
ssh -i ./naas-prod-staging-key.pem ubuntu@<master-ip>

# Check installed components
kubectl version --client
kubeadm version
sudo systemctl status containerd
```

### Step 3: Initialize Kubernetes Cluster
```bash
# On master node
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=<master-private-ip>
```

**Expected Output:**
```
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Step 4: Configure kubectl
```bash
# Configure kubectl for ubuntu user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Test kubectl access
kubectl get nodes
```

### Step 5: Install CNI Plugin
```bash
# Install Flannel CNI
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Wait for CNI pods to be ready
kubectl get pods -n kube-flannel
```

### Step 6: Join Worker Nodes
```bash
# On master, get join command
kubeadm token create --print-join-command

# Copy the output and run on each worker node
# SSH to each worker node and run:
sudo <join-command-from-master>
```

### Step 7: Verify Cluster
```bash
# Check all nodes are ready
kubectl get nodes

# Check system pods
kubectl get pods -n kube-system

# Check cluster info
kubectl cluster-info
```

## 🎯 Deployment Validation

### Infrastructure Validation
```bash
# Check Terraform state
terraform show

# Verify AWS resources
aws ec2 describe-instances --filters "Name=tag:Project,Values=naas-prod"
aws budgets describe-budgets --account-id $(aws sts get-caller-identity --query Account --output text)
```

### Kubernetes Validation
```bash
# Node status
kubectl get nodes -o wide

# System components
kubectl get componentstatuses

# Cluster events
kubectl get events --sort-by=.metadata.creationTimestamp

# Test pod deployment
kubectl run test-pod --image=nginx --rm -it --restart=Never -- curl -I localhost
```

## 📊 Monitoring Setup

### Basic Monitoring
```bash
# Check node resources
kubectl top nodes

# Monitor system pods
watch kubectl get pods -n kube-system

# View logs
kubectl logs -n kube-system -l app=flannel
```

### AWS CloudWatch
- Instance metrics automatically available
- Custom metrics can be configured
- Log groups created for application logs

## 🔄 Environment-Specific Deployments

### Staging Environment
```bash
cd infrastructure/live/staging
terraform init
terraform plan
terraform apply
```

### Production Environment
```bash
cd infrastructure/live/prod
# Update terraform.tfvars for production settings
terraform init
terraform plan
terraform apply
```

## 🚨 Troubleshooting Deployment

### Common Issues

#### Terraform Apply Fails
```bash
# Check AWS credentials
aws sts get-caller-identity

# Verify permissions
aws iam get-user

# Check region availability
aws ec2 describe-availability-zones
```

#### SSH Connection Issues
```bash
# Check security group
aws ec2 describe-security-groups --filters "Name=tag:Project,Values=naas-prod"

# Verify key permissions
chmod 400 *.pem

# Test connectivity
telnet <instance-ip> 22
```

#### Cloud-init Failures
```bash
# Check cloud-init status
sudo cloud-init status

# View detailed logs
sudo cat /var/log/cloud-init-output.log

# Check for errors
sudo journalctl -u cloud-init
```

#### Kubernetes Init Issues
```bash
# Reset if needed
sudo kubeadm reset

# Check system requirements
sudo kubeadm init phase preflight

# Verify container runtime
sudo systemctl status containerd
```

### Recovery Procedures

#### Partial Deployment Failure
```bash
# Destroy and redeploy
terraform destroy
terraform apply
```

#### Node Join Failures
```bash
# Generate new token
kubeadm token create --print-join-command

# Reset worker node
sudo kubeadm reset

# Rejoin with new token
sudo <new-join-command>
```

## 📈 Scaling Operations

### Add Worker Nodes
```bash
# Update terraform.tfvars
worker_count = 3

# Apply changes
terraform plan
terraform apply

# Join new nodes to cluster
# (Follow Step 6 from Post-Deployment Configuration)
```

### Upgrade Instance Types
```bash
# Update terraform.tfvars
master_instance_type = "t3.large"
worker_instance_type = "t3.medium"

# Plan and apply
terraform plan
terraform apply
```

## 🧹 Cleanup

### Destroy Infrastructure
```bash
# Drain nodes (optional)
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Destroy Terraform resources
terraform destroy

# Confirm cleanup
aws ec2 describe-instances --filters "Name=tag:Project,Values=naas-prod"
```

## 📚 Next Steps

After successful deployment:

1. **Install Additional Components**
   - Ingress controller (NGINX, ALB)
   - Monitoring (Prometheus, Grafana)
   - Logging (ELK stack, Fluentd)

2. **Configure Security**
   - Network policies
   - Pod security standards
   - RBAC policies

3. **Deploy Applications**
   - Create namespaces
   - Deploy workloads
   - Configure services

4. **Set Up CI/CD**
   - GitOps workflows
   - Automated deployments
   - Testing pipelines