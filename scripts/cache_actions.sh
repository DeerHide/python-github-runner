#!/usr/bin/env bash

set -euo pipefail

manifest_path="${1:-manifest.yaml}"
actions_root="${ACTIONS_CACHE_ROOT:-/home/runner/_work/_actions}"

if ! command -v yq >/dev/null 2>&1; then
  echo "Error: yq is required but not installed." >&2
  exit 1
fi

if [[ ! -f "${manifest_path}" ]]; then
  echo "Error: manifest file not found at ${manifest_path}" >&2
  exit 1
fi

mkdir -p "${actions_root}"

declare -A seen_actions=()

while IFS= read -r action_ref; do
  [[ -z "${action_ref}" ]] && continue

  if [[ "${action_ref}" != *@* ]]; then
    echo "Error: invalid action entry '${action_ref}', expected owner/repo[/path]@ref" >&2
    exit 1
  fi

  repo_with_optional_path="${action_ref%@*}"
  ref="${action_ref##*@}"

  if [[ "${repo_with_optional_path}" != */* ]]; then
    echo "Error: invalid action repo '${repo_with_optional_path}' in '${action_ref}'" >&2
    exit 1
  fi

  owner="${repo_with_optional_path%%/*}"
  remainder="${repo_with_optional_path#*/}"
  repo="${remainder%%/*}"

  if [[ -z "${owner}" || -z "${repo}" || -z "${ref}" ]]; then
    echo "Error: invalid action entry '${action_ref}'" >&2
    exit 1
  fi

  cache_key="${owner}/${repo}@${ref}"
  if [[ -n "${seen_actions[${cache_key}]:-}" ]]; then
    continue
  fi
  seen_actions["${cache_key}"]=1

  dest_dir="${actions_root}/${owner}/${repo}/${ref}"
  archive_url="https://codeload.github.com/${owner}/${repo}/tar.gz/${ref}"

  rm -rf "${dest_dir}"
  mkdir -p "${dest_dir}"

  echo "Caching ${cache_key}"
  curl -fsSL "${archive_url}" \
    | tar -xz --strip-components=1 -C "${dest_dir}"

  touch "${dest_dir}/.completed"
done < <(yq e -r '.cache.actions[]' "${manifest_path}")
