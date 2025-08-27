# Security Guide

## 🔒 Security Overview

This guide covers security considerations, best practices, and recommendations for the NAAS Production Infrastructure.

## 🛡️ Current Security Implementation

### Infrastructure Security

#### Network Security
- **VPC**: Uses AWS Default VPC with public subnets
- **Security Groups**: Restrictive rules for Kubernetes traffic
- **SSH Access**: Key-based authentication only
- **Internet Gateway**: Direct internet access for all instances

#### Instance Security
- **Encrypted Storage**: All EBS volumes encrypted at rest
- **IAM Roles**: Instance profiles with minimal permissions
- **OS Updates**: Ubuntu 22.04 LTS with security updates
- **SSH Keys**: Auto-generated TLS private keys

#### Access Control
- **SSH Keys**: Unique key pair per environment
- **IAM Policies**: Least privilege access
- **No Default Passwords**: Key-based access only

## 🔐 Security Group Configuration

### Current Rules
```hcl
# Kubernetes Security Group
resource "aws_security_group" "kubernetes" {
  name_prefix = "${var.project_name}-${var.environment}-k8s"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ⚠️ Consider restricting
  }

  # Kubernetes API server
  ingress {
    from_port = 6443
    to_port   = 6443
    protocol  = "tcp"
    self      = true
  }

  # kubelet API
  ingress {
    from_port = 10250
    to_port   = 10250
    protocol  = "tcp"
    self      = true
  }

  # NodePort services
  ingress {
    from_port = 30000
    to_port   = 32767
    protocol  = "tcp"
    self      = true
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

## ⚠️ Security Risks and Mitigations

### High Priority Risks

#### 1. SSH Access from Anywhere
**Risk**: SSH port 22 open to 0.0.0.0/0
**Impact**: Potential brute force attacks
**Mitigation**:
```hcl
# Restrict SSH to specific IP ranges
ingress {
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = ["YOUR_IP/32", "OFFICE_IP_RANGE/24"]
}
```

#### 2. Public Subnets for All Instances
**Risk**: All instances have public IPs
**Impact**: Increased attack surface
**Mitigation**:
```hcl
# Move workers to private subnets
resource "aws_instance" "worker" {
  subnet_id                   = var.private_subnet_ids[count.index]
  associate_public_ip_address = false
}
```

#### 3. No Network Segmentation
**Risk**: All instances in same security group
**Impact**: Lateral movement if compromised
**Mitigation**:
```hcl
# Separate security groups for master/worker
resource "aws_security_group" "master" { ... }
resource "aws_security_group" "worker" { ... }
```

### Medium Priority Risks

#### 4. Default VPC Usage
**Risk**: Shared network infrastructure
**Impact**: Less control over network configuration
**Mitigation**: Create dedicated VPC

#### 5. No WAF or Load Balancer
**Risk**: Direct exposure of Kubernetes API
**Impact**: No DDoS protection or traffic filtering
**Mitigation**: Add Application Load Balancer with WAF

## 🔧 Security Hardening Recommendations

### Immediate Improvements

#### 1. Restrict SSH Access
```hcl
# Get your current IP
data "http" "myip" {
  url = "http://ipv4.icanhazip.com"
}

# Restrict SSH to your IP only
resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["${chomp(data.http.myip.body)}/32"]
  security_group_id = aws_security_group.kubernetes.id
}
```

#### 2. Enable VPC Flow Logs
```hcl
resource "aws_flow_log" "vpc" {
  iam_role_arn    = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.vpc.arn
  traffic_type    = "ALL"
  vpc_id          = data.aws_vpc.default.id
}
```

#### 3. Add CloudTrail Logging
```hcl
resource "aws_cloudtrail" "main" {
  name           = "${var.project_name}-${var.environment}-trail"
  s3_bucket_name = aws_s3_bucket.cloudtrail.bucket

  event_selector {
    read_write_type                 = "All"
    include_management_events       = true
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::*/*"]
    }
  }
}
```

### Advanced Security Measures

#### 1. Private Subnet Architecture
```hcl
# Create private subnets for workers
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-${count.index + 1}"
    Type = "private"
  })
}

# NAT Gateway for outbound traffic
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
}
```

#### 2. Bastion Host Setup
```hcl
resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  key_name                    = var.key_pair_name
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.bastion.id]
  associate_public_ip_address = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-bastion"
    Role = "bastion"
  })
}

resource "aws_security_group" "bastion" {
  name_prefix = "${var.project_name}-${var.environment}-bastion"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["YOUR_IP/32"]
  }
}
```

#### 3. Systems Manager Session Manager
```hcl
# IAM role for SSM
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Access instances without SSH
aws ssm start-session --target <instance-id>
```

## 🔍 Security Monitoring

### CloudWatch Security Metrics
```bash
# Monitor failed SSH attempts
aws logs filter-log-events \
  --log-group-name /aws/ec2/ssh \
  --filter-pattern "Failed password"

# Monitor sudo usage
aws logs filter-log-events \
  --log-group-name /var/log/auth.log \
  --filter-pattern "sudo"
```

### Security Scanning
```bash
# Install security scanner on instances
sudo apt update
sudo apt install -y lynis

# Run security audit
sudo lynis audit system

# Check for vulnerabilities
sudo apt install -y unattended-upgrades
sudo unattended-upgrade --dry-run
```

### Kubernetes Security Scanning
```bash
# Install kube-bench (CIS Kubernetes Benchmark)
kubectl apply -f https://raw.githubusercontent.com/aquasecurity/kube-bench/main/job.yaml

# Check results
kubectl logs job/kube-bench

# Install Falco for runtime security
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco
```

## 🛡️ Kubernetes Security

### Pod Security Standards
```yaml
# Apply pod security standards
apiVersion: v1
kind: Namespace
metadata:
  name: secure-namespace
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
```

### Network Policies
```yaml
# Deny all traffic by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

# Allow specific traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-web-traffic
spec:
  podSelector:
    matchLabels:
      app: web
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

### RBAC Configuration
```yaml
# Create service account
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-service-account

# Create role with minimal permissions
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-role
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]

# Bind role to service account
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-role-binding
subjects:
- kind: ServiceAccount
  name: app-service-account
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
```

## 🔐 Secrets Management

### Kubernetes Secrets
```bash
# Create secret from command line
kubectl create secret generic app-secret \
  --from-literal=username=admin \
  --from-literal=password=secretpassword

# Use secret in pod
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: app
    image: nginx
    env:
    - name: USERNAME
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: username
```

### AWS Secrets Manager Integration
```bash
# Install AWS Load Balancer Controller with IRSA
# This enables secure access to AWS services from pods

# Create secret in AWS Secrets Manager
aws secretsmanager create-secret \
  --name "naas-prod/database" \
  --secret-string '{"username":"admin","password":"secretpassword"}'

# Use External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets external-secrets/external-secrets
```

## 📋 Security Checklist

### Infrastructure Security
- [ ] Restrict SSH access to specific IP ranges
- [ ] Move worker nodes to private subnets
- [ ] Implement NAT Gateway for outbound traffic
- [ ] Enable VPC Flow Logs
- [ ] Configure CloudTrail logging
- [ ] Set up CloudWatch security monitoring
- [ ] Implement bastion host or SSM Session Manager

### Kubernetes Security
- [ ] Apply Pod Security Standards
- [ ] Configure Network Policies
- [ ] Implement RBAC with least privilege
- [ ] Scan images for vulnerabilities
- [ ] Enable audit logging
- [ ] Install runtime security monitoring (Falco)
- [ ] Regular security benchmarking (kube-bench)

### Operational Security
- [ ] Regular security updates
- [ ] Backup and disaster recovery plan
- [ ] Incident response procedures
- [ ] Security training for team members
- [ ] Regular security assessments
- [ ] Compliance documentation

## 🚨 Incident Response

### Security Incident Procedures
1. **Immediate Response**
   - Isolate affected instances
   - Preserve logs and evidence
   - Notify security team

2. **Investigation**
   - Analyze CloudTrail logs
   - Check VPC Flow Logs
   - Review application logs
   - Identify attack vectors

3. **Containment**
   - Block malicious IPs
   - Rotate compromised credentials
   - Apply security patches
   - Update security groups

4. **Recovery**
   - Restore from clean backups
   - Rebuild compromised systems
   - Verify system integrity
   - Monitor for persistence

### Emergency Contacts
```bash
# Emergency shutdown
terraform destroy

# Isolate specific instance
aws ec2 modify-instance-attribute \
  --instance-id <instance-id> \
  --groups <isolated-security-group-id>

# Block IP address
aws ec2 authorize-security-group-ingress \
  --group-id <sg-id> \
  --protocol tcp \
  --port 0-65535 \
  --source-group <deny-sg-id>
```

## 📚 Security Resources

### Documentation
- [AWS Security Best Practices](https://aws.amazon.com/security/security-resources/)
- [Kubernetes Security Documentation](https://kubernetes.io/docs/concepts/security/)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

### Tools
- **Static Analysis**: Checkov, Terrascan, tfsec
- **Runtime Security**: Falco, Sysdig
- **Vulnerability Scanning**: Trivy, Clair
- **Compliance**: AWS Config, AWS Security Hub