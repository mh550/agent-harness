#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- sync: the live checkout level with origin (merged PRs in, ledger commits out), only when that is safe ----
git init -q --bare -b main "$T/live.git"; git init -q -b main "$T/live"; mkdir -p "$T/live/ledger"; echo a > "$T/live/code.sh"; echo '{}' > "$T/live/ledger/runs.jsonl"
git -C "$T/live" add -A && git -C "$T/live" commit -qm init && git -C "$T/live" remote add origin "$T/live.git" && git -C "$T/live" push -q -u origin main
git clone -q "$T/live.git" "$T/dev"
sy() { HARNESS_HOME=$HERE/.. "$HERE/../lib/sync.sh" "$T/live/ledger"; }
echo b >> "$T/dev/code.sh"; git -C "$T/dev" commit -qam "a merged PR"; git -C "$T/dev" push -q origin main
echo '{"run":"x"}' >> "$T/live/ledger/runs.jsonl"; git -C "$T/live" commit -qam "ledger: x"
check "sync: pulls the merged PR and pushes the ledger commit, no merge commit" 'O=$(sy) && grep -q "pulled 1, pushed 1 ledger commit" <<< "$O" && [[ $(git -C "$T/live" rev-parse HEAD) == $(git -C "$T/live.git" rev-parse main) ]] \
  && [[ $(sed -n 2p "$T/live/code.sh") == b ]] && [[ $(git -C "$T/live" rev-list --merges --count HEAD) == 0 ]]'
check "sync: level says so" 'grep -q "level with origin/main" <<< "$(sy)"'
echo c >> "$T/live/code.sh"; git -C "$T/live" commit -qam "someone's own work"; H0=$(git -C "$T/live.git" rev-parse main)
check "sync: a local commit outside ledger/ is left alone, nothing pushed" 'grep -q "touch files outside ledger/; not syncing" <<< "$(sy)" && [[ $(git -C "$T/live.git" rev-parse main) == "$H0" ]]'
git -C "$T/live" reset -q --hard origin/main; echo d >> "$T/live/code.sh"
check "sync: a modified tracked file: skipped" 'grep -q "modified tracked files; skipped" <<< "$(sy)"'
git -C "$T/live" checkout -q -- code.sh; git -C "$T/dev" pull -q --ff-only; echo e >> "$T/dev/code.sh"; git -C "$T/dev" commit -qam "another PR"; git -C "$T/dev" push -q origin main
check "sync: nothing local: fast-forward" 'grep -q "^sync: pulled 1; main at" <<< "$(sy)" && [[ $(tail -1 "$T/live/code.sh") == e ]]'
git -C "$T/live" checkout -q -b side; echo 'LIVE_SYNC=0' > "$T/nosync.sh"
check "sync: another branch checked out: skipped; LIVE_SYNC=0: off" 'grep -q "on side, not main; skipped" <<< "$(sy)" && grep -q "off (LIVE_SYNC=0)" <<< "$(HARNESS_CONFIG=$T/nosync.sh sy)"'

suite_end
