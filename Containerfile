ARG RUNNER_VERSION=2.321.0

FROM ghcr.io/actions/runner:${RUNNER_VERSION} as base

ARG APP_HOME=/home/runner

USER root

# System upgrade, Python 3.12/3.13 (deadsnakes), skopeo, buildah
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install --no-install-recommends -y gnupg ca-certificates software-properties-common curl \
    && DEBIAN_FRONTEND=noninteractive add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update \
    && apt-get install --no-install-recommends -y \
       python3.12 python3.13 \
       skopeo buildah \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure buildah storage for container/rootless usage
RUN mkdir -p /etc/containers \
    && printf '[storage]\ndriver = "vfs"\n' > /etc/containers/storage.conf

# Install trivy (vulnerability scanner)
# hadolint ignore=DL3008,DL4006
RUN curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key \
      | gpg --dearmor -o /usr/share/keyrings/trivy.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
      | tee /etc/apt/sources.list.d/trivy.list \
    && apt-get update \
    && apt-get install --no-install-recommends -y trivy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install dive (container filesystem analysis)
ARG DIVE_VERSION=0.12.0
# hadolint ignore=DL3008
RUN curl -sSL -o /tmp/dive.deb \
      "https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.deb" \
    && apt-get update \
    && apt-get install --no-install-recommends -y /tmp/dive.deb \
    && rm /tmp/dive.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install hadolint (Dockerfile/Containerfile linter)
ARG HADOLINT_VERSION=2.12.0
RUN curl -sSL -o /usr/local/bin/hadolint \
      "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64" \
    && chmod +x /usr/local/bin/hadolint

# Install yq (YAML processor)
ARG YQ_VERSION=4.45.4
RUN curl -sSL -o /usr/local/bin/yq \
      "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" \
    && chmod +x /usr/local/bin/yq

# Install Argo Workflows CLI
ARG ARGO_VERSION=3.6.4
RUN curl -sSL -o /tmp/argo-linux-amd64.gz \
      "https://github.com/argoproj/argo-workflows/releases/download/v${ARGO_VERSION}/argo-linux-amd64.gz" \
    && gunzip /tmp/argo-linux-amd64.gz \
    && mv /tmp/argo-linux-amd64 /usr/local/bin/argo \
    && chmod +x /usr/local/bin/argo

# Install Kargo CLI
ARG KARGO_VERSION=1.9.2
RUN curl -sSL -o /usr/local/bin/kargo \
      "https://github.com/akuity/kargo/releases/download/v${KARGO_VERSION}/kargo-linux-amd64" \
    && chmod +x /usr/local/bin/kargo

# Install pack (Cloud Native Buildpacks CLI)
ARG PACK_VERSION=0.36.4
RUN curl -sSL -o /tmp/pack.tgz \
      "https://github.com/buildpacks/pack/releases/download/v${PACK_VERSION}/pack-v${PACK_VERSION}-linux.tgz" \
    && tar -xzf /tmp/pack.tgz -C /usr/local/bin/ \
    && rm /tmp/pack.tgz

# Install pre-commit
# hadolint ignore=DL3013
RUN pip install --no-cache-dir pre-commit

# Base stage must not end as root (hadolint DL3002)
USER runner

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
