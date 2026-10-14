variable "REGISTRY" {
  default = "localhost:5000"
}

group "default" {
  targets = ["vulnerable", "fixed"]
}

target "vulnerable" {
  context = "vulnerable"
  tags    = ["${REGISTRY}/supply-chain-demo:1.0"]
  labels = {
    "org.opencontainers.image.title"       = "supply-chain-demo"
    "org.opencontainers.image.description" = "Vulnerable build: golang:1.25-alpine + alpine:3.16.7"
    "org.opencontainers.image.version"     = "1.0"
    "org.opencontainers.image.vendor"      = "Supply Chain Security Presentation"
    "org.opencontainers.image.licenses"    = "MIT"
    "org.opencontainers.image.created"     = timestamp()
  }
}

target "fixed" {
  context = "fixed"
  tags    = ["${REGISTRY}/supply-chain-demo:2.0"]
  labels = {
    "org.opencontainers.image.title"       = "supply-chain-demo"
    "org.opencontainers.image.description" = "Fixed build: golang:1.27.1-alpine + distroless/static-debian12:nonroot"
    "org.opencontainers.image.version"     = "2.0"
    "org.opencontainers.image.vendor"      = "Supply Chain Security Presentation"
    "org.opencontainers.image.licenses"    = "MIT"
    "org.opencontainers.image.created"     = timestamp()
  }
}
