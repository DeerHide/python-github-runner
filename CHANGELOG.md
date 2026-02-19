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
