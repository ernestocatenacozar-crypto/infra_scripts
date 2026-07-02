FROM debian:bookworm-slim

ENV DAGU_VERSION=2.8.3
ENV DOCKER_CLI_VERSION=29.1.3
ENV DAGU_HOME=/var/lib/dagu

RUN groupadd -r dagu && useradd -r -g dagu -d ${DAGU_HOME} -s /bin/sh dagu

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
       curl ca-certificates \
  && rm -rf /var/lib/apt/lists/* \
  && if getent group docker >/dev/null; then groupmod -g 988 docker; else groupadd -g 988 docker; fi \
  && usermod -aG docker dagu

RUN curl -fsSL "https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_CLI_VERSION}.tgz" \
    | tar -xz --strip-components=1 -C /usr/local/bin docker/docker \
  && chmod +x /usr/local/bin/docker

RUN curl -fsSL "https://github.com/dagu-org/dagu/releases/download/v${DAGU_VERSION}/dagu_${DAGU_VERSION}_linux_amd64.tar.gz" \
    | tar -xz -C /usr/local/bin dagu \
  && chmod +x /usr/local/bin/dagu

RUN mkdir -p \
      ${DAGU_HOME}/dags \
      ${DAGU_HOME}/configs \
      ${DAGU_HOME}/data \
      ${DAGU_HOME}/logs \
      ${DAGU_HOME}/suspend \
  && chown -R dagu:dagu ${DAGU_HOME}

EXPOSE 6806

USER root

ENTRYPOINT ["/usr/local/bin/dagu"]
CMD ["start-all"]
