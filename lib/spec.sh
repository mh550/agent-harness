# shellcheck shell=bash
# Usage: source lib/spec.sh; spec_missing <project dir> <ref> <path>… → the first path not in <ref> (fetched now), one line, return 1
# A run's worktree is made from <ref> (origin/<main> or --base), so what its sessions can read is what <ref> holds, not
# the working tree: a spec that isn't there is refused before anything starts (decisions/2026-10-31-spec-must-exist).

spec_missing() {
  local p=$1 ref=$2 f; shift 2
  git -C "$p" fetch -q origin 2> /dev/null || echo "spec: git fetch origin failed in $p; checking the last fetched $ref" >&2
  for f; do
    git -C "$p" cat-file -e "$ref:$f" 2> /dev/null && continue
    echo "spec $f: not in $ref (fetched now); commit and push it, or name its ref with --base"; return 1
  done
}
