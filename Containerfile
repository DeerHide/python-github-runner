ARG UBUNTU_VERSION=24.04

FROM docker.io/library/ubuntu:$UBUNTU_VERSION as base

ARG APP_UID=1000
ARG APP_HOME=/home/appuser

# Setup the non-root user
RUN userdel --remove ubuntu \
    && useradd \
      --no-log-init \
      --uid $APP_UID \
      --home-dir ${APP_HOME} \
      --create-home \
      --user-group \
      appuser && \
    chown -R appuser:appuser ${APP_HOME}

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

USER ${APP_UID}
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
