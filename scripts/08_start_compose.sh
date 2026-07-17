#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env"

log() {
  printf '\n=========================================\n'
  printf '  %s\n' "$1"
  printf '=========================================\n'
}

require_env_file() {
  if [ ! -f "${ENV_FILE}" ]; then
    echo "Falta ${ENV_FILE}. Crea el archivo con las variables no secret antes de levantar el stack." >&2
    exit 1
  fi
}

require_doppler() {
  if ! command -v doppler >/dev/null 2>&1; then
    echo "Doppler CLI no esta instalado. Ejecuta ./scripts/01_setup_docker_doppler.sh primero." >&2
    exit 1
  fi
}

check_doppler_token() {
  log "1. VERIFICANDO DOPPLER"

  if doppler configure get token >/dev/null 2>&1; then
    echo "Token de Doppler configurado."
    return
  fi

  echo "No hay token de Doppler configurado." >&2
  echo 'Configuralo antes de levantar el stack:' >&2
  echo '  export DOPPLER_TOKEN="dp.st.xxxxx"' >&2
  echo '  doppler configure set token "$DOPPLER_TOKEN"' >&2
  exit 1
}

validate_compose() {
  log "2. VALIDANDO DOCKER COMPOSE"
  doppler run -- docker compose -f "${REPO_ROOT}/docker-compose.yml" config --quiet
}

start_stack() {
  log "3. LEVANTANDO STACK"
  doppler run -- docker compose -f "${REPO_ROOT}/docker-compose.yml" up -d
}

print_summary() {
  log "4. SERVICIOS"
  docker compose -f "${REPO_ROOT}/docker-compose.yml" ps
}

main() {
  require_env_file
  require_doppler
  check_doppler_token
  validate_compose
  start_stack
  print_summary
}

main "$@"
