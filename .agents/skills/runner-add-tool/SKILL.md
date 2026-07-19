---
name: runner-add-tool
description: >-
  Add or update a CLI/tool in the Deerhide python-github-runner image (Containerfile,
  manifest.yaml pins, Renovate, OpenAPI npm overrides, README). Use when adding a binary,
  apt package, OpenAPI npm CLI, changing an install RUN layer, or wiring a new *_VERSION pin.
---

# Add a tool to the runner image

## When to use

- New CLI or runtime in the image
- Change how an existing tool is installed
- OpenAPI npm tool / CVE override in `openapi-tools/`
- Keywords: Containerfile, manifest.yaml, Renovate, `*_VERSION`, redocly, spectral, portman, newman, oasdiff

## Install method

| Method | When |
| --- | --- |
| GitHub release binary (curl + install to `/usr/local/bin`) | Default for pin-able CLIs |
| apt | OS packages only (skopeo, buildah, jq, trivy repo, deadsnakes) |
| npm via `openapi-tools/` | OpenAPI JS CLIs sharing one prefix + CVE overrides |
| pip | Rare (e.g. pre-commit); prefer binary otherwise |

## Checklist

Copy and track:

```
Task progress:
- [ ] 1. Choose install method
- [ ] 2. Pin FOO_VERSION in manifest.yaml + Containerfile ARG
- [ ] 3. Add RUN install layer (root, before USER runner)
- [ ] 4. OpenAPI npm only: package + symlink + overrides if needed
- [ ] 5. Renovate customManagers entry for the new pin
- [ ] 6. Update README "What's included"
- [ ] 7. Validate (hadolint / pre-commit / build-scan)
```

### 1–2. Pin versions

Add the same value in both places:

```yaml
# manifest.yaml → build.args
- FOO_VERSION=1.2.3
```

```dockerfile
# Containerfile
ARG FOO_VERSION=1.2.3
```

### 3. Binary install example

```dockerfile
ARG FOO_VERSION=1.2.3
RUN curl -sSL -o /usr/local/bin/foo \
      "https://github.com/org/foo/releases/download/v${FOO_VERSION}/foo-linux-amd64" \
    && chmod +x /usr/local/bin/foo
```

Install as root in the `base` stage. Do not leave the final stage as root.

**Bun:** use `bun-linux-x64-baseline.zip` (no AVX2 on some runner CPUs).

### 4. OpenAPI npm tools

Versions come from build args. CVE overrides only in `openapi-tools/package.json` (no lockfile).

1. Add `FOO_VERSION` to `manifest.yaml` and `ARG` in Containerfile.
2. Extend the `npm install --prefix /tmp/openapi-tools` line with `"@scope/pkg@${FOO_VERSION}"`.
3. Add the binary name to the symlink `for bin in ...` loop.
4. Add `overrides` only when Trivy reports a fixable transitive CVE.

`oasdiff` is a standalone Go binary — do **not** put it in the npm prefix.

### 5. Renovate

Mirror existing managers in `renovate.json`:

```json
{
  "customType": "regex",
  "description": "Update Foo version",
  "fileMatch": ["^Containerfile$", "^manifest\\.yaml$"],
  "matchStrings": ["FOO_VERSION=(?<currentValue>\\S+)"],
  "depNameTemplate": "org/foo",
  "datasourceTemplate": "github-releases",
  "extractVersionTemplate": "^v?(?<version>.+)$"
}
```

Adjust `extractVersionTemplate` / `datasourceTemplate` to match upstream tags (see Node / Bun managers).

### 6–7. Docs and validate

- Update the matching table in [README.md](../../../README.md).
- Run `pre-commit run --all-files` (includes hadolint).
- Prefer a full build-scan via the [`runner-build-release`](../runner-build-release/SKILL.md) skill before merge.
