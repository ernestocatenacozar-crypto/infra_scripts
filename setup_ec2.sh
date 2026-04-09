#!/bin/bash
set -e

echo "========================================="
echo "  1. ACTUALIZANDO SISTEMA"
echo "========================================="
sudo apt update && sudo apt upgrade -y

echo "========================================="
echo "  2. INSTALANDO DOCKER"
echo "========================================="
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Añadir usuario al grupo docker
sudo usermod -aG docker $USER

echo "========================================="
echo "  3. GENERANDO SSH KEY PARA GITHUB"
echo "========================================="
SSH_KEY="$HOME/.ssh/id_ed25519"

if [ -f "$SSH_KEY" ]; then
    echo "Ya existe una clave SSH en $SSH_KEY, saltando..."
else
    ssh-keygen -t ed25519 -C "ernestocatenacozar@gmail.com" -f "$SSH_KEY" -N ""
    echo ""
    echo "Clave generada. Añádela en GitHub -> Settings -> SSH Keys:"
    echo ""
    cat "${SSH_KEY}.pub"
fi

echo ""
echo "========================================="
echo "  INSTALANDO GIT"
echo "========================================="
sudo apt install -y git

echo ""
echo "========================================="
echo "  VERIFICACIÓN"
echo "========================================="
echo "Docker: $(docker --version)"
echo "Docker Compose: $(docker compose version)"
echo "Git: $(git --version)"
echo ""
echo "IMPORTANTE: Cierra sesión y vuelve a entrar para que el grupo docker aplique."
echo "Luego verifica GitHub con: ssh -T git@github.com"

git config --global user.name "Ernesto Catena"
git config --global user.email "ernestocatenacozar@gmail.com"

sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab