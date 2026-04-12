.PHONY: all cluster calico cert gateway-crds gateway demo clean

all: cluster calico cert demo gateway-crds gateway

cluster:
	chmod +x scripts/cluster.sh
	./scripts/cluster.sh

calico:
	chmod +x scripts/install-calico.sh
	./scripts/install-calico.sh

cert:
	chmod +x scripts/install-cert-manager.sh
	./scripts/install-cert-manager.sh

demo:
	chmod +x scripts/deploy-demo.sh
	./scripts/deploy-demo.sh

gateway-crds:
	chmod +x scripts/install-gateway-api.sh
	./scripts/install-gateway-api.sh

gateway:
	kubectl apply -f manifests/gateway/

clean:
	k3d cluster delete calico-demo-cluster || true