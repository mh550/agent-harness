#!/usr/bin/env bash
# Usage: source lib/record.sh   (by lib/driver.sh) → the run record on its own branch and the lane slot (lanes P1-03)
# The record (.harness/runs/<run>/) lives only on harness/<run>, in the record worktree RWT; code lives on lane branches
# harness-lane/<run>/<m>, worked in the slot worktree. Every write to the record goes through `record` (one flock on
# $STATE/record.lock, so two writers never lose each other's lines); sessions, inits and suites never run under it.
# A session sees the record as a copy materialized into the slot, excluded from git there, and taken back after it.
# Plan: docs/plans/2026-10-26-P1-lanes-serial.md §2, §5. Needs STATE RWT REC RUN_DIR RBRANCH RUN_ID MAIN_BRANCH.

# The spec's helper: the lock is held while "$@" runs and released when fd 9 closes. HARNESS_RECORD_DELAY=<s> (tests
# only, unset everywhere else) holds it that long first, so a check can make two writers meet.
_record() { flock 9; [[ -n ${HARNESS_RECORD_DELAY:-} ]] && sleep "$HARNESS_RECORD_DELAY"; "$@"; } 9> "$STATE/record.lock"
# A wrapped function may call another (note inside a commit): the inner call runs under the lock it already holds,
# never a second flock on a new descriptor, which would wait on itself.
record() { (( ${REC_HELD:-0} )) && { "$@"; return; }; REC_HELD=1; _record "$@"; local rc=$?; REC_HELD=0; return $rc; }

commit_all() { git add -A && ! git diff --cached --quiet && git commit -q -m "$1"; return 0; }
rec_commit_() { ( cd "$RWT" && commit_all "$1" ); }
rec_commit() { record rec_commit_ "$1"; }   # <message>: a commit of the record worktree

# <file> [<delta>] → the run counter in <file> (sessions: coding sessions started, limits: refused in a row) plus delta
rec_count_() { local n; n=$(cat "$1" 2> /dev/null || echo 0); echo $(( n + ${2:-0} )) > "$1"; }
rec_count() { record rec_count_ "$1" "${2:-0}"; cat "$1"; }

# Pull Michael's phone edits (INBOX.md) into the record, push its commits. Never rewrites history. 9>&-: a network
# command never holds the lock past this call (an ssh ControlPersist master would keep fd 9).
sync_record_() {
  if git -C "$RWT" fetch -q origin "$RBRANCH" 9>&- 2> /dev/null; then
    git -C "$RWT" merge -q --ff-only "origin/$RBRANCH" 2> /dev/null \
      || git -C "$RWT" merge -q --no-edit "origin/$RBRANCH" > /dev/null 2>&1 \
      || { git -C "$RWT" merge --abort 2> /dev/null; log "remote edits on $RBRANCH conflict with local work; kept local"; }
  fi
  git -C "$RWT" push -q -u origin "$RBRANCH" 9>&- 2>> "$STATE/run.log" || log "push of $RBRANCH failed"
}
sync_record() { record sync_record_; }
sync_lane() { [[ -n ${LBRANCH:-} ]] || return 0; git -C "$SLOT" push -q -u origin "$LBRANCH" 2>> "$STATE/run.log" || log "push of $LBRANCH failed"; }

# <m> → the slot (slot-0) on harness-lane/<run>/<m>, cwd there; HARNESS_WT and HARNESS_BRANCH name it for sessions.
# A lane resumes its branch (local, else the origin's: a segment that ended mid-milestone), else starts from BASE_REF
# (harness start --base) or origin/main, then merges the tag of every dependency main doesn't have yet. 1 = its base
# conflicts or the slot can't be checked out (needs-<m>, noted: the loop would only pick it again), cwd back in the
# record worktree.
slot_open() {
  local m=$1 b=harness-lane/$RUN_ID/$1 base dep tag first=0 sha
  SLOT=$WT_ROOT_DIR/lanes/$RUN_ID/slot-0
  if [[ ${LBRANCH:-} == "$b" && -d $SLOT ]]; then lane_cd; return 0; fi
  LBRANCH="" LANE=""   # from here the slot leaves the open lane's branch: only a full open names a lane again
  git -C "$RWT" fetch -q origin 2> /dev/null
  base=${BASE_REF:-origin/$MAIN_BRANCH}
  if git -C "$RWT" rev-parse -q --verify "refs/heads/$b" > /dev/null; then base=$b
  elif git -C "$RWT" rev-parse -q --verify "refs/remotes/origin/$b" > /dev/null; then base=origin/$b; fi
  if [[ ! -d $SLOT ]]; then
    mkdir -p "${SLOT%/*}"; first=1
    git -C "$RWT" worktree add -q -f "$SLOT" -B "$b" "$base" 2>> "$STATE/run.log" || { slot_fail "$m" "worktree add of $SLOT"; return 1; }
  else
    local cur; cur=$(git -C "$SLOT" branch --show-current)   # a segment killed mid-session left its work here
    ( cd "$SLOT" && commit_all "WIP: uncommitted in the slot when it was reused (harness)" )
    [[ $cur == harness-lane/* ]] && git -C "$SLOT" push -q origin "$cur" 2> /dev/null
    git -C "$SLOT" checkout -q -f -B "$b" "$base" 2>> "$STATE/run.log" || { slot_fail "$m" "checkout of $b"; return 1; }
  fi
  for dep in $(F deps "$LIST" "$m"); do
    tag=run/$RUN_ID/$dep
    git -C "$SLOT" rev-parse -q --verify "refs/tags/$tag" > /dev/null || continue
    git -C "$SLOT" merge-base --is-ancestor "$tag" "origin/$MAIN_BRANCH" 2> /dev/null && continue
    git -C "$SLOT" merge-base --is-ancestor "$tag" HEAD && continue
    if ! git -C "$SLOT" merge -q --no-edit "$tag" > /dev/null 2>&1; then
      git -C "$SLOT" merge --abort 2> /dev/null
      note "$m: its base conflicts ($dep vs $MAIN_BRANCH); needs Michael"; touch "$STATE/needs-$m"
      cd "$RWT" || return 1; return 1
    fi
  done
  # the copy of the record is invisible to the slot's git (a per-worktree excludes file, never .git/info/exclude,
  # which the record worktree shares), plus the user's own global excludes the worktree value would shadow
  mkdir -p "$STATE/lanes/$m"
  { echo ".harness/runs/"; cat "$(git config --global --path core.excludesFile 2> /dev/null || echo "${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore")" 2> /dev/null; } > "$STATE/lanes/$m/exclude"
  [[ $(git -C "$RWT" config extensions.worktreeConfig) == true ]] || git -C "$RWT" config extensions.worktreeConfig true
  git -C "$SLOT" config --worktree core.excludesFile "$STATE/lanes/$m/exclude"
  echo "$SLOT" > "$STATE/lanes/$m/slot"   # lib/prompt.sh as a command renders a lane's prompt from it
  LBRANCH=$b LANE=$m; lane_cd
  sha=$(git rev-parse --short HEAD)
  note "lane $m opened (slot 0, port $PORT, from $sha$( (( first )) || echo ", slot reused"))"
}
slot_fail() { note "$1: its slot failed ($2; see run.log); needs Michael"; touch "$STATE/needs-$1"; cd "$RWT" || :; }
lane_cd() { cd "$SLOT" || return 1; export HARNESS_WT=$SLOT HARNESS_BRANCH=$LBRANCH; SLIST=$SLOT/$RUN_DIR/feature_list.json; }
rec_cd() { cd "$RWT" || return 1; export HARNESS_WT=$RWT HARNESS_BRANCH=$RBRANCH; SLIST=$LIST; }

# The record copied into the slot for the next session; the snapshot and the INBOX it is judged against are the copy's,
# so a phone edit merged into the record meanwhile is never the session's. A record tracked at the slot's base (a run
# whose record reached main before lanes) is marked skip-worktree, so the session's `git add -A` stages none of it.
materialize_() {
  rm -rf "${SLOT:?}/$RUN_DIR"; mkdir -p "$SLOT/$RUN_DIR"; cp -a "$REC/." "$SLOT/$RUN_DIR/"
  git -C "$SLOT" ls-files -z -- "$RUN_DIR" | (cd "$SLOT" && xargs -0 -r git update-index --skip-worktree)
  F snapshot "$SLIST" > "$STATE/before.json"
  cp "$SLOT/$RUN_DIR/INBOX.md" "$STATE/inbox-before.md" 2> /dev/null || : > "$STATE/inbox-before.md"
}
materialize() { record materialize_; }
# The copy goes; the slot is clean again (the next checkout -B and gc rely on it).
unmaterialize() {
  [[ -n ${SLOT:-} && -d $SLOT/$RUN_DIR ]] || return 0
  local tracked; tracked=$(git -C "$SLOT" ls-files -- "$RUN_DIR")
  rm -rf "${SLOT:?}/$RUN_DIR"
  [[ -n $tracked ]] && { git -C "$SLOT" ls-files -z -- "$RUN_DIR" | (cd "$SLOT" && xargs -0 -r git update-index --no-skip-worktree); git -C "$SLOT" checkout -q HEAD -- "$RUN_DIR"; }
  return 0
}

# The lines a session added above "## Answers" in its copy go into the record's INBOX.md above that line (at the end
# they would sit under the answers and change answers_hash, unparking at once); saved for the park's notification.
take_question_() {
  local q; q=$(node "$NOTIFY_MJS" question "$STATE/inbox-before.md" "$SLOT/$RUN_DIR/INBOX.md" 2> /dev/null)
  printf '%s' "$q" > "$STATE/question"
  [[ -n $q ]] || return 0
  if grep -q '^## Answers' "$REC/INBOX.md"; then
    node -e 'const fs=require("fs"),[f,q]=process.argv.slice(1),t=fs.readFileSync(f,"utf8"),i=t.search(/^## Answers/m);fs.writeFileSync(f,t.slice(0,i)+q+"\n\n"+t.slice(i))' "$REC/INBOX.md" "$q"
  else printf '\n%s\n' "$q" >> "$REC/INBOX.md"; fi
}
take_question() { record take_question_; }

# <start commit> <who>: a lane commit that touched .harness/runs/ (a session that `git add -f`'d the copy) is reverted
# by a new commit; the record never takes anything from it.
lane_guard() {
  [[ -n $(git diff --name-only "$1" HEAD -- .harness/runs/ 2> /dev/null) ]] || return 0
  restrict "$1" runs "$2" > /dev/null
  note "$2: a lane commit touched the run record; reverted"
  sync_lane
}

# The slot goes at the end of a segment (its branch is pushed: a continuation reopens it); merged lanes' branches go.
slot_close() {
  rec_cd
  [[ -n ${SLOT:-} ]] || SLOT=$WT_ROOT_DIR/lanes/$RUN_ID/slot-0
  if [[ -d $SLOT ]]; then
    git -C "$RWT" worktree remove --force "$SLOT" 2>> "$STATE/run.log" || log "slot: could not remove $SLOT"
    git -C "$RWT" worktree prune
    rmdir "$WT_ROOT_DIR/lanes/$RUN_ID" "$WT_ROOT_DIR/lanes" 2> /dev/null
  fi
  LBRANCH="" LANE=""
  local f m b
  for f in "$STATE"/merged-*; do
    [[ -f $f ]] || continue; m=${f##*/merged-} b=harness-lane/$RUN_ID/$m
    git -C "$RWT" rev-parse -q --verify "refs/heads/$b" > /dev/null && git -C "$RWT" branch -q -D "$b"
    git -C "$RWT" rev-parse -q --verify "refs/remotes/origin/$b" > /dev/null && git -C "$RWT" push -q origin --delete "$b" 2> /dev/null
  done
  return 0
}
