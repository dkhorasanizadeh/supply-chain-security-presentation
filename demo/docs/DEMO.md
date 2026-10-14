# Run the supply-chain security demo

Run these commands on Linux from this directory, in one Bash session. This assumes Docker (with the `buildx` plugin), Go, Syft, Grype, Cosign, `kind`, `kubectl`, and `curl` are already available.

## Infrastructure

`make up` brings up the kind cluster, the Zot registry, and Kyverno (applied from its pinned GitHub release), and generates the cosign signing keypair.

## The enforcement policy

```bash
awk -v key="$(sed 's/^/            /' cosign.pub)" '{gsub(/__COSIGN_PUBLIC_KEY__/, key)} 1' kyverno-policy.yaml | kubectl apply -f -
```

## Step 1: build, inventory, and scan the vulnerable image

```bash
export IMAGE=localhost:5000/supply-chain-demo:1.0

docker buildx bake --push vulnerable

export IMAGE_REF="$(docker image inspect --format='{{index .RepoDigests 0}}' "$IMAGE")"
printf 'Vulnerable artifact reference: %s\n' "$IMAGE_REF"

syft "$IMAGE_REF" -o cyclonedx-json=sbom.json
grype "$IMAGE_REF" -o table
```

```bash
kubectl apply -f vulnerable/pod-vulnerable.yaml
```

## Step 2: build, inventory, scan, sign, and attest the fixed image

```bash
export FIXED_IMAGE=localhost:5000/supply-chain-demo:2.0

docker buildx bake --push fixed

export FIXED_IMAGE_REF="$(docker image inspect --format='{{index .RepoDigests 0}}' "$FIXED_IMAGE")"
printf 'Fixed artifact reference: %s\n' "$FIXED_IMAGE_REF"

syft "$FIXED_IMAGE_REF" -o cyclonedx-json=sbom-updated.json
grype "$FIXED_IMAGE_REF" -o table
```

### Sign the fixed image, and attest its SBOM and provenance

`provenance.json` is hand-written for this demo — SLSA Build L1 at best, not from a real trusted builder.

```bash
SOURCE_REVISION="$(git rev-parse HEAD 2>/dev/null || printf 'working-tree')"
APP_SHA256="$(sha256sum fixed/main.go | cut -d' ' -f1)"
cat > provenance.json <<JSON
{
  "buildDefinition": {
    "buildType": "https://example.org/demo/local-docker-build/v1",
    "externalParameters": {
      "sourceRevision": "$SOURCE_REVISION",
      "dockerfile": "fixed/Dockerfile",
      "image": "$FIXED_IMAGE"
    },
    "internalParameters": {},
    "resolvedDependencies": [
      {
        "uri": "file:fixed/main.go",
        "digest": {"sha256": "$APP_SHA256"}
      }
    ]
  },
  "runDetails": {
    "builder": {"id": "https://example.org/demo/local-docker-builder"}
  }
}
JSON

export COSIGN_PASSWORD=''
cosign sign --yes --new-bundle-format=false --use-signing-config=false --tlog-upload=false --allow-insecure-registry --registry-referrers-mode=legacy --key cosign.key "$FIXED_IMAGE_REF" 2>/dev/null
cosign attest --yes --new-bundle-format=false --use-signing-config=false --tlog-upload=false --allow-insecure-registry --key cosign.key --type slsaprovenance --predicate provenance.json "$FIXED_IMAGE_REF" 2>/dev/null
cosign attest --yes --new-bundle-format=false --use-signing-config=false --tlog-upload=false --allow-insecure-registry --key cosign.key --type cyclonedx --predicate sbom-updated.json "$FIXED_IMAGE_REF" 2>/dev/null
```

### Verify all three pieces of evidence

```bash
cosign verify --allow-insecure-registry --insecure-ignore-tlog --key cosign.pub "$FIXED_IMAGE_REF" 2>/dev/null
cosign verify-attestation --allow-insecure-registry --insecure-ignore-tlog --key cosign.pub --type slsaprovenance "$FIXED_IMAGE_REF" 2>/dev/null
cosign verify-attestation --allow-insecure-registry --insecure-ignore-tlog --key cosign.pub --type cyclonedx "$FIXED_IMAGE_REF" 2>/dev/null
```

```bash
kubectl apply -f fixed/pod-fixed.yaml
```

## Clean up

```bash
make clean
```
