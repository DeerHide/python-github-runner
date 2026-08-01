ARG RUNNER_VERSION=2.336.0

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
       jq \
       unzip \
       xz-utils \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# deadsnakes PPA does not ship python3.x-pip; bootstrap via get-pip.py.
# PEP 668 marks the environment as externally managed; --break-system-packages is
# acceptable in a container image where we own the environment.
# hadolint ignore=DL4006,DL3013
RUN curl -sSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py \
    && python3.12 /tmp/get-pip.py --no-cache-dir --break-system-packages \
    && python3.13 /tmp/get-pip.py --no-cache-dir --break-system-packages \
    && rm /tmp/get-pip.py \
    && python3.12 -m pip install --no-cache-dir --break-system-packages --upgrade \
         "setuptools>=78.1.1" "msgpack>=1.2.1" \
    && python3.13 -m pip install --no-cache-dir --break-system-packages --upgrade \
         "setuptools>=78.1.1" "msgpack>=1.2.1"

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
ARG SYFT_VERSION=1.50.0
RUN curl -sSL -o /tmp/syft.tgz \
      "https://github.com/anchore/syft/releases/download/v${SYFT_VERSION}/syft_${SYFT_VERSION}_linux_amd64.tar.gz" \
    && tar -xzf /tmp/syft.tgz -C /tmp syft \
    && mv /tmp/syft /usr/local/bin/syft \
    && chmod +x /usr/local/bin/syft \
    && rm -f /tmp/syft.tgz

# Install grype (vulnerability scanner)
ARG GRYPE_VERSION=0.116.1
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
ARG YQ_VERSION=4.53.3
RUN curl -sSL -o /usr/local/bin/yq \
      "https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64" \
    && chmod +x /usr/local/bin/yq

# Install Argo Workflows CLI
ARG ARGO_VERSION=4.0.8
RUN curl -sSL -o /tmp/argo-linux-amd64.gz \
      "https://github.com/argoproj/argo-workflows/releases/download/v${ARGO_VERSION}/argo-linux-amd64.gz" \
    && gunzip /tmp/argo-linux-amd64.gz \
    && mv /tmp/argo-linux-amd64 /usr/local/bin/argo \
    && chmod +x /usr/local/bin/argo

# Install Kargo CLI
ARG KARGO_VERSION=1.11.0
RUN curl -sSL -o /usr/local/bin/kargo \
      "https://github.com/akuity/kargo/releases/download/v${KARGO_VERSION}/kargo-linux-amd64" \
    && chmod +x /usr/local/bin/kargo

# Install kubectl (in-cluster kpack Build CRs from green ARC runners)
ARG KUBECTL_VERSION=1.36.3
RUN curl -sSL -o /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x /usr/local/bin/kubectl

# Install GitHub CLI (workflows calling `gh api`, e.g. dependency-graph snapshots)
ARG GH_CLI_VERSION=2.97.0
RUN curl -sSL -o /tmp/gh.tgz \
      "https://github.com/cli/cli/releases/download/v${GH_CLI_VERSION}/gh_${GH_CLI_VERSION}_linux_amd64.tar.gz" \
    && tar -xzf /tmp/gh.tgz -C /tmp "gh_${GH_CLI_VERSION}_linux_amd64/bin/gh" \
    && mv "/tmp/gh_${GH_CLI_VERSION}_linux_amd64/bin/gh" /usr/local/bin/gh \
    && chmod +x /usr/local/bin/gh \
    && rm -rf /tmp/gh.tgz "/tmp/gh_${GH_CLI_VERSION}_linux_amd64" \
    && gh --version

# Install pack (Cloud Native Buildpacks CLI)
ARG PACK_VERSION=0.40.8
RUN curl -sSL -o /tmp/pack.tgz \
      "https://github.com/buildpacks/pack/releases/download/v${PACK_VERSION}/pack-v${PACK_VERSION}-linux.tgz" \
    && tar -xzf /tmp/pack.tgz -C /usr/local/bin/ \
    && rm /tmp/pack.tgz

# Install crane (daemonless OCI append/push for kpack -src images; no userns)
ARG CRANE_VERSION=0.21.8
RUN curl -sSL -o /tmp/crane.tgz \
      "https://github.com/google/go-containerregistry/releases/download/v${CRANE_VERSION}/go-containerregistry_Linux_x86_64.tar.gz" \
    && tar -xzf /tmp/crane.tgz -C /tmp crane \
    && mv /tmp/crane /usr/local/bin/crane \
    && chmod +x /usr/local/bin/crane \
    && rm -f /tmp/crane.tgz \
    && crane version

# Install Node.js (bundles npm and npx)
ARG NODE_VERSION=24.18.0
RUN curl -sSL -o /tmp/node.tgz \
      "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz" \
    && tar -xzf /tmp/node.tgz -C /usr/local --strip-components=1 \
    && rm -f /tmp/node.tgz

# Install Bun (JS runtime, package manager, bundler, test runner)
# Use the baseline build to support runner CPUs without AVX2.
ARG BUN_VERSION=1.3.14
RUN curl -sSL -o /tmp/bun.zip \
      "https://github.com/oven-sh/bun/releases/download/bun-v${BUN_VERSION}/bun-linux-x64-baseline.zip" \
    && unzip -q /tmp/bun.zip -d /tmp \
    && mv /tmp/bun-linux-x64-baseline/bun /usr/local/bin/bun \
    && chmod +x /usr/local/bin/bun \
    && ln -sf /usr/local/bin/bun /usr/local/bin/bunx \
    && rm -rf /tmp/bun.zip /tmp/bun-linux-x64-baseline

# OpenAPI CLIs: oasdiff is a standalone Go binary; npm-only tools share one prefix
# install with CVE overrides (openapi-tools/package.json). Versions aligned with
# customer_backend/scripts/openapi-tools.env and manifest.yaml build args.
ARG REDOCLY_CLI_VERSION=2.39.0
ARG SPECTRAL_CLI_VERSION=6.16.1
ARG PORTMAN_VERSION=1.35.0
ARG NEWMAN_VERSION=6.2.2
COPY openapi-tools/package.json /tmp/openapi-tools/
# hadolint ignore=DL3013
RUN npm install --prefix /tmp/openapi-tools --omit=dev --no-package-lock \
      "@redocly/cli@${REDOCLY_CLI_VERSION}" \
      "@stoplight/spectral-cli@${SPECTRAL_CLI_VERSION}" \
      "@apideck/portman@${PORTMAN_VERSION}" \
      "newman@${NEWMAN_VERSION}" \
    && for bin in redocly openapi spectral portman newman; do \
         ln -sf "/tmp/openapi-tools/node_modules/.bin/${bin}" "/usr/local/bin/${bin}"; \
       done \
    && rm -rf /root/.npm

# Install oasdiff (OpenAPI diff and breaking-change detection)
ARG OASDIFF_VERSION=1.27.0
RUN curl -sSL -o /tmp/oasdiff.tgz \
      "https://github.com/Tufin/oasdiff/releases/download/v${OASDIFF_VERSION}/oasdiff_${OASDIFF_VERSION}_linux_amd64.tar.gz" \
    && tar -xzf /tmp/oasdiff.tgz -C /tmp oasdiff \
    && mv /tmp/oasdiff /usr/local/bin/oasdiff \
    && chmod +x /usr/local/bin/oasdiff \
    && rm -f /tmp/oasdiff.tgz

# Rust toolchain (velmios-aws-lambdas / cargo-lambda CI)
ARG RUST_VERSION=1.97.1
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:${PATH}
# hadolint ignore=DL4006
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --default-toolchain "${RUST_VERSION}" --profile minimal \
    && chmod -R a+rX /usr/local/rustup /usr/local/cargo \
    && rustc --version && cargo --version

# Zig linker for cargo-lambda arm64 cross-builds.
# 0.14.0 uses zig-linux-x86_64-*; 0.14.1+ renamed to zig-x86_64-linux-* — update URL on bump.
ARG ZIG_VERSION=0.14.0
RUN curl -sSL -o /tmp/zig.tar.xz \
      "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz" \
    && tar -xJf /tmp/zig.tar.xz -C /usr/local \
    && mv "/usr/local/zig-linux-x86_64-${ZIG_VERSION}" /usr/local/zig \
    && ln -sf /usr/local/zig/zig /usr/local/bin/zig \
    && rm -f /tmp/zig.tar.xz \
    && zig version

# cargo-lambda (AWS Lambda Rust packaging)
ARG CARGO_LAMBDA_VERSION=1.9.1
RUN curl -sSL -o /tmp/cargo-lambda.tgz \
      "https://github.com/cargo-lambda/cargo-lambda/releases/download/v${CARGO_LAMBDA_VERSION}/cargo-lambda-v${CARGO_LAMBDA_VERSION}.x86_64-unknown-linux-musl.tar.gz" \
    && tar -xzf /tmp/cargo-lambda.tgz -C /usr/local/bin cargo-lambda \
    && chmod +x /usr/local/bin/cargo-lambda \
    && rm -f /tmp/cargo-lambda.tgz \
    && cargo lambda --version

# Install pre-commit; re-pin setuptools/msgpack after its deps settle.
# hadolint ignore=DL3013
RUN pip3 install --no-cache-dir --break-system-packages pre-commit \
    && python3.12 -m pip install --no-cache-dir --break-system-packages --upgrade \
         "setuptools>=78.1.1" "msgpack>=1.2.1" \
    && python3.13 -m pip install --no-cache-dir --break-system-packages --upgrade \
         "setuptools>=78.1.1" "msgpack>=1.2.1"

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
RUN echo "export PATH=\"/usr/local/bin:/usr/local/cargo/bin:${APP_HOME}/.uv/bin:${APP_HOME}/.poetry/bin:${APP_HOME}/.local/bin:\$PATH\"" >> ~/.bashrc
