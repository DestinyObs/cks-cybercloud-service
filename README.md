# Kubernetes Cluster Setup (CKS)

A comprehensive guide for setting up a multi-node Kubernetes cluster on Ubuntu instances for Certified Kubernetes Security Specialist (CKS) preparation.

## Overview

This repository contains scripts and documentation for deploying a production-ready Kubernetes cluster with:
- 1 Master node
- 2 Worker nodes
- Containerd runtime
- Calico CNI plugin
- Security best practices

## Prerequisites

- 3 Ubuntu instances (18.04+ or 20.04+)
- Minimum 2 CPU cores and 2GB RAM per node
- Network connectivity between all nodes
- Root or sudo access on all nodes

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   k8s-master    │    │  k8s-worker1    │    │  k8s-worker2    │
│                 │    │                 │    │                 │
│ Control Plane   │◄──►│   Worker Node   │    │   Worker Node   │
│ - API Server    │    │ - kubelet       │    │ - kubelet       │
│ - etcd          │    │ - kube-proxy    │    │ - kube-proxy    │
│ - Scheduler     │    │ - containerd    │    │ - containerd    │
│ - Controller    │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd cks
   ```

2. **Run the setup script on all nodes:**
   ```bash
   chmod +x network-setup.sh
   sudo ./network-setup.sh
   ```

3. **Follow the step-by-step instructions below**

## Step-by-Step Setup

### Phase 1: System Preparation (All Nodes)

#### 1.1 Update System Packages
```bash
sudo apt update && sudo apt upgrade -y
```

#### 1.2 Configure Hostnames
```bash
# On master node
sudo hostnamectl set-hostname k8s-master

# On worker node 1
sudo hostnamectl set-hostname k8s-worker1

# On worker node 2
sudo hostnamectl set-hostname k8s-worker2
```

#### 1.3 Configure Host Resolution
1. Find private IPs:
   ```bash
   hostname -I
   ```

2. Update `/etc/hosts` on all nodes:
   ```bash
   sudo nano /etc/hosts
   ```
   Add these lines (replace with actual IPs):
   ```
   <master-private-ip> k8s-master
   <worker1-private-ip> k8s-worker1
   <worker2-private-ip> k8s-worker2
   ```

#### 1.4 Disable Swap
```bash
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
```

### Phase 2: Container Runtime Setup (All Nodes)

#### 2.1 Install Containerd
```bash
sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
```

### Phase 3: Kubernetes Installation (All Nodes)

#### 3.1 Install Kubernetes Components
```bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

#### 3.2 Configure Network Settings
```bash
# Load br_netfilter module
sudo modprobe br_netfilter
echo "br_netfilter" | sudo tee /etc/modules-load.d/br_netfilter.conf

# Configure sysctl settings
sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sudo sysctl --system
```

### Phase 4: Cluster Initialization (Master Node Only)

#### 4.1 Initialize Kubernetes Cluster
```bash
sudo kubeadm init --pod-network-cidr=10.244.0.0/16
```

#### 4.2 Configure kubectl
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

#### 4.3 Install CNI Plugin (Calico)
```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

### Phase 5: Join Worker Nodes

#### 5.1 Generate Join Command (Master Node)
```bash
sudo kubeadm token create --print-join-command
```

#### 5.2 Join Workers (Worker Nodes)
Run the join command from step 5.1 on each worker node.

### Phase 6: Verification

#### 6.1 Check Node Status
```bash
kubectl get nodes
```

#### 6.2 Verify System Pods
```bash
kubectl get pods -n kube-system -o wide
```

#### 6.3 Deploy Test Application
```bash
# Create test pod
kubectl run nginx --image=nginx --port=80

# Expose as service
kubectl expose pod nginx --type=NodePort --port=80

# Check service
kubectl get svc
kubectl get nodes -o wide
```

## Troubleshooting

### Common Issues

#### Node Not Ready
```bash
# Check kubelet logs
sudo journalctl -xeu kubelet

# Check containerd status
sudo systemctl status containerd
```

#### Pod Network Issues
```bash
# Verify CNI installation
kubectl get pods -n kube-system | grep calico

# Check network settings
cat /proc/sys/net/bridge/bridge-nf-call-iptables
cat /proc/sys/net/ipv4/ip_forward
```

#### Join Command Expired
```bash
# Generate new token
kubeadm token create --print-join-command
```

### Service Status Checks
```bash
# Check kubelet
sudo systemctl status kubelet

# Check containerd
sudo systemctl status containerd

# Restart services if needed
sudo systemctl restart kubelet
sudo systemctl restart containerd
```

## Security Considerations

- Firewall rules should be configured appropriately
- Regular security updates should be applied
- RBAC should be implemented for production use
- Network policies should be configured
- Pod security standards should be enforced

## File Structure

```
cks/
├── README.md           # This documentation
└── network-setup.sh    # Automated setup script
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [CKS Exam Guide](https://kubernetes.io/docs/reference/config-file/kubeadm-config/)
- [Calico Documentation](https://docs.projectcalico.org/)
- [Containerd Documentation](https://containerd.io/)

## Support

For issues and questions:
- Check the troubleshooting section
- Review Kubernetes official documentation
- Open an issue in this repository