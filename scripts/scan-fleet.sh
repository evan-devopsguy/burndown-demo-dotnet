#!/usr/bin/env bash
# Build every service image and scan each one two ways, then print the fleet
# report: the manifest view (the wall of findings) next to the shipped-DLL view
# (the one service that is actually vulnerable).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${REPO_ROOT}"

SERVICES=(Payments Orders Inventory Shipping Notifications Customers Pricing Reporting Ledger)

for NAME in "${SERVICES[@]}"; do
  LOWER="$(echo "${NAME}" | tr '[:upper:]' '[:lower:]')"
  IMAGE="contoso-${LOWER}-api:demo"
  echo "[build] ${IMAGE} (CI-style validation build; the SDK only exists inside the build container)"
  docker build -q -f "src/Contoso.${NAME}.Api/Dockerfile" -t "${IMAGE}" . > /dev/null
  ./scripts/scan-image.sh "${IMAGE}"
done

python3 ./scripts/fleet_report.py scan-results
