#!/usr/bin/env bash
set -euo pipefail

TARGET_USER="${SUDO_USER:-${USER}}"
TARGET_HOME="$(eval echo "~${TARGET_USER}")"

log() {
  printf '\n=========================================\n'
  printf '  %s\n' "$1"
  printf '=========================================\n'
}

require_apt() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "Este script solo soporta hosts basados en apt (Ubuntu/Debian)." >&2
    exit 1
  fi
}

install_base_packages() {
  log "1. INSTALANDO PAQUETES BASE"
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg git
}

install_docker_repo() {
  log "2. CONFIGURANDO REPOSITORIO DE DOCKER"
  sudo install -m 0755 -d /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    local distro_id
    distro_id="$(. /etc/os-release && echo "${ID}")"
    if [ "${distro_id}" != "ubuntu" ] && [ "${distro_id}" != "debian" ]; then
      echo "Distro no soportada para instalar Docker automaticamente: ${distro_id}" >&2
      exit 1
    fi

    curl -fsSL "https://download.docker.com/linux/${distro_id}/gpg" \
      | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  fi
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  local codename architecture repo_line distro_id
  distro_id="$(. /etc/os-release && echo "${ID}")"
  codename="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
  architecture="$(dpkg --print-architecture)"
  repo_line="deb [arch=${architecture} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${distro_id} ${codename} stable"

  echo "${repo_line}" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
}

install_docker_packages() {
  log "3. INSTALANDO DOCKER Y COMPOSE"
  sudo apt-get update
  sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

  sudo systemctl enable --now docker
  sudo usermod -aG docker "${TARGET_USER}"
}

print_summary() {
  log "4. VERIFICACION"
  echo "Docker: $(docker --version)"
  echo "Docker Compose: $(docker compose version)"
  echo "Git: $(git --version)"
  echo
  echo "Usuario objetivo para el grupo docker: ${TARGET_USER}"
  echo "Home detectado: ${TARGET_HOME}"
  echo
  echo "Siguiente paso:"
  echo "  1. Cierra sesion y vuelve a entrar para aplicar el grupo docker."
  echo "  2. Si necesitas swap: SETUP_SWAP_SIZE=2G ./scripts/02_setup_swap.sh"
  echo "  3. Clona los repos en las rutas que pondras en .env."
  echo "  4. Ejecuta ./scripts/04_setup_git_repos.sh, ./scripts/05_setup_paths.sh <workspace_root> y ./scripts/06_setup_docker_images.sh."
}

main() {
  require_apt
  install_base_packages
  install_docker_repo
  install_docker_packages
  print_summary
}

main "$@"
