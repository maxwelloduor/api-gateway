# 🚀 Calico API Gateway (k3s + Gateway API)

This project sets up a **Kubernetes-native API Gateway** using:

- Calico (CNI + NetworkPolicy)
- Gateway API (Ingress replacement)
- cert-manager (TLS)
- Microservices demo (backend)

## 🧱 Architecture

Client → Gateway (Envoy via Calico) → HTTPRoute → Service → Pods

## ⚡ Quick Start (Codespaces)

```bash
make all