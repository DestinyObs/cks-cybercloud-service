# Kubernetes Cluster Setup for CKS

Complete Kubernetes cluster setup with security configurations and tenant management for CKS exam preparation.

## What You'll Build

- 1 Master node (k8s-master)
- 2 Worker nodes (k8s-worker1, k8s-worker2)
- Containerd runtime
- Calico networking
- Multi-tenant security configurations
- RBAC and network policies

## Requirements

- 3 Ubuntu 20.04+ servers
- 2GB RAM, 2 CPU cores per node minimum
- Internet connection
- SSH access to all nodes

## Quick Setup

1. Run `network-setup.sh` on all nodes
2. Follow the step-by-step installation below
3. Use tenant management scripts for security configurations

## Step-by-Step Installation

### 1. Prepare All Nodes

Update and set hostnames:
```bash
sudo apt update && sudo apt upgrade -y

# Set hostname (different on each node)
sudo hostnamectl set-hostname k8s-master   # on master
sudo hostnamectl set-hostname k8s-worker1 # on worker1
sudo hostnamectl set-hostname k8s-worker2 # on worker2
```

Configure hosts file on all nodes:
```bash
sudo nano /etc/hosts
```
Add your node IPs:
```
<master-ip> k8s-master
<worker1-ip> k8s-worker1
<worker2-ip> k8s-worker2
```

Disable swap:
```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

### 2. Install Container Runtime (All Nodes)

Install containerd:
```bash
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```

### 3. Install Kubernetes (All Nodes)

Add Kubernetes repository:
```bash
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Install Kubernetes components:
```bash
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

Configure networking:
```bash
sudo modprobe br_netfilter
echo "br_netfilter" | sudo tee /etc/modules-load.d/br_netfilter.conf

sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

### 4. Initialize Cluster (Master Node Only)

Initialize the cluster:
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

Configure kubectl:
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Install Calico networking:
```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### 5. Join Worker Nodes

Get join command from master:
```bash
sudo kubeadm token create --print-join-command
```

Run the join command on each worker node:
```bash
sudo kubeadm join <master-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

### 6. Verify Installation

Check nodes:
```bash
kubectl get nodes
```

Check system pods:
```bash
kubectl get pods -n kube-system
```

## File Structure and Descriptions

```
cks/
├── README.md                    # This comprehensive guide
├── Server-access.md             # SSH access information for cluster nodes
├── network-setup.sh             # Automated cluster setup script
├── create-tenant.sh             # Complete tenant creation with isolation
├── create-sa.sh                 # Service account and RBAC creator
├── namespace.yaml               # Namespace template for tenants
├── rbac.yaml                    # Role and RoleBinding templates
├── networkpolicy.yaml           # Network policy for tenant isolation
├── limitrange.yaml              # Resource limits for containers
├── resourcequota.yaml           # Resource quotas for namespaces
├── kubeconfig-template..yml     # Kubeconfig template for service accounts
├── role-template.yml            # Role template for RBAC
└── rolebinding-template..yml    # RoleBinding template for RBAC
```

## Core Files

### network-setup.sh
Automated script that performs complete cluster setup on all nodes. Contains all commands from the step-by-step installation guide.

**Usage:**
```bash
chmod +x network-setup.sh
sudo ./network-setup.sh
```

### Server-access.md
Contains SSH connection commands for accessing cluster nodes with proper key files and IP addresses.

## Security Configuration Files

### Tenant Management Scripts

#### create-tenant.sh
Complete tenant creation script that sets up isolated namespaces with:
- Resource quotas and limits
- Service accounts with admin access
- Network policies for isolation
- Kubeconfig files for tenant users

**Usage:**
```bash
chmod +x create-tenant.sh
./create-tenant.sh
```

**Features:**
- Interactive prompts for tenant configuration
- Automatic resource quota setup
- Network isolation between tenants
- Kubeconfig generation for tenant access

#### create-sa.sh
Service account creator with flexible RBAC configuration:
- Creates service accounts in specified namespaces
- Configures roles with admin or view access
- Generates kubeconfig files for service account access

**Usage:**
```bash
chmod +x create-sa.sh
./create-sa.sh
```

### YAML Configuration Templates

#### namespace.yaml
Template for creating tenant namespaces with proper labeling:
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: {{TENANT_NAME}}
  labels:
    tenant: {{TENANT_NAME}}
```

**Purpose:** Creates isolated namespaces for different tenants or applications.

#### rbac.yaml
Role-based access control template defining:
- Role with permissions for pods, services, deployments, configmaps, secrets
- RoleBinding connecting users to roles within namespaces

**Purpose:** Implements least-privilege access control for tenant users.

#### networkpolicy.yaml
Network policy for tenant isolation:
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-cross-ns
  namespace: {{TENANT_NAME}}
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

**Purpose:** Prevents cross-namespace communication, ensuring tenant isolation.

#### limitrange.yaml
Container resource limits template:
- Default CPU: 500m, Memory: 512Mi
- Default requests: CPU: 200m, Memory: 256Mi

**Purpose:** Prevents resource exhaustion by setting default limits on containers.

#### resourcequota.yaml
Namespace-level resource quotas:
- CPU requests: 2 cores
- Memory requests: 4Gi
- Storage: 10Gi
- Pod limit: 10

**Purpose:** Controls resource consumption at the namespace level.

### Template Files

#### kubeconfig-template..yml
Template for generating kubeconfig files for service accounts with:
- Cluster configuration
- User authentication via service account tokens
- Namespace context setup

#### role-template.yml
Flexible role template supporting both admin and view access levels with configurable permissions.

#### rolebinding-template..yml
RoleBinding template that connects service accounts to roles within specific namespaces.

## Security Features for CKS

### Network Security
- **Network Policies:** Isolate tenant traffic and prevent cross-namespace communication
- **Calico CNI:** Advanced networking with security features

### Access Control
- **RBAC:** Role-based access control with least-privilege principles
- **Service Accounts:** Dedicated accounts for applications and users
- **Namespace Isolation:** Logical separation of resources

### Resource Management
- **Resource Quotas:** Prevent resource exhaustion attacks
- **Limit Ranges:** Set default resource limits for containers
- **Pod Security:** Container security contexts and restrictions

## Usage Examples

### Create a New Tenant
```bash
./create-tenant.sh
# Follow prompts to create isolated tenant environment
```

### Create Service Account with Admin Access
```bash
./create-sa.sh
# Choose namespace: production
# ServiceAccount name: app-admin
# Access level: admin
```

### Apply Security Policies
```bash
# Apply network policy for existing namespace
sed 's/{{TENANT_NAME}}/production/g' networkpolicy.yaml | kubectl apply -f -

# Apply resource quota
sed 's/{{TENANT_NAME}}/production/g' resourcequota.yaml | kubectl apply -f -
```

## Common Issues

**Node not ready:**
```bash
sudo systemctl restart kubelet
sudo systemctl restart containerd
```

**Network issues:**
```bash
kubectl get pods -n kube-system | grep calico
```

**Join command expired:**
```bash
sudo kubeadm token create --print-join-command
```

**Permission denied for tenant:**
```bash
# Check RBAC configuration
kubectl get rolebindings -n <namespace>
kubectl describe role <role-name> -n <namespace>
```

## CKS Exam Topics Covered

This setup addresses all major CKS exam domains:

### Cluster Setup (10%)
- Secure cluster installation
- Network security policies
- CIS benchmark compliance

### Cluster Hardening (15%)
- RBAC configuration
- Service account security
- Minimize access permissions

### System Hardening (15%)
- Network policies
- Resource quotas and limits
- Secure configurations

### Minimize Microservice Vulnerabilities (20%)
- Security contexts
- Resource restrictions
- Network isolation

### Supply Chain Security (20%)
- Service account management
- RBAC best practices
- Secure configurations

### Monitoring and Runtime Security (20%)
- Resource monitoring
- Access logging
- Security policy enforcement

## Testing Your Setup

### Verify Network Isolation
```bash
# Create test pods in different namespaces
kubectl run test-pod1 --image=busybox -n tenant1 --sleep 3600
kubectl run test-pod2 --image=busybox -n tenant2 --sleep 3600

# Test connectivity (should fail with network policy)
kubectl exec test-pod1 -n tenant1 -- ping <pod2-ip>
```

### Test RBAC
```bash
# Use tenant kubeconfig
export KUBECONFIG=tenant1-kubeconfig.yaml

# Try accessing other namespaces (should fail)
kubectl get pods -n kube-system
```

### Verify Resource Limits
```bash
# Deploy resource-intensive pod
kubectl run resource-test --image=nginx --requests=cpu=3 -n tenant1
# Should be rejected due to quota limits
```

## Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [CKS Exam Guide](https://kubernetes.io/docs/reference/config-file/kubeadm-config/)
- [Calico Documentation](https://docs.projectcalico.org/)
- [RBAC Documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

## Next Steps

1. Practice creating and managing tenants
2. Implement advanced network policies
3. Configure pod security standards
4. Set up monitoring and logging
5. Practice CKS exam scenarios