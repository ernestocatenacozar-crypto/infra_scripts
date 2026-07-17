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

require_doppler() {
  if ! command -v doppler >/dev/null 2>&1; then
    echo "Doppler CLI no esta instalado. Ejecuta ./scripts/01_setup_docker_doppler.sh primero." >&2
    exit 1
  fi

  if ! doppler configure get token >/dev/null 2>&1; then
    echo "No hay token de Doppler configurado." >&2
    echo 'Configuralo antes de levantar compose:' >&2
    echo '  export DOPPLER_TOKEN="dp.st.xxxxx"' >&2
    echo '  doppler configure set token "$DOPPLER_TOKEN"' >&2
    exit 1
  fi
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

check_http_endpoint() {
  local service_name="$1"
  local url="$2"
  local expected_pattern="$3"
  local http_code=""

  http_code="$(curl -L -sS -o /dev/null -w "%{http_code}" "${url}" || true)"
  if printf '%s\n' "${http_code}" | grep -Eq "${expected_pattern}"; then
    printf '[OK] %s -> %s (%s)\n' "${service_name}" "${url}" "${http_code}"
    return 0
  fi

  printf '[FAIL] %s -> %s (codigo=%s)\n' "${service_name}" "${url}" "${http_code:-000}" >&2
  return 1
}

reset_stack() {
  log "1. PARANDO STACK"
  doppler run -- docker compose -f "${REPO_ROOT}/docker-compose.yml" down --remove-orphans
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
  doppler run -- docker compose -f "${REPO_ROOT}/docker-compose.yml" up -d
}

verify_exposed_endpoints() {
  local failures=0

  log "6. COMPROBANDO ENDPOINTS"

  check_http_endpoint "frontend" "http://localhost:${FRONTEND_PORT}/${ORBITA_CITY}/" '^200$' || failures=1
  check_http_endpoint "refinement_portal" "http://localhost:${REFINEMENT_PORTAL_PORT}/health" '^200$' || failures=1
  check_http_endpoint "dagu" "http://localhost:${DAGU_HOST_PORT}/" '^(200|301|302|303|307|308)$' || failures=1

  if [ "${failures}" -ne 0 ]; then
    echo "Uno o mas endpoints expuestos no han pasado la comprobacion." >&2
    return 1
  fi
}

print_summary() {
  log "7. RESET COMPLETADO"
  doppler run -- docker compose -f "${REPO_ROOT}/docker-compose.yml" ps
}

main() {
  require_doppler
  reset_stack
  reset_docker_state
  reset_storage
  rebuild_and_start
  verify_exposed_endpoints
  print_summary
}

main "$@"
