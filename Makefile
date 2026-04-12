.PHONY: all bootstrap platform api controllers demo clean tls

all: bootstrap api controllers tls demo

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

# -------------------------
# API LAYER (CRDs ONLY)
# -------------------------
api: gateway-crds wait-gateway-crds

gateway-crds:
	chmod +x scripts/install-gateway-api.sh
	./scripts/install-gateway-api.sh

wait-gateway-crds:
	kubectl wait --for condition=Established \
		crd/gateways.gateway.networking.k8s.io \
		--timeout=1000h

# -------------------------
# CONTROLLERS
# -------------------------
controllers: envoy-gateway gateway-class

envoy-gateway:
	kubectl apply --server-side --force-conflicts -f https://github.com/envoyproxy/gateway/releases/download/v1.7.0/install.yaml
	kubectl wait -n envoy-gateway-system \
		--for=condition=Available deployment \
		--all --timeout=1000h

gateway-class:
	kubectl apply -f manifests/gateway/gatewayclass.yaml
	@echo "Waiting for GatewayClass to be accepted..."
	sleep 5

# -------------------------
# SECURITY (TLS)
# -------------------------
tls:
	@echo "Applying TLS Infrastructure and Permissions..."
	kubectl apply -f manifests/gateway/tls-setup.yaml
	# ReferenceGrant allows the Gateway in 'default' to access the Secret in 'envoy-gateway-system'
	kubectl apply -f manifests/gateway/reference-grant.yaml
	@echo "Waiting for Certificate to be issued in envoy-gateway-system..."
	kubectl wait -n envoy-gateway-system certificate frontend-tls --for=condition=Ready --timeout=300s

# -------------------------
# WORKLOADS & ROUTING
# -------------------------
demo:
	chmod +x scripts/deploy-demo.sh
	./scripts/deploy-demo.sh
	# Apply Gateway and HTTPRoutes
	@echo "Configuring Gateway and Routing..."
	kubectl apply -f manifests/gateway/gateway.yaml
	kubectl apply -f manifests/gateway/httproute.yaml
	@echo "Waiting for Gateway to be Programmed..."
	kubectl wait --for=condition=Programmed gateway/calico-demo-gw --timeout=1000h

clean:
	k3d cluster delete calico-demo-cluster || true