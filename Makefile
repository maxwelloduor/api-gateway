.PHONY: all bootstrap api controllers tls demo canary obs mesh clean

all: bootstrap api controllers tls demo

# --- INFRASTRUCTURE LAYER ---
bootstrap: cluster calico cert

cluster:
	chmod +x scripts/cluster.sh
	./scripts/cluster.sh

calico:
	chmod +x scripts/install-calico.sh
	./scripts/install-calico.sh

cert:
	chmod +x scripts/install-cert-manager.sh
	./scripts/install-cert-manager.sh

# --- API LAYER (CRDs) ---
api: gateway-crds wait-gateway-crds

gateway-crds:
	chmod +x scripts/install-gateway-api.sh
	./scripts/install-gateway-api.sh

wait-gateway-crds:
	kubectl wait --for condition=Established crd/gateways.gateway.networking.k8s.io --timeout=60s

# --- CONTROLLERS ---
controllers: envoy-gateway gateway-class

envoy-gateway:
	kubectl apply --server-side --force-conflicts -f https://github.com/envoyproxy/gateway/releases/download/v1.1.0/install.yaml
	kubectl wait -n envoy-gateway-system --for=condition=Available deployment --all --timeout=300s

gateway-class:
	kubectl apply -f manifests/gateway/gatewayclass.yaml
	sleep 5

# --- SECURITY (TLS) ---
tls:
	@echo "Applying TLS Infrastructure and Permissions..."
	kubectl apply -f manifests/gateway/tls-setup.yaml
	kubectl apply -f manifests/gateway/reference-grant.yaml
	@echo "Waiting for Certificate..."
	kubectl wait -n envoy-gateway-system certificate frontend-tls --for=condition=Ready --timeout=100h

# --- WORKLOADS & ROUTING ---
demo:
	chmod +x scripts/deploy-demo.sh
	./scripts/deploy-demo.sh
	@echo "Configuring Gateway and Routing..."
	kubectl apply -f manifests/gateway/gateway.yaml
	kubectl apply -f manifests/gateway/httproute.yaml
	kubectl wait --for=condition=Programmed gateway/calico-demo-gw --timeout=100h

# 🔥 1 & 2. CANARY DEPLOYMENTS & TRAFFIC SPLITTING
canary:
	@echo "Deploying Frontend V2 (Canary)..."
	kubectl apply -f manifests/services/canary/frontend-v2.yaml
	@echo "Waiting for Canary Rollout..."
	kubectl rollout status deployment/frontend-v2 --timeout=120s
	@echo "Applying 90/10 Traffic Split..."
	# This assumes you have a version of httproute.yaml with weights
	kubectl apply -f manifests/gateway/httproute.yaml

# 🔥 3. OBSERVABILITY (PROMETHEUS & GRAFANA)
obs:
	git clone --depth 1 https://github.com/prometheus-operator/kube-prometheus.git

	kubectl apply --server-side -f kube-prometheus/manifests/setup

	until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done

	kubectl apply -f kube-prometheus/manifests/

# 🔥 4. SERVICE MESH EVOLUTION (CALICO POLICY)
mesh:
	@echo "Enforcing Zero-Trust mTLS and Staged Policies..."
	kubectl apply -f manifests/calico/staged-policy.yaml
	kubectl apply -f manifests/services/base/frontend-policy.yaml
	@echo "Calico is now governing East-West traffic."

clean:
	k3d cluster delete calico-demo-cluster || true