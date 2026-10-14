.PHONY: up down clean

KIND_CLUSTER := supply-chain-demo
KYVERNO_VERSION := v1.19.1
KYVERNO_INSTALL := https://github.com/kyverno/kyverno/releases/download/$(KYVERNO_VERSION)/install.yaml

up:
	kind create cluster --name $(KIND_CLUSTER) --config k8s/kind-config.yaml
	kubectl apply -f k8s/zot.yaml
	kubectl -n supply-chain-demo rollout status deployment/zot
	until curl --fail --silent http://127.0.0.1:5000/v2/ >/dev/null; do sleep 1; done
	kubectl apply --server-side -f $(KYVERNO_INSTALL)
	kubectl -n kyverno wait --for=condition=Available --timeout=180s deployment --all
	COSIGN_PASSWORD='' cosign generate-key-pair
	cosign signing-config create --out signing-config.json

down:
	kind delete cluster --name $(KIND_CLUSTER)

clean: down
	rm -f sbom.json sbom-updated.json provenance.json cosign.key cosign.pub signing-config.json
	docker image rm -f localhost:5000/supply-chain-demo:1.0 localhost:5000/supply-chain-demo:2.0 2>/dev/null || true
