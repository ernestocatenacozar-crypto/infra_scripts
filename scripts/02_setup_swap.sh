#!/usr/bin/env bash
set -euo pipefail

# Este script crea y activa un swapfile persistente en /swapfile.
# Uso:
#   SWAP_SIZE=2G ./scripts/02_setup_swap.sh
# Tambien admite SETUP_SWAP_SIZE por claridad y BOOTSTRAP_SWAP_SIZE por compatibilidad.

SWAP_SIZE="${SETUP_SWAP_SIZE:-${SWAP_SIZE:-${BOOTSTRAP_SWAP_SIZE:-}}}"

log() {
  printf '\n=========================================\n'
  printf '  %s\n' "$1"
  printf '=========================================\n'
}

require_swap_size() {
  if [ -z "${SWAP_SIZE}" ]; then
    echo "Debes indicar el tamano del swap con SETUP_SWAP_SIZE o SWAP_SIZE, por ejemplo: SETUP_SWAP_SIZE=2G ./scripts/02_setup_swap.sh" >&2
    exit 1
  fi
}

configure_swap() {
  log "1. CONFIGURANDO SWAP (${SWAP_SIZE})"

  if sudo swapon --show | awk 'NR>1 {print $1}' | grep -qx "/swapfile"; then
    echo "Swapfile ya activo en /swapfile, saltando."
    return
  fi

  if [ -f /swapfile ]; then
    echo "Existe /swapfile pero no esta activo. Se reutilizara."
  else
    sudo fallocate -l "${SWAP_SIZE}" /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
  fi

  sudo swapon /swapfile
  if ! grep -q '^/swapfile ' /etc/fstab; then
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
  fi
}

print_summary() {
  log "2. VERIFICACION"
  sudo swapon --show
}

main() {
  require_swap_size
  configure_swap
  print_summary
}

main "$@"
