# shellcheck shell=bash
# Usage: source lib/resolve.sh   → resolve <who> <what>: a merge left in conflict, resolved by a session and committed, or aborted
# Layer 2 of conflict resolution (decisions/2026-10-29-conflict-resolution; plan docs/plans/2026-10-29-N2-conflict-resolution.md):
# sourced by lib/lane.sh after lib/record.sh, so it runs in a lane, in its slot, on its lane branch. What it commits is
# never merged as it is: the caller's verify round re-checks the merged tree first (the gate).

# <m> → 0 when a resolve session may run for this merge, else the reason on stdout and 1. Cwd a merge in progress.
resolve_ok() {
  local m=$1 mn n lim
  [[ ${CONFLICTS:-} == resolve ]] || { echo "CONFLICTS=${CONFLICTS:-unset}"; return 1; }
  [[ ${HARNESS_MERGE_ONLY:-} ]] && { echo "harness merge"; return 1; }   # no session runs from a CLI command
  [[ -n ${LANE:-} ]] || { echo "not in a lane"; return 1; }   # the record branch's conflicts are Michael's
  mn=$(git rev-parse -q --verify MERGE_HEAD) || { echo "no merge in progress"; return 1; }
  [[ -f $STATE/resolve-$m-$mn ]] && { echo "a resolve session already ran for main ${mn:0:7}"; return 1; }
  n=$(cat "$STATE/resolves-$m" 2> /dev/null || echo 0)
  (( n >= MAX_RESOLVES )) && { echo "its $n resolve session(s) used"; return 1; }
  lim=$(dur_s "$RESOLVE_TIMEOUT") || lim=1800
  (( $(date +%s) + lim > DEADLINE )) && { echo "less than RESOLVE_TIMEOUT ($RESOLVE_TIMEOUT) before the deadline"; return 1; }
  return 0
}

# <m> <what merged in>, cwd the slot with the merge in progress. 0 = resolved and committed (the merge commit) · 1 =
# unresolved (no session, or it or the checks below failed): merge aborted · 2 = refused by a limit (deferred): merge
# aborted. Sets RESOLVE_TRIED (empty when no session ran), RESOLVE_FILES ("a, b"), RESOLVE_MODEL_RAN, RESOLVE_MIN and
# RESOLVE_END (set: the lane must end with 13, as the coding loop does at the cap, the weekly gate or MAX_LIMIT_HITS).
resolve() {
  local m=$1 what=$2 fa=() files mn pre mb why model rlog n limits upto line rec p RESTORED=()
  local -A snap=() unt=() conf=() mk=()
  RESOLVE_TRIED="" RESOLVE_FILES="" RESOLVE_MODEL_RAN="" RESOLVE_MIN=0 RESOLVE_END=""
  files=$(git -c core.quotePath=false diff --name-only --diff-filter=U); [[ -n $files ]] && mapfile -t fa <<< "$files"
  (( ${#fa[@]} )) || { git merge --abort 2> /dev/null; return 1; }   # the merge never started
  RESOLVE_FILES=$(printf '%s, ' "${fa[@]}" | sed 's/, $//')
  if ! why=$(resolve_ok "$m"); then
    [[ $why == *"resolve session(s) used" ]] && { note "$m: $why; not merged (needs Michael)"; RESOLVE_TRIED=$why; }
    # this main's session failed before: its marker holds what it said, so the card a later record replaces keeps it
    [[ $why == "a resolve session already ran"* ]] && RESOLVE_TRIED=$(cat "$STATE/resolve-$m-$(git rev-parse MERGE_HEAD)" 2> /dev/null)
    git merge --abort 2> /dev/null; return 1
  fi
  mn=$(git rev-parse MERGE_HEAD) pre=$(git rev-parse HEAD)
  note "$m: ${#fa[@]} files conflict with $what ($RESOLVE_FILES); a resolve session"
  # the session cap and the weekly gate, as the coding loop's (lane.sh)
  n=$(rec_count "$STATE/sessions" 1)
  if (( n > MAX_SESSIONS )); then rec_count "$STATE/sessions" -1 > /dev/null; git merge --abort 2> /dev/null; RESOLVE_END="session cap ($MAX_SESSIONS)"; return 2; fi
  if why=$(weekly_over "$USAGE"); then
    rec_count "$STATE/sessions" -1 > /dev/null; note "stopping before the resolve session: $why"; git merge --abort 2> /dev/null; RESOLVE_END="weekly budget ($why)"; return 2
  fi
  if ! mem_gate && [[ -f $STATE/lanes-end || $(control) == stop ]]; then   # a wait cut short: the lane loop's top says why
    rec_count "$STATE/sessions" -1 > /dev/null; git merge --abort 2> /dev/null; return 2
  fi
  # what git merged by itself (stage 0) and what was untracked: anything else the session touches is put back. NUL-
  # separated, so a path with a blank or a non-ASCII byte is itself; kept in $SCRATCH for a look after the run
  git ls-files -s -z -- . ":!$RUN_DIR" > "$SCRATCH/resolve-index"
  git ls-files --others --exclude-standard -z -- . ":!$RUN_DIR" > "$SCRATCH/resolve-untracked"
  while IFS= read -r -d '' rec; do [[ ${rec%%$'\t'*} == *" 0" ]] && snap[${rec#*$'\t'}]=${rec%% 0$'\t'*}; done < "$SCRATCH/resolve-index"
  while IFS= read -r -d '' p; do unt[$p]=1; done < "$SCRATCH/resolve-untracked"
  for p in "${fa[@]}"; do   # marker-like lines either side already had (a setext underline) aren't the session's
    conf[$p]=1; n=$(git show ":2:$p" 2> /dev/null | marker_lines); mk[$p]=$(git show ":3:$p" 2> /dev/null | marker_lines); (( n > ${mk[$p]} )) && mk[$p]=$n
  done
  materialize   # the slot's copy of the record: entry.json's home (no context pack)
  mb=$(git merge-base HEAD MERGE_HEAD)
  local SESSION_TIMEOUT=$RESOLVE_TIMEOUT MAX_TURNS=$RESOLVE_MAX_TURNS SESSION_BUDGET_USD=$RESOLVE_BUDGET_USD   # session() and clock() read these
  model=$(F model "$RESOLVE_MODEL")
  HARNESS_MILESTONE=$m HARNESS_FEATURES=$(F ids "$LIST" "$m" | paste -sd' ') \
    HARNESS_FEATURE_LINES=$(jq -r --arg m "$m" '.features[] | select(.milestone == $m) | "- `\(.id)` · \(.description)"' "$LIST") \
    HARNESS_MERGING=$what HARNESS_CONFLICT_FILES=$files \
    HARNESS_OURS=$(git log --format=%s -n 20 "$mb..HEAD" -- "${fa[@]}") HARNESS_THEIRS=$(git log --format=%s -n 20 "$mb..MERGE_HEAD" -- "${fa[@]}") \
    HARNESS_CLOCK=$(clock "resolve session for $m: $what merged in") prompt resolve
  rlog="$LOGS/$(date +%H%M%S)-resolve-$m.jsonl"
  log "resolve $m · $model"; echo "resolve session" > "$LDIR/now"
  session resolve "$model" "$rlog" "resolve $m"
  journal resolve "$m" "$rlog" "$model" "$pre"   # before the restore and the limit branch: a refused session is journaled too
  unmaterialize
  RESOLVE_MIN=$(( (S_WALL + 59) / 60 )) RESOLVE_MODEL_RAN=$model
  if why=$(MET limit "$rlog" "$S_WALL" "$S_EXIT"); then   # refused: no verdict; the same session again after the wait
    rec_count "$STATE/sessions" -1 > /dev/null; limits=$(rec_count "$STATE/limits" 1)
    record MET append "$rlog" "$REC/metrics.jsonl" "$RUN_ID" resolve "$m" "$model" false "$S_WALL" "$S_EXIT" true resolve "$S_PEAK" "$LANE"
    resolve_undo "$pre"
    if (( limits >= MAX_LIMIT_HITS )); then
      RESOLVE_TRIED="a resolve session ($model): refused $limits times in a row (${why%%$'\t'*})"
      note "$limits sessions in a row refused (${why%%$'\t'*})"; RESOLVE_END="usage limit ($limits sessions refused in a row)"; return 2
    fi
    upto=$(( ${why##*$'\t'} > 0 ? ${why##*$'\t'} + 120 : $(date +%s) + 900 ))
    record limit_raise "$upto"
    note "$m: the resolve session was refused (${why%%$'\t'*}); deferred until $(date -d "@$upto" '+%H:%M')"
    rec_commit "HARNESS: resolve $m deferred"; sync_record; return 2
  fi
  echo 0 > "$STATE/limits"; rec_count "$STATE/resolves-$m" 1 > /dev/null; : > "$STATE/resolve-$m-$mn"   # a session went through
  # the driver's checks, in order: the first that fails is why
  why="" line=$(MET final "$rlog" 2> /dev/null | sed -n '/^[[:space:]*`>-]*UNRESOLVED:/{s/^[[:space:]*`>-]*UNRESOLVED:[[:space:]]*//;p;q}')
  if [[ $(git rev-parse HEAD) != "$pre" ]] || ! git rev-parse -q --verify MERGE_HEAD > /dev/null; then why="it committed or aborted the merge itself"
  elif [[ -n $line ]]; then why="UNRESOLVED: $line"
  elif files=$(git -c core.quotePath=false diff --name-only --diff-filter=U) && [[ -n $files ]]; then why="$(paste -sd' ' <<< "$files") still unmerged"
  else
    files=""; for p in "${fa[@]}"; do [[ -f $p ]] && (( $(marker_lines < "$p") > ${mk[$p]} )) && files+=" $p"; done
    [[ -n $files ]] && why="conflict markers left in${files}"
  fi
  if [[ -z $why ]]; then
    resolve_restore   # outside the conflict: put back as git merged it (not a failure)
    (( ${#RESTORED[@]} )) && note "$m: the resolve session edited ${RESTORED[*]} outside the conflict; restored"
    # each file as the session left it (one it deleted, deleted); the commit is the tree the verify round re-checks
    for p in "${fa[@]}"; do git --literal-pathspecs add -A -- "$p" 2> /dev/null || git --literal-pathspecs rm -q --cached --ignore-unmatch -- "$p" > /dev/null; done
    git commit -q --no-edit 2>> "$STATE/run.log" || why="the merge commit failed (see run.log)"
  fi
  record MET append "$rlog" "$REC/metrics.jsonl" "$RUN_ID" resolve "$m" "$model" "$([[ -z $why ]] && echo true || echo false)" "$S_WALL" "$S_EXIT" false resolve "$S_PEAK" "$LANE"
  if [[ -z $why ]]; then
    printf '%s\n' "${fa[@]}" > "$STATE/resolved-$m"   # the PR body names them (N2-05)
    rec_commit "HARNESS: resolve $m"; return 0
  fi
  resolve_undo "$pre"
  RESOLVE_TRIED="a resolve session ($model, $RESOLVE_MIN min): $why"; printf '%s' "$RESOLVE_TRIED" > "$STATE/resolve-$m-$mn"
  note "$m: the resolve session did not resolve the merge ($why); merge aborted"
  rec_commit "HARNESS: resolve $m failed"; return 1
}

# <m> <what follows>: the note after a resolved merge (the last resolve's RESOLVE_*), never a question for Michael: the
# summary's conflicts and report.md's Conflicts row count it (lib/summary.mjs resolutions)
resolved_note() { note "$1: $MAIN_BRANCH merged in by a resolve session ($RESOLVE_FILES; $RESOLVE_MODEL_RAN, $RESOLVE_MIN min); $2"; }

# stdin → how many lines look like a conflict marker (diff3's base marker too)
marker_lines() { grep -cE '^(<<<<<<<|=======|>>>>>>>|\|{7})( |$)'; }

# The paths outside the conflict the session changed (the snapshot's snap and unt, conf the conflicted files: the
# caller's locals), put back as git merged them; RESTORED names them. checkout-index writes a symlink as a link.
resolve_restore() {
  local rec meta p; local -A now=() dirty=()
  while IFS= read -r -d '' rec; do meta=${rec%%$'\t'*}; [[ $meta == *" 0" ]] && now[${rec#*$'\t'}]=${meta% 0}; done < <(git ls-files -s -z -- . ":!$RUN_DIR")
  while IFS= read -r -d '' p; do dirty[$p]=1; done < <(git diff --name-only -z -- . ":!$RUN_DIR")
  for p in "${!snap[@]}"; do   # one git call per changed path only
    [[ ${now[$p]:-} == "${snap[$p]}" && -z ${dirty[$p]:-} ]] && continue
    git update-index --add --cacheinfo "${snap[$p]% *}" "${snap[$p]#* }" "$p" && git checkout-index -f -- "$p"; RESTORED+=("$p")
  done
  for p in "${!now[@]}"; do   # a file the session created and added
    [[ -n ${snap[$p]:-} || -n ${conf[$p]:-} ]] && continue
    git --literal-pathspecs rm -q -f --cached -- "$p"; rm -f -- "$p"; RESTORED+=("$p")
  done
  while IFS= read -r -d '' p; do [[ -n ${unt[$p]:-} ]] || { rm -f -- "$p"; RESTORED+=("$p"); }; done < <(git ls-files --others --exclude-standard -z -- . ":!$RUN_DIR")
}

# <pre> → the slot back at the lane's commit: the merge, the session's edits and the files it created gone (unt: the
# caller's snapshot of what was untracked before)
resolve_undo() {
  local p; git reset -q --hard "$1"
  while IFS= read -r -d '' p; do [[ -n ${unt[$p]:-} ]] || rm -f -- "$p"; done < <(git ls-files --others --exclude-standard -z -- . ":!$RUN_DIR")
}
