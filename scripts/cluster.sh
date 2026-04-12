#!/usr/bin/env bash
set -euo pipefail

CLUSTER_NAME="calico-demo-cluster"

echo "=== Bootstrap: dependency checks ==="

check_command() {
  command -v "$1" >/dev/null 2>&1
}

install_k3d() {
  echo "[INFO] Installing k3d..."
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
}

install_kubectl() {
  echo "[INFO] Installing kubectl..."
  curl -LO "https://dl.k8s.io/release/$(curl -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  chmod +x kubectl
  sudo mv kubectl /usr/local/bin/
}

# Ensure PATH includes common install locations
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

# Docker (hard requirement)
if ! check_command docker; then
  echo "[ERROR] Docker is required but not installed."
  exit 1
fi

# k3d
if ! check_command k3d; then
  install_k3d
fi

# kubectl
if ! check_command kubectl; then
  install_kubectl
fi

echo "=== Cluster lifecycle ==="

# Idempotency: delete if exists
if k3d cluster list | grep -q "$CLUSTER_NAME"; then
  echo "[INFO] Existing cluster found. Deleting..."
  k3d cluster delete "$CLUSTER_NAME"
fi

echo "[INFO] Creating k3d cluster: $CLUSTER_NAME"

k3d cluster create "$CLUSTER_NAME" \
  -s 1 -a 2 \
  --k3s-arg '--flannel-backend=none@server:*' \
  --k3s-arg '--disable-network-policy@server:*' \
  --k3s-arg '--disable=traefik@server:*' \
  --k3s-arg '--cluster-cidr=192.168.0.0/16@server:*' \
  --wait

echo "[SUCCESS] Cluster created"

echo "[INFO] Verifying cluster access"
kubectl cluster-info
kubectl get nodes