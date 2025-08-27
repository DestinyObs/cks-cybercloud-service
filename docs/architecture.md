# Architecture Overview

## 🏛️ Infrastructure Architecture

### Network Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                        Default VPC                          │
│                     172.31.0.0/16                          │
│                                                             │
│  ┌─────────────────┐              ┌─────────────────┐      │
│  │   Subnet AZ-A   │              │   Subnet AZ-B   │      │
│  │                 │              │                 │      │
│  │  ┌───────────┐  │              │  ┌───────────┐  │      │
│  │  │  Master   │  │              │  │  Worker   │  │      │
│  │  │    Node   │  │              │  │   Node    │  │      │
│  │  │t3.medium  │  │              │  │ t3.small  │  │      │
│  │  └───────────┘  │              │  └───────────┘  │      │
│  └─────────────────┘              └─────────────────┘      │
│                                                             │
│                    Internet Gateway                         │
└─────────────────────────────────────────────────────────────┘
```

### Component Architecture

#### Compute Layer
- **Master Nodes**: 1x t3.medium (2 vCPU, 4GB RAM)
- **Worker Nodes**: 2x t3.small (2 vCPU, 2GB RAM)
- **Storage**: 20GB GP3 encrypted EBS volumes
- **OS**: Ubuntu 22.04 LTS

#### Network Layer
- **VPC**: Uses AWS Default VPC (172.31.0.0/16)
- **Subnets**: Public subnets across multiple AZs
- **Security Groups**: Kubernetes-specific rules
- **Internet Access**: Via Internet Gateway

#### Security Layer
- **IAM**: Instance profiles with minimal required permissions
- **Encryption**: EBS volumes encrypted at rest
- **Access**: SSH key-based authentication
- **Network**: Security group restrictions

## 🔧 Software Stack

### Container Runtime
- **containerd**: Primary container runtime
- **SystemdCgroup**: Enabled for proper resource management

### Kubernetes Components
- **kubelet**: Node agent (v1.28)
- **kubeadm**: Cluster management tool
- **kubectl**: Command-line interface

### System Configuration
- **Swap**: Disabled (Kubernetes requirement)
- **Kernel Modules**: overlay, br_netfilter loaded
- **Network**: Bridge netfilter and IP forwarding enabled

## 📊 Resource Allocation

| Component | Instance Type | vCPU | Memory | Storage | Count |
|-----------|---------------|------|--------|---------|-------|
| Master    | t3.medium     | 2    | 4GB    | 20GB    | 1     |
| Worker    | t3.small      | 2    | 2GB    | 20GB    | 2     |

**Total Resources**: 6 vCPUs, 8GB RAM, 60GB storage

## 🔄 Data Flow

1. **Deployment**: Terraform provisions infrastructure
2. **Initialization**: cloud-init installs Kubernetes components
3. **Configuration**: Manual cluster initialization required
4. **Operation**: Standard Kubernetes cluster operations

## 🌐 Network Security

### Security Group Rules
- **SSH (22)**: Access from anywhere (0.0.0.0/0)
- **Kubernetes API (6443)**: Internal cluster communication
- **kubelet (10250)**: Node-to-node communication
- **NodePort (30000-32767)**: Service exposure range

### IAM Permissions
- **EC2**: Basic instance operations
- **CloudWatch**: Logging and monitoring
- **Systems Manager**: Optional management access

## 📈 Scalability Considerations

### Horizontal Scaling
- Add more worker nodes by increasing `worker_count`
- Distribute across additional availability zones
- Use Auto Scaling Groups for dynamic scaling

### Vertical Scaling
- Upgrade instance types in terraform.tfvars
- Increase EBS volume sizes
- Adjust resource requests/limits in Kubernetes

## 🔒 Security Best Practices

### Implemented
- ✅ Encrypted EBS volumes
- ✅ IAM instance profiles
- ✅ Security group restrictions
- ✅ SSH key authentication

### Recommended Additions
- 🔄 Private subnets for worker nodes
- 🔄 NAT Gateway for outbound traffic
- 🔄 AWS Load Balancer Controller
- 🔄 Network policies in Kubernetes
- 🔄 Pod Security Standards