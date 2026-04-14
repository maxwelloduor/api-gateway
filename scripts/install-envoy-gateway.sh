#!/usr/bin/env bash
set -e

echo "Installing Envoy Gateway..."

kubectl apply --server-side --force-conflicts \
  -f https://github.com/envoyproxy/gateway/releases/download/v1.7.0/install.yaml

kubectl wait -n envoy-gateway-system \
  --for=condition=Available deployment \
  --all --timeout=300s

echo "Envoy Gateway ready"