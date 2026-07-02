#!/usr/bin/env bash
set -euo pipefail

# Este script prepara una clave SSH para GitHub en una maquina nueva.
# Hace tres cosas:
#   1. Genera una clave ed25519 si aun no existe.
#   2. Registra github.com en known_hosts para evitar el prompt inicial.
#   3. Muestra la clave publica y los siguientes pasos para anadirla a GitHub.

KEY_PATH="${GITHUB_SSH_KEY_PATH:-${HOME}/.ssh/id_ed25519}"
KEY_COMMENT="${GITHUB_SSH_COMMENT:-ec2-github-$(hostname)}"
KNOWN_HOSTS_FILE="${HOME}/.ssh/known_hosts"

log() {
  printf '\n=========================================\n'
  printf '  %s\n' "$1"
  printf '=========================================\n'
}

ensure_ssh_dir() {
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"
}

generate_key_if_missing() {
  log "1. PREPARANDO CLAVE SSH"

  if [ -f "${KEY_PATH}" ]; then
    echo "La clave ya existe en ${KEY_PATH}. Se reutilizara."
    return
  fi

  ssh-keygen -t ed25519 -C "${KEY_COMMENT}" -f "${KEY_PATH}" -N ""
  echo "Clave creada en ${KEY_PATH}"
}

trust_github_host() {
  log "2. REGISTRANDO GITHUB EN KNOWN_HOSTS"

  touch "${KNOWN_HOSTS_FILE}"
  chmod 600 "${KNOWN_HOSTS_FILE}"

  if ssh-keygen -F github.com -f "${KNOWN_HOSTS_FILE}" >/dev/null 2>&1; then
    echo "github.com ya estaba presente en ${KNOWN_HOSTS_FILE}"
    return
  fi

  ssh-keyscan -H github.com >> "${KNOWN_HOSTS_FILE}" 2>/dev/null
  echo "Huella de github.com anadida a ${KNOWN_HOSTS_FILE}"
}

print_next_steps() {
  log "3. COPIA ESTA CLAVE PUBLICA EN GITHUB"
  cat "${KEY_PATH}.pub"
  echo
  echo "Pegala en GitHub > Settings > SSH and GPG keys > New SSH key"
  echo
  echo "Cuando la hayas anadido, prueba la conexion con:"
  echo "  ssh -T git@github.com"
  echo
  echo "Y para clonar un repo privado usa la URL SSH:"
  echo "  git clone git@github.com:ORG_O_USUARIO/NOMBRE_REPO.git"
}

main() {
  ensure_ssh_dir
  generate_key_if_missing
  trust_github_host
  print_next_steps
}

main "$@"
