#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env"
TMP_DAGU_BUILD_CONTEXT="$(mktemp -d)"
trap 'rm -rf "${TMP_DAGU_BUILD_CONTEXT}"' EXIT

set -a
. "${ENV_FILE}"
set +a

FISGON_SCRAPER_IMAGE="${FISGON_SCRAPER_IMAGE:-fisgon_scraper:latest}"
DAGU_IMAGE="${DAGU_IMAGE:-infra_scripts-dagu:latest}"
REFINEMENT_PORTAL_IMAGE="${REFINEMENT_PORTAL_IMAGE:-refinement_portal:latest}"
FRONTEND_IMAGE="${FRONTEND_IMAGE:-orbitando_frontend:latest}"
FRONTEND_BUILD_IMAGE="${FRONTEND_BUILD_IMAGE:-orbitando_frontend_build:latest}"

docker build \
  -f "${REPO_ROOT}/images/dagu/Dockerfile" \
  -t "${DAGU_IMAGE}" \
  "${TMP_DAGU_BUILD_CONTEXT}"
docker build \
  -f "${REPO_ROOT}/images/refinement_portal/Dockerfile" \
  -t "${REFINEMENT_PORTAL_IMAGE}" \
  "${HOST_REFINEMENT_PORTAL_PATH}"
docker build \
  -f "${REPO_ROOT}/images/frontend/Dockerfile.dev" \
  -t "${FRONTEND_IMAGE}" \
  "${HOST_FRONTEND_PATH}"
docker build \
  -f "${REPO_ROOT}/images/frontend/Dockerfile.static" \
  -t "${FRONTEND_BUILD_IMAGE}" \
  "${HOST_FRONTEND_PATH}"
docker build \
  -f "${REPO_ROOT}/images/fisgon_scraper/Dockerfile" \
  -t "${FISGON_SCRAPER_IMAGE}" \
  "${HOST_FISGON_PATH}"

echo "Imagenes construidas:"
echo "  ${DAGU_IMAGE}"
echo "  ${REFINEMENT_PORTAL_IMAGE}"
echo "  ${FRONTEND_IMAGE}"
echo "  ${FRONTEND_BUILD_IMAGE}"
echo "  ${FISGON_SCRAPER_IMAGE}"
