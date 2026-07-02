# Infra Scripts

Este repo orquesta la infraestructura del proyecto alrededor de `dagu`, `docker compose` y varios repos externos que contienen la aplicacion y sus `Dockerfile`.

## Objetivo

- Poder levantar un entorno local minimo sin rutas hardcodeadas de EC2.
- Mantener el despliegue actual de cloud parametrizado en vez de acoplado a `/home/ubuntu/...`.
- Reducir sorpresas: configuracion en `.env`, scripts idempotentes y checks previos de rutas.

## Estructura

- `docker-compose.yml`: stack principal, ahora parametrizado por variables de entorno.
- `images/`: Dockerfiles centralizados de `dagu`, `refinement_portal`, `fisgon_scraper` y `frontend`.
- `dagu/dags`: workflows de Dagu, usando rutas del host inyectadas por entorno.
- `scripts/04_setup_git_repos.sh`: clona los repos necesarios usando las rutas definidas en `.env`.
- `scripts/05_setup_paths.sh`: actualiza `WORKSPACE_ROOT` en `.env` y valida que las rutas apuntan a repos reales.
- `scripts/06_setup_docker_images.sh`: construye las imagenes desde los Dockerfiles de este repo.
- `docs/ec2_install.md`: guia de despliegue en EC2 con puertos y Security Groups.
- `endpoints.md`: endpoints publicados en EC2.

## Setup local

```bash
cp .env.example .env
./scripts/04_setup_git_repos.sh
# ajustar WORKSPACE_ROOT a la raiz donde viven los repos
./scripts/05_setup_paths.sh /ruta/a/tu/workspace
./scripts/06_setup_docker_images.sh
docker compose up -d
```

## Bootstrap maquina nueva

Antes de levantar el stack en otra maquina necesitas Docker, `docker compose` y Git.

```bash
./scripts/01_setup_docker.sh
```

Si tambien quieres preparar swap en esa maquina, hazlo aparte:

```bash
SETUP_SWAP_SIZE=2G ./scripts/02_setup_swap.sh
```

Tambien se mantienen `SWAP_SIZE` y `BOOTSTRAP_SWAP_SIZE` por compatibilidad con comandos antiguos.

Si la EC2 va a clonar repos privados por SSH, prepara antes la clave de GitHub:

```bash
./scripts/03_setup_github_ssh.sh
```

El script genera una clave `ed25519`, registra `github.com` en `known_hosts` y te imprime la clave publica para pegarla en GitHub.

El despliegue no necesita autodeteccion. Solo necesita que `.env` contenga los paths correctos de los repos.

Si todos los repos viven bajo una misma raiz, `scripts/05_setup_paths.sh` te actualiza `WORKSPACE_ROOT` en `.env` y luego valida los `HOST_*` derivados.

## Como funciona el build

Los `Dockerfile` viven en `images/`, pero el build usa directamente los paths definidos en `.env` como contexto de Docker. Asi este repo controla la capa de infraestructura sin copiar codigo a directorios temporales.

## Siguiente paso recomendable

El siguiente salto natural es dejar de depender de clones externos por ruta y traer esos `Dockerfile` aqui o convertirlos en imagenes versionadas. No lo he forzado en esta iteracion para no mezclar estandarizacion con una reestructuracion mayor.
