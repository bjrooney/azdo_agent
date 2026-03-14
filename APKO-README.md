# AZDO Agent via melange + apko

This directory now supports a full Wolfi-native package/image flow.

## Files

- `melange.yaml`: builds local package `azdo-agent-tools` (includes `start.sh` and toolchain binaries)
- `apko.yaml`: assembles final image from Wolfi packages + local package repo
- `build-apko.sh`: one-command build wrapper
- `.github/workflows/build.yml`: GitHub Actions CI pipeline

## CI Pipeline

The GitHub Actions workflow (`.github/workflows/build.yml`) runs two parallel jobs on pushes and PRs to `main`:

1. **Build with melange + apko** — installs melange via `chainguard-dev/actions/setup-melange` and apko from its GitHub release binary, then runs `melange build`, `melange index`, and `apko build` natively on the runner. The built image is loaded into Docker and verified by running tool version checks (`kubectl`, `az`, `terraform`, `vendir`, `kluctl`, `melange`).

2. **Build with Dockerfile** — standard `docker build` using the `Dockerfile`, with the same tool verification step.

### CI notes

- Melange and apko are installed **natively** on the runner rather than via their distroless container images (`cgr.dev/chainguard/melange`, `cgr.dev/chainguard/apko`). The distroless apko image lacks a shell and fails on GitHub Actions runners.
- The local `build-apko.sh` script still uses the container approach for local builds where Docker is available with full namespace support.
- A fresh signing key is generated per CI run (`melange keygen`); the private key (`melange.rsa`) is gitignored.

## Build

```bash
cd /home/brendan/projects/sita/brendan/Dockerfile/azdo_agent
./build-apko.sh
```

Build output:

- `packages/x86_64/azdo-agent-tools-0.1.0-r0.apk`
- `packages/x86_64/APKINDEX.tar.gz`
- `azdo-agent-apko.tar`

## Load and test

```bash
docker load -i azdo-agent-apko.tar
# apko appends arch to the tag on load:
docker run --rm --entrypoint /bin/bash azdo-agent:apko-amd64 -lc 'melange version && az version'
```

## Notes

- `melange` is pinned via runtime dependency: `melange=0.45.3-r1`.
- `start.sh` is installed to `/azp/start.sh` and used as image entrypoint.
- The build script uses `--privileged` for melange due to bubblewrap namespace requirements in containerized builds.
- The `melange index` step in `build-apko.sh` uses `--entrypoint sh` with `sh -c '...'` so the `*.apk` glob is expanded inside the container.
