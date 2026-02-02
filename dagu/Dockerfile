FROM ghcr.io/dagu-org/dagu:latest

USER root

# Install docker CLI for running ephemeral containers from DAG steps.
# Also align docker group id with host docker.sock group (typically 988).
RUN apt-get update \
  && apt-get install -y --no-install-recommends docker.io \
  && rm -rf /var/lib/apt/lists/* \
  && if getent group docker >/dev/null; then groupmod -g 988 docker; else groupadd -g 988 docker; fi \
  && usermod -aG docker dagu

# Leave user as root so entrypoint can manage users/groups.
