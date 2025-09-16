#!/bin/bash

echo " Service Account + Role Creator "

# Ask for Namespace
read -p "Enter namespace: " NAMESPACE

# Ask for Service Account Name
read -p "Enter ServiceAccount name: " SA_NAME

# Ask for Access Level (admin/view)
read -p "Choose access level (admin/view): " ACCESS

# Auto-generate Role name
ROLE_NAME="${SA_NAME}-${ACCESS}-role"

# Auto-generate RoleBinding name
ROLEBINDING_NAME="${SA_NAME}-${ACCESS}-binding"

# Define access verbs
if [[ "$ACCESS" == "admin" ]]; then
  ACCESS_VERBS="- \"*\""
else
  ACCESS_VERBS=$(cat <<EOF
- get
- list
- watch
EOF
)
fi

echo " Creating ServiceAccount $SA_NAME in $NAMESPACE"
kubectl create serviceaccount $SA_NAME -n $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo " Creating Role $ROLE_NAME with $ACCESS access in $NAMESPACE"
sed "s|<NAMESPACE>|$NAMESPACE|g; s|<ROLE_NAME>|$ROLE_NAME|g" role-template.yaml | \
  sed "s|<ACCESS_VERBS>|$ACCESS_VERBS|g" | kubectl apply -f -

echo " Creating RoleBinding $ROLEBINDING_NAME"
sed "s|<NAMESPACE>|$NAMESPACE|g; s|<ROLE_NAME>|$ROLE_NAME|g; s|<ROLEBINDING_NAME>|$ROLEBINDING_NAME|g; s|<SA_NAME>|$SA_NAME|g" rolebinding-template.yaml | kubectl apply -f -

# Generate kubeconfig
TOKEN=$(kubectl create token $SA_NAME -n $NAMESPACE)
CA_DATA=$(base64 -w0 /etc/kubernetes/pki/ca.crt)
SERVER=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')

sed "s|<NAMESPACE>|$NAMESPACE|g; s|<SA_NAME>|$SA_NAME|g; s|<TOKEN>|$TOKEN|g; s|<CA_DATA>|$CA_DATA|g; s|<SERVER>|$SERVER|g" kubeconfig-template.yaml > ${SA_NAME}-kubeconfig.yaml

echo "Kubeconfig file created: ${SA_NAME}-kubeconfig.yaml"
