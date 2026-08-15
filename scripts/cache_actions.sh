#!/usr/bin/env bash
# Pre-populate ACTIONS_RUNNER_ACTION_ARCHIVE_CACHE for the runner image.
#
# Layout (required by the Actions runner):
#   ${ACTIONS_ARCHIVE_CACHE_ROOT}/{owner}_{repo}/{resolved-sha}.tar.gz
#
# Must live outside /home/runner/_work and /home/runner/.cache — ARC pods
# mount emptyDir over those paths and would shadow an extracted _actions tree.
set -euo pipefail

manifest_path="${1:-manifest.yaml}"
cache_root="${ACTIONS_ARCHIVE_CACHE_ROOT:-/home/runner/action-archive-cache}"

if ! command -v yq >/dev/null 2>&1; then
  echo "Error: yq is required but not installed." >&2
  exit 1
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is required but not installed." >&2
  exit 1
fi

if [[ ! -f "${manifest_path}" ]]; then
  echo "Error: manifest file not found at ${manifest_path}" >&2
  exit 1
fi

mkdir -p "${cache_root}"

# Resolve owner/repo@ref to a commit SHA via the GitHub commits API.
resolve_sha() {
  local owner="$1"
  local repo="$2"
  local ref="$3"
  local api_url="https://api.github.com/repos/${owner}/${repo}/commits/${ref}"
  local sha
  sha="$(
    curl -fsSL \
      -H "Accept: application/vnd.github+json" \
      -H "X-GitHub-Api-Version: 2022-11-28" \
      "${api_url}" \
      | yq e -r '.sha // ""'
  )"
  if [[ -z "${sha}" || "${sha}" == "null" ]]; then
    echo "Error: could not resolve ${owner}/${repo}@${ref} to a SHA" >&2
    return 1
  fi
  printf '%s\n' "${sha}"
}

declare -A seen_archives=()

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

  # Archive key is owner_repo (path segments after repo are ignored — same tarball).
  archive_key="${owner}_${repo}"
  dedupe_key="${archive_key}@${ref}"
  if [[ -n "${seen_archives[${dedupe_key}]:-}" ]]; then
    continue
  fi
  seen_archives["${dedupe_key}"]=1

  echo "Resolving ${owner}/${repo}@${ref}"
  sha="$(resolve_sha "${owner}" "${repo}" "${ref}")"

  dest_dir="${cache_root}/${archive_key}"
  dest_file="${dest_dir}/${sha}.tar.gz"
  mkdir -p "${dest_dir}"

  if [[ -f "${dest_file}" ]]; then
    echo "Already cached ${archive_key}/${sha}.tar.gz (from ${ref})"
    continue
  fi

  archive_url="https://codeload.github.com/${owner}/${repo}/tar.gz/${sha}"
  echo "Caching ${archive_key}/${sha}.tar.gz (ref ${ref})"
  curl -fsSL "${archive_url}" -o "${dest_file}"
done < <(yq e -r '.cache.actions[]' "${manifest_path}")

echo "Action archive cache ready at ${cache_root}"
find "${cache_root}" -type f -name '*.tar.gz' | sort
