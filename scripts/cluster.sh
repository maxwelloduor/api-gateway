#!/bin/bash
set -e

# Cluster name
CLUSTER_NAME="calico-demo-cluster"

echo "Creating k3d cluster: $CLUSTER_NAME"

k3d cluster create $CLUSTER_NAME \
  -s 1 -a 2 \
  --k3s-arg '--flannel-backend=none@server:*' \
  --k3s-arg '--disable-network-policy@server:*' \
  --k3s-arg '--disable=traefik@server:*' \
  --k3s-arg '--cluster-cidr=192.168.0.0/16@server:*'

echo "Cluster created successfully!"

echo "Setting kubectl context to $CLUSTER_NAME"
kubectl cluster-info