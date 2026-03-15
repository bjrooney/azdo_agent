#!/usr/bin/env bash
# update-checksums.sh — refresh SHA256 values in melange.yaml after a version bump.
# Run this after Renovate opens a PR that changes tool versions, then commit the result.
#
# Usage: ./update-checksums.sh
#
# Reads current *_VERSION values from melange.yaml and fetches the authoritative
# checksums from each project's release page. Rewrites the SHA256 lines in-place.
#
# Note: Azure CLI (AZCLI_VERSION) is installed via PyPI and has no per-release
# SHA256 published by upstream. It is not handled here.

set -euo pipefail

MELANGE_YAML="$(cd "$(dirname "$0")" && pwd)/melange.yaml"

# Parse versions from melange.yaml
version() { grep -m1 "${1}_VERSION=" "$MELANGE_YAML" | sed 's/.*=//'; }

KUBECTL_VERSION="$(version KUBECTL)"
KUBELOGIN_VERSION="$(version KUBELOGIN)"
TERRAFORM_VERSION="$(version TERRAFORM)"
VENDIR_VERSION="$(version VENDIR)"
KLUCTL_VERSION="$(version KLUCTL)"

echo "Fetching checksums for:"
echo "  kubectl        ${KUBECTL_VERSION}"
echo "  kubelogin      ${KUBELOGIN_VERSION}"
echo "  terraform      ${TERRAFORM_VERSION}"
echo "  vendir         ${VENDIR_VERSION}"
echo "  kluctl         ${KLUCTL_VERSION}"
echo "  azure-cli      (PyPI — no checksum available, skipped)"
echo

# Helper: fetch a URL and assert the result is a non-empty 64-char hex string.
fetch_sha256() {
  local desc="$1"
  local url="$2"
  local val
  val="$(curl -fsSL "$url")"
  # Strip any trailing filename (e.g. "abc123  filename") — keep only the hash
  val="$(echo "$val" | awk '{print $1}')"
  if [[ ! "$val" =~ ^[0-9a-f]{64}$ ]]; then
    echo 1>&2 "error: could not fetch a valid SHA256 for ${desc} from ${url}"
    echo 1>&2 "got: '${val}'"
    exit 1
  fi
  echo "$val"
}

# kubectl
KUBECTL_AMD64="$(fetch_sha256 "kubectl amd64" "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256")"
KUBECTL_ARM64="$(fetch_sha256 "kubectl arm64" "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/arm64/kubectl.sha256")"

# kubelogin — try per-file .sha256 first, fall back to checksums.txt
KUBELOGIN_SUMS="$(curl -fsSL "https://github.com/Azure/kubelogin/releases/download/v${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip.sha256" 2>/dev/null || true)"
if [[ "$KUBELOGIN_SUMS" =~ ^[0-9a-f]{64} ]]; then
  KUBELOGIN_AMD64="$(echo "$KUBELOGIN_SUMS" | awk '{print $1}')"
  KUBELOGIN_ARM64="$(fetch_sha256 "kubelogin arm64" "https://github.com/Azure/kubelogin/releases/download/v${KUBELOGIN_VERSION}/kubelogin-linux-arm64.zip.sha256")"
else
  CHECKSUMS="$(curl -fsSL "https://github.com/Azure/kubelogin/releases/download/v${KUBELOGIN_VERSION}/checksums.txt")"
  KUBELOGIN_AMD64="$(echo "$CHECKSUMS" | grep 'linux-amd64.zip' | awk '{print $1}')"
  KUBELOGIN_ARM64="$(echo "$CHECKSUMS" | grep 'linux-arm64.zip' | awk '{print $1}')"
  for desc_val in "kubelogin amd64:$KUBELOGIN_AMD64" "kubelogin arm64:$KUBELOGIN_ARM64"; do
    desc="${desc_val%%:*}"; val="${desc_val#*:}"
    if [[ ! "$val" =~ ^[0-9a-f]{64}$ ]]; then
      echo 1>&2 "error: could not parse SHA256 for ${desc} from checksums.txt"; exit 1
    fi
  done
fi

# terraform
TF_SUMS="$(curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS")"
TERRAFORM_AMD64="$(echo "$TF_SUMS" | grep 'linux_amd64' | awk '{print $1}')"
TERRAFORM_ARM64="$(echo "$TF_SUMS" | grep 'linux_arm64' | awk '{print $1}')"
for desc_val in "terraform amd64:$TERRAFORM_AMD64" "terraform arm64:$TERRAFORM_ARM64"; do
  desc="${desc_val%%:*}"; val="${desc_val#*:}"
  if [[ ! "$val" =~ ^[0-9a-f]{64}$ ]]; then
    echo 1>&2 "error: could not parse SHA256 for ${desc}"; exit 1
  fi
done

# vendir
VENDIR_SUMS="$(curl -fsSL "https://github.com/carvel-dev/vendir/releases/download/v${VENDIR_VERSION}/checksums.txt")"
VENDIR_AMD64="$(echo "$VENDIR_SUMS" | grep 'vendir-linux-amd64$' | awk '{print $1}')"
VENDIR_ARM64="$(echo "$VENDIR_SUMS" | grep 'vendir-linux-arm64$' | awk '{print $1}')"
for desc_val in "vendir amd64:$VENDIR_AMD64" "vendir arm64:$VENDIR_ARM64"; do
  desc="${desc_val%%:*}"; val="${desc_val#*:}"
  if [[ ! "$val" =~ ^[0-9a-f]{64}$ ]]; then
    echo 1>&2 "error: could not parse SHA256 for ${desc}"; exit 1
  fi
done

# kluctl
KLUCTL_SUMS="$(curl -fsSL "https://github.com/kluctl/kluctl/releases/download/v${KLUCTL_VERSION}/kluctl_v${KLUCTL_VERSION}_checksums.txt")"
KLUCTL_AMD64="$(echo "$KLUCTL_SUMS" | grep 'linux_amd64.tar.gz' | awk '{print $1}')"
KLUCTL_ARM64="$(echo "$KLUCTL_SUMS" | grep 'linux_arm64.tar.gz' | awk '{print $1}')"
for desc_val in "kluctl amd64:$KLUCTL_AMD64" "kluctl arm64:$KLUCTL_ARM64"; do
  desc="${desc_val%%:*}"; val="${desc_val#*:}"
  if [[ ! "$val" =~ ^[0-9a-f]{64}$ ]]; then
    echo 1>&2 "error: could not parse SHA256 for ${desc}"; exit 1
  fi
done

echo "All checksums fetched and validated. Updating $MELANGE_YAML ..."

sed -i \
  -e "s|KUBECTL_SHA_amd64=\"[^\"]*\"|KUBECTL_SHA_amd64=\"${KUBECTL_AMD64}\"|" \
  -e "s|KUBECTL_SHA_arm64=\"[^\"]*\"|KUBECTL_SHA_arm64=\"${KUBECTL_ARM64}\"|" \
  -e "s|KUBELOGIN_SHA_amd64=\"[^\"]*\"|KUBELOGIN_SHA_amd64=\"${KUBELOGIN_AMD64}\"|" \
  -e "s|KUBELOGIN_SHA_arm64=\"[^\"]*\"|KUBELOGIN_SHA_arm64=\"${KUBELOGIN_ARM64}\"|" \
  -e "s|TERRAFORM_SHA_amd64=\"[^\"]*\"|TERRAFORM_SHA_amd64=\"${TERRAFORM_AMD64}\"|" \
  -e "s|TERRAFORM_SHA_arm64=\"[^\"]*\"|TERRAFORM_SHA_arm64=\"${TERRAFORM_ARM64}\"|" \
  -e "s|VENDIR_SHA_amd64=\"[^\"]*\"|VENDIR_SHA_amd64=\"${VENDIR_AMD64}\"|" \
  -e "s|VENDIR_SHA_arm64=\"[^\"]*\"|VENDIR_SHA_arm64=\"${VENDIR_ARM64}\"|" \
  -e "s|KLUCTL_SHA_amd64=\"[^\"]*\"|KLUCTL_SHA_amd64=\"${KLUCTL_AMD64}\"|" \
  -e "s|KLUCTL_SHA_arm64=\"[^\"]*\"|KLUCTL_SHA_arm64=\"${KLUCTL_ARM64}\"|" \
  "$MELANGE_YAML"

echo "Done. Review the diff and commit:"
echo "  git diff melange.yaml"
echo "  git add melange.yaml && git commit -m 'chore: update checksums for <tool> <version>'"
