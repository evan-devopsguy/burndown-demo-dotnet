#!/usr/bin/env bash
# Scan one built image two ways:
#   1. manifest view  — syft configured to trust *.deps.json blindly, then grype
#      (what a manifest-believing scanner reports)
#   2. shipped view   — trivy with default settings, which only reports packages
#      the manifest's targets section records as actually deployed
#      (what really ships in the image)
# Results land in scan-results/<image>-manifest.json and <image>-shipped.json.
#
# All tools run as pinned containers; nothing is installed on the workstation.
set -euo pipefail

IMAGE="${1:?usage: scan-image.sh <image:tag>}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="${REPO_ROOT}/scan-results"
SAFE_NAME="$(echo "${IMAGE}" | tr '/:' '__')"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

SYFT_IMAGE="anchore/syft:v1.46.0"
GRYPE_IMAGE="anchore/grype:v0.115.0"
TRIVY_IMAGE="aquasec/trivy:0.72.0"

mkdir -p "${OUT_DIR}"

docker save "${IMAGE}" -o "${TMP_DIR}/image.tar"

echo "[scan] ${IMAGE}: manifest view (deps.json as gospel)"
docker run --rm \
  -v "${TMP_DIR}:/scan" \
  -v "${REPO_ROOT}/scanners:/scanners:ro" \
  -v syft-demo-cache:/.cache \
  "${SYFT_IMAGE}" -c /scanners/syft-manifest-trusting.yaml \
  docker-archive:/scan/image.tar -o json > "${TMP_DIR}/sbom.json" 2>/dev/null

docker run --rm \
  -v "${TMP_DIR}:/scan" \
  -v grype-demo-cache:/.cache \
  "${GRYPE_IMAGE}" sbom:/scan/sbom.json -o json 2>/dev/null \
  > "${OUT_DIR}/${SAFE_NAME}-manifest.json"

echo "[scan] ${IMAGE}: shipped view (only DLLs that are really there)"
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v trivy-demo-cache:/root/.cache \
  "${TRIVY_IMAGE}" image --scanners vuln --format json --quiet "${IMAGE}" \
  > "${OUT_DIR}/${SAFE_NAME}-shipped.json" 2>/dev/null

echo "[scan] ${IMAGE}: done"
