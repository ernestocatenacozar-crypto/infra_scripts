# Guia De Instalacion En EC2

Esta guia resume el despliegue del stack en una EC2 nueva y el mapeo de puertos que hay que reflejar tanto en `docker-compose.yml` como en el Security Group de AWS.

## Orden recomendado

1. Crear la EC2.
2. Crear o asignar un Security Group con las reglas de entrada necesarias.
3. Conectarse por SSH a la maquina.
4. Clonar este repo y los repos dependientes.
5. Ejecutar los scripts de setup dentro de la EC2.
6. Construir imagenes y levantar `docker compose`.
7. Verificar que los endpoints externos responden.

## Security Group

Crea un Security Group dedicado para la instancia, por ejemplo `orbitando-ec2`, y configura las reglas de entrada asi:

| Name | Version de IP | Tipo | Protocolo | Intervalo de puertos | Origen | Descripcion |
| --- | --- | --- | --- | --- | --- | --- |
| `-` | `IPv4` | `TCP personalizado` | `TCP` | `5002` | `0.0.0.0/0` | `FlaskRefinement` |
| `-` | `IPv4` | `TCP personalizado` | `TCP` | `3012` | `0.0.0.0/0` | `Dagu` |
| `-` | `IPv4` | `SSH` | `TCP` | `22` | `0.0.0.0/0` | `SSH access` |
| `-` | `IPv4` | `TCP personalizado` | `TCP` | `7900` | `0.0.0.0/0` | `Selenium` |
| `-` | `IPv4` | `TCP personalizado` | `TCP` | `5000` | `0.0.0.0/0` | `FlaskFront` |

Captura de reglas de entrada:

![Reglas de entrada del Security Group](./images/security_group_inbound.png)

Captura de reglas de salida:

![Reglas de salida del Security Group](./images/security_group_outbound.png)

Notas:

- Esta tabla refleja literalmente la configuracion de tu captura y sirve como checklist de lo que tienes que meter en AWS.
- Evita `0.0.0.0/0` en `22`, `7900` y `3012` salvo que sea imprescindible.
- Si vas a usar Selenium remoto por WebDriver desde fuera de la EC2, tendras que abrir tambien el puerto `4444/TCP`.
- El puerto externo de Dagu depende de `DAGU_HOST_PORT` en `.env`. En `.env.example` aparece `3013`, pero en tu despliegue actual la referencia visible es `3012`. El Security Group y `.env` tienen que usar el mismo valor.

## Mapeo de puertos del stack

Este es el mapeo relevante del `docker-compose.yml`:

| Servicio | Puerto externo | Puerto interno | Variable |
| --- | --- | --- | --- |
| `frontend` | `5000` | `5000` | `FRONTEND_PORT` |
| `refinement_portal` | `5002` | `5002` | `REFINEMENT_PORTAL_PORT` |
| `dagu` | `3012` o `3013` | `6806` | `DAGU_HOST_PORT` |
| `selenium` | `7900` | `7900` | `SELENIUM_VNC_PORT` |
| `selenium` | `4444` | `4444` | `SELENIUM_PORT` |

Si quieres reproducir exactamente el mapeo de la captura, revisa `.env` para que incluya:

```env
FRONTEND_PORT=5000
REFINEMENT_PORTAL_PORT=5002
SELENIUM_VNC_PORT=7900
DAGU_HOST_PORT=3012
```

## Pasos dentro de la EC2

Suponiendo Ubuntu o Debian:

```bash
cp .env.example .env
./scripts/01_setup_docker.sh
./scripts/03_setup_github_ssh.sh
```

Despues:

1. Anade la clave publica generada en GitHub.
2. Verifica la conexion SSH con GitHub:

```bash
ssh -T git@github.com
```

3. Clona los repos dependientes del stack:

```bash
./scripts/04_setup_git_repos.sh
```

4. Ajusta `WORKSPACE_ROOT` y valida rutas:

```bash
./scripts/05_setup_paths.sh /ruta/al/workspace
```

5. Si necesitas swap:

```bash
SETUP_SWAP_SIZE=2G ./scripts/02_setup_swap.sh
```

6. Construye imagenes:

```bash
./scripts/06_setup_docker_images.sh
```

7. Levanta los servicios:

```bash
docker compose up -d
```

## Checklist final

- `.env` existe y tiene los puertos correctos.
- El Security Group expone exactamente los mismos puertos externos.
- Los repos montados en `HOST_*` existen en la EC2.
- `docker compose up -d` termina sin errores.
- Los endpoints responden desde fuera.

## Endpoints de ejemplo

Sustituye `TU_IP_O_DNS` por la IP publica o DNS de la instancia:

- Frontend: `http://TU_IP_O_DNS:5000`
- Refinement Portal: `http://TU_IP_O_DNS:5002`
- Dagu: `http://TU_IP_O_DNS:3012`
- Selenium noVNC: `http://TU_IP_O_DNS:7900`
