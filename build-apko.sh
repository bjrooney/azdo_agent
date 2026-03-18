#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Pinned digests for reproducible local builds.
# Update these when bumping tool versions (run: docker pull <image> && docker inspect --format '{{index .RepoDigests 0}}').
MELANGE_IMAGE="cgr.dev/chainguard/melange@sha256:09a0195ba41b483a069d0b21d4442fc87ea24975abcae0377a1ed3d1638cbddd"
APKO_IMAGE="cgr.dev/chainguard/apko@sha256:48723aaeadd24f01a82c6920c4e2d7e49df259bb36e972c14cf414264d7bf676"

cd "$ROOT_DIR"

if [[ ! -f melange.rsa || ! -f melange.rsa.pub ]]; then
  docker run --rm -v "$ROOT_DIR:/work" -w /work "${MELANGE_IMAGE}" keygen
fi

# melange uses bubblewrap; privileged mode avoids namespace restrictions in many Docker setups.
docker run --rm --privileged \
  -v "$ROOT_DIR:/work" \
  -w /work \
  "${MELANGE_IMAGE}" \
  build melange.yaml --arch amd64,arm64 --signing-key melange.rsa --out-dir /work/packages

# Ensure repository index exists and is signed for apko consumption.
# Globs use relative paths (host CWD=$ROOT_DIR, container -w /work) so expansion works on host.
docker run --rm \
  -v "$ROOT_DIR:/work" \
  -w /work \
  "${MELANGE_IMAGE}" \
  index --signing-key melange.rsa packages/x86_64/*.apk

docker run --rm \
  -v "$ROOT_DIR:/work" \
  -w /work \
  "${MELANGE_IMAGE}" \
  index --signing-key melange.rsa packages/aarch64/*.apk

docker run --rm \
  -v "$ROOT_DIR:/work" \
  -w /work \
  --entrypoint /usr/bin/apko \
  "${APKO_IMAGE}" \
  build apko.yaml azdo-agent:apko azdo-agent-apko.tar

echo "Built: $ROOT_DIR/azdo-agent-apko.tar"
echo "Load with: docker load -i $ROOT_DIR/azdo-agent-apko.tar"
