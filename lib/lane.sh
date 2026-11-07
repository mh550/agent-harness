#!/usr/bin/env bash
# Usage: lib/lane.sh <m>   → one milestone as its own process (lanes P1-04), started by lib/driver.sh (the coordinator)
# Its features in list order, each in a fresh coding session in the lane's slot worktree on harness-lane/<run>/<m>, then
# its verify and merge, then it exits; the reason also goes to $STATE/lanes/<m>/exit as "<code> <reason>":
#   0 verified and merged (or proposed, or its PR waits for a dependency) · 10 given up <ids> · 11 parked <ids> ·
#   12 needs Michael (verify, merge, feature-list edits) · 13 limit ended (session cap, usage limit, weekly budget) ·
#   14 stopped · 15 deadline · 16 the run is ending (another lane ended it: state/lanes-end holds why)
# Its services stay up when it closes (the next lane in its slot stops them; finish tears them down: D4); a lane that
# dies (the coordinator's TERM) stops its session and tears its services down at once.
# Environment: the driver's (WT = the record worktree, RUN_ID STATE PROJECT_DIR HARNESS_HOME) plus LANE LANE_SLOT
# LANE_PORT HARNESS_T0 HARNESS_DEADLINE LANE_MAX_SESSIONS; LANE_ONCE=1: the deadline's one verify, then exit;
# LANE_MERGE=1: a verified milestone whose main moved (state/rebase-<m>): only its re-base and merge, then exit.
# Plans: docs/plans/2026-10-26-P1-lanes-serial.md §6, §8; docs/plans/2026-10-26-P2-two-lanes.md §3 (the re-base).
set -uo pipefail
: "${WT:?}" "${RUN_ID:?}" "${STATE:?}" "${PROJECT_DIR:?}" "${HARNESS_HOME:?}" "${LANE:?}" "${LANE_SLOT:?}" "${LANE_PORT:?}"
[[ -z ${HARNESS_XTRACE:-} ]] || source "$HARNESS_HOME/lib/xtrace.sh"   # the coverage trace, off unless set (lib/xtrace.sh)
M=$1
cd "$WT" || exit 1
# shellcheck source=lib/config.sh
source "$HARNESS_HOME/lib/config.sh"
# shellcheck source=lib/prompt.sh
source "$HARNESS_HOME/lib/prompt.sh"
# shellcheck source=lib/scope.sh
source "$HARNESS_HOME/lib/scope.sh"
# shellcheck source=lib/notify.sh
source "$HARNESS_HOME/lib/notify.sh"; NOTIFY_TAG=$RUN_ID
# shellcheck source=lib/record.sh
source "$HARNESS_HOME/lib/record.sh"
# shellcheck source=lib/needs.sh
source "$HARNESS_HOME/lib/needs.sh"   # needs_open: a needs-you record (lib/needs.mjs)
source "$HARNESS_HOME/lib/review.sh"   # review_diff: the lane's diff the review gate sizes a review's model by (M6)
source "$HARNESS_HOME/lib/resolve.sh"   # resolve: a merge with main that conflicts, resolved by a session (N2)
run_paths   # the record worktree's paths; from here the lane works in its slot
LANE=$M LANEU=${M//[^A-Za-z0-9_]/_} LDIR=$STATE/lanes/$M LS=$STATE/lanes/$M T0=$HARNESS_T0 DEADLINE=$HARNESS_DEADLINE
SLOT=$WT_ROOT_DIR/lanes/$RUN_ID/slot-$LANE_SLOT LBRANCH=harness-lane/$RUN_ID/$M
# its own units (harness-<run>-<m>-s<n>, -svc, -check-<pid>), port and scratch; the configuration and the session's
# --settings and .mcp.json are its slot's. BRANCH stays the record's: gh_url's links show the record, never a lane branch
WT=$SLOT PORT=$LANE_PORT SCRATCH=$SCRATCH/lanes/$M SVC_UNIT=$(scope_unit "$RUN_ID" "$LANEU-svc")
mkdir -p "$LDIR" "$SCRATCH"
lane_exit() { echo "$1 $2" > "$LDIR/exit"; exit "$1"; }
# A TERM (the coordinator exiting) runs this at once while a session goes on: its scope first, then the services (a forked
# child inherits it and skips it)
trap '[[ $BASHPID == "$$" ]] || exit 0; trap "" TERM INT HUP; [[ -n ${S_UNIT:-} ]] && scope_stop "$S_UNIT"
  if [[ ! -s $LDIR/exit ]]; then services_down "driver exited"; echo "12 lane exited unexpectedly" > "$LDIR/exit"; fi; helper_stop' EXIT
lane_cd || lane_exit 12 "its slot $SLOT is gone"
load_config; MAX_SESSIONS=$LANE_MAX_SESSIONS
lane_cd   # after load_config: sessions see the slot and the lane branch as HARNESS_WT and HARNESS_BRANCH
export HARNESS_SCOPE_PREFIX; HARNESS_SCOPE_PREFIX=$(scope_unit "$RUN_ID" "$LANEU")   # its suites run as harness-<run>-<m>-check-<pid>
export HARNESS_LANE=$M   # check.sh names it in a flakes.jsonl row, its sessions' {{CHECK}} calls too

# A red suite's names, of the slot's tree as `green` just left it (decisions/2026-11-04-fix-rounds): RED_FILES, the
# red-<key> marker's stored names when it exists, else its output's last HARNESS_FAILED= line (none: the whole suite);
# RED_NAMES, every `FAIL <name>` line of that output (the tree's first run, check-<key>.out), else the files, else
# "whole suite": never empty; RED_OUT, that output.
red_names() {
  local key l; key=$(ask treekey.mjs 2> /dev/null)
  RED_NAMES=() RED_FILES=() RED_OUT=$SCRATCH/check-$key.out; [[ -n $key && -f $RED_OUT ]] || RED_OUT=$SCRATCH/check.out
  if [[ -n $key && -f $STATE/green/red-$key ]]; then read -ra RED_FILES <<< "$(sed -n 2p "$STATE/green/red-$key")"
  else read -ra RED_FILES <<< "$(sed -n 's/^HARNESS_FAILED=//p' "$RED_OUT" 2> /dev/null | tail -1)"; fi
  while IFS= read -r l; do [[ -n $l ]] && RED_NAMES+=("$l"); done < <(sed -n 's/^FAIL //p' "$RED_OUT" 2> /dev/null)
  (( ${#RED_NAMES[@]} )) || RED_NAMES=("${RED_FILES[@]}")
  (( ${#RED_NAMES[@]} )) || RED_NAMES=("whole suite")
}
# <m> <r> <verify-rounds-<m> before this verify> <whose the red is>: round r opens instead of the card. Under one hold
# of the record lock: the fix feature onto the record's list (the driver's one list write besides repair's; the next
# session's before.json is snapshotted after it, materialize_), then the red's last 200 lines into the record
# (fix/<m>-<r>.out), the counters, the fix_round row, the note and their commit; no needs-<m>, record or notification.
# The verdict was the suite's, the evidence held: verify-rounds-<m> goes back. 1: the feature could not be appended
# (noted; nothing of the round is written): the caller opens the card.
# <m> → the ids of m's features that don't pass, when there is one and every one is a fix feature; else 1
fix_unpassed() {
  jq -er --arg m "$1" '[.features[] | select(.milestone == $m and (.passes | not))] | if length > 0 and all(.kind == "fix") then .[].id else empty end' "$LIST" 2>> "$STATE/run.log"
}
fix_open() { record fix_open_ "$@" || return 1; : > "$LDIR/need"; sync_record; return 0; }
fix_open_() {
  local m=$1 r=$2 added id
  # the steps name the suite as sessions see it ($HARNESS_CHECK): an absolute path would trip the lint's outside-repo
  added=$(F fix-add "$LIST" "$m" "$r" all "${RED_NAMES[@]}" -- "${RED_FILES[@]}" -- "$RUN_DIR/fix/$m-$r.out" '$HARNESS_CHECK' "$WORKER_MODEL" 2>> "$STATE/run.log") \
    || { note "verify $m: fix round $r could not be opened (its feature was not appended; see run.log)"; return 1; }
  id=${added%%$'\t'*}
  mkdir -p "$REC/fix"; tail -n 200 "$RED_OUT" > "$REC/fix/$m-$r.out" 2>> "$STATE/run.log"
  echo "$r" > "$STATE/fix-rounds-$m"; echo "$r" > "$STATE/fix-open-$m"; echo "$3" > "$STATE/verify-rounds-$m"
  MET fix-round "$REC/metrics.jsonl" open "$RUN_ID" "$m" "$r" all "$id" "${RED_NAMES[@]}" -- "${RED_FILES[@]}"
  note "verify $m: the suite is red on the verified tree ($4); fix round $r of $MAX_FIX_ROUNDS: $id appended (${added#*$'\t'})"
  rec_commit_ "HARNESS: verify $m: fix round $r"
}

# <m>, at its verified verdict: the check names m's tree adds, replaces and removes against its base, from the fixture
# CHECK_NAMES (decisions/2026-11-03-check-budget). The base: main as this lane merged it (the merge-base), or the tag of
# a milestone the lane opened from when that is later (a dependency not yet on main; with two, the second one's own names
# count here too). Without the fixture on either side nothing is written; else checks-<m> (summary.json's by_milestone)
# and one note `<m>: checks +a ~b −c`, with the list's check_budget for m when it has one and, over it, the reason the
# milestone's last coding entry gave in `checks` (`none given` without). A note, never a gate.
checks_note() {
  local m=$1 base t j b="" why="" words
  base=$(git merge-base HEAD "origin/$MAIN_BRANCH" 2> /dev/null) || return 0
  for t in $(F deps "$LIST" "$m"); do t=run/$RUN_ID/$t
    git merge-base --is-ancestor "$t" HEAD 2> /dev/null && git merge-base --is-ancestor "$base" "$t" 2> /dev/null && base=$t
  done
  # a blob on each side, or nothing: `git show <commit>:` with an empty CHECK_NAMES (a project opting out) or a directory
  # would print the tree's listing and count file names as check names (the S3 review's finding)
  for t in base tip; do
    local c=HEAD; [[ $t == base ]] && c=$base
    if [[ $(git cat-file -t "$c:$CHECK_NAMES" 2> /dev/null) == blob ]]; then git show "$c:$CHECK_NAMES" > "$SCRATCH/checks-$t.txt"; else : > "$SCRATCH/checks-$t.txt"; fi
  done
  [[ -s $SCRATCH/checks-base.txt || -s $SCRATCH/checks-tip.txt ]] || return 0
  j=$(SUM checks-diff "$SCRATCH/checks-base.txt" "$SCRATCH/checks-tip.txt" 2>> "$STATE/run.log") || return 0
  words="checks $(jq -r '"+\(.added) ~\(.replaced) −\(.removed)"' <<< "$j")"
  if b=$(F budget "$LIST" "$m"); then
    words+=" against a budget of $b"
    if (( $(jq -r .added <<< "$j") > b )); then
      why=$(ask entries.mjs checks-reason "$REC" $(F ids "$LIST" "$m") 2>> "$STATE/run.log"); words+=" (over budget: ${why:-none given})"
    fi
  fi
  jq -c --argjson b "${b:-null}" '. + {budget: $b}' <<< "$j" > "$STATE/checks-$m"
  note "$m: $words"
}

# Independently re-check milestone m, in its lane. 0 = verified (tagged) · 1 = not verified · 2 = deferred (a usage
# limit: retry). `once` (at the deadline): one session, no escalation, and this round is the last
# (decisions/2026-10-26-verify-before-deadline). `rebase`: the re-base's verify round (rebase below) on the merged
# tree: no attempt granted on a failure, the tag moved on a hold, no merge here (the caller's loop merges). The session
# reads a copy of the record; what it un-passes in it is applied to the record's list afterwards.
verify() {
  local m=$1 out vlog rounds model short before vstart reverted result=fail need="" failed=() maxr=$MAX_VERIFY_ROUNDS id nref="" rc own=0
  local models=("$VERIFY_MODEL" "$VERIFY_ESCALATE_MODEL") last=$VERIFY_ESCALATE_MODEL
  rounds=$(( $(cat "$STATE/verify-rounds-$m" 2>/dev/null || echo 0) + 1 ))
  local mode=${2:-} what="verify round $rounds of $maxr"
  [[ $mode == once ]] && { models=("$VERIFY_MODEL"); maxr=$rounds last="one verify at the deadline"; what="verify round $rounds of $maxr"; }
  [[ $mode == rebase ]] && { maxr=$rounds what="re-base verify round $(cat "$STATE/rebase-rounds-$m") of $MAX_REBASE_ROUNDS"; }
  rm -f "$STATE/nomerge-$m"   # a conflict an earlier verify found: this one tries main again
  if [[ $mode != rebase ]]; then   # a re-base round verifies the tree rebase just made; a main that moved since is the next re-base's
    local pre; pre=$(git rev-parse HEAD); sync_main; rc=$?
    (( rc == 0 )) && [[ $(git rev-parse HEAD) == "$pre" ]] && own=1   # main had nothing new: a red verified tree is the milestone's own
    # refused (a resolve session's limit): no round counted, the lane loop waits for the window, then this verify again
    (( rc == 2 )) && { [[ -n $RESOLVE_END ]] && lane_exit 13 "$RESOLVE_END"; return 2; }
    (( rc == 1 )) && touch "$STATE/nomerge-$m"
  fi
  sync_lane
  # the verified tree's suite runs in full: a session can leave a stale green marker (decisions/2026-10-26-verify-runs-the-suite)
  note "verify $m: suite cache cleared; the suite runs in full on the verified tree"
  run_init fresh
  for model in "${models[@]}"; do
    pack_and_copy "$m" "$CONTEXT_PACK_BYTES_VERIFY"   # each round: an escalated verify's pack has the first round's entry
    before=$(vcount "$m"); vstart=$(git rev-parse HEAD)
    if ! mem_gate; then   # before the clock, so the prompt's time is the session's; a wait stopped the services
      [[ -f $STATE/lanes-end || $(control) == stop ]] && { unmaterialize; return 2; }   # cut short: the loop's top ends the lane
      run_init
    fi
    local vids; Fv vids ids "$LIST" "$m"   # Fv: answered in this shell, so the memo keeps it (lib/record.sh)
    HARNESS_CLOCK=$(clock "$what") HARNESS_MILESTONE=$m HARNESS_FEATURES=${vids//$'\n'/ } prompt verify
    vlog="$LOGS/$(date +%H%M%S)-verify-$m.jsonl"
    log "verify $m · $(F model "$model")"; echo "$what" > "$LDIR/now"
    session verify "$(F model "$model")" "$vlog" "verify $m"
    reverted=$(restrict "$vstart" record verify | paste -sd' ')
    [[ -n $reverted ]] && note "verify $m: reverted code edits the verifier may not make: $reverted"
    journal verify "$m" "$vlog" "$(F model "$model")" "$vstart"   # before the limit branch: a refused verify is journaled too
    lane_guard "$vstart" "verify $m"; sync_lane
    rec_commit "HARNESS: journal verify $m"
    if why=$(MET limit "$vlog" "$S_WALL" "$S_EXIT"); then   # refused: no verdict, and nothing reached the record's list
      unmaterialize
      record MET append "$vlog" "$REC/metrics.jsonl" "$RUN_ID" verify "$m" "$(F model "$model")" false "$S_WALL" "$S_EXIT" true verify "$S_PEAK" "$LANE"
      local upto; upto=$(( ${why##*$'\t'} > 0 ? ${why##*$'\t'} + 120 : $(date +%s) + 900 ))
      record limit_raise "$upto"
      note "verify $m refused (${why%%$'\t'*}); deferred until $(date -d "@$upto" '+%H:%M')"
      rec_commit "HARNESS: verify $m deferred"; sync_record; return 2
    fi
    out=$(F repair-verify "$SLIST" "$LS/before.json" "$m") || note "verify $m: reverted list edits beyond un-passing: $out"
    Fv vids ids "$LIST" "$m"
    for id in $vids; do F passes "$SLIST" "$id" || record F unpass "$LIST" "$id"; done   # the verdict, on the record
    unmaterialize
    local vdone=false; F milestone-done "$LIST" "$m" && vdone=true
    record MET append "$vlog" "$REC/metrics.jsonl" "$RUN_ID" verify "$m" "$(F model "$model")" \
      "$vdone" "$S_WALL" "$S_EXIT" false verify "$S_PEAK" "$LANE"
    local vnew=false vev=false vlast=false vr
    [[ $model == "${models[-1]}" ]] && vlast=true   # the last model (the only one in once mode)
    if [[ $vdone == true ]]; then
      if (( $(vcount "$m") <= before )); then short="no new verify entry"
      else vnew=true; short=$(F evidence "$LIST" "$m" "$REC/progress.md") && vev=true; fi
    fi
    vr=$(ask lane.mjs verify-round "$vdone" "$vnew" "$vev" "$vlast")
    # no answer: a milestone not done is the fail; a done one is thin, the card (a fail with every feature passing has none,
    # and the lane would verify again and again)
    [[ -n $vr ]] || { [[ $vdone == true ]] && vr=thin || vr=fail; }
    case $vr in fail | hold | thin) result=$vr; break ;; esac
    note "verify $m: evidence short of the steps ($short); re-running on $VERIFY_ESCALATE_MODEL"
  done
  echo "$rounds" > "$STATE/verify-rounds-$m"
  # The suite runs on the slot's tree, the one tagged below, and only on a hold or on a fail where fix features are all
  # the verifier un-passed. One that performs a fix feature's steps as written (its last is the full suite) un-passes it
  # on a tree whose suite is red. That verdict is the suite's, and the rule below answers it (the next round, or the
  # card), not a re-check's attempt: on a red suite they pass again and the result is red
  local fixu="" sgreen=1 was=$result
  if [[ $result == hold ]] || { [[ $result == fail ]] && fixu=$(fix_unpassed "$m"); }; then green || sgreen=0; fi
  local sv; sv=$(ask lane.mjs suite-verdict "$result" "$sgreen" "${fixu:+1}")
  if [[ -n $sv ]]; then result=$sv; else (( sgreen )) || result=red; fi   # no answer: a red suite is never a hold
  if [[ $was == fail && $result == red ]]; then
    for id in $fixu; do record F pass "$LIST" "$id"; done
    note "verify $m: the verifier un-passed ${fixu//$'\n'/, } on a red suite; the verdict is the suite's (a fix round or the card, no re-check)"
  fi
  flakes_note
  # Fix rounds (decisions/2026-11-04-fix-rounds). The suite spoke (hold: green; red: after check.sh's rerun guard, so
  # never a flake): the round that is open (fix-open-<m>) gets its fix_result row, once. A thin or failed verify has no
  # suite verdict and leaves it open for the next one.
  local fixn fixr fixed="" fixj=""; RED_NAMES=()
  fixn=$(cat "$STATE/fix-rounds-$m" 2> /dev/null || echo 0); fixr=$(cat "$STATE/fix-open-$m" 2> /dev/null)
  [[ $result == red ]] && red_names
  if [[ -n $fixr && $result == @(hold|red) ]]; then
    record MET fix-round "$REC/metrics.jsonl" result "$RUN_ID" "$m" "$fixr" all "${RED_NAMES[@]}"
    rm -f "$STATE/fix-open-$m"; [[ $result == hold ]] && fixed=" (after fix round $fixr)"
  fi
  case $result in
    hold)
      touch "$STATE/verified-$m"
      checks_note "$m"
      if [[ $mode == rebase ]]; then   # the tag exists: moved to the merged commit, the one forced push (the old stays reachable from its PR)
        git tag -f -a "run/$RUN_ID/$m" -m "harness run $RUN_ID: $m verified (v3); re-based on $MAIN_BRANCH, verify round $(cat "$STATE/rebase-rounds-$m")" > /dev/null \
          && tag_push "$m" --force
        note "$m verified on the re-based tree and re-tagged run/$RUN_ID/$m$(tag_local_words "$m")"
      else
        # a tag an earlier verify made and could not push goes now; one origin has stays as it is
        if git tag -a "run/$RUN_ID/$m" -m "harness run $RUN_ID: $m verified (v3)" 2>> "$STATE/run.log" || [[ -f $STATE/tag-local-$m ]]; then tag_push "$m"; fi
        if [[ -z $(tag_commit "$m") ]]; then note "$m verified$fixed; tag run/$RUN_ID/$m could not be made (see run.log)"   # lane_done's last branch says the rest
        elif [[ -f $STATE/tag-local-$m ]]; then note "$m verified$(tag_local_words "$m")$fixed"
        else note "$m verified and tagged run/$RUN_ID/$m$fixed"; fi
      fi
      rec_commit "HARNESS: $m verified"; sync_record
      if [[ $mode == once ]]; then [[ -f $STATE/nomerge-$m ]] || merge_milestones "$m"   # past the deadline: a re-base waits for the next segment
      elif [[ $mode != rebase && ! -f $STATE/nomerge-$m ]]; then merge_own; fi
      return 0 ;;
    thin) touch "$STATE/needs-$m"; note "verify $m: evidence still short of the steps ($short) after $last; not verified (needs Michael)"
      ;;
    red)
      # with main merged in, main and the milestone disagree; without, a slow-tier red the fast gate let through (fast-gate)
      local whose="main merged in" after=""
      (( own )) && whose="main had nothing new: a slow-tier red the fast gate let through"
      # under MAX_FIX_ROUNDS a red opens a fix round, no card: the lane loop's next pick is its feature, then this verify
      # again. In a plain verify only: `once` is past the deadline (no session can follow), `rebase`'s caller is no lane loop
      if ask lane.mjs fix-round "$mode" "$fixn" "$MAX_FIX_ROUNDS" && fix_open "$m" $(( fixn + 1 )) $(( rounds - 1 )) "$whose"; then return 1; fi
      # the card, as before fix rounds; after rounds (never a re-base's: its milestone was verified since) the note names
      # them (their ids from the list) and the card's why what each left red (the rows, paired by metrics.mjs fixPairs)
      touch "$STATE/needs-$m"
      if [[ $mode != rebase ]] && (( fixn )); then
        after=" after $fixn fix round$( (( fixn == 1 )) || echo s) ($(jq -r --arg m "$m" '[.features[] | select(.milestone == $m and .kind == "fix") | .id] | join(", ")' "$LIST"))"
        fixj=$(MET fix-rounds "$REC/metrics.jsonl" "$m" 2>> "$STATE/run.log")
      fi
      note "verify $m: the suite is red on the verified tree ($whose); not verified (needs Michael)$after" ;;
    fail)
      local fids; Fv fids ids "$LIST" "$m"
      for id in $fids; do
        F passes "$LIST" "$id" && continue
        if (( rounds < maxr )); then
          note "verify $m: $id failed the re-check, back in the queue (one more attempt)"; record F grant "$ATT" "$id" "$MAX_ATTEMPTS"
        else
          touch "$STATE/needs-$m"; note "verify $m: $id failed the re-check in round $rounds of $maxr; $m needs Michael (see progress.md)"
          failed+=("$id")
        fi
      done ;;
  esac
  # its need, the lane's exit reason, and its card: thin, red, or the re-check's failed ids (verify_recheck's rebase words are rebase_fail's)
  local k v reason="" variant=""
  while read -r k v; do case $k in need) need=$v ;; reason) reason=$v ;; variant) variant=$v ;; esac; done < <(ask lane.mjs verdict "$result" "$own" "$mode" "${failed[@]}")
  # no answer where the verdict needs Michael (needs-<m> is there): words of its own and the card, never an empty need
  [[ -n $need || ! -f $STATE/needs-$m ]] || { need="verify $result (see harness-log.md)" reason=verify_${result/#fail/recheck}; }
  if [[ $mode == rebase ]]; then   # not verified on today's main: the old tag must not merge, and a later verify tags afresh
    rm -f "$STATE/verified-$m" "$STATE/tag-local-$m" "$STATE/merge-failed-$m"; git tag -d "run/$RUN_ID/$m" > /dev/null 2>&1   # this verdict's card speaks for it now
    origin_t git push -q origin --delete "refs/tags/run/$RUN_ID/$m" 8>&- 2>> "$STATE/run.log"
    note "verify $m: the re-based tree did not hold; tag run/$RUN_ID/$m removed"
  fi
  printf '%s' "$need" > "$LDIR/need"
  [[ -n $need ]] && nref=$(needs_open "$reason" "$m" milestone="$m" failed="${failed[*]}" variant="$variant" ${fixj:+"rounds=$fixj"})   # its record, committed with the verdict
  rec_commit "HARNESS: verify $m"; sync_record
  [[ -n $need ]] && needs_you "$m" "$need" progress.md "$nref"   # after the push: the click shows the verify entry
  return 1
}

# Main moved under the verified tag (state/rebase-<m>, merge_one's 3): main merged into the verified commit, then the
# files main brought in compared with the milestone's own (decisions/2026-10-26-lane-rebase-disjoint). Disjoint, under
# LANE_REBASE=suite: the suite in full on the merged tree, in this lane's check scope; green, the tag moves there.
# Overlapping, or LANE_REBASE=verify: one verify round on it (MAX_REBASE_ROUNDS per milestone). 0 = re-tagged, or
# nothing left to re-base: merge it · 1 = not (needs Michael; or a usage limit deferred the round, rebase-<m> back).
# A merge that conflicts goes to a resolve session (CONFLICTS=resolve, a round left): resolved, it always takes the
# verify round, whatever LANE_REBASE says (decisions/2026-10-29-conflict-resolution).
# Cwd the slot, on the lane branch. At most 3 re-bases per lane process: a main that keeps moving needs Michael.
REBASES=0
rebase() {
  local m=$1 tag=run/$RUN_ID/$1 c mn base theirs ours both n r how rc files resolved=""
  rm -f "$STATE/rebase-$m"; echo "re-base on $MAIN_BRANCH" > "$LDIR/now"   # harness status's lane line
  c=$(git rev-list -n1 "$tag" 2> /dev/null) || { touch "$STATE/needs-$m"; printf 'its tag is gone' > "$LDIR/need"; note "$m: its tag $tag is gone; not re-based (needs Michael)"
    needs_open verify_recheck "$m" milestone="$m" variant=tag > /dev/null; return 1; }
  fetch_main_ 2>> "$STATE/run.log"; mn=$(git rev-parse "origin/$MAIN_BRANCH")
  # merged meanwhile: nothing to re-base (else an empty `ours` would read as disjoint and re-tag main's tip)
  [[ -f $STATE/merged-$m ]] || git merge-base --is-ancestor "$c" "$mn" && return 0
  (( ++REBASES > 3 )) && { rebase_fail "$m" "$c" "$m: $MAIN_BRANCH moved during 3 re-bases; not merged (needs Michael)" "$MAIN_BRANCH kept moving" merge_conflict moving; return 1; }
  base=$(git merge-base "$c" "$mn")   # main as this lane last merged it (verify's sync_main)
  git checkout -q -B "$LBRANCH" "$c"   # the verified tip, nothing else
  r=$(( $(cat "$STATE/rebase-rounds-$m" 2> /dev/null || echo 0) + 1 ))
  merge_main "$m" "$( (( r <= MAX_REBASE_ROUNDS )) && echo resolve)"; rc=$?   # a resolution needs a verify round left
  (( rc == 2 )) && { echo "$mn" > "$STATE/rebase-$m"; [[ -n $RESOLVE_END ]] && lane_exit 13 "$RESOLVE_END"; return 1; }   # refused: the re-base again after the wait
  # conflict-<m>: merge_one's once per main, so the run's end doesn't record it again (and lose tried)
  (( rc == 0 )) || { echo "$mn" > "$STATE/conflict-$m"
    rebase_fail "$m" "$c" "$m conflicts with $MAIN_BRANCH; not merged (needs Michael)" "conflicts with $MAIN_BRANCH" merge_conflict rebase files="$MERGE_FILES" main="$mn" ${RESOLVE_TRIED:+tried="$RESOLVE_TRIED"}; return 1; }
  resolved=$MERGE_RESOLVED; [[ -n $resolved ]] && resolved_note "$m" "one verify round follows"
  main_clear "$m"   # main is in the lane branch now: a main_conflict an earlier verify opened resolves
  theirs=$(git diff --name-only "$c" HEAD)   # what main brought in
  ours=$(git diff --name-only "$base" "$c")   # the milestone's own (and its unmerged dependencies')
  both=$(comm -12 <(sort <<< "$ours") <(sort <<< "$theirs") | grep . | paste -sd' ')
  n=$(grep -c . <<< "$theirs"); how="$MAIN_BRANCH ${mn:0:7}: $n files"
  if [[ -z $both && $LANE_REBASE != verify && -z $resolved ]]; then
    run_init fresh   # the install, then the suite in full (marker cleared), as harness-<run>-<m>-check-<pid>
    cp "$SCRATCH/init.out" "$LDIR/rebase-check.out"   # its uncached `check: …` line: the evidence
    green; rc=$?; flakes_note
    (( rc == 0 )) || { rebase_fail "$m" "$c" "$m re-based on $how, disjoint, suite red; not merged (needs Michael)" "suite red after the re-base" verify_red rebase; return 1; }
    git tag -f -a "$tag" -m "harness run $RUN_ID: $m verified (v3); re-based on $MAIN_BRANCH ${mn:0:7}, suite green" > /dev/null
    # the one forced push, to the tag ref alone: the old commit stays reachable from the lane branch and its PR
    tag_push "$m" --force
    sync_lane   # a fast-forward to the merge commit
    note "$m re-based on $how, disjoint, suite green; re-tagged$(tag_local_words "$m")"
    rec_commit "HARNESS: $m re-based"; sync_record; return 0
  fi
  if [[ -n $both ]]; then how+=", overlapping ($both)"; elif [[ -n $resolved ]]; then how+=", resolved by a session ($RESOLVE_FILES)"; else how+=", disjoint"; fi
  (( r > MAX_REBASE_ROUNDS )) && { rebase_fail "$m" "$c" "$m re-based on $how; its $MAX_REBASE_ROUNDS re-base round(s) used; not merged (needs Michael)" "re-base rounds used" verify_recheck rebase; return 1; }
  echo "$r" > "$STATE/rebase-rounds-$m"; sync_lane   # the verify works on the merged commit
  note "$m re-based on $how; one verify round ($( [[ -n $both || -n $resolved ]] && echo "$r of $MAX_REBASE_ROUNDS" || echo LANE_REBASE=verify))"
  rec_commit "HARNESS: $m re-based; one verify round"; sync_record
  verify "$m" rebase; rc=$?
  (( rc == 2 )) && { echo $(( r - 1 )) > "$STATE/rebase-rounds-$m"; echo "$mn" > "$STATE/rebase-$m"   # refused: the round (and its resolve) again later
    [[ -n $resolved ]] && { rm -f "$STATE/resolve-$m-$mn"; rec_count "$STATE/resolves-$m" -1 > /dev/null; }; }
  (( rc == 0 ))
}
# <m> <verified commit> <note> <need> <reason> <variant> [key=value…]: the slot back at the verified commit (the merge
# commit never pushed), its needs record opened, Michael asked
rebase_fail() {
  local m=$1 c=$2 msg=$3 need=$4 r=$5 v=$6 ref; shift 6
  git reset -q --hard "$c"; touch "$STATE/needs-$m"; printf '%s' "$need" > "$LDIR/need"
  note "$msg"; ref=$(needs_open "$r" "$m" milestone="$m" variant="$v" head="$c" "$@")
  rec_commit "HARNESS: $m not re-based"; sync_record; needs_you "$m" "$need" harness-log.md "$ref"
}
# This lane's milestone merged (merge_milestones: the dependency rule, MERGE_POLICY), re-based first whenever main moved
merge_own() { merge_milestones "$M"; while [[ -f $STATE/rebase-$M ]]; do rebase "$M" || break; merge_milestones "$M"; done; }

# Verified: merged, proposed, waiting on a dependency's merge or on its re-base's deferred round is the lane's 0; a
# merge or re-base that needs Michael its 12. A lane never closes "needs Michael" without a card: every branch's card
# exists; the last, which nothing should reach, opens one (fail-closed), and no answer takes that branch too.
lane_done() {
  local f on=() a mf
  for f in merged needs rebase proposed waits nomerge main-conflict refused conflict; do [[ -f $STATE/$f-$M ]] && on+=("$f"); done
  a=$(ask lane.mjs lane-done "$M" "$MAIN_BRANCH" "$MERGE_POLICY" "$(cat "$LDIR/need" 2> /dev/null)" "${on[@]}")   # <code> <merge failed 0|1> <reason>
  [[ -n $a ]] || a="12 1 $M needs Michael: its merge"
  mf=${a#* }; mf=${mf%% *}
  [[ $mf == 1 ]] && merge_failed "$M" unknown
  lane_exit "${a%% *}" "${a#* * }"
}
in_lane() { local m; m=$(F milestone "$LIST" "$1"); [[ ${m:-default} == "$M" ]]; }

if [[ ${LANE_MERGE:-0} == 1 ]]; then   # opened on the verified commit (slot_open) for its re-base and merge alone
  limit_wait || { [[ -f $STATE/lanes-end ]] && lane_exit 16 "the run is ending ($(cat "$STATE/lanes-end"))"; lane_exit 14 stopped; }
  while [[ -f $STATE/rebase-$M ]]; do rebase "$M" || break; merge_milestones "$M"; done
  lane_done
fi
if [[ ${LANE_ONCE:-0} == 1 ]]; then   # the deadline's verify: no cap, deadline or control check (the coordinator decided)
  verify "$M" once && lane_done
  [[ -f $STATE/needs-$M ]] && lane_exit 12 "$M needs Michael: $(cat "$LDIR/need" 2> /dev/null)"
  lane_exit 15 deadline
fi

repairs=0 gated=0
while :; do
  lane_cd
  [[ -f $STATE/lanes-end ]] && lane_exit 16 "the run is ending ($(cat "$STATE/lanes-end"))"
  (( $(cat "$STATE/sessions") >= MAX_SESSIONS )) && lane_exit 13 "session cap ($MAX_SESSIONS)"
  past_deadline && lane_exit 15 deadline
  take_answers; sync_record
  for id in $(record F unpark "$PARKED" "$(answers_hash)"); do note "$id unparked: INBOX.md has new answers"; done
  needs_sweep   # before the pick: an unparked feature's record resolves
  c=$(control)
  [[ $c == stop ]] && lane_exit 14 stopped
  if [[ $c == pause ]]; then   # after its session: the services go, nothing new starts (the coordinator logs the pause)
    services_down paused; rec_commit "HARNESS: lane $M paused"; sync_record
    while [[ $(control) == pause ]]; do
      past_deadline && lane_exit 15 deadline
      [[ -f $STATE/lanes-end ]] && lane_exit 16 "the run is ending ($(cat "$STATE/lanes-end"))"
      sleep "${HARNESS_PAUSE_POLL:-60}"; take_answers; sync_record
    done
    continue
  fi
  limit_wait || continue   # cut short by the run's end or a stop: the checks above say which
  past_deadline && continue
  if why=$(weekly_over "$USAGE"); then note "stopping before the next session: $why"; lane_exit 13 "weekly budget ($why)"; fi

  # one node start (F poll) answers milestone-done and next below, parked and blocked too, from the memo it fills
  F poll "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED" "$M" > /dev/null   # in this shell: the memo keeps what it fills
  # complete: its verify, then its merge (merge_milestones: the dependency rule, MERGE_POLICY)
  if [[ $M != default ]] && F milestone-done "$LIST" "$M"; then
    verify "$M"; rc=$?
    (( rc == 0 )) && lane_done
    (( rc == 2 )) && continue   # deferred by a usage limit: the window is waited for first
    [[ -f $STATE/needs-$M ]] && lane_exit 12 "$M needs Michael: $(cat "$LDIR/need" 2> /dev/null)"
    continue   # a feature back in the queue
  fi
  esc=""   # a sonnet review's escalation round goes before any pick: same feature, REVIEW_ESCALATE_MODEL, no attempt (M6)
  if [[ -s $LS/review-escalate ]]; then   # the lane's own: a feature of this milestone (decisions/2026-10-27-p1-main-merge)
    IFS=$'\t' read -r id rc ri rdiff < "$LS/review-escalate"
    milestone=$(F milestone "$LIST" "$id") mdl=$(F model "$REVIEW_ESCALATE_MODEL") esc="sonnet found $rc Critical, $ri Important"
    rdiff="${rdiff%; *}; escalated to $REVIEW_ESCALATE_MODEL"   # the measure stands; the model it named doesn't
  else
  Fv next next "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED" "$M"
  if [[ -z $next ]]; then
    # the default lane (features with no milestone) has no verify: done when they all pass
    [[ $M == default ]] && jq -e '[.features[] | select((.milestone // "") == "")] | all(.passes)' "$LIST" > /dev/null \
      && lane_exit 0 "default: every feature passes"
    p=$(F parked "$PARKED" "$LIST" | cut -f1 | while read -r id; do in_lane "$id" && echo "$id"; done | paste -sd, -)
    [[ -n $p ]] && lane_exit 11 "parked $p"
    g=$(F blocked "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED" "$M" | awk -F'\t' '{print $2}' | sort -u | paste -sd, -)
    lane_exit 10 "given up ${g:-(nothing left to try)}"
  fi
  IFS=$'\t' read -r id mdl milestone <<< "$next"
  fi
  # the memory gate before the attempt and its prompt; after a wait, the checks above (deadline, stop, pause, the pick)
  # run again, and the gate doesn't: once is enough, then the session starts anyway (decisions/2026-10-25-memory-gate)
  if (( ! gated )) && ! mem_gate; then gated=1; continue; fi; gated=0
  [[ $esc ]] || rdiff=""   # the review gate: a review runs on sonnet under REVIEW_OPUS_LINES changed lines, on opus at or over (M6)
  Fv kind kind "$LIST" "$id"
  if [[ ! $esc && $kind == review ]]; then
    if rd=$(review_diff); then   # the slot's lane branch against main: this milestone's diff
      read -r rfiles rlines <<< "$rd"
      if [[ -e $STATE/review-escalated-$id ]]; then   # its round ran (and parked or failed): the next attempt stays there
        mdl=$(F model "$REVIEW_ESCALATE_MODEL") rside="escalated earlier in this run; $REVIEW_ESCALATE_MODEL"
      elif (( rlines < REVIEW_OPUS_LINES )); then mdl=$(F model sonnet) rside="under $REVIEW_OPUS_LINES; sonnet"
      else mdl=$(F model opus) rside="at or over $REVIEW_OPUS_LINES; opus"; fi
      note "review $id: $rlines changed lines, $rside"
      rdiff="Review diff: $rfiles files, $rlines changed lines (git diff --shortstat origin/$MAIN_BRANCH...HEAD, the run directory left out); $rside"
    else   # unmeasured: the safe side
      mdl=$(F model opus); note "review $id: diff not measured ($rd); opus"
      rdiff="Review diff: not measured ($rd); opus"
    fi
  fi
  n=$(rec_count "$STATE/sessions" 1)   # the cap once more, atomically: another lane's session may have taken the last
  (( n > MAX_SESSIONS )) && { rec_count "$STATE/sessions" -1 > /dev/null; lane_exit 13 "session cap ($MAX_SESSIONS)"; }
  [[ $esc ]] || record F bump "$ATT" "$id"
  run_init fast; pack_and_copy "$id"   # the copy, the snapshot and the INBOX the session is judged against; the fast tier
  if [[ $esc ]]; then sclock="Review round 2 of 2 (escalated: $esc)"; else sclock="attempt $(jq -r --arg id "$id" '.[$id] // 0' "$ATT") of $MAX_ATTEMPTS"; fi
  # the counts the gate reads (the findings check below and the summary's found_nothing), asked in one fixed form
  [[ $kind == review ]] && rdiff+=$'\n'"Review findings: give your entry's summary this review's findings as \`<n> Critical, <n> Important, <n> Minor\` (the driver reads the counts)."
  HARNESS_CLOCK=$(clock "$sclock") HARNESS_FEATURE=$id HARNESS_MILESTONE=$milestone HARNESS_MODEL=$mdl HARNESS_REVIEW_DIFF=$rdiff prompt coding
  log "session $n · $id · $mdl"; printf '%s · session %s\n' "$id" "$n" > "$LDIR/now"   # harness status's lane line
  slog="$LOGS/$(printf '%02d' "$n")-$id.jsonl"
  sstart=$(git rev-parse HEAD)
  t0=$(date +%s.%6N); session coding "$mdl" "$slog" "$id"; t1=$(date +%s.%6N)   # the session's own suite calls are check-runs.log's rows in between
  commit_all "WIP: $id — uncommitted at session end (harness)"   # the copy is excluded: code only
  memory_guard "$sstart" "$id"; sync_lane   # its CLAUDE.md edit goes before the journal and the gate see the tree
  # the full and fast ones apart for metrics.jsonl's suite_runs, suite_full and suite_fast: no log, no third field, so all
  # null (decisions/2026-10-31-one-full-run, decisions/2026-11-03-fast-gate)
  read -r sn ss sf sk < <(awk -F'\t' -v a="$t0" -v b="$t1" '$1 > a && $1 < b && $2 != "cached" { n++; s += $3; f += ($2 == "full"); k += ($2 == "fast") }
    END { print n + 0, s + 0, f + 0, k + 0 }' "$SCRATCH/check-runs.log" 2> /dev/null || echo "0 0")
  nsuite=${sf:+$sn}
  note "$id: suite ran ${sn}x ($ss s) in the session"
  journal coding "$id" "$slog" "$mdl" "$sstart"   # before the limit branch and F repair: every session is journaled
  inbox_repair "$id" "$LS/inbox-before.md" "$SLOT/$RUN_DIR/INBOX.md"   # a question inside the comment, moved out first
  take_question   # what it asked above ## Answers, into the record's INBOX.md
  lane_guard "$sstart" "$id"

  # A usage/rate limit, an API error or a session that did no work is not the feature's fault: give the attempt back.
  # Its work stays (committed above); its claims never reach the record (the copy goes).
  if why=$(MET limit "$slog" "$S_WALL" "$S_EXIT"); then
    IFS=$'\t' read -r reason reset <<< "$why"
    unmaterialize
    [[ $esc ]] || record F unbump "$ATT" "$id"   # an escalation round runs again after the wait
    rec_count "$STATE/sessions" -1 > /dev/null; limits=$(rec_count "$STATE/limits" 1)
    record MET append "$slog" "$REC/metrics.jsonl" "$RUN_ID" coding "$id" "$mdl" false "$S_WALL" "$S_EXIT" true "" "$S_PEAK" "$LANE" "$nsuite" "$sf" "$sk"
    if (( limits >= MAX_LIMIT_HITS )); then
      note "$limits sessions in a row refused ($reason)"
      lane_exit 13 "usage limit ($limits sessions refused in a row)"
    fi
    read -ra waits <<< "$LIMIT_WAITS"; w=${waits[$(( limits > ${#waits[@]} ? ${#waits[@]} - 1 : limits - 1 ))]}
    upto=$(( ${reset:-0} > 0 ? reset + 120 : $(date +%s) + w ))
    record limit_raise "$upto"
    (( limits == 1 )) && notify "refused ($reason); waiting until $(date -d "@$upto" '+%H:%M')"
    note "session for $id hit a limit ($reason); not counted; resuming at $(date -d "@$upto" '+%H:%M')"
    rec_commit "HARNESS: usage limit"; sync_record
    continue
  fi
  echo 0 > "$STATE/limits"   # a session went through

  # the driver's checks act on the session's copy; only the flip reaches the record's list
  if out=$(F repair "$SLIST" "$LS/before.json" "$id"); then repairs=0; else
    repairs=$(( repairs + 1 )); note "restored the feature list after $id: $out"
    (( repairs >= MAX_REPAIRS )) && { note "$repairs sessions in a row edited the feature list; stopping for Michael"; lane_exit 12 "feature-list edits"; }
  fi
  # passes stands on the fast tier; the full suite runs at the verify (decisions/2026-11-03-fast-gate). A fix feature's
  # stands on its red's files first, then the fast tier (green_fix, decisions/2026-11-04-fix-rounds)
  if F passes "$SLIST" "$id"; then
    if [[ $kind == fix ]]; then green_fix "$id" || { F unpass "$SLIST" "$id"; note "$id un-passed: $FIX_RED red after the session"; }
    elif ! green_fast; then F unpass "$SLIST" "$id"; note "$id un-passed: fast tier red after the session"; fi
  fi
  flakes_note   # the rows of that suite and of the session's own calls
  tests_end   # the slot's tree: a full green-<key> only, so after a fast-gated session the last full count stays
  passed=$(F passes "$SLIST" "$id" && echo true || echo false)
  unmaterialize
  why=""; [[ $passed == false ]] && why=$(MET final "$slog" | sed -n 's/^[[:space:]*`>-]*PARKED:[[:space:]]*//p' | head -1)
  nref=""
  if [[ $esc ]]; then rm -f "$LS/review-escalate"   # the round ran; its verdict stands
  elif [[ -z $why && $mdl == "$(F model sonnet)" && $kind == review && ! -e $STATE/review-escalated-$id ]]; then
    # a sonnet review that found something gets one round on REVIEW_ESCALATE_MODEL, once per feature; un-passed before its
    # record, row and passes= note, so its verify waits for that round's verdict (decisions/2026-10-27-review-gate). Its
    # entry is in the record now.
    if rf=$(ask entries.mjs findings "$REC" "$id" "$SCRATCH/entry-final"); then
      IFS=$'\t' read -r rc ri <<< "$rf"
      if (( rc + ri > 0 )); then
        note "review $id: sonnet found $rc Critical, $ri Important; one round on $REVIEW_ESCALATE_MODEL"
        passed=false; touch "$STATE/review-escalated-$id"
        printf '%s\t%s\t%s\t%s\n' "$id" "$rc" "$ri" "${rdiff%%$'\n'*}" > "$LS/review-escalate"
      fi
    else note "review $id: no \"<n> Critical, <n> Important\" in its summary or final message; not escalated"; fi
  fi
  if [[ $passed == true ]]; then record F pass "$LIST" "$id"; else record F unpass "$LIST" "$id"; fi
  record MET append "$slog" "$REC/metrics.jsonl" "$RUN_ID" coding "$id" "$mdl" "$passed" "$S_WALL" "$S_EXIT" false "$kind" "$S_PEAK" "$LANE" "$nsuite" "$sf" "$sk"
  note "$id · $mdl · passes=$passed · $(( S_WALL / 60 )) min · $(F summary "$LIST")$( [[ -f $STATE/tests-end ]] && echo " · tests $(cat "$STATE/tests-end")")"
  if [[ -n $why ]]; then   # waiting on Michael is not the feature's fault (an escalation round took none)
    [[ $esc ]] || record F unbump "$ATT" "$id"; record F park "$PARKED" "$id" "$(answers_hash)" "$why"
    note "$id parked (waiting on Michael): $why"
  fi
  # the needs records, committed with this session's record (needs.md, the park's click): a park (its question is in the
  # record's INBOX.md now), a feature whose attempts are used up without a park or a pending escalation round
  if [[ -n $why ]]; then   # a question without a Files: line points at the session's files (its entry's, then its diff)
    nref=$(needs_open parked "$id" feature="$id" why="$why" actions="$(park_actions)" \
      session_files="$(ask entries.mjs session-files "$REC" "$id" "$SCRATCH/entry-files" "$PWD")")
    [[ -n $nref ]] && jq -e '.card.files_from == "session" and (.card.question.text // "") != ""' "$STATE/needs/${nref##*/}.json" > /dev/null 2>&1 \
      && note "$id: its INBOX question had no Files: line; the park card's where is the session's files"   # the entry's own fill is journal_'s note
  elif [[ $passed == false && ! -s $LS/review-escalate ]] && (( $(jq -r --arg id "$id" '.[$id] // 0' "$ATT") >= MAX_ATTEMPTS )); then
    needs_open given_up "$id" feature="$id" attempts="$(jq -r --arg id "$id" '.[$id]' "$ATT")" max_attempts="$MAX_ATTEMPTS" log="$slog" > /dev/null
  fi
  rec_commit "HARNESS: after $id (passes=$passed)"; sync_record
  if [[ -n $why ]]; then   # after the push, so its links show the question; a failed post's note is committed too
    notify_park "$id" "$why" "$nref"; [[ -n $(git -C "$RWT" status --porcelain -- "$RUN_DIR") ]] && { rec_commit "HARNESS: park notification failed"; sync_record; }
    desk "$id parked: $why"
  fi
done
