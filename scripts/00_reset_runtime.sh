#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env"

if [ ! -f "${ENV_FILE}" ]; then
  echo "Falta ${ENV_FILE}. Crea o revisa tu .env antes de ejecutar este reset." >&2
  exit 1
fi

set -a
. "${ENV_FILE}"
set +a

FISGON_SCRAPER_IMAGE="${FISGON_SCRAPER_IMAGE:-fisgon_scraper:latest}"
DAGU_IMAGE="${DAGU_IMAGE:-infra_scripts-dagu:latest}"
REFINEMENT_PORTAL_IMAGE="${REFINEMENT_PORTAL_IMAGE:-refinement_portal:latest}"
FRONTEND_IMAGE="${FRONTEND_IMAGE:-orbitando_frontend:latest}"
FRONTEND_BUILD_IMAGE="${FRONTEND_BUILD_IMAGE:-orbitando_frontend_build:latest}"
FRONTEND_NODE_MODULES_VOLUME="${FRONTEND_NODE_MODULES_VOLUME:-orbitando_frontend_node_modules}"

log() {
  printf '\n=========================================\n'
  printf '  %s\n' "$1"
  printf '=========================================\n'
}

clear_dir() {
  local target_dir="$1"

  if ! mkdir -p "${target_dir}" 2>/dev/null; then
    sudo mkdir -p "${target_dir}"
  fi

  if ! find "${target_dir}" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null; then
    sudo find "${target_dir}" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
  fi
}

remove_image_if_present() {
  local image_name="$1"

  if docker image inspect "${image_name}" >/dev/null 2>&1; then
    docker image rm "${image_name}"
  else
    echo "Imagen no presente, se omite: ${image_name}"
  fi
}

reset_stack() {
  log "1. PARANDO STACK"
  docker compose -f "${REPO_ROOT}/docker-compose.yml" down --remove-orphans
}

reset_docker_state() {
  log "2. LIMPIANDO VOLUMENES E IMAGENES"
  docker volume rm "${FRONTEND_NODE_MODULES_VOLUME}" >/dev/null 2>&1 || true

  remove_image_if_present "${FISGON_SCRAPER_IMAGE}"
  remove_image_if_present "${REFINEMENT_PORTAL_IMAGE}"
  remove_image_if_present "${FRONTEND_IMAGE}"
  remove_image_if_present "${FRONTEND_BUILD_IMAGE}"
  remove_image_if_present "${DAGU_IMAGE}"
}

reset_storage() {
  log "3. LIMPIANDO STORAGE Y ARTEFACTOS"
  clear_dir "${HOST_DATA_STORAGE_PATH}"
  clear_dir "${REPO_ROOT}/dagu/data"
  clear_dir "${REPO_ROOT}/dagu/logs"
  clear_dir "${REPO_ROOT}/dagu/suspend"
  clear_dir "${HOST_FRONTEND_DIST_PATH}"
}

rebuild_and_start() {
  log "4. RECONSTRUYENDO IMAGENES"
  "${REPO_ROOT}/scripts/06_setup_docker_images.sh"

  log "5. LEVANTANDO STACK"
  docker compose -f "${REPO_ROOT}/docker-compose.yml" up -d
}

print_summary() {
  log "6. RESET COMPLETADO"
  docker compose -f "${REPO_ROOT}/docker-compose.yml" ps
}

main() {
  reset_stack
  reset_docker_state
  reset_storage
  rebuild_and_start
  print_summary
}

main "$@"
