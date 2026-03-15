# Azure DevOps Self-Hosted Agent

A container image for running Azure DevOps self-hosted pipeline agents, built using the Wolfi-native supply-chain toolchain (melange + apko). A legacy Dockerfile build path is also maintained.

## Build Approaches

### Primary: melange + apko (recommended)

The primary build uses [melange](https://github.com/chainguard-dev/melange) to produce a signed APK package containing all tools and the agent entrypoint, then [apko](https://github.com/chainguard-dev/apko) to assemble a minimal OCI image from Wolfi packages. No Dockerfile is involved at runtime.

**Benefits:**
- Produces multi-arch images (amd64 + arm64) from a single build
- All binaries are SHA256-verified at build time
- Image is assembled entirely from APK packages — reproducible and auditable
- SBOM generated automatically by apko

### Alternative: Dockerfile

A `Dockerfile` based on `cgr.dev/chainguard/wolfi-base` is maintained as a backup path. It installs the same toolchain via `curl` + `pip` at image build time.

## Toolchain

Both build paths produce an image containing:

| Tool | Version |
|---|---|
| kubectl | 1.35.2 |
| kubelogin | 0.2.16 |
| Terraform | 1.14.7 |
| vendir | 0.45.2 |
| kluctl | 2.27.0 |
| Azure CLI | 2.84.0 |
| melange | 0.45.3-r1 |
| Python 3, git, jq, yq, make, openssh, curl | (Wolfi latest) |

## Key Files

| File | Purpose |
|---|---|
| `melange.yaml` | APK build spec — downloads, SHA256-verifies, and installs all tool binaries |
| `apko.yaml` | Image assembly config — packages, users, entrypoint, environment variables |
| `build-apko.sh` | One-command local build wrapper (keygen → melange → index → apko) |
| `Dockerfile` | Wolfi-based Dockerfile build (alternative path) |
| `start.sh` | Azure DevOps agent entrypoint installed to `/azp/start.sh` in the image |
| `melange.rsa.pub` | Public signing key for local APK repository (committed) |

## Local Build

Requires Docker with privileged mode support (melange uses bubblewrap namespaces).

```bash
# Full build: generates signing key if absent, builds package and image
./build-apko.sh

# Load the image
docker load -i azdo-agent-apko.tar

# Verify tools (amd64)
docker run --rm --entrypoint /bin/bash azdo-agent:apko-amd64 -lc '
  kubectl version --client
  az version
  terraform version
  vendir --version
  kluctl version
  melange version
'
```

> After `docker load`, the image tag includes the arch suffix: `azdo-agent:apko-amd64` (not `azdo-agent:apko`).

## CI/CD

GitHub Actions (`.github/workflows/build.yml`) runs two parallel jobs on pushes and PRs to `main`:

- **Build with melange + apko** — installs melange via `chainguard-dev/actions/setup-melange` and apko from its GitHub release binary, builds multi-arch packages (amd64 + arm64), assembles the image, loads it into Docker, and runs tool version checks on both architectures via QEMU.
- **Build with Dockerfile** — standard `docker build` followed by the same tool verification step.

> CI installs melange and apko as native binaries on the runner rather than using their distroless container images. The distroless apko image has no shell and cannot run on GitHub Actions runners.

## Running the Agent

The agent is configured via environment variables at container start:

| Variable | Required | Description |
|---|---|---|
| `AZP_URL` | Yes | Azure DevOps organization URL (e.g. `https://dev.azure.com/myorg`) |
| `AZP_TOKEN` | Yes | Personal Access Token with Agent Pools (read/manage) scope |
| `AZP_POOL` | No | Agent pool name (default: `Default`) |
| `AZP_AGENT_NAME` | No | Agent name (default: hostname) |
| `AZP_WORK` | No | Work directory (default: `_work`) |

```bash
docker run -e AZP_URL=https://dev.azure.com/myorg \
           -e AZP_TOKEN=<pat> \
           -e AZP_POOL=MyPool \
           azdo-agent:apko-amd64
```

The agent registers itself on startup and deregisters cleanly on `SIGTERM`/`SIGINT`.

## Updating Tool Versions

Tool versions are defined in two places that must stay in sync:

- `melange.yaml` — pipeline shell variables + SHA256 checksums
- `apko.yaml` — `environment:` entries

When bumping a version, update both files and fetch new checksums from the official source. See `azdo-agent-build.prompt.md` for per-tool checksum fetch commands.

## Signing Key Management

The private key (`melange.rsa`) is gitignored and never committed. The public key (`melange.rsa.pub`) is committed and referenced by `apko.yaml`.

```bash
# Regenerate keypair (if lost or rotating)
melange keygen

# Commit only the public key
git add melange.rsa.pub && git commit -m "chore: rotate melange signing key"
```

## Dependency Updates

[Renovate](https://docs.renovatebot.com/) is configured via `renovate.json` to automatically track Dockerfile base image and container image dependency updates.
