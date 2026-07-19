---
name: runner-build-release
description: >-
  Build, scan, and release the Deerhide python-github-runner OCI image. Use when running
  local builds, debugging CI/PR validation, semantic-release on main, dive/trivy failures,
  image tags, or .trivyignore updates.
---

# Build and release the runner image

## When to use

- Local image build / push
- PR CI failures (commitlint, hadolint, build-and-scan)
- Release on `main` (semantic-release + GHCR push)
- dive efficiency or Trivy HIGH/CRITICAL findings
- Keywords: `builder.sh`, validate.yaml, release.yaml, GHCR, `.trivyignore`, dive

## Prerequisites

```bash
# Docker required
./scripts/install_tools.sh
skopeo login ghcr.io
```

Local tool versions from `install_tools.sh` MAY differ from pinned image/CI versions.

## Local full pipeline

```bash
./scripts/builder.sh
```

Order: hadolint → buildah (OCI, squashed) → dive → trivy → push to registry from `manifest.yaml`.

Config knobs:

| File | Role |
| --- | --- |
| `manifest.yaml` | Name, registry, build args, labels |
| `.hadolint.yaml` | Containerfile lint |
| `.dive-ci` | Layer efficiency thresholds |
| `.trivyignore` | Base-image CVEs with `exp:` dates |

## CI map

| Workflow | Trigger | What it does |
| --- | --- | --- |
| `ci.yaml` | PR → `main` | commitlint + calls `validate.yaml` |
| `validate.yaml` | `workflow_call` | hadolint, buildah build, dive, trivy |
| `release.yaml` | push → `main` | validate → semantic-release → build & push if new version |

## Image tags (after release)

```
ghcr.io/deerhide/python-github-runner:latest
ghcr.io/deerhide/python-github-runner:1
ghcr.io/deerhide/python-github-runner:1.2
ghcr.io/deerhide/python-github-runner:1.2.3
```

## Semantic-release / commits

Conventional Commits drive the bump (commitlint enforced):

| Prefix | Bump |
| --- | --- |
| `fix:` | patch |
| `feat:` | minor |
| `feat!:` / `BREAKING CHANGE:` | major |

Examples:

```bash
git commit -m "feat: add kubectl to image"
git commit -m "fix: correct trivy scan exit code"
git commit -m "chore: update argo to v4.0.7"
```

On new version, release workflow updates `CHANGELOG.md`, creates the GitHub release, builds, scans, and pushes semver tags.

## Scan policy

Trivy in this repo:

- Library packages only (`--pkg-types library`)
- Ignores unfixed vulnerabilities
- Fails on HIGH/CRITICAL that are not ignored

**When a finding appears:**

1. Prefer upgrade (tool pin / `RUNNER_VERSION` / Renovate PR).
2. For base-image / upstream-only CVEs that cannot be fixed here: add to `.trivyignore` with `exp:YYYY-MM-DD` and a short comment naming the origin.
3. MUST NOT add ignores without expiry. Re-evaluate when bumping the base runner.

Dive failures: fix layer bloat in Containerfile (cleanup apt lists, remove temp archives) or adjust `.dive-ci` only with justification.

## Quick checklist

```
Task progress:
- [ ] Tools installed (`install_tools.sh`)
- [ ] Registry login (`skopeo login ghcr.io`)
- [ ] `./scripts/builder.sh` green locally OR CI validate green
- [ ] Conventional commit message matches intended bump
- [ ] New .trivyignore entries have exp: dates (if any)
```
