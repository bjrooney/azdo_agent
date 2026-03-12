---
mode: agent
description: Build and maintain the Azure DevOps agent image using the Wolfi-native apko + melange pipeline. Use this prompt when updating tool versions, adding new tools, rotating signing keys, or rebuilding the image.
---

# Azure DevOps Agent – Wolfi/apko/melange Build

## Overview

This image is the Azure DevOps self-hosted agent. It is built using the Wolfi-native supply-chain toolchain:

- **melange** — builds `azdo-agent-tools` as a proper APK package (binary installs + `start.sh`)
- **apko** — assembles the final OCI image from APK packages; no Dockerfile runtime

The legacy `Dockerfile` (Wolfi-based) still exists as an alternative but the **primary flow is `melange` + `apko`**.

---

## Key Files

| File | Purpose |
|---|---|
| `melange.yaml` | APK build spec — downloads + verifies + installs all tool binaries |
| `apko.yaml` | Image assembly config — packages, users, entrypoint, env vars |
| `build-apko.sh` | One-command build wrapper (keygen → melange → index → apko) |
| `Dockerfile` | Wolfi+melange Dockerfile (backup path, not primary) |
| `melange.rsa.pub` | Public signing key (commit this; `melange.rsa` is gitignored) |
| `start.sh` | Azure DevOps agent entrypoint installed to `/azp/start.sh` in the image |

---

## Tool Versions (update all consistently)

These versions appear in **both** `melange.yaml` (as shell vars) **and** `apko.yaml` (as `environment:` entries):

| Tool | Variable | Where to update |
|---|---|---|
| kubectl | `KUBECTL_VERSION` | `melange.yaml` + `apko.yaml` |
| kubelogin | `KUBELOGIN_VERSION` | `melange.yaml` + `apko.yaml` |
| Terraform | `TERRAFORM_VERSION` | `melange.yaml` + `apko.yaml` |
| vendir | `VENDIR_VERSION` | `melange.yaml` + `apko.yaml` |
| kluctl | `KLUCTL_VERSION` | `melange.yaml` + `apko.yaml` |
| Azure CLI | `AZCLI_VERSION` | `melange.yaml` + `apko.yaml` |
| melange | `MELANGE_VERSION` | `melange.yaml` (runtime dep) + `apko.yaml` |

---

## SHA256 Checksum Policy

Every downloaded binary in `melange.yaml` is verified with `sha256sum -c -` immediately after download. When updating a tool version you **must** fetch the new hash from the official source:

```bash
# kubectl
curl -fsSL https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256

# kubelogin
curl -fsSL https://github.com/Azure/kubelogin/releases/download/v${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip.sha256

# terraform
curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS | grep linux_amd64

# vendir  
curl -fsSL https://api.github.com/repos/carvel-dev/vendir/releases/tags/v${VENDIR_VERSION} | jq -r '.body' | grep vendir-linux-amd64

# kluctl
curl -fsSL https://github.com/kluctl/kluctl/releases/download/v${KLUCTL_VERSION}/kluctl_v${KLUCTL_VERSION}_checksums.txt | grep linux_amd64.tar.gz
```

Update the `echo "<newhash>  <filename>" | sha256sum -c -` lines in `melange.yaml` pipeline accordingly.

---

## Build

```bash
cd /home/brendan/projects/sita/brendan/Dockerfile/azdo_agent

# Full build (keygen is idempotent — skips if keys already exist)
./build-apko.sh

# Load image
docker load -i azdo-agent-apko.tar

# Verify
docker run --rm --entrypoint /bin/bash azdo-agent:apko-amd64 -lc \
  'kubectl version --client && az version && terraform version && vendir version && kluctl version && melange version'
```

---

## melange Build Internals

melange runs inside Docker and **requires `--privileged`** for bubblewrap namespace creation:

```bash
docker run --privileged --rm \
  -v "$PWD:/work" \
  cgr.dev/chainguard/melange build /work/melange.yaml \
  --arch amd64 \
  --signing-key /work/melange.rsa \
  --out-dir /work/packages
```

The build environment must include `busybox` (provides `/bin/sh`) in `environment.contents.packages`.

---

## Gotchas

- `melange.rsa` is the private signing key — **gitignored, never commit**. Regenerate with `melange keygen` if lost; rebuilding packages after key rotation requires all consumers to re-import the new public key.
- After `docker load`, the image tag includes the arch suffix: `azdo-agent:apko-amd64` (not `azdo-agent:apko`).
- `pip install azure-cli` uses `--break-system-packages` (required on Wolfi's managed Python). The pip dependency tree is **not** hash-locked — consider building a locked wheelhouse or packaging azure-cli as an APK for full supply-chain integrity.
- kluctl downloads as a `.tar.gz` (not a raw binary) — extract with `tar -xzf`.
- Wolfi does not have a `tar` package by that name; `busybox` provides it in the build environment.
- `dependencies` in `melange.yaml` must be nested under `package:`, not at the root level.

---

## Signing Key Rotation

```bash
# Generate new keypair (overwrites existing)
melange keygen melange.rsa

# Rebuild all packages against new key
./build-apko.sh

# In apko.yaml, the keyring entry ./melange.rsa.pub auto-picks up the new public key
# Commit the new melange.rsa.pub, never melange.rsa
git add melange.rsa.pub && git commit -m "chore: rotate melange signing key"
```
