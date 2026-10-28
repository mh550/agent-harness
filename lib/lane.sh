#!/usr/bin/env bash
# Usage: lib/lane.sh <m>   → one milestone as its own process (lanes P1-04), started by lib/driver.sh (the coordinator)
# Its features in list order, each in a fresh coding session in the lane's slot worktree on harness-lane/<run>/<m>, then
# its verify and merge, then it exits; the reason also goes to $STATE/lanes/<m>/exit as "<code> <reason>":
#   0 verified and merged (or proposed, or its PR waits for a dependency) · 10 given up <ids> · 11 parked <ids> ·
#   12 needs Michael (verify, merge, feature-list edits) · 13 limit ended (session cap, usage limit, weekly budget) ·
#   14 stopped · 15 deadline
# Its services stay up when it closes (the next lane in its slot stops them; finish tears them down: D4); a lane that
# dies (the coordinator's TERM) stops its session and tears its services down at once.
# Environment: the driver's (WT = the record worktree, RUN_ID STATE PROJECT_DIR HARNESS_HOME) plus LANE LANE_SLOT
# LANE_PORT HARNESS_T0 HARNESS_DEADLINE LANE_MAX_SESSIONS; LANE_ONCE=1: the deadline's one verify, then exit.
# Plan: docs/plans/2026-10-26-P1-lanes-serial.md §6, §8.
set -uo pipefail
: "${WT:?}" "${RUN_ID:?}" "${STATE:?}" "${PROJECT_DIR:?}" "${HARNESS_HOME:?}" "${LANE:?}" "${LANE_SLOT:?}" "${LANE_PORT:?}"
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
source "$HARNESS_HOME/lib/review.sh"   # review_diff: the lane's diff the review gate sizes a review's model by (M6)
run_paths   # the record worktree's paths; from here the lane works in its slot
LANE=$M LANEU=${M//[^A-Za-z0-9_]/_} LDIR=$STATE/lanes/$M LS=$STATE/lanes/$M T0=$HARNESS_T0 DEADLINE=$HARNESS_DEADLINE
SLOT=$WT_ROOT_DIR/lanes/$RUN_ID/slot-$LANE_SLOT LBRANCH=harness-lane/$RUN_ID/$M
# its own units (harness-<run>-<m>-s<n>, -svc, -check-<pid>), port and scratch; the configuration and the session's
# --settings and .mcp.json are its slot's. BRANCH stays the record's: gh_url's links show the record, never a lane branch
WT=$SLOT PORT=$LANE_PORT SCRATCH=$SCRATCH/lanes/$M SVC_UNIT=$(scope_unit "$RUN_ID" "$LANEU-svc")
mkdir -p "$LDIR" "$SCRATCH"
lane_exit() { echo "$1 $2" > "$LDIR/exit"; exit "$1"; }
# A TERM (the coordinator exiting) runs this at once while a session goes on: its scope first, then the services
trap 'trap "" TERM INT HUP; [[ -n ${S_UNIT:-} ]] && scope_stop "$S_UNIT"
  if [[ ! -s $LDIR/exit ]]; then services_down "driver exited"; echo "12 lane exited unexpectedly" > "$LDIR/exit"; fi' EXIT
lane_cd || lane_exit 12 "its slot $SLOT is gone"
load_config; MAX_SESSIONS=$LANE_MAX_SESSIONS
lane_cd   # after load_config: sessions see the slot and the lane branch as HARNESS_WT and HARNESS_BRANCH
export HARNESS_SCOPE_PREFIX; HARNESS_SCOPE_PREFIX=$(scope_unit "$RUN_ID" "$LANEU")   # its suites run as harness-<run>-<m>-check-<pid>

# Independently re-check milestone m, in its lane. 0 = verified (tagged) · 1 = not verified · 2 = deferred (a usage
# limit: retry). `once` (at the deadline): one session, no escalation, and this round is the last
# (decisions/2026-10-26-verify-before-deadline). The session reads a copy of the record; what it un-passes in it is
# applied to the record's list afterwards.
verify() {
  local m=$1 out vlog rounds model short before vstart reverted result=fail need="" failed=() maxr=$MAX_VERIFY_ROUNDS id
  local models=("$VERIFY_MODEL" "$VERIFY_ESCALATE_MODEL") last=$VERIFY_ESCALATE_MODEL
  rounds=$(( $(cat "$STATE/verify-rounds-$m" 2>/dev/null || echo 0) + 1 ))
  [[ ${2:-} == once ]] && { models=("$VERIFY_MODEL"); maxr=$rounds last="one verify at the deadline"; }
  sync_main || touch "$STATE/nomerge-$m"
  sync_lane
  # the verified tree's suite runs in full: a session can leave a stale green marker (decisions/2026-10-26-verify-runs-the-suite)
  note "verify $m: suite cache cleared; the suite runs in full on the verified tree"
  run_init fresh
  for model in "${models[@]}"; do
    context "$m" "$CONTEXT_PACK_BYTES_VERIFY"   # each round: an escalated verify's pack has the first round's entry
    materialize
    before=$(vcount "$m"); vstart=$(git rev-parse HEAD)
    mem_gate || run_init   # before the clock, so the prompt's time is the session's; a wait stopped the services
    HARNESS_CLOCK=$(clock "verify round $rounds of $maxr") HARNESS_MILESTONE=$m HARNESS_FEATURES=$(F ids "$LIST" "$m" | paste -sd' ') prompt verify
    vlog="$LOGS/$(date +%H%M%S)-verify-$m.jsonl"
    log "verify $m · $(F model "$model")"
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
    for id in $(F ids "$LIST" "$m"); do F passes "$SLIST" "$id" || record F unpass "$LIST" "$id"; done   # the verdict, on the record
    unmaterialize
    record MET append "$vlog" "$REC/metrics.jsonl" "$RUN_ID" verify "$m" "$(F model "$model")" \
      "$(F milestone-done "$LIST" "$m" && echo true || echo false)" "$S_WALL" "$S_EXIT" false verify "$S_PEAK" "$LANE"
    F milestone-done "$LIST" "$m" || { result=fail; break; }
    if (( $(vcount "$m") <= before )); then short="no new verify entry"
    elif short=$(F evidence "$LIST" "$m" "$REC/progress.md"); then result=hold; break; fi
    [[ $model == "${models[-1]}" ]] && { result=thin; break; }   # the last model (the only one in once mode)
    note "verify $m: evidence short of the steps ($short); re-running on $VERIFY_ESCALATE_MODEL"
  done
  echo "$rounds" > "$STATE/verify-rounds-$m"
  if [[ $result == hold ]] && ! green; then result=red; fi   # on the slot's tree, the one tagged below
  case $result in
    hold)
      touch "$STATE/verified-$m"
      git tag -a "run/$RUN_ID/$m" -m "harness run $RUN_ID: $m verified (v3)" 2>/dev/null \
        && git push -q origin "run/$RUN_ID/$m" 2>> "$STATE/run.log"
      note "$m verified and tagged run/$RUN_ID/$m"
      rec_commit "HARNESS: $m verified"; sync_record
      [[ -f $STATE/nomerge-$m ]] || merge_milestones "$m"
      return 0 ;;
    thin) touch "$STATE/needs-$m"; note "verify $m: evidence still short of the steps ($short) after $last; not verified (needs Michael)"
      need="verify evidence too thin" ;;
    red) touch "$STATE/needs-$m"; note "verify $m: the suite is red on the verified tree (main merged in); not verified (needs Michael)"
      need="suite red after merging main" ;;
    fail)
      for id in $(F ids "$LIST" "$m"); do
        F passes "$LIST" "$id" && continue
        if (( rounds < maxr )); then
          note "verify $m: $id failed the re-check, back in the queue (one more attempt)"; record F grant "$ATT" "$id" "$MAX_ATTEMPTS"
        else
          touch "$STATE/needs-$m"; note "verify $m: $id failed the re-check in round $rounds of $maxr; $m needs Michael (see progress.md)"
          failed+=("$id")
        fi
      done
      if (( ${#failed[@]} == 1 )); then need="${failed[0]} fails verification"
      elif (( ${#failed[@]} )); then need=$(printf '%s, ' "${failed[@]}"); need="${need%, } fail verification"; fi ;;
  esac
  printf '%s' "$need" > "$LDIR/need"   # the lane's exit reason
  rec_commit "HARNESS: verify $m"; sync_record
  [[ -n $need ]] && needs_you "$m" "$need" progress.md   # after the push: the click shows the verify entry
  return 1
}

# Verified: merged, proposed or waiting on a dependency's merge is the lane's 0; a merge that needs Michael its 12
lane_done() {
  if [[ -f $STATE/merged-$M ]]; then lane_exit 0 "$M merged"
  elif [[ -f $STATE/proposed-$M ]]; then lane_exit 0 "$M proposed"
  elif [[ -f $STATE/waits-$M ]]; then lane_exit 0 "$M verified; its PR waits"
  elif [[ -f $STATE/nomerge-$M ]]; then lane_exit 12 "$M needs Michael: $MAIN_BRANCH conflicts with its lane"
  elif [[ $MERGE_POLICY == off ]]; then lane_exit 0 "$M verified"
  else lane_exit 12 "$M needs Michael: its merge"; fi
}
in_lane() { local m; m=$(F milestone "$LIST" "$1"); [[ ${m:-default} == "$M" ]]; }

if [[ ${LANE_ONCE:-0} == 1 ]]; then   # the deadline's verify: no cap, deadline or control check (the coordinator decided)
  verify "$M" once && lane_done
  [[ -f $STATE/needs-$M ]] && lane_exit 12 "$M needs Michael: $(cat "$LDIR/need" 2> /dev/null)"
  lane_exit 15 deadline
fi

repairs=0 gated=0
while :; do
  lane_cd
  (( $(cat "$STATE/sessions") >= MAX_SESSIONS )) && lane_exit 13 "session cap ($MAX_SESSIONS)"
  (( $(date +%s) >= DEADLINE )) && lane_exit 15 deadline
  take_answers; sync_record
  for id in $(record F unpark "$PARKED" "$(answers_hash)"); do note "$id unparked: INBOX.md has new answers"; done
  c=$(control)
  [[ $c == stop ]] && lane_exit 14 stopped
  if [[ $c == pause ]]; then   # after its session: the services go, nothing new starts (the coordinator logs the pause)
    services_down paused; rec_commit "HARNESS: lane $M paused"; sync_record
    while [[ $(control) == pause ]]; do
      (( $(date +%s) >= DEADLINE )) && lane_exit 15 deadline
      sleep "${HARNESS_PAUSE_POLL:-60}"; take_answers; sync_record
    done
    continue
  fi
  limit_wait
  (( $(date +%s) >= DEADLINE )) && continue
  if why=$(weekly_over "$USAGE"); then note "stopping before the next session: $why"; lane_exit 13 "weekly budget ($why)"; fi

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
  next=$(F next "$LIST" "$ATT" "$MAX_ATTEMPTS" "$PARKED" "$M")
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
  kind=$(F kind "$LIST" "$id")
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
  n=$(rec_count "$STATE/sessions" 1)
  [[ $esc ]] || record F bump "$ATT" "$id"
  run_init; context "$id"; materialize   # the copy, the snapshot and the INBOX the session is judged against
  if [[ $esc ]]; then sclock="Review round 2 of 2 (escalated: $esc)"; else sclock="attempt $(jq -r --arg id "$id" '.[$id] // 0' "$ATT") of $MAX_ATTEMPTS"; fi
  # the counts the gate reads (the findings check below and the summary's found_nothing), asked in one fixed form
  [[ $kind == review ]] && rdiff+=$'\n'"Review findings: give your entry's summary this review's findings as \`<n> Critical, <n> Important, <n> Minor\` (the driver reads the counts)."
  HARNESS_CLOCK=$(clock "$sclock") HARNESS_FEATURE=$id HARNESS_MILESTONE=$milestone HARNESS_REVIEW_DIFF=$rdiff prompt coding
  log "session $n · $id · $mdl"
  slog="$LOGS/$(printf '%02d' "$n")-$id.jsonl"
  sstart=$(git rev-parse HEAD)
  session coding "$mdl" "$slog" "$id"
  commit_all "WIP: $id — uncommitted at session end (harness)"; sync_lane   # the copy is excluded: code only
  journal coding "$id" "$slog" "$mdl" "$sstart"   # before the limit branch and F repair: every session is journaled
  take_question   # what it asked above ## Answers, into the record's INBOX.md
  lane_guard "$sstart" "$id"
  gotchas "$id" "$sstart"   # a limited session's edit is noted too

  # A usage/rate limit, an API error or a session that did no work is not the feature's fault: give the attempt back.
  # Its work stays (committed above); its claims never reach the record (the copy goes).
  if why=$(MET limit "$slog" "$S_WALL" "$S_EXIT"); then
    IFS=$'\t' read -r reason reset <<< "$why"
    unmaterialize
    [[ $esc ]] || record F unbump "$ATT" "$id"   # an escalation round runs again after the wait
    rec_count "$STATE/sessions" -1 > /dev/null; limits=$(rec_count "$STATE/limits" 1)
    record MET append "$slog" "$REC/metrics.jsonl" "$RUN_ID" coding "$id" "$mdl" false "$S_WALL" "$S_EXIT" true "" "$S_PEAK" "$LANE"
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
  if F passes "$SLIST" "$id" && ! green; then F unpass "$SLIST" "$id"; note "$id un-passed: suite red after the session"; fi
  tests_end   # the slot's tree, after the un-pass above ran its suite
  passed=$(F passes "$SLIST" "$id" && echo true || echo false)
  unmaterialize
  if [[ $passed == true ]]; then record F pass "$LIST" "$id"; else record F unpass "$LIST" "$id"; fi
  record MET append "$slog" "$REC/metrics.jsonl" "$RUN_ID" coding "$id" "$mdl" "$passed" "$S_WALL" "$S_EXIT" false "$kind" "$S_PEAK" "$LANE"
  note "$id · $mdl · passes=$passed · $(( S_WALL / 60 )) min · $(F summary "$LIST")$( [[ -f $STATE/tests-end ]] && echo " · tests $(cat "$STATE/tests-end")")"
  if [[ $passed == false ]] && why=$(MET final "$slog" | sed -n 's/^[[:space:]*`>-]*PARKED:[[:space:]]*//p' | head -1) && [[ -n $why ]]; then
    [[ $esc ]] || record F unbump "$ATT" "$id"; record F park "$PARKED" "$id" "$(answers_hash)" "$why"   # waiting on Michael is not the feature's fault (an escalation round took none)
    note "$id parked (waiting on Michael): $why"
  else why=""; fi
  if [[ $esc ]]; then rm -f "$LS/review-escalate"   # the round ran; its verdict stands
  elif [[ -z $why && $mdl == "$(F model sonnet)" && $kind == review && ! -e $STATE/review-escalated-$id ]]; then
    # a sonnet review that found something gets one round on REVIEW_ESCALATE_MODEL, once per feature; un-passed first,
    # so its verify waits for that round's verdict (decisions/2026-10-27-review-gate). Its entry is in the record now.
    if rf=$(node "$HARNESS_HOME/lib/entries.mjs" findings "$REC" "$id" "$SCRATCH/entry-final"); then
      IFS=$'\t' read -r rc ri <<< "$rf"
      if (( rc + ri > 0 )); then
        note "review $id: sonnet found $rc Critical, $ri Important; one round on $REVIEW_ESCALATE_MODEL"
        record F unpass "$LIST" "$id"; touch "$STATE/review-escalated-$id"
        printf '%s\t%s\t%s\t%s\n' "$id" "$rc" "$ri" "${rdiff%%$'\n'*}" > "$LS/review-escalate"
      fi
    else note "review $id: no \"<n> Critical, <n> Important\" in its summary or final message; not escalated"; fi
  fi
  rec_commit "HARNESS: after $id (passes=$passed)"; sync_record
  if [[ -n $why ]]; then   # after the push, so its links show the question; a failed post's note is committed too
    notify_park "$id" "$why"; [[ -n $(git -C "$RWT" status --porcelain -- "$RUN_DIR") ]] && { rec_commit "HARNESS: park notification failed"; sync_record; }
    desk "$id parked: $why"
  fi
done
