# Deerhide / Python GitHub Runner

Container image based on the [GitHub Actions Runner](https://github.com/actions/runner) with Python tooling, DevOps CLIs, and a full container build pipeline baked in. Designed to be used as a self-hosted runner that can build itself.

## What's included

### Base image

`ghcr.io/actions/actions-runner` (GitHub Actions Runner). Trivy is run with `--pkg-types library` and `--ignore-unfixed`, so OS packages from the base image (Ubuntu, containerd, docker-buildx, etc.) are not reported. Any remaining base-origin library findings can be listed in [`.trivyignore`](.trivyignore) with expiration dates. Base image version is controlled by `RUNNER_VERSION` in [manifest.yaml](manifest.yaml) and is kept up to date by [Renovate](renovate.json).

### Python

| Tool | Version |
|------|---------|
| Python | 3.12, 3.13 (via deadsnakes PPA) |
| Poetry | latest |
| UV | latest |

### DevOps CLIs

| Tool | Description |
|------|-------------|
| [Argo Workflows CLI](https://github.com/argoproj/argo-workflows) | Workflow orchestration on Kubernetes |
| [Kargo CLI](https://github.com/akuity/kargo) | Application lifecycle orchestration |
| [kubectl](https://kubernetes.io/docs/reference/kubectl/) | Kubernetes CLI (in-cluster kpack builds from green ARC runners) |
| [gh](https://cli.github.com/) | GitHub CLI (`gh api` calls from workflows, e.g. dependency-graph snapshots) |
| [jq](https://jqlang.org/) | JSON processor (kpack git-token refresher CronJob) |
| [pack](https://github.com/buildpacks/pack) | Cloud Native Buildpacks CLI |
| [skopeo](https://github.com/containers/skopeo) | Container image registry operations |
| [Node.js](https://nodejs.org/) / npm | JavaScript runtime and package manager (npm/npx bundled) |
| [Bun](https://bun.sh/) | JavaScript runtime, package manager, bundler, and test runner |

### Rust / AWS Lambda

Pre-installed for [`velmios-aws-lambdas`](https://github.com/Laelidona/velmios-aws-lambdas) release builds (`cargo lambda build --arm64`).

| Tool | Version source | Notes |
|------|----------------|-------|
| [Rust](https://www.rust-lang.org/) (rustc, cargo) | `RUST_VERSION` | rustup `minimal` profile under `/usr/local/{rustup,cargo}` |
| [Zig](https://ziglang.org/) | `ZIG_VERSION` | Linker for cargo-lambda cross-compile; `0.14.0` tarball name differs from `0.14.1+` |
| [cargo-lambda](https://www.cargo-lambda.info/) | `CARGO_LAMBDA_VERSION` | Musl binary from GitHub releases |

### Build pipeline tools

These tools allow the image to run its own build pipeline as a self-hosted runner.

| Tool | Description |
|------|-------------|
| [buildah](https://github.com/containers/buildah) | OCI container image builder |
| [crane](https://github.com/google/go-containerregistry) | Daemonless OCI append/push (`CRANE_VERSION`; kpack `-src` packaging) |
| [dive](https://github.com/wagoodman/dive) | Container filesystem analysis |
| [trivy](https://github.com/aquasecurity/trivy) | Vulnerability scanner |
| [syft](https://github.com/anchore/syft) | Software bill of materials (SBOM) generator |
| [grype](https://github.com/anchore/grype) | Container and SBOM vulnerability scanner |
| [hadolint](https://github.com/hadolint/hadolint) | Dockerfile/Containerfile linter |
| [yq](https://github.com/mikefarah/yq) | YAML processor |
| [pre-commit](https://pre-commit.com/) | Git hooks framework |

## CI/CD

### Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| **CI** | Pull request to `main` | Commitlint, hadolint lint, test build |
| **Release** | Push to `main` | Semantic release, build, scan, push to GHCR |
| **Renovate** | Automated | Keeps tool versions and dependencies up to date via PRs |

### Release process

Releases are fully automated via [semantic-release](https://github.com/semantic-release/semantic-release). Pushing to `main` triggers version analysis based on [Conventional Commits](https://www.conventionalcommits.org/). Tool versions are kept up to date automatically by [Renovate](https://docs.renovatebot.com/).

| Commit prefix | Version bump |
|---------------|-------------|
| `fix:` | Patch (1.0.0 -> 1.0.1) |
| `feat:` | Minor (1.0.0 -> 1.1.0) |
| `feat!:` / `BREAKING CHANGE:` | Major (1.0.0 -> 2.0.0) |

When a new version is determined, the release workflow:

1. Creates a GitHub release with auto-generated notes
2. Updates `CHANGELOG.md`
3. Validates the Containerfile with hadolint
4. Builds the image with `buildah` (OCI format, squashed layers)
5. Runs `dive` filesystem efficiency scan
6. Runs `trivy` vulnerability scan (library packages only, HIGH/CRITICAL, unfixed ignored)
7. Pushes to GHCR with semver tags: `1.2.3`, `1.2`, `1`, `latest`

### Image tags

```
ghcr.io/deerhide/python-github-runner:latest
ghcr.io/deerhide/python-github-runner:1
ghcr.io/deerhide/python-github-runner:1.2
ghcr.io/deerhide/python-github-runner:1.2.3
```

## Local development

### Pre-requisites

Install [Docker](https://docs.docker.com/get-docker/), then install the build tools:

```bash
./scripts/install_tools.sh
```

Local install may use different (e.g. latest) versions for some tools than the pinned versions in the image and CI.

### Configuration

Build configuration is defined in `manifest.yaml`:

```yaml
name: python-github-runner
tags:
  - latest
registry: ghcr.io/deerhide/python-github-runner
build:
  format: oci
  args:
    - RUNNER_VERSION=2.333.1
    - ARGO_VERSION=4.0.4
    - KARGO_VERSION=1.9.6
    - PACK_VERSION=0.40.2
    - DIVE_VERSION=0.13.1
    - SYFT_VERSION=1.43.0
    - GRYPE_VERSION=0.111.1
    - HADOLINT_VERSION=2.14.0
    - YQ_VERSION=4.53.2
    - NODE_VERSION=24.16.0
    - BUN_VERSION=1.3.14
  labels:
    - org.opencontainers.image.source=https://github.com/deerhide/python-github-runner
    - org.opencontainers.image.description="Python GitHub Runner"
    - org.opencontainers.image.licenses="MIT"
    - org.opencontainers.image.authors="Deerhide"
    - org.opencontainers.image.vendor="Deerhide"
```

### Build

Authenticate to the container registry:

```bash
skopeo login ghcr.io
```

Run the full build pipeline (lint, build, scan, push):

```bash
./scripts/builder.sh
```

### Pre-commit hooks

Install the git hooks locally:

```bash
pre-commit install --hook-type pre-commit --hook-type commit-msg
```

Hooks run automatically on every commit:

| Hook | Stage | Description |
|------|-------|-------------|
| trailing-whitespace | pre-commit | Remove trailing whitespace |
| end-of-file-fixer | pre-commit | Ensure files end with a newline |
| check-yaml | pre-commit | Validate YAML syntax |
| check-added-large-files | pre-commit | Prevent large files from being committed |
| check-merge-conflict | pre-commit | Detect merge conflict markers |
| detect-private-key | pre-commit | Prevent private keys from being committed |
| hadolint | pre-commit | Lint Containerfile |
| shellcheck | pre-commit | Lint shell scripts |
| commitlint | commit-msg | Validate conventional commit messages |

Run all hooks manually against all files:

```bash
pre-commit run --all-files
```

### Contributing

This project uses [Conventional Commits](https://www.conventionalcommits.org/). Commit messages are validated by commitlint on pull requests and locally via pre-commit hooks.

```bash
# Good
git commit -m "feat: add kubectl to image"
git commit -m "fix: correct trivy scan exit code"
git commit -m "chore: update argo to v3.7.0"

# Bad
git commit -m "added stuff"
git commit -m "WIP"
```

## Project structure

```
.
├── Containerfile                        # Multi-stage container definition
├── manifest.yaml                        # Build configuration and metadata
├── CHANGELOG.md                         # Generated by semantic-release
├── install-man-page.sh                  # Optional: install yq man page locally
├── .releaserc.yaml                      # Semantic release configuration
├── .hadolint.yaml                       # Hadolint configuration
├── .commitlintrc.yaml                   # Commitlint configuration
├── .pre-commit-config.yaml              # Pre-commit hooks configuration
├── .containerignore                     # Build context exclusions
├── .dive-ci                             # Dive efficiency thresholds
├── .github/
│   └── workflows/
│       ├── ci.yaml                      # PR validation
│       └── release.yaml                 # Semantic release + build + push
├── renovate.json                        # Renovate dependency update config
└── scripts/
    ├── builder.sh                       # Local build orchestration
    ├── install_tools.sh                 # Build tool installer
    ├── lib_utils.sh                     # Logging utilities
    └── login_skopeo.sh                  # Registry authentication helper
```

## Security

This image is based on [actions/actions-runner](https://github.com/actions/runner). Trivy is configured to scan only library packages and to ignore unfixed vulnerabilities, so base-image OS packages are not reported. Any remaining base-origin findings can be listed in [`.trivyignore`](.trivyignore) with expiration dates. Keep `RUNNER_VERSION` in [manifest.yaml](manifest.yaml) up to date (Renovate opens PRs) and review or remove `.trivyignore` entries when upgrading.

## License

[MIT](LICENSE)
