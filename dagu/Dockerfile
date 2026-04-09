FROM debian:bookworm-slim

ENV DAGU_VERSION=2.4.3
ENV DAGU_HOME=/var/lib/dagu

# Create dagu user and group
RUN groupadd -r dagu && useradd -r -g dagu -d ${DAGU_HOME} -s /bin/sh dagu

# Install dependencies + docker CLI, align docker group GID with host (988)
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       curl ca-certificates docker.io \
  && rm -rf /var/lib/apt/lists/* \
  && if getent group docker >/dev/null; then groupmod -g 988 docker; else groupadd -g 988 docker; fi \
  && usermod -aG docker dagu

# Download and install dagu binary
RUN curl -fsSL "https://github.com/dagu-org/dagu/releases/download/v${DAGU_VERSION}/dagu_${DAGU_VERSION}_linux_amd64.tar.gz" \
    | tar -xz -C /usr/local/bin dagu \
  && chmod +x /usr/local/bin/dagu

# Create data directories
RUN mkdir -p \
      ${DAGU_HOME}/dags \
      ${DAGU_HOME}/configs \
      ${DAGU_HOME}/data \
      ${DAGU_HOME}/logs \
      ${DAGU_HOME}/suspend \
  && chown -R dagu:dagu ${DAGU_HOME}

EXPOSE 6806

# Run as root so the entrypoint can write to host-mounted volumes
USER root

ENTRYPOINT ["/usr/local/bin/dagu"]
CMD ["start-all"]
