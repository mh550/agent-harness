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
# ---- backlog run: the retro writes retro-proposals.json, the driver merges it into the ledger's backlog in finish() ----
# The seed rows above are gone first: no-retry-on-denial is one of them. bk2's retro also edits the worktree's ledger/.
rm -f "$ST"
STUB_RETRO_PROPOSALS=no-retry-on-denial "$H" start "$T/proj" bk1 --spec SPEC.md --foreground > "$T/bk1.out" 2>&1
check "backlog run: a retro proposal lands as a proposed row, noted 1 new, 0 seen again" '
  [[ $(wc -l < "$ST") == 1 ]] && [[ $(jq -r "[.id, .status, .first_seen.run, (.runs_seen | join(\",\"))] | join(\" \")" "$ST") == "no-retry-on-denial proposed bk1 bk1" ]] &&
  hlog bk1 | grep -q " · backlog: 1 new, 0 seen again$" && [[ -f $T/ledger/proj/bk1/retro-proposals.json ]]'
STUB_RETRO_PROPOSALS=no-retry-on-denial STUB_RETRO_EDITS=1 "$H" start "$T/proj" bk2 --spec SPEC.md --foreground > "$T/bk2.out" 2>&1
check "backlog run: the same id from a second run adds it to runs_seen, noted 0 new, 1 seen again" '
  [[ $(wc -l < "$ST") == 1 ]] && [[ $(jq -r "[.status, .first_seen.run, (.runs_seen | join(\",\"))] | join(\" \")" "$ST") == "proposed bk1 bk1,bk2" ]] &&
  hlog bk2 | grep -q " · backlog: 0 new, 1 seen again$"'
check "backlog run: restrict reverts a retro's edit to the backlog, and the merge still lands" '
  hlog bk2 | grep "retro: reverted edits" | grep -q " ledger/retro-backlog.jsonl" && ! hlog bk2 | grep "retro: reverted edits" | grep -q retro-proposals.json &&
  [[ ! -e $T/wt/proj/bk2/ledger/retro-backlog.jsonl ]] && jq -e "select(.id == \"no-retry-on-denial\") | .runs_seen | index(\"bk2\")" "$ST" > /dev/null'
# the retro's prompt carries the backlog as the list prints it (bk3's run, a specced row beside bk1's proposal)
printf '%s\n' '{"id":"test-counts","title":"real test counts per runner","first_seen":{"run":"seed","date":"2026-10-25"},"runs_seen":[],"status":"specced","spec":"docs/specs/2026-10-21-retro-fixes.md","pr":null,"note":null}' >> "$ST"
sum0=$(sha256sum < "$ST")
STUB_RETRO_PROPOSALS=bad "$H" start "$T/proj" bk3 --spec SPEC.md --foreground > "$T/bk3.out" 2>&1
check "backlog run: a malformed retro-proposals.json is noted, the run finishes, the backlog unchanged" '
  hlog bk3 | grep -q " · backlog: retro-proposals.json invalid" && grep -q "\"run\":\"bk3\"" "$T/ledger/runs.jsonl" &&
  [[ $(sha256sum < "$ST") == "$sum0" ]] && grep -q "run kept in" "$T/bk3.out"'
check "backlog run: the rendered retro prompt carries test-counts · specced" '
  P=$HARNESS_STATE/proj/bk3/prompt-retro.md; grep -q "^## Backlog" "$P" && grep -q "^test-counts · specced · seen 0" "$P" &&
  grep -q "^no-retry-on-denial · proposed · seen 2" "$P" && ! grep -q "{{BACKLOG}}" "$P"'
"$H" debrief --dry-run > "$T/bk-dry.out" 2>&1
check "debrief --dry-run gathers the retro backlog, not Earlier retros" '
  grep -qxF "## Retro backlog (ledger/retro-backlog.jsonl)" "$T/bk-dry.out" && ! grep -q "Earlier retros" "$T/bk-dry.out" &&
  grep -q "^{\"id\":\"no-retry-on-denial\",.*\"runs_seen\":\[\"bk1\",\"bk2\"\]" "$T/bk-dry.out" && ! grep -q "/retro\.md$" "$T/bk-dry.out"'
# ---- the M1 review (M1-06): the run's ledger commit carries the backlog; a symlink or an unlistable store is noted ----
GA=(GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t)
env "${GA[@]}" HARNESS_CONFIG=$T/commit-config.sh HARNESS_LEDGER=$T/live/ledger STUB_RETRO_PROPOSALS=from-bk4 "$H" start "$T/proj" bk4 --spec SPEC.md --foreground > "$T/bk4.out" 2>&1
check "backlog run: with LEDGER_COMMIT=1 the run's ledger commit carries retro-backlog.jsonl with its proposal" '
  [[ $(git -C "$T/live" log -1 --format=%s) == "ledger: bk4 (proj)"* ]] &&
  git -C "$T/live" show --name-only --format= HEAD | grep -qx ledger/retro-backlog.jsonl &&
  git -C "$T/live" show HEAD:ledger/retro-backlog.jsonl | grep -q "^{\"id\":\"from-bk4\",.*\"status\":\"proposed\""'
cp "$ST" "$T/st.keep"; echo "{broken" >> "$ST"
STUB_RETRO_PROPOSALS=link "$H" start "$T/proj" bk5 --spec SPEC.md --foreground > "$T/bk5.out" 2>&1
check "backlog run: a symlinked retro-proposals.json is not followed, and a store that will not list is noted" '
  hlog bk5 | grep -q " · backlog: the retro wrote no retro-proposals.json$" && hlog bk5 | grep "retro: reverted edits" | grep -q retro-proposals.json &&
  [[ ! -e $T/wt/proj/bk5/.harness/runs/bk5/retro-proposals.json && ! -e $T/ledger/proj/bk5/retro-proposals.json ]] &&
  hlog bk5 | grep -q " · backlog: the retro prompt has no backlog: line [0-9]*: not JSON"'
cp "$T/st.keep" "$ST"
suite_end
