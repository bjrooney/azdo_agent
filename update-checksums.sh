#!/usr/bin/env bash
# update-checksums.sh — refresh SHA256 values in melange.yaml after a version bump.
# Run this after Renovate opens a PR that changes tool versions, then commit the result.
#
# Usage: ./update-checksums.sh
#
# Reads current *_VERSION values from melange.yaml and fetches the authoritative
# checksums from each project's release page. Rewrites the SHA256 lines in-place.

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
echo

# kubectl
KUBECTL_AMD64="$(curl -fsSL "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256")"
KUBECTL_ARM64="$(curl -fsSL "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/arm64/kubectl.sha256")"

# kubelogin
KUBELOGIN_SUMS="$(curl -fsSL "https://github.com/Azure/kubelogin/releases/download/v${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip.sha256" 2>/dev/null || true)"
if [[ -z "$KUBELOGIN_SUMS" ]]; then
  KUBELOGIN_AMD64="$(curl -fsSL "https://github.com/Azure/kubelogin/releases/download/v${KUBELOGIN_VERSION}/checksums.txt" | grep 'linux-amd64.zip' | awk '{print $1}')"
  KUBELOGIN_ARM64="$(curl -fsSL "https://github.com/Azure/kubelogin/releases/download/v${KUBELOGIN_VERSION}/checksums.txt" | grep 'linux-arm64.zip' | awk '{print $1}')"
else
  KUBELOGIN_AMD64="$(echo "$KUBELOGIN_SUMS" | awk '{print $1}')"
  KUBELOGIN_ARM64="$(curl -fsSL "https://github.com/Azure/kubelogin/releases/download/v${KUBELOGIN_VERSION}/kubelogin-linux-arm64.zip.sha256" | awk '{print $1}')"
fi

# terraform
TERRAFORM_AMD64="$(curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" | grep 'linux_amd64' | awk '{print $1}')"
TERRAFORM_ARM64="$(curl -fsSL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_SHA256SUMS" | grep 'linux_arm64' | awk '{print $1}')"

# vendir
VENDIR_AMD64="$(curl -fsSL "https://github.com/carvel-dev/vendir/releases/download/v${VENDIR_VERSION}/checksums.txt" | grep 'vendir-linux-amd64$' | awk '{print $1}')"
VENDIR_ARM64="$(curl -fsSL "https://github.com/carvel-dev/vendir/releases/download/v${VENDIR_VERSION}/checksums.txt" | grep 'vendir-linux-arm64$' | awk '{print $1}')"

# kluctl
KLUCTL_AMD64="$(curl -fsSL "https://github.com/kluctl/kluctl/releases/download/v${KLUCTL_VERSION}/kluctl_v${KLUCTL_VERSION}_checksums.txt" | grep 'linux_amd64.tar.gz' | awk '{print $1}')"
KLUCTL_ARM64="$(curl -fsSL "https://github.com/kluctl/kluctl/releases/download/v${KLUCTL_VERSION}/kluctl_v${KLUCTL_VERSION}_checksums.txt" | grep 'linux_arm64.tar.gz' | awk '{print $1}')"

echo "Updating $MELANGE_YAML ..."

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
