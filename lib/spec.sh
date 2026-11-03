# shellcheck shell=bash
# Usage: source lib/spec.sh; spec_missing <project dir> <ref> <path>… → the first path not in <ref> (fetched now), one line, return 1
# A run's worktree is made from <ref> (origin/<main> or --base), so what its sessions can read is what <ref> holds, not
# the working tree: a spec that isn't there is refused before anything starts, and a queued start whose spec is gone by
# its dequeue is parked by the runner, never started (decisions/2026-10-31-spec-must-exist).

spec_missing() {
  local p=$1 ref=$2 f; shift 2
  git -C "$p" fetch -q origin 2> /dev/null || echo "spec: git fetch origin failed in $p; checking the last fetched $ref" >&2
  for f; do
    git -C "$p" cat-file -e "$ref:$f" 2> /dev/null && continue
    echo "spec $f: not in $ref (fetched now); commit and push it, or name its ref with --base"; return 1
  done
}

# <harness start args after the project> → SPEC_RUN (the run id, or ""), SPEC_ARG (--spec), SPEC_BASE (--base)
spec_args() {
  SPEC_RUN="" SPEC_ARG="" SPEC_BASE=""; [[ ${1:-} && $1 != --* ]] && { SPEC_RUN=$1; shift; }
  while (( $# )); do case $1 in --spec) SPEC_ARG=${2:-}; shift ;; --base) SPEC_BASE=${2:-}; shift ;;
    --brief|--brief-file|--until|--until-epoch) shift ;; esac; shift; done
}

# <project dir> <run id or ""> <--spec value> <--base value>, the project's config loaded: spec_missing's line and 1
# when a new run's spec (--spec, else SPEC_FILES; split on spaces) is not in its base ref; a resume and --brief alone pass
spec_new_run() {
  local p=$1 run=$2 spec=$3 base=$4 sp
  [[ -n $run && -d ${WT_ROOT:-${HARNESS_WORKTREES:-$HOME/worktrees}}/$(basename "$p")/$run ]] && return 0   # a resume: checked when it started
  read -ra sp <<< "${spec:-$SPEC_FILES}"; (( ${#sp[@]} )) || return 0   # --brief alone
  spec_missing "$p" "${base:-origin/$MAIN_BRANCH}" "${sp[@]}"
}

# <queue entry .args> → for a start entry, spec_new_run's line and 1 on a miss; any other entry passes. The runner's
# re-check at dequeue: the ref may have moved since `queue add` checked it, and an entry may be planted by hand.
# A subshell: the project's config must not leak into the runner's. A project that is no repository passes (its start
# says why, as before); a check that fails without a line (a config that exits) still gives one, never an empty reason.
spec_entry() {
  local a out rc=0; mapfile -t a < "$1"; a=("${a[@]//$'\x1f'/$'\n'}")   # queue_add's newlines back, as the runner reads them
  [[ ${a[0]:-} == start && -n ${a[1]:-} ]] || return 0
  git -C "${a[1]}" rev-parse --git-dir > /dev/null 2>&1 || return 0
  out=$( harness_config "${a[1]}"; spec_args "${a[@]:2}"; GIT_TERMINAL_PROMPT=0 spec_new_run "${a[1]}" "$SPEC_RUN" "$SPEC_ARG" "$SPEC_BASE" ) || rc=$?
  (( rc )) || return 0
  echo "${out:-spec check failed in ${a[1]} (exit $rc)}"; return 1
}
