#!/bin/bash
set -e

echo "=== Installing Calico Operator ==="
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/tigera-operator.yaml

echo "=== Waiting for Tigera operator deployment ==="
kubectl rollout status -n tigera-operator deployment/tigera-operator

echo "=== Waiting for Tigera operator pod to be Ready ==="
kubectl wait --for=condition=Ready pod \
  -l k8s-app=tigera-operator \
  -n tigera-operator \
  --timeout=1000h

# 🔹 HARD GATE: Ensure operator is actually running
echo "=== Verifying operator pod is Running ==="
until kubectl get pods -n tigera-operator | grep tigera-operator | grep -q Running; do
  echo "Waiting for tigera-operator pod to be Running..."
  sleep 2
done

echo "=== Waiting for Calico CRDs ==="
until kubectl get crd installations.operator.tigera.io >/dev/null 2>&1; do
  echo "Waiting for CRDs..."
  sleep 2
done

echo "=== Applying Calico Installation ==="
kubectl apply -f manifests/calico/installation.yaml

# 🔹 HARD GATE: Wait for namespace creation
echo "=== Waiting for calico-system namespace ==="
until kubectl get ns calico-system >/dev/null 2>&1; do
  echo "Waiting for calico-system namespace..."
  sleep 3
done

# 🔹 HARD GATE: Wait for pods to exist
echo "=== Waiting for Calico pods to be created ==="
until kubectl get pods -n calico-system | grep -q calico; do
  echo "Waiting for Calico pods..."
  sleep 3
done

# 🔹 HARD GATE: Wait for all pods except kube-controllers first
echo "=== Waiting for core Calico pods (node, typha) ==="
kubectl wait --for=condition=Ready pod \
  -l k8s-app=calico-node \
  -n calico-system \
  --timeout=1000h

kubectl wait --for=condition=Ready pod \
  -l k8s-app=calico-typha \
  -n calico-system \
  --timeout=1000h

# 🔹 HANDLE kube-controllers separately (known flaky startup)
echo "=== Waiting for calico-kube-controllers ==="

RETRIES=100
COUNT=0

until kubectl get pods -n calico-system | grep calico-kube-controllers | grep -q "1/1"; do
  if [ $COUNT -ge $RETRIES ]; then
    echo "kube-controllers not ready, restarting..."
    kubectl delete pod -n calico-system -l k8s-app=calico-kube-controllers
    COUNT=0
  fi

  echo "Waiting for calico-kube-controllers..."
  sleep 5
  COUNT=$((COUNT+1))
done

echo "=== Verifying full Calico readiness ==="
kubectl get pods -n calico-system

echo "=== Checking tigerastatus (final validation) ==="
kubectl get tigerastatus || true

echo "=== Calico installation COMPLETE ==="
