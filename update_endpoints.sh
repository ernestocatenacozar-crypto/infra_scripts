#!/bin/bash
set -e

REPO_DIR="/home/ubuntu/work/infra_scripts"
MD_FILE="endpoints.md"

IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

cd "$REPO_DIR"

# Crear archivo si no existe
if [ ! -f "$MD_FILE" ]; then
  cat <<EOF > $MD_FILE
Cronicle   IP:PORT
Selenium   IP:PORT
Flask      IP:PORT
EOF
fi

sed -i "s|^Cronicle.*|Cronicle   ${IP}:3012|" $MD_FILE
sed -i "s|^Selenium.*|Selenium   ${IP}:7900|" $MD_FILE
sed -i "s|^Flask.*|Flask      ${IP}:5002|" $MD_FILE

git config user.email "ec2@infra.local"
git config user.name "EC2 Bootstrap"

git add $MD_FILE

git diff --cached --quiet || git commit -m "Update service endpoints (${IP})"

git push origin main
