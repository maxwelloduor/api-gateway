#!/bin/bash
set -e

kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/microservices-demo/release/v0.10.2/release/kubernetes-manifests.yaml

kubectl rollout status deployment/frontend

kubectl delete svc frontend-external || true

echo "Demo deployed"