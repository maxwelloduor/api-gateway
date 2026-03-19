#!/bin/bash
set -e

echo "Installing Calico operator..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.30.2/manifests/tigera-operator.yaml

echo "Waiting for Tigera operator to be ready..."
kubectl rollout status -n tigera-operator deployment/tigera-operator

echo "Applying Calico installation manifest..."
kubectl apply -f manifests/calico/installation.yaml

echo "Verifying Calico installation..."
kubectl get tigerastatus