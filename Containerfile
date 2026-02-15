ARG RUNNER_VERSION=latest

FROM ghcr.io/actions/runner:${RUNNER_VERSION} as base

ARG APP_HOME=/home/runner

USER root

# Update and upgrade the system
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get autoremove -y \
    && apt-get autoclean -y

# Add Python 3.12, 3.13 and 3.14
# Add deadsnake apt repository
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install --no-install-recommends -y gnupg ca-certificates software-properties-common curl \
    && DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install --no-install-recommends -y python3.12 python3.13 python3.14 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install skopeo
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install --no-install-recommends -y skopeo \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Argo Workflows CLI
ARG ARGO_VERSION=3.6.4
RUN curl -sSL -o /tmp/argo-linux-amd64.gz \
      "https://github.com/argoproj/argo-workflows/releases/download/v${ARGO_VERSION}/argo-linux-amd64.gz" \
    && gunzip /tmp/argo-linux-amd64.gz \
    && mv /tmp/argo-linux-amd64 /usr/local/bin/argo \
    && chmod +x /usr/local/bin/argo

# Install HashiCorp Packer
ARG PACKER_VERSION=1.11.2
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install --no-install-recommends -y unzip \
    && curl -sSL -o /tmp/packer.zip \
      "https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip" \
    && unzip /tmp/packer.zip -d /usr/local/bin/ \
    && rm /tmp/packer.zip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install pack (Cloud Native Buildpacks CLI)
ARG PACK_VERSION=0.36.4
RUN curl -sSL -o /tmp/pack.tgz \
      "https://github.com/buildpacks/pack/releases/download/v${PACK_VERSION}/pack-v${PACK_VERSION}-linux.tgz" \
    && tar -xzf /tmp/pack.tgz -C /usr/local/bin/ \
    && rm /tmp/pack.tgz

# Install Poetry latest version and add it to PATH
# hadolint ignore=DL4006
RUN curl -sSL https://install.python-poetry.org | python3 -

# Install UV
# hadolint ignore=DL4006
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Add Poetry and UV to PATH
RUN echo "export PATH=\"${APP_HOME}/.local/bin:\$PATH\"" >> ~/.bashrc

FROM base as runtime

LABEL org.opencontainers.image.source=https://github.com/deerhide/python-github-runner
LABEL org.opencontainers.image.description="Python GitHub Runner"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.authors="Deerhide"
LABEL org.opencontainers.image.vendor="Deerhide"

USER runner
WORKDIR ${APP_HOME}

# Install Poetry latest version and add it to PATH
# hadolint ignore=DL4006
RUN curl -sSL https://install.python-poetry.org | python3 -

# Install UV
# hadolint ignore=DL4006
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Add Poetry and UV to PATH
RUN echo "export PATH=\"${APP_HOME}/.local/bin:\$PATH\"" >> ~/.bashrc

# Placeholder command to keep the container running
# CMD ["/bin/bash", "-c", "while true; do sleep 1; done"]
