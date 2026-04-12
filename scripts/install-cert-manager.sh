#!/bin/bash
set -e

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.2/cert-manager.yaml

kubectl wait --for=condition=Available deployment --all -n cert-manager --timeout=300s

kubectl apply -f manifests/cert-manager/issuer.yaml

kubectl patch deployment -n cert-manager cert-manager --type='json' --patch '
[
  {
    "op": "add",
    "path": "/spec/template/spec/containers/0/args/-",
    "value": "--enable-gateway-api"
  }
]'