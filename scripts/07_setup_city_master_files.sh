#!/usr/bin/env sh

set -eu

if [ "$#" -ne 2 ]; then
    echo "Parametros invalidos." >&2
    echo "Uso: $0 <path_base> <ciudad>" >&2
    echo "Recibidos ($#): $*" >&2
    exit 1
fi

BASE_PATH=$1
CITY=$2
MASTER_DIR="${BASE_PATH%/}/${CITY}/00_master"

mkdir -p "$MASTER_DIR"

printf '%s\n' '[]' > "$MASTER_DIR/master_events.json"

cat <<'EOF' > "$MASTER_DIR/master_url.json"
{
  "extracted_url": []
}
EOF

cat <<'EOF' > "$MASTER_DIR/normalized_places.json"
{
  "geo_areas": [],
  "locations": []
}
EOF

cat <<'EOF' > "$MASTER_DIR/master_avoid_word.json"
{
  "words_to_avoid": [],
  "ignored_event_ids": []
}
EOF

echo "Carpeta creada y JSON reiniciados en: $MASTER_DIR"
