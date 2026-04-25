ARG RUNNER_VERSION=2.334.0

FROM ghcr.io/actions/actions-runner:${RUNNER_VERSION} AS base

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
       build-essential \
       python3.12 python3.12-dev \
       python3.13 python3.13-dev \
       skopeo buildah \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# deadsnakes PPA does not ship python3.x-pip; bootstrap via get-pip.py.
# PEP 668 marks the environment as externally managed; --break-system-packages is
# acceptable in a container image where we own the environment.
# hadolint ignore=DL4006
RUN curl -sSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
    && python3.12 /tmp/get-pip.py --no-cache-dir --break-system-packages \
    && python3.13 /tmp/get-pip.py --no-cache-dir --break-system-packages \
    && rm /tmp/get-pip.py

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

# Install syft (SBOM generator)
ARG SYFT_VERSION=1.43.0
RUN curl -sSL -o /tmp/syft.tgz \
      "https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_amd64.tar.gz" \
    && tar -xzf /tmp/syft.tgz -C /tmp syft \
    && mv /tmp/syft /usr/local/bin/syft \
    && chmod +x /usr/local/bin/syft \
    && rm -f /tmp/syft.tgz

# Install grype (vulnerability scanner)
ARG GRYPE_VERSION=0.111.1
RUN curl -sSL -o /tmp/grype.tgz \
      "https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_linux_amd64.tar.gz" \
    && tar -xzf /tmp/grype.tgz -C /tmp grype \
    && mv /tmp/grype /usr/local/bin/grype \
    && chmod +x /usr/local/bin/grype \
    && rm -f /tmp/grype.tgz

# Install dive (container filesystem analysis)
ARG DIVE_VERSION=0.13.1
# hadolint ignore=DL3008
RUN curl -sSL -o /tmp/dive.deb \
      "https://github.com/wagoodman/dive/releases/download/v${DIVE_VERSION}/dive_${DIVE_VERSION}_linux_amd64.deb" \
    && apt-get update \
    && apt-get install --no-install-recommends -y /tmp/dive.deb \
    && rm /tmp/dive.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install hadolint (Dockerfile/Containerfile linter)
ARG HADOLINT_VERSION=2.14.0
RUN curl -sSL -o /usr/local/bin/hadolint \
      "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64" \
    && chmod +x /usr/local/bin/hadolint

# Install yq (YAML processor)
ARG YQ_VERSION=4.53.2
RUN curl -sSL -o /usr/local/bin/yq \
      "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" \
    && chmod +x /usr/local/bin/yq

# Install Argo Workflows CLI
ARG ARGO_VERSION=4.0.4
RUN curl -sSL -o /tmp/argo-linux-amd64.gz \
      "https://github.com/argoproj/argo-workflows/releases/download/v${ARGO_VERSION}/argo-linux-amd64.gz" \
    && gunzip /tmp/argo-linux-amd64.gz \
    && mv /tmp/argo-linux-amd64 /usr/local/bin/argo \
    && chmod +x /usr/local/bin/argo

# Install Kargo CLI
ARG KARGO_VERSION=1.9.6
RUN curl -sSL -o /usr/local/bin/kargo \
      "https://github.com/akuity/kargo/releases/download/v${KARGO_VERSION}/kargo-linux-amd64" \
    && chmod +x /usr/local/bin/kargo

# Install pack (Cloud Native Buildpacks CLI)
ARG PACK_VERSION=0.40.2
RUN curl -sSL -o /tmp/pack.tgz \
      "https://github.com/buildpacks/pack/releases/download/v${PACK_VERSION}/pack-v${PACK_VERSION}-linux.tgz" \
    && tar -xzf /tmp/pack.tgz -C /usr/local/bin/ \
    && rm /tmp/pack.tgz

# Install pre-commit
# hadolint ignore=DL3013
RUN pip3 install --no-cache-dir pre-commit

# Base stage must not end as root (hadolint DL3002)
USER runner

FROM base AS runtime

LABEL org.opencontainers.image.source=https://github.com/deerhide/python-github-runner
LABEL org.opencontainers.image.description="Python GitHub Runner"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.authors="Deerhide"
LABEL org.opencontainers.image.vendor="Deerhide"

USER runner
WORKDIR ${APP_HOME}

# Ensure user-installed CLI tools are available in all shells (sh/bash, interactive/non-interactive)
ENV PATH="/usr/local/bin:${APP_HOME}/.uv/bin:${APP_HOME}/.poetry/bin:${APP_HOME}/.local/bin:${PATH}"
# Install Poetry latest version and add it to PATH
# hadolint ignore=DL4006
RUN curl -sSL https://install.python-poetry.org | python3 -

# Install UV
# hadolint ignore=DL4006
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Pre-cache selected GitHub Actions used by project workflows.
COPY --chown=runner:runner manifest.yaml /tmp/manifest.yaml
COPY --chown=runner:runner scripts/cache_actions.sh /tmp/cache_actions.sh
RUN chmod +x /tmp/cache_actions.sh \
    && /tmp/cache_actions.sh /tmp/manifest.yaml \
    && rm -f /tmp/manifest.yaml /tmp/cache_actions.sh

# Add user tool paths to interactive shell PATH
RUN echo "export PATH=\"/usr/local/bin:${APP_HOME}/.uv/bin:${APP_HOME}/.poetry/bin:${APP_HOME}/.local/bin:\$PATH\"" >> ~/.bashrc
