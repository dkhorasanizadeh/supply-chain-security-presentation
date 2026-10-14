# Supply-chain security demo

A small, self-contained Kubernetes demo of what it takes to trust a container
artifact: inventory it, scan it, sign it, attest it, and then let a cluster
admission policy refuse anything that cannot prove where it came from.

One application is built twice — a **vulnerable** variant with an old base image
and an old dependency, and a **fixed** variant with an updated base image and
dependency. The same enforcement policy is applied to both, so the difference in
outcome comes purely from the evidence attached to each artifact.

## Layout

```tree
.
├── vulnerable/          # 1.0 — golang:1.25-alpine + alpine:3.16.7, golang.org/x/net v0.7.0
│   ├── Dockerfile
│   ├── main.go
│   ├── go.mod / go.sum
│   └── pod-vulnerable.yaml
├── fixed/               # 2.0 — golang:1.27.1-alpine + distroless, golang.org/x/net v0.59.0
│   ├── Dockerfile
│   ├── main.go
│   ├── go.mod / go.sum
│   └── pod-fixed.yaml
├── k8s/
│   ├── kind-config.yaml       # single-node cluster, host port 5000 → registry
│   └── zot.yaml               # in-cluster OCI registry
├── kyverno-policy.yaml        # ImageValidatingPolicy: require a valid Cosign signature
├── docker-bake.hcl            # buildx targets for both variants
├── Makefile                   # up / down / clean
└── docs/DEMO.md               # step-by-step walkthrough
```

## Quick start

Requirements: Docker with the `buildx` plugin, Go, `kind`, `kubectl`, `curl`,
and the Syft, Grype, and Cosign CLIs on `PATH`.

```bash
make up
```

This creates the kind cluster, applies Zot and Kyverno, waits for both to become
available, and generates the Cosign keypair used to sign and verify the demo
image. Kyverno is applied directly from its pinned GitHub release, and all
container images are pulled from their public registries — nothing is vendored
in this repository, so an internet connection is required.

The full run-through — building both variants, generating the SBOMs, scanning,
signing, attesting, and watching the policy accept one pod and would reject the
other — is in **[docs/DEMO.md](docs/DEMO.md)**.

Tear everything down with:

```bash
make clean
```

## A note on the provenance

The SLSA provenance predicate generated during the demo is hand-written and
describes a local Docker build. It demonstrates the *shape* of provenance and
how a policy consumes it — it is SLSA Build L1 at best, and not the output of a
trusted builder.

## License

[MIT](../LICENSE)
