#!/usr/bin/env sh

set -eu

if [ "$#" -ne 2 ]; then
    echo "Parametros invalidos." >&2
    echo "Uso: $0 <path_base> <ciudad>" >&2
    echo "Recibidos ($#): $*" >&2
    exit 1
fi

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname "$0")" && pwd)
REPO_ROOT=$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)
ENV_FILE="${REPO_ROOT}/.env"

BASE_PATH=$1
CITY=$2
CITY_SLUG=$(printf '%s' "$CITY" | tr '[:upper:]' '[:lower:]')
MASTER_DIR="${BASE_PATH%/}/${CITY}/00_master"

if [ -f "${ENV_FILE}" ]; then
    set -a
    . "${ENV_FILE}"
    set +a
fi

resolve_frontend_data_dir() {
    if [ -n "${HOST_FRONTEND_PATH:-}" ]; then
        if [ -d "${HOST_FRONTEND_PATH}/data/${CITY}" ]; then
            printf '%s\n' "${HOST_FRONTEND_PATH}/data/${CITY}"
            return 0
        fi

        if [ -d "${HOST_FRONTEND_PATH}/data/${CITY_SLUG}" ]; then
            printf '%s\n' "${HOST_FRONTEND_PATH}/data/${CITY_SLUG}"
            return 0
        fi
    fi

    WORKSPACE_ROOT_FALLBACK=$(dirname "${REPO_ROOT}")
    if [ -d "${WORKSPACE_ROOT_FALLBACK}/frontend_build_orbitando/data/${CITY}" ]; then
        printf '%s\n' "${WORKSPACE_ROOT_FALLBACK}/frontend_build_orbitando/data/${CITY}"
        return 0
    fi

    if [ -d "${WORKSPACE_ROOT_FALLBACK}/frontend_build_orbitando/data/${CITY_SLUG}" ]; then
        printf '%s\n' "${WORKSPACE_ROOT_FALLBACK}/frontend_build_orbitando/data/${CITY_SLUG}"
        return 0
    fi

    return 1
}

write_default_master_url() {
    cat <<'EOF' > "$MASTER_DIR/master_url.json"
{
  "extracted_url": []
}
EOF
}

write_default_normalized_places() {
    cat <<'EOF' > "$MASTER_DIR/normalized_places.json"
{
  "geo_areas": [],
  "locations": []
}
EOF
}

write_default_master_avoid_word() {
    cat <<'EOF' > "$MASTER_DIR/master_avoid_word.json"
{
  "words_to_avoid": [],
  "ignored_event_ids": []
}
EOF
}

copy_or_default() {
    file_name="$1"
    default_writer="$2"
    source_dir="${3:-}"

    if [ -n "${source_dir}" ] && [ -f "${source_dir}/${file_name}" ]; then
        cp "${source_dir}/${file_name}" "${MASTER_DIR}/${file_name}"
        echo "Copiado desde frontend: ${source_dir}/${file_name}"
        return 0
    fi

    "${default_writer}"
    echo "Creado default: ${MASTER_DIR}/${file_name}"
}

mkdir -p "$MASTER_DIR"

printf '%s\n' '[]' > "$MASTER_DIR/master_events.json"

FRONTEND_DATA_DIR=""
if FRONTEND_DATA_DIR=$(resolve_frontend_data_dir); then
    echo "Usando datos de frontend en: ${FRONTEND_DATA_DIR}"
fi

copy_or_default "master_url.json" "write_default_master_url" "${FRONTEND_DATA_DIR}"
copy_or_default "normalized_places.json" "write_default_normalized_places" "${FRONTEND_DATA_DIR}"
copy_or_default "master_avoid_word.json" "write_default_master_avoid_word" "${FRONTEND_DATA_DIR}"

echo "Carpeta creada y JSON preparados en: $MASTER_DIR"
