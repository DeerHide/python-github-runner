## [Unreleased]

### Added

### Changed

### Fixed

## [1.2.1](https://github.com/DeerHide/python-github-runner/compare/v1.2.0...v1.2.1) (2026-04-25)

### Added

### Changed

* **deps:** update manifest tool versions (argo 4.0.5, kargo 1.10.2, pack 0.40.3) for upcoming image builds

### Fixed


# [1.2.0](https://github.com/DeerHide/python-github-runner/compare/v1.1.0...v1.2.0) (2026-04-17)


### Features

* **runner:** make poetry and uv shell-agnostic ([2be47c6](https://github.com/DeerHide/python-github-runner/commit/2be47c654099efa62e0a4864ef43a6273a1a83a1))

# [1.1.0](https://github.com/DeerHide/python-github-runner/compare/v1.0.9...v1.1.0) (2026-04-17)


### Features

* trigger release pipeline ([cb88666](https://github.com/DeerHide/python-github-runner/commit/cb88666857422706939330ae21334b1684766bc6))


## [1.2.0](https://github.com/DeerHide/python-github-runner/compare/v1.1.0...v1.2.0) (2026-04-25)

### Added

* **runner:** export `${APP_HOME}/.local/bin` at image level so Poetry and UV are discoverable in both `sh` and `bash` execution contexts
* **tools:** add `syft` and `grype` to the image with pinned versions, Renovate tracking, and documentation updates

### Changed

### Fixed

## [1.1.0](https://github.com/DeerHide/python-github-runner/compare/v1.0.9...v1.1.0) (2026-04-17)


### Features

* trigger release pipeline ([cb88666](https://github.com/DeerHide/python-github-runner/commit/cb88666857422706939330ae21334b1684766bc6))

## [1.0.10](https://github.com/DeerHide/python-github-runner/compare/v1.0.9...v1.0.10) (2026-04-17)

### Added

### Changed

* **security:** ignore remaining inherited Go CVEs in `.trivyignore` (expires 2026-08-19) to keep scans actionable until upstream runner/toolchain updates land

### Fixed

## [1.0.9](https://github.com/DeerHide/python-github-runner/compare/v1.0.8...v1.0.9) (2026-04-17)

### Added

### Changed

* **deps:** sync Containerfile defaults and local tooling pins to patched versions (argo 4.0.4, kargo 1.9.6, pack 0.40.2, dive 0.13.1, hadolint 2.14.0, yq 4.53.2)

### Fixed

## [1.0.8](https://github.com/DeerHide/python-github-runner/compare/v1.0.7...v1.0.8) (2026-04-17)

### Added

* **ci:** scheduled workflow to update GitHub Actions runner version daily (push to main, no human intervention; requires `REPO_PAT` secret)

### Changed

* **security:** add CVE-2026-24051 to .trivyignore (OpenTelemetry SDK in containerd, trivy, argo)
* **deps:** upgrade runner and bundled tool versions in `manifest.yaml` (runner 2.333.1, argo 4.0.4, kargo 1.9.6, pack 0.40.2, dive 0.13.1, hadolint 2.14.0, yq 4.53.2)
* **ci(trivy):** write JSON report to `build/trivy-report.json` and print a human-readable vulnerability summary when scans fail

### Fixed

* **container:** bootstrap pip with --break-system-packages for PEP 668 (externally-managed-environment)
* **deps:** update GitHub Actions runner to 2.333.0 and 2.333.1

## [1.0.7](https://github.com/DeerHide/python-github-runner/compare/v1.0.6...v1.0.7) (2026-03-01)


### Bug Fixes

* **container:** bootstrap pip with --break-system-packages for PEP 668 ([12eb4cf](https://github.com/DeerHide/python-github-runner/commit/12eb4cf891e570ea32023ba9aec30fb2a241f1bd))

## [1.0.6](https://github.com/DeerHide/python-github-runner/compare/v1.0.5...v1.0.6) (2026-03-01)

### Bug Fixes

* **deps:** upgrade Actions runner from 2.321.0 to 2.332.0 (v2.321.0 deprecated by GitHub)

## [1.0.5](https://github.com/DeerHide/python-github-runner/compare/v1.0.4...v1.0.5) (2026-02-20)


### Bug Fixes

* **ci:** remove --all flag from skopeo copy to fix registry push ([1602822](https://github.com/DeerHide/python-github-runner/commit/1602822af22b17eb6574d798c3a592e0a86fe734))

## [1.0.4](https://github.com/DeerHide/python-github-runner/compare/v1.0.3...v1.0.4) (2026-02-20)


### Bug Fixes

* add .trivyignore for base-image CVEs and document security ([706ba83](https://github.com/DeerHide/python-github-runner/commit/706ba83c5a683a1e2c76cd217529d29d7d5c9aea))
* **ci:** scan image from Docker daemon in Trivy step ([54334d3](https://github.com/DeerHide/python-github-runner/commit/54334d368df683df7327bac34af29dd772b75f38))
* **ci:** use --input flag for trivy OCI archive scan ([88da58a](https://github.com/DeerHide/python-github-runner/commit/88da58a85d198bd7a1438f268d5bb5a1e3472609))
* use +0000 in .trivyignore exp dates for Trivy parse ([e2d66c5](https://github.com/DeerHide/python-github-runner/commit/e2d66c551b5d1c5871945a8cc5d8c153fdacfdc6))

## [1.0.3](https://github.com/DeerHide/python-github-runner/compare/v1.0.2...v1.0.3) (2026-02-19)


### Bug Fixes

* **ci:** use oci-archive format for trivy scan and cache vulndb ([acd077c](https://github.com/DeerHide/python-github-runner/commit/acd077cc362338d1646f0a8f750d87f76933431e))

## [1.0.2](https://github.com/DeerHide/python-github-runner/compare/v1.0.1...v1.0.2) (2026-02-19)


### Bug Fixes

* use bash arrays for BUILD_ARGS and LABELS to handle values with spaces ([0dd5806](https://github.com/DeerHide/python-github-runner/commit/0dd5806532c3cd3956767434f397b62576464eca))

## [1.0.1](https://github.com/DeerHide/python-github-runner/compare/v1.0.0...v1.0.1) (2026-02-19)


### Bug Fixes

* **ci:** add missing -y flags and fix trivy command in release pipeline ([33ca427](https://github.com/DeerHide/python-github-runner/commit/33ca4270e9784e4129a4c61938fbcb9f2850a92f))

# 1.0.0 (2026-02-19)


### Bug Fixes

* address PR review feedback ([d1e532f](https://github.com/DeerHide/python-github-runner/commit/d1e532f82656a860305a99ce2f8acbad3ef1339b))
* address PR review feedback ([a178c21](https://github.com/DeerHide/python-github-runner/commit/a178c21fb18a4bbb69bfad5a0e08d479fdedcc6a))
* comments from pr (hadolint, python version) ([30e5588](https://github.com/DeerHide/python-github-runner/commit/30e558875c4c3a7b726cc794cad9c1717f4d9e89))
* **container:** bootstrap pip via get-pip.py for deadsnakes Python ([48a8477](https://github.com/DeerHide/python-github-runner/commit/48a8477832e60affc29cb559a2379a2f88cab3bb))
* **container:** install pip for Python 3.12/3.13 via ensurepip ([76980ea](https://github.com/DeerHide/python-github-runner/commit/76980ea1de1d5f1ee7c249ad07c50c8fefe086a8))
* use ghcr.io/actions/actions-runner base image and fix FromAsCasing ([697a7a6](https://github.com/DeerHide/python-github-runner/commit/697a7a6ec3ca7f4026098701c4aa4a2ec30e293a))


### Features

* add pre-commit with hadolint, shellcheck, and commitlint hooks ([ea59872](https://github.com/DeerHide/python-github-runner/commit/ea59872e5ea5a21d5f2198d2988fa76f46a2001c))
* add semantic-release pipeline with build tools and best practices ([6db1c23](https://github.com/DeerHide/python-github-runner/commit/6db1c23843ca87fa27e8c57429a3912a3f50d790))
* **container:** add Python pip packages and GCC build tooling ([559933d](https://github.com/DeerHide/python-github-runner/commit/559933d8724b6b3e9d16f3ad8b38d3feaf812654))
* replace custom update-tools workflow with Renovate ([ba84de9](https://github.com/DeerHide/python-github-runner/commit/ba84de91c92b58218faad11667bb00dc509c866c))
* replace packer with kargo CLI ([51c2b52](https://github.com/DeerHide/python-github-runner/commit/51c2b520dfb567270096e8d8d2b10d945385c167))
* switch base image to GitHub runner and add DevOps tools ([10d0b70](https://github.com/DeerHide/python-github-runner/commit/10d0b70f5750e0be6db00d2f420357cc7a99e43c))
* v1 ([20b6ec2](https://github.com/DeerHide/python-github-runner/commit/20b6ec203e21e1c27e3666626c2399e86f294f46))
