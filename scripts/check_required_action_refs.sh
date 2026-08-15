#!/usr/bin/env bash
# Fail if any ref in required-github-actions-refs.txt is missing from
# manifest.yaml cache.actions. Used when Laelidona/github-actions is private
# and cannot be checked out from DeerHide CI.
set -euo pipefail

refs_file="${1:-scripts/required-github-actions-refs.txt}"
manifest_path="${2:-manifest.yaml}"

if [[ ! -f "${refs_file}" ]]; then
  echo "Error: refs file not found at ${refs_file}" >&2
  exit 1
fi
if [[ ! -f "${manifest_path}" ]]; then
  echo "Error: manifest not found at ${manifest_path}" >&2
  exit 1
fi

mapfile -t cached < <(
  awk '
    /^cache:/ { in_cache=1; next }
    in_cache && /^[^[:space:]#]/ { in_cache=0 }
    in_cache && /^[[:space:]]+actions:/ { in_actions=1; next }
    in_actions && /^[[:space:]]+-[[:space:]]+/ {
      sub(/^[[:space:]]+-[[:space:]]+/, "")
      print
      next
    }
    in_actions && /^[[:space:]]*[^[:space:]#-]/ { in_actions=0 }
  ' "${manifest_path}"
)

is_cached() {
  local want="$1"
  local entry
  for entry in "${cached[@]}"; do
    [[ "${entry}" == "${want}" ]] && return 0
  done
  local owner_repo ref parent
  ref="${want##*@}"
  owner_repo="${want%@*}"
  if [[ "${owner_repo}" == */*/* ]]; then
    parent="${owner_repo%/*}@${ref}"
    for entry in "${cached[@]}"; do
      [[ "${entry}" == "${parent}" ]] && return 0
    done
  fi
  return 1
}

missing=0
while IFS= read -r uses || [[ -n "${uses}" ]]; do
  [[ -z "${uses}" || "${uses}" =~ ^# ]] && continue
  if ! is_cached "${uses}"; then
    echo "MISSING from cache.actions: ${uses}" >&2
    missing=1
  fi
done < "${refs_file}"

if [[ "${missing}" -ne 0 ]]; then
  echo "Update manifest.yaml cache.actions (and rebuild the runner image)." >&2
  exit 1
fi

echo "All refs in ${refs_file} are covered by ${manifest_path}"
