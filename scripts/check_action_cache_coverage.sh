#!/usr/bin/env bash
# Fail if any third-party `uses: owner/repo@ref` under a workflows tree is
# missing from manifest.yaml cache.actions (exact ref match).
#
# Usage:
#   ./scripts/check_action_cache_coverage.sh <workflows_dir> [manifest.yaml]
#
# Skips local reusable workflows (./.github/...) and same-org workflow_call
# refs (Laelidona/..., DeerHide/...). Composite/action paths under an owner/repo
# (e.g. actions/cache/restore@v5.0.3) must appear as that full uses string or as
# the parent owner/repo@ref in cache.actions.
set -euo pipefail

workflows_dir="${1:-}"
manifest_path="${2:-manifest.yaml}"

if [[ -z "${workflows_dir}" || ! -d "${workflows_dir}" ]]; then
  echo "Usage: $0 <workflows_dir> [manifest.yaml]" >&2
  exit 2
fi

if [[ ! -f "${manifest_path}" ]]; then
  echo "Error: manifest not found at ${manifest_path}" >&2
  exit 1
fi

# ponytail: parse cache.actions with awk — list is flat strings under cache.actions.
# Ceiling: breaks if manifest nests differently; upgrade = yq.
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
    if [[ "${entry}" == "${want}" ]]; then
      return 0
    fi
  done
  # actions/cache/restore@v5.0.3 is covered by actions/cache@v5.0.3
  local owner_repo ref parent
  ref="${want##*@}"
  owner_repo="${want%@*}"
  if [[ "${owner_repo}" == */*/* ]]; then
    parent="${owner_repo%/*}@${ref}"
    for entry in "${cached[@]}"; do
      if [[ "${entry}" == "${parent}" ]]; then
        return 0
      fi
    done
  fi
  return 1
}

missing=0
while IFS= read -r uses; do
  [[ -z "${uses}" ]] && continue
  # Skip local and org reusable workflows
  case "${uses}" in
    ./*) continue ;;
    Laelidona/*) continue ;;
    DeerHide/*|deerhide/*) continue ;;
  esac
  if ! is_cached "${uses}"; then
    echo "MISSING from cache.actions: ${uses}" >&2
    missing=1
  fi
done < <(
  # Match `uses: owner/repo[@/path]@ref` (ignore comments / expressions)
  grep -RhoE 'uses:[[:space:]]*[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+@[A-Za-z0-9._/-]+' \
    "${workflows_dir}" \
    | sed -E 's/^uses:[[:space:]]*//' \
    | grep -Ev '\$\{\{' \
    | sort -u
)

if [[ "${missing}" -ne 0 ]]; then
  echo "Add the missing refs to ${manifest_path} cache.actions and rebuild the runner image." >&2
  exit 1
fi

echo "All third-party uses: refs under ${workflows_dir} are covered by ${manifest_path}"
