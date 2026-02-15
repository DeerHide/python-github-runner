# Deerhide / Python GitHub Runner

Container image based on the [GitHub Actions Runner](https://github.com/actions/runner) with Python tooling, DevOps CLIs, and a full container build pipeline baked in. Designed to be used as a self-hosted runner that can build itself.

## What's included

### Base image

`ghcr.io/actions/runner` (GitHub Actions Runner)

### Python

| Tool | Version |
|------|---------|
| Python | 3.12, 3.13, 3.14 (via deadsnakes PPA) |
| Poetry | latest |
| UV | latest |

### DevOps CLIs

| Tool | Description |
|------|-------------|
| [Argo Workflows CLI](https://github.com/argoproj/argo-workflows) | Workflow orchestration on Kubernetes |
| [Kargo CLI](https://github.com/akuity/kargo) | Application lifecycle orchestration |
| [pack](https://github.com/buildpacks/pack) | Cloud Native Buildpacks CLI |
| [skopeo](https://github.com/containers/skopeo) | Container image registry operations |

### Build pipeline tools

These tools allow the image to run its own build pipeline as a self-hosted runner.

| Tool | Description |
|------|-------------|
| [buildah](https://github.com/containers/buildah) | OCI container image builder |
| [dive](https://github.com/wagoodman/dive) | Container filesystem analysis |
| [trivy](https://github.com/aquasecurity/trivy) | Vulnerability scanner |
| [hadolint](https://github.com/hadolint/hadolint) | Dockerfile/Containerfile linter |
| [yq](https://github.com/mikefarah/yq) | YAML processor |

## CI/CD

### Workflows

| Workflow | Trigger | Description |
|----------|---------|-------------|
| **CI** | Pull request to `master` | Commitlint, hadolint lint, test build |
| **Release** | Push to `master` | Semantic release, build, scan, push to GHCR |
| **Update tools** | Weekly (Monday 08:00 UTC) / manual | Checks for new tool versions, opens a PR |

### Release process

Releases are fully automated via [semantic-release](https://github.com/semantic-release/semantic-release). Pushing to `master` triggers version analysis based on [Conventional Commits](https://www.conventionalcommits.org/):

| Commit prefix | Version bump |
|---------------|-------------|
| `fix:` | Patch (1.0.0 -> 1.0.1) |
| `feat:` | Minor (1.0.0 -> 1.1.0) |
| `feat!:` / `BREAKING CHANGE:` | Major (1.0.0 -> 2.0.0) |

When a new version is determined, the release workflow:

1. Creates a GitHub release with auto-generated notes
2. Updates `CHANGELOG.md`
3. Builds the image with `buildah` (OCI format, squashed layers)
4. Runs `hadolint` lint validation
5. Runs `dive` filesystem efficiency scan
6. Runs `trivy` vulnerability scan (HIGH/CRITICAL)
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
    - RUNNER_VERSION=latest
    - ARGO_VERSION=3.6.4
    - KARGO_VERSION=1.9.2
    - PACK_VERSION=0.36.4
    - DIVE_VERSION=0.12.0
    - HADOLINT_VERSION=2.12.0
    - YQ_VERSION=4.45.4
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

### Contributing

This project uses [Conventional Commits](https://www.conventionalcommits.org/). Commit messages are validated by commitlint on pull requests.

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
├── .releaserc.yaml                      # Semantic release configuration
├── .hadolint.yaml                       # Hadolint configuration
├── .commitlintrc.yaml                   # Commitlint configuration
├── .containerignore                     # Build context exclusions
├── .dive-ci                             # Dive efficiency thresholds
├── .github/
│   └── workflows/
│       ├── ci.yaml                      # PR validation
│       ├── release.yaml                 # Semantic release + build + push
│       └── update-tools.yaml            # Automated tool version updates
└── scripts/
    ├── builder.sh                       # Local build orchestration
    ├── install_tools.sh                 # Build tool installer
    ├── lib_utils.sh                     # Logging utilities
    └── login_skopeo.sh                  # Registry authentication helper
```

## License

[MIT](LICENSE)
