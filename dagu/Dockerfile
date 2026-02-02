FROM ghcr.io/dagu-org/dagu:latest

USER root

# Install docker CLI for running ephemeral containers from DAG steps.
RUN apt-get update \
  && apt-get install -y --no-install-recommends docker.io \
  && rm -rf /var/lib/apt/lists/*

USER dagu
