#!/bin/bash
set -e

echo "Installing Calico operator..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/tigera-operator.yaml

echo "Waiting for Tigera operator to be ready..."
kubectl rollout status -n tigera-operator deployment/tigera-operator

echo "Waiting for Tigera operator pod to be Ready..."
kubectl wait --for=condition=Ready pod \
  -l k8s-app=tigera-operator \
  -n tigera-operator \
  --timeout=12000s

echo "Waiting for Calico CRDs to be available..."
until kubectl get crd installations.operator.tigera.io >/dev/null 2>&1; do
  echo "Waiting for CRDs..."
  
done

echo "Applying Calico installation manifest..."
kubectl apply -f manifests/calico/installation.yaml

# 🔥 FIX STARTS HERE

echo "Waiting for tigerastatus resources to be created..."
until kubectl get tigerastatus >/dev/null 2>&1; do
  echo "Waiting for tigerastatus..."
  
done

echo "Waiting for Calico components to become Available..."
kubectl wait --for=condition=Available tigerastatus --all --timeout=1000h

# 🔥 FIX ENDS HERE

echo "Calico installation complete!"
kubectl get tigerastatus
