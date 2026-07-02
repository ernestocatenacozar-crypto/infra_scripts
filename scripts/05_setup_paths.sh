#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env"
ENV_EXAMPLE_FILE="${REPO_ROOT}/.env.example"

if [ "$#" -ne 1 ]; then
  echo "Parametros invalidos." >&2
  echo "Uso: $0 <workspace_root>" >&2
  echo "Recibidos ($#): $*" >&2
  exit 1
fi

WORKSPACE_ROOT_INPUT="$1"

if [ ! -f "${ENV_FILE}" ]; then
  echo "Falta ${ENV_FILE}. Crea el archivo a partir de .env.example y rellena los paths de los repos."
  exit 1
fi

if [ ! -d "${WORKSPACE_ROOT_INPUT}" ]; then
  echo "WORKSPACE_ROOT invalido: ${WORKSPACE_ROOT_INPUT}" >&2
  exit 1
fi

update_workspace_root() {
  local tmp_file
  tmp_file="$(mktemp)"

  awk -v new_value="${WORKSPACE_ROOT_INPUT}" '
    BEGIN { updated=0 }
    /^WORKSPACE_ROOT=/ {
      print "WORKSPACE_ROOT=" new_value
      updated=1
      next
    }
    { print }
    END {
      if (!updated) {
        print "WORKSPACE_ROOT=" new_value
      }
    }
  ' "${ENV_FILE}" > "${tmp_file}"

  mv "${tmp_file}" "${ENV_FILE}"
}

print_workspace_summary() {
  echo "WORKSPACE_ROOT actualizado en ${ENV_FILE}: ${WORKSPACE_ROOT_INPUT}"
  if [ -f "${ENV_EXAMPLE_FILE}" ]; then
    echo "Referencia base: ${ENV_EXAMPLE_FILE}"
  fi
}

update_workspace_root

set -a
. "${ENV_FILE}"
set +a

required_dirs=(
  "HOST_FISGON_PATH"
  "HOST_REFINEMENT_PORTAL_PATH"
  "HOST_FRONTEND_PATH"
  "HOST_DATA_STORAGE_PATH"
)

missing=0

for var_name in "${required_dirs[@]}"; do
  value="${!var_name:-}"
  if [ -z "${value}" ] || [ ! -d "${value}" ]; then
    echo "Ruta invalida en ${var_name}: ${value:-<vacia>}"
    missing=1
  fi
done

mkdir -p \
  "${REPO_ROOT}/dagu/configs" \
  "${REPO_ROOT}/dagu/logs" \
  "${REPO_ROOT}/dagu/suspend" \
  "${HOST_DATA_STORAGE_PATH}"

if [ "${missing}" -ne 0 ]; then
  echo "Configuracion incompleta. Corrige .env antes de levantar Docker."
  exit 1
fi

print_workspace_summary
echo "Rutas OK. El stack deberia poder resolver los bind mounts."
