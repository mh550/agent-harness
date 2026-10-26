#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the retro backlog (M1): `harness backlog` lists, sets and imports ledger/retro-backlog.jsonl under the ledger lock ----
ST=$HARNESS_LEDGER/retro-backlog.jsonl SEED=docs/specs/2026-10-25-memory.backlog-seed.jsonl
check "harness backlog with no store prints (empty)" '
  [[ $($H backlog) == "(empty)" && $($H backlog list) == "(empty)" ]] && [[ ! -e $ST ]]'
mkdir -p "$HARNESS_LEDGER"
printf '%s\n' '{"id":"test-counts","title":"real test counts per runner","first_seen":{"run":"seed","date":"2026-10-25"},"runs_seen":[],"status":"queued","spec":"retro-fixes R1","pr":null,"note":null}' > "$ST"
check "harness backlog set flips test-counts to specced and list shows the spec" '
  [[ $($H backlog set test-counts specced --spec docs/specs/2026-10-21-retro-fixes.md) == "backlog: test-counts → specced" ]] &&
  [[ $($H backlog list) == "test-counts · specced · seen 0 · real test counts per runner · spec docs/specs/2026-10-21-retro-fixes.md" ]] &&
  [[ $(jq -r .status "$ST") == specced ]]'
bad() { local s e o; s=$(sha256sum < "$ST"); o=$($H backlog set "$@" 2>&1 > /dev/null); e=$?
  (( e == 1 )) && [[ $(printf "%s\n" "$o" | wc -l) == 1 && $o == *"usage: harness backlog set"* ]] && [[ $(sha256sum < "$ST") == "$s" ]]; }
check "harness backlog set with an unknown id, a bad status or a missing argument exits 1, store byte-identical" '
  bad no-such specced && bad test-counts done && bad test-counts && bad && bad test-counts queued --spec &&
  { $H backlog frob > /dev/null 2>&1; (( $? == 1 )); }'
# the import path is the caller's: a relative one from the harness checkout
check "harness backlog import of the seed file gives 8 rows, and 8 again on a second import" '
  rm -f "$ST" && [[ $(cd "$HERE/.." && $H backlog import "$SEED") == "backlog: imported 8 rows (8 new, 0 updated)" ]] &&
  [[ $(wc -l < "$ST") == 8 ]] && (cd "$HERE/.." && $H backlog import "$SEED") > /dev/null && [[ $(wc -l < "$ST") == 8 ]] &&
  [[ $(jq -r .status "$ST" | sort | uniq -c | tr -s " " | paste -sd ,) == " 1 proposed, 7 queued" ]] &&
  [[ $(jq -r "select(.id == \"no-retry-on-denial\") | .spec" "$ST") == null ]] && ! jq -e "select(.status == \"queued\" and (.spec | not))" "$ST" > /dev/null &&
  [[ $(jq -r .id "$ST" | paste -sd " ") == "test-counts review-cost step-lint carry-on-past-given-up verify-fresh-suite merge-before-deadline no-retry-on-denial session-memory-cap" ]]'
# LEDGER_COMMIT=1 and a ledger in a git checkout: each write is one ledger commit of that file alone
git init -q -b main "$T/live" && mkdir -p "$T/live/ledger" && touch "$T/live/ledger/other" && git -C "$T/live" add -A && git -C "$T/live" -c user.name=t -c user.email=t@t commit -qm init
sed 's/LEDGER_COMMIT=0/LEDGER_COMMIT=1/' "$T/base-config.sh" > "$T/commit-config.sh"; echo x > "$T/live/ledger/other"
lc() { HARNESS_CONFIG=$T/commit-config.sh HARNESS_LEDGER=$T/live/ledger GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t $H backlog "$@"; }
check "harness backlog with LEDGER_COMMIT=1 commits retro-backlog.jsonl alone, one ledger commit per write" '
  (cd "$HERE/.." && lc import "$SEED") > /dev/null && lc set step-lint merged --pr https://github.com/x/y/pull/1 > /dev/null &&
  [[ $(git -C "$T/live" log --format=%s -2 | paste -sd "|") == "ledger: backlog set step-lint merged|ledger: backlog import 2026-10-25-memory.backlog-seed.jsonl" ]] &&
  [[ $(git -C "$T/live" status --porcelain) == " M ledger/other" ]] && [[ $(git -C "$T/live" show HEAD:ledger/retro-backlog.jsonl | wc -l) == 8 ]]'
suite_end
