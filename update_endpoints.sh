#!/bin/bash
set -e

REPO_DIR="/home/ubuntu/work/infra_scripts"
MD_FILE="README.md"
CRONICLE_CONF="$REPO_DIR/cronicle/conf/config.json"
CRONICLE_CONTAINER="cronicle"

TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

IP=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/public-ipv4)

if [ -z "$IP" ]; then
  echo "ERROR: Public IP not found"
  exit 1
fi

cd "$REPO_DIR"

cat <<EOF > $MD_FILE
# EC2 Service Endpoints

## Cronicle
http://${IP}:3012

## Selenium (noVNC)
http://${IP}:7900

## Flask API
http://${IP}:5002
EOF

jq --arg url "http://${IP}:3012" '
  .base_app_url = $url
  | .custom_live_log_socket_url = $url
  | .server_comm_use_hostnames = false
  | .web_socket_use_hostnames = false
' "$CRONICLE_CONF" > "${CRONICLE_CONF}.tmp"

mv "${CRONICLE_CONF}.tmp" "$CRONICLE_CONF"

git config user.email "ec2@infra.local"
git config user.name "EC2 Bootstrap"

git add $MD_FILE
git diff --cached --quiet || git commit -m "Update service endpoints (${IP})"
git push origin main


docker restart "$CRONICLE_CONTAINER"
