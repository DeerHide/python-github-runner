# AGENTS.md — Python GitHub Runner

Always-on orientation for AI agents working in this repo. Read before touching files.

## What this repo is

Self-hosted GitHub Actions runner **container image** for Deerhide / Velmios CI:

- Image: `ghcr.io/deerhide/python-github-runner`
- Base: `ghcr.io/actions/actions-runner` (`RUNNER_VERSION` in `manifest.yaml`)
- Includes Python 3.12/3.13 (deadsnakes), Poetry, UV, DevOps CLIs (argo, kargo, kubectl, pack, skopeo, buildah, …), OpenAPI CLIs (redocly, spectral, portman, newman, oasdiff), Node/Bun, and a full OCI build/scan pipeline so the image can build itself.

Tool inventory and version tables live in [README.md](README.md). Do not duplicate them here.

## Directory map

| Path | What lives here |
| --- | --- |
| [Containerfile](Containerfile) | Multi-stage image definition (`base` → `runtime`) |
| [manifest.yaml](manifest.yaml) | Build args, OCI labels, registry, Actions cache list |
| [openapi-tools/package.json](openapi-tools/package.json) | CVE `overrides` for npm OpenAPI CLIs (no lockfile) |
| [scripts/](scripts/) | `builder.sh`, `install_tools.sh`, `cache_actions.sh`, helpers |
| [.github/workflows/](.github/workflows/) | `ci.yaml`, `validate.yaml`, `release.yaml`, nightly/update |
| [renovate.json](renovate.json) | Regex managers for `*_VERSION=` pins |
| [.pre-commit-config.yaml](.pre-commit-config.yaml) | hadolint, shellcheck, commitlint, hygiene |
| [.hadolint.yaml](.hadolint.yaml) | Containerfile lint config |
| [.trivyignore](.trivyignore) | Base-image CVEs with `exp:` dates |
| [.dive-ci](.dive-ci) | Dive efficiency thresholds |
| [.releaserc.yaml](.releaserc.yaml) | semantic-release config |

## Key invariants

- Pin tool versions in **both** `manifest.yaml` `build.args` and `Containerfile` `ARG` defaults. Renovate regex managers match both files.
- Prefer pinned GitHub-release / curl binary installs over apt. Use apt for OS packages only (skopeo, buildah, jq, trivy apt repo, deadsnakes Python, etc.).
- OpenAPI npm CLIs: versions come from build args; CVE overrides **only** in `openapi-tools/package.json`. No `package-lock.json`.
- Pre-cache GitHub Actions listed under `manifest.yaml` `cache.actions` via `scripts/cache_actions.sh` at image build time.
- Trivy scans library packages only and ignores unfixed vulns. Base-image findings go in `.trivyignore` with `exp:` dates — MUST NOT ignore without expiry.
- Conventional Commits + commitlint; semantic-release bumps and publishes on push to `main`.
- Install as root in `base`, then switch to `USER runner`. Final stage MUST NOT stay root (hadolint DL3002).
- Bun: install `bun-linux-x64-baseline` (runner CPUs may lack AVX2).

## Local validation

```bash
pre-commit install --hook-type pre-commit --hook-type commit-msg
pre-commit run --all-files
./scripts/install_tools.sh
skopeo login ghcr.io
./scripts/builder.sh   # hadolint → buildah → dive → trivy → push
```

## Task → skill index

Skills live under [.agents/skills/](.agents/skills/). Read the matching skill when starting a task:

| Task | Skill |
| --- | --- |
| Add or change a CLI/tool in the image (binary, apt, OpenAPI npm, Renovate pin) | [`runner-add-tool`](.agents/skills/runner-add-tool/SKILL.md) |
| Local build, CI/PR validation, release, dive/trivy failures, semantic-release | [`runner-build-release`](.agents/skills/runner-build-release/SKILL.md) |
