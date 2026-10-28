# shellcheck shell=bash
# Usage: source lib/needs.sh; needs_open <reason> <subject> [key=value…]   (needs run_paths' STATE RUN_ID PROJECT_NAME
#        LIST REC RWT RBRANCH and record.sh's record, note) → the ref on stdout; 0 new, 3 refreshed, else failed (noted)
# The shell side of lib/needs.mjs (plan: docs/plans/2026-10-28-U2-needs-record.md §4.2). A record never stops a run.
NEEDS_MJS=$HARNESS_HOME/lib/needs.mjs
needs_open() {
  local r=$1 s=$2 rc; shift 2
  # under the record lock: two lanes never take one seq. A later key=value overrides an earlier one (the caller's
  # milestone= on the coordinator, where LANE is empty)
  record node "$NEEDS_MJS" open "$STATE" "$RUN_ID" "$PROJECT_NAME" "$r" "$s" \
    milestone="${LANE:-}" list="$LIST" record="$REC" inbox="$REC/INBOX.md" worktree="${HARNESS_WT:-$RWT}" \
    branch="${LBRANCH:-$RBRANCH}" record_branch="$RBRANCH" main_branch="$MAIN_BRANCH" \
    origin="$(git config --get remote.origin.url)" state="$STATE" suite="${CHECK_CMD:-}" "$@"
  rc=$?; (( rc == 0 || rc == 3 )) || note "needs: could not record $r $s (exit $rc)"
  return "$rc"
}
