#!/usr/bin/env bash
# Keep the live harness checkout (the one holding the ledger) level with origin: merged PRs reach the running harness
# and the driver's ledger commits reach origin, without anyone pulling by hand. The queue runner calls it only while no
# run is alive (a driver reads its scripts as it goes); `harness sync` calls it by hand. It acts only when that is safe:
# the checkout is on MAIN_BRANCH, no rebase or merge is going, no tracked file is modified, and every local commit
# origin lacks touches only ledger/ (anything else is someone's work: left alone, said so). Then: fetch, rebase the
# unpushed ledger commits onto origin (they were never pushed, so nothing shared is rewritten), push without force, or
# fast-forward. Never fails its caller: prints one line saying what it did or why it didn't, and exits 0.
#   sync.sh [<checkout>]   (default: the toplevel of HARNESS_LEDGER, else of HARNESS_HOME/ledger)
set -uo pipefail
: "${HARNESS_HOME:?}"
# shellcheck source=lib/config.sh
source "$HARNESS_HOME/lib/config.sh"; harness_config /nonexistent   # MAIN_BRANCH, LIVE_SYNC
say() { echo "sync: $*"; exit 0; }
[[ $LIVE_SYNC == 1 ]] || say "off (LIVE_SYNC=$LIVE_SYNC)"
L=${1:-${HARNESS_LEDGER:-$HARNESS_HOME/ledger}}
D=$(git -C "$L" rev-parse --show-toplevel 2> /dev/null) || say "$L is not in a git checkout; skipped"
g() { git -C "$D" "$@"; }
b=$(g symbolic-ref -q --short HEAD) || say "$D is on a detached HEAD; skipped"
[[ $b == "$MAIN_BRANCH" ]] || say "$D is on $b, not $MAIN_BRANCH; skipped"
for s in rebase-merge rebase-apply MERGE_HEAD CHERRY_PICK_HEAD REVERT_HEAD; do
  [[ -e $(g rev-parse --git-path "$s") ]] && say "$D has a ${s%%_*} in progress; skipped"
done
g diff --quiet HEAD -- || say "$D has modified tracked files; skipped"
g fetch -q origin "$MAIN_BRANCH" 2> /dev/null || say "fetch from origin failed; skipped"
o=origin/$MAIN_BRANCH
mine=$(g rev-list --count "$o..HEAD") theirs=$(g rev-list --count "HEAD..$o")
(( mine + theirs )) || say "$MAIN_BRANCH is level with $o ($(g rev-parse --short HEAD))"
if (( mine )); then
  other=$(g log --format= --name-only "$o..HEAD" | grep -v '^ledger/' | grep -c .)
  (( other )) && say "$mine local commit(s) on $MAIN_BRANCH touch files outside ledger/; not syncing (push or merge them yourself)"
  if (( theirs )); then
    g rebase -q "$o" > /dev/null 2>&1 || { g rebase --abort 2> /dev/null; say "rebasing $mine ledger commit(s) onto $o conflicted; aborted, nothing changed"; }
  fi
  g push -q origin "HEAD:$MAIN_BRANCH" 2> /dev/null || say "pulled $theirs, but pushing $mine ledger commit(s) failed; try again later"
  say "pulled $theirs, pushed $mine ledger commit(s); $MAIN_BRANCH at $(g rev-parse --short HEAD)"
fi
g merge -q --ff-only "$o" 2> /dev/null || say "fast-forward to $o failed (an untracked file in the way?); skipped"
say "pulled $theirs; $MAIN_BRANCH at $(g rev-parse --short HEAD)"
