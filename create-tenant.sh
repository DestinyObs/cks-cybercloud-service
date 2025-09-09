#!/bin/bash
set -euo pipefail

# ========= CONFIG ==========
KUBECONFIG_PATH="/home/ubuntu/tenants"
CLUSTER_NAME="k8s-cluster"
CLUSTER_SERVER="https://$(hostname -I | awk '{print $1}'):6443"
TEMPLATE_DIR="."
# ===========================

echo "🔹 Welcome to Tenant Creator 🔹"

# 1. Ask for namespace
read -p "Enter tenant namespace name: " TENANT
if [[ -z "$TENANT" ]]; then
  echo " Namespace name cannot be empty!"
  exit 1
fi

# Check if namespace already exists
if kubectl get ns "$TENANT" >/dev/null 2>&1; then
  echo " Namespace $TENANT already exists. Exiting..."
  exit 1
fi

# 2. Ask for username
read -p "Enter username for this tenant: " USER
if [[ -z "$USER" ]]; then
  echo " Username cannot be empty!"
  exit 1
fi

# 3. Ask for resource quotas
echo " Enter resource quota for tenant $TENANT"
read -p "CPU requests (e.g. 2): " REQ_CPU
read -p "Memory requests (e.g. 2Gi): " REQ_MEM
read -p "CPU limits (e.g. 4): " LIM_CPU
read -p "Memory limits (e.g. 4Gi): " LIM_MEM
read -p "Storage (e.g. 10Gi): " STORAGE

echo " Creating namespace: $TENANT"
kubectl create namespace "$TENANT"

# 4. ResourceQuota
sed -e "s/{{TENANT_NAME}}/$TENANT/g" \
    -e "s/{{REQ_CPU}}/$REQ_CPU/g" \
    -e "s/{{REQ_MEM}}/$REQ_MEM/g" \
    -e "s/{{LIM_CPU}}/$LIM_CPU/g" \
    -e "s/{{LIM_MEM}}/$LIM_MEM/g" \
    -e "s/{{STORAGE}}/$STORAGE/g" \
    "./resourcequota.yaml" | kubectl apply -f -

# 5. LimitRange
sed "s/{{TENANT_NAME}}/$TENANT/g" "./limitrange.yaml" | kubectl apply -f -

# 6. ServiceAccount
kubectl create serviceaccount ${USER}-sa -n $TENANT

# 7. RoleBinding
sed -e "s/{{TENANT_USER}}/$USER/g" \
    -e "s/{{TENANT_NAME}}/$TENANT/g" \
    "./rbac.yaml" | kubectl apply -f -

# 8. Extract token
SECRET_NAME=$(kubectl get sa ${USER}-sa -n $TENANT -o jsonpath='{.secrets[0].name}')
USER_TOKEN=$(kubectl get secret $SECRET_NAME -n $TENANT -o jsonpath='{.data.token}' | base64 --decode)

# 9. Generate kubeconfig
mkdir -p $KUBECONFIG_PATH
KUBECONFIG_FILE="$KUBECONFIG_PATH/${USER}-${TENANT}-kubeconfig"
CA_DATA=$(kubectl config view --raw -o jsonpath="{.clusters[0].cluster.certificate-authority-data}")

sed -e "s/{{USER}}/$USER/g" \
    -e "s/{{TENANT}}/$TENANT/g" \
    -e "s/{{CLUSTER_NAME}}/$CLUSTER_NAME/g" \
    -e "s|{{CLUSTER_SERVER}}|$CLUSTER_SERVER|g" \
    -e "s/{{CA_DATA}}/$CA_DATA/g" \
    -e "s/{{USER_TOKEN}}/$USER_TOKEN/g" \
    "./kubeconfig-template.yaml" > "$KUBECONFIG_FILE"

# 10. Apply NetworkPolicy (Phase 2: Tenant Isolation)
sed "s/{{TENANT_NAME}}/$TENANT/g" "./networkpolicy.yaml" | kubectl apply -f -

echo " Tenant $TENANT with user $USER created successfully!"
echo " Kubeconfig saved at: $KUBECONFIG_FILE"
echo " To use it: export KUBECONFIG=$KUBECONFIG_FILE"
echo " NetworkPolicy applied: Tenant $TENANT is isolated from other namespaces"
echo "Happy K8s-ing!"