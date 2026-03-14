#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

cd "$ROOT_DIR"

if [[ ! -f melange.rsa || ! -f melange.rsa.pub ]]; then
  docker run --rm -v "$ROOT_DIR:/work" -w /work cgr.dev/chainguard/melange:latest keygen
fi

# melange uses bubblewrap; privileged mode avoids namespace restrictions in many Docker setups.
docker run --rm --privileged \
  -v "$ROOT_DIR:/work" \
  -w /work \
  cgr.dev/chainguard/melange:latest \
  build melange.yaml --arch amd64,arm64 --signing-key melange.rsa --out-dir /work/packages

# Ensure repository index exists and is signed for apko consumption.
# Use sh -c so the glob is expanded inside the container.
docker run --rm \
  -v "$ROOT_DIR:/work" \
  -w /work \
  --entrypoint sh \
  cgr.dev/chainguard/melange:latest \
  -c 'melange index --signing-key melange.rsa /work/packages/x86_64/*.apk && melange index --signing-key melange.rsa /work/packages/aarch64/*.apk'

docker run --rm \
  -v "$ROOT_DIR:/work" \
  -w /work \
  --entrypoint /usr/bin/apko \
  cgr.dev/chainguard/apko:latest \
  build apko.yaml azdo-agent:apko azdo-agent-apko.tar

echo "Built: $ROOT_DIR/azdo-agent-apko.tar"
echo "Load with: docker load -i $ROOT_DIR/azdo-agent-apko.tar"
