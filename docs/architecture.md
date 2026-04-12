
---

# 📄 `docs/architecture.md`

```markdown
# Architecture

## Components

### 1. Gateway Layer
- Calico Gateway (Envoy)
- Handles ingress traffic

### 2. Routing Layer
- HTTPRoute resources
- Path-based routing

### 3. Networking Layer
- Calico CNI
- NetworkPolicy enforcement

### 4. Services
- Kubernetes services
- Backend workloads

---

## Flow

Client
↓
Gateway (Envoy)
↓
HTTPRoute
↓
Service
↓
Pods

---

## Security Model

- Default deny
- Allow only gateway → services