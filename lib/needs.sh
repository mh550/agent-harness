# shellcheck shell=bash
# Usage: source lib/needs.sh; needs_open <reason> <subject> [key=value…] → the ref on stdout; 0 new, 3 refreshed, else
#        failed (noted) · needs_notify <ref> <message> [key=value…] · needs_sweep   (needs run_paths' STATE RUN_ID
#        PROJECT_NAME LIST REC RWT RBRANCH, record.sh's record and note, notify.sh's notify)
# The shell side of lib/needs.mjs (plan: docs/plans/2026-10-28-U2-needs-record.md §4.2). A record never stops a run.
NEEDS_MJS=$HARNESS_HOME/lib/needs.mjs
needs_open() {
  local r=$1 s=$2 rc; shift 2
  # under the record lock: two lanes never take one seq. A later key=value overrides an earlier one (the caller's
  # milestone= on the coordinator, where LANE is empty)
  record node "$NEEDS_MJS" open "$STATE" "$RUN_ID" "$PROJECT_NAME" "$r" "$s" \
    milestone="${LANE:-}" list="$LIST" record="$REC" inbox="$REC/INBOX.md" worktree="${HARNESS_WT:-$RWT}" \
    branch="${LBRANCH:-$RBRANCH}" record_branch="$RBRANCH" main_branch="$MAIN_BRANCH" \
    origin="$(git config --get remote.origin.url)" state="$STATE" suite="${CHECK_CMD:-}" fix_root="${HARNESS_SCRATCH_ROOT:-/tmp/harness}/$PROJECT_NAME" "$@"
  rc=$?; (( rc == 0 || rc == 3 )) || note "needs: could not record $r $s (exit $rc)" >&2   # stdout is the ref alone
  return "$rc"
}
# <ref> <message> [key=value…]: the record's title, body, click, priority and actions, sent; the caller's fields are
# the rest (tags=) and what goes out when the record can't be read (a failed open)
needs_notify() {
  local ref=$1 msg=$2 f=() x; shift 2
  [[ -n $ref ]] && while IFS= read -r -d '' x; do f+=("$x"); done < <(node "$NEEDS_MJS" fields "$STATE" "$ref" 2>> "$STATE/run.log")
  (( ${#f[@]} == 5 )) || { note "needs: no record ${ref:-(none)} to notify from; sent without it"; notify "$msg" "$@"; return 0; }
  notify "$msg" "$@" title="${f[0]}" body="${f[1]}" click="${f[2]}" priority="${f[3]}" actions="${f[4]}"
}
# the items the state now resolves move to needs/done/ (needs.md re-rendered), each noted
needs_sweep() {
  local out l; out=$(record node "$NEEDS_MJS" sweep "$STATE" 2>> "$STATE/run.log")
  while IFS= read -r l; do [[ -n $l ]] && note "needs: $l"; done <<< "$out"
  return 0
}
