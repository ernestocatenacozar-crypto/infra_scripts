#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
ENV_FILE="${REPO_ROOT}/.env"

if [ ! -f "${ENV_FILE}" ]; then
  echo "No existe el archivo .env: ${ENV_FILE}" >&2
  exit 1
fi

set -a
. "${ENV_FILE}"
set +a

# Edita estas URLs SSH segun tu org o usuario de GitHub.
REPO_CLONES=(
  "git@github.com:ernestocatenacozar-crypto/fisgon.git|${HOST_FISGON_PATH}"
  "git@github.com:ernestocatenacozar-crypto/refinement_portal.git|${HOST_REFINEMENT_PORTAL_PATH}"
  "git@github.com:ernestocatenacozar-crypto/frontend_build_orbitando.git|${HOST_FRONTEND_PATH}"
  "git@github.com:ernestocatenacozar-crypto/infra_scripts.git|${HOST_INFRA_PATH}"
)

for repo_clone in "${REPO_CLONES[@]}"; do
  ssh_repo="${repo_clone%%|*}"
  target_path="${repo_clone#*|}"

  if [ -z "${ssh_repo}" ] || [ -z "${target_path}" ]; then
    echo "Entrada invalida en REPO_CLONES: ${repo_clone}" >&2
    exit 1
  fi

  if [ -e "${target_path}" ]; then
    echo "Saltando ${ssh_repo}: ya existe ${target_path}"
    continue
  fi

  mkdir -p "$(dirname "${target_path}")"
  echo "Clonando ${ssh_repo} en ${target_path}"
  git clone "${ssh_repo}" "${target_path}"
done

echo "Clonado de repos completado."
