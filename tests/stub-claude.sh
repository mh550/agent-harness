#!/usr/bin/env bash
# Stand-in for `claude -p` in tests: acts out initializer / coding / verify / retro sessions keyed on the prompt's exact
# first line (the feature id and milestone are read from the `Feature:`/`Milestone:` lines under `# This session`), including scripted misbehaviour, and prints stream-json lines like the real CLI. Usage limits replay the real
# lines captured on 2026-10-17 (fixtures/usage-limit.jsonl), finished sessions the 2026-10-21 capture
# (fixtures/usage-tokens.jsonl): fakes mirror the live API. Without -p it is a desk
# (`claude --remote-control <name>`, no -p, in tmux): it prints the pane line of fixtures/remote-control-pane.txt with
# session_TEST<n>, records argv and $PWD in $STUB_DIR/desk/<n>-<name>.args, its environment's names in <n>-<name>.env
# and each typed line in <n>-<name>.in. STUB_DESK_MENU=1: after the first typed line it shows the permission dialog of
# fixtures/permission-menu.txt (the desk asks to run a command) and takes nothing more as an answer.
# STUB_STALE_GREEN=<id>: that feature's first coding session leaves the suite red (BROKEN) and writes an empty green
# marker for that tree into $HARNESS_CHECK_CACHE (a stale cached green, R4), then marks the feature passing.
# STUB_PHONE_STOP=1|<why>: the initializer pushes INBOX.md line 1 `status: stop` (1) or `status: stop <why>` from a
# clone of the origin, as Michael's phone would. STUB_CLI_STOP=-|<why>: it runs `harness stop <run>` (-) or
# `harness stop <run> --why "<why>"` (R7). STUB_CLI_REQUEST=<brief>: then `harness queue add --continue <run> --brief
# "<brief>"`, a request made after the stop and before the driver acts on it.
# STUB_RETRO_PROPOSALS=<id>[,<id>…]: the retro writes retro-proposals.json in the run directory, one
# `{id, title: "stub proposal <id>", evidence}` per id (`bad`: `{not json`; `link`: a symlink to feature_list.json). STUB_RETRO_EDITS=1: the retro edits code, progress.md
# and the worktree's ledger/retro-backlog.jsonl (restrict reverts all three).
# STUB_GOTCHA=<id>: that feature's first coding session adds a `## Gotchas` line to CLAUDE.md (and the section when
# it has none), committed with its work (M3). STUB_ASK=<id>: that feature's first coding session's entry asks
# "Should <id> default to off?"; STUB_RESOLVE=<id>: its later sessions' entries list it in `resolved`. STUB_ASK_TWO=<id>:
# that feature's first coding session's entry asks two questions, each with a `Files:` line (R4-03); STUB_ASK_AGAIN=<id>:
# that feature's first coding session's entry asks STUB_ASK's question again, same words. STUB_PROJECT_FACT=<id>:
# its first session's entry has the discovery STUB_GOTCHA writes, affecting "project" (M3-03). STUB_VERIFY_FAIL_ROW=1: A's
# coding entries record a dead end and verify M1 round 1's entry has a `holds: false` row for A step 1 (M3-04).
# STUB_TESTS_N=<id>:<n>[,<id>:<n>…]: that feature's first coding session commits tests.n <n> (a suite echoing it counts <n>). STUB_SNAPSHOT=<id>:
# its first coding session saves `harness status`, `harness report` and the state's summary.json, tests-start and
# tests-end in $STUB_DIR/snap-<run>/ (M5-02).
# STUB_REVIEW_LIST=1: the initializer writes A (sonnet), B, D (build) and R (review, sonnet), all in M1, and no C (M6).
# STUB_BIG_DIFF=1: A's first coding session also commits big-A.txt, 500 lines (a review diff at or over 400).
# STUB_REVIEW_FINDINGS=<c>,<i>: every R session's entry summary is "R: stub review (<n>): <c> Critical, <i> Important, 0 Minor" (M6).
# STUB_REVIEW_ROUND=limit|fail: R's second session (the escalation round) is refused by the usage limit, or ends not
# passing (M6-05).
# STUB_VERIFY_WAIT=<m>:<path>: the verify session of <m> touches $STUB_DIR/vwait-<run>-<m>, then, before its verdict,
# waits (≤ 120 s) until origin's main has <path>: another lane merges while it verifies (P2-03's re-base).
# STUB_SHARED=<file>: A's first coding session rewrites <file>'s first line to A, C's its last line to C, committed with
# their work (one path, distinct hunks: the merge is clean and the two milestones' files overlap).
# STUB_SORTED=<file>: A's first coding session adds the line `b A check` to <file>, C's `b C check`, each re-sorted and
# committed with their work: two names between the same two lines of a sorted list (N2-02's sorted-union driver).
# STUB_CONFLICT=<file>: A's first coding session rewrites line 2 of <file> to `line two, from A`, C's to `line two, from
# C`, committed with their work: one line both lanes change, a real merge conflict (N2-03's resolve session).
# STUB_MERGE_RESOLVE=both: a `# Resolve session` deletes the marker lines of every conflicted file (both sides' lines
# stay, HEAD's first), `git add`s each and ends `RESOLVED: <file>: kept both sides` per file; markers: as both, then puts
# `<<<<<<< HEAD` back as README.md's first line (one marker left) and ends `RESOLVED: README.md: kept both sides`;
# stray: as both, and also appends `stray` to work-A.txt, writes stray.txt (untracked) and stray-added.txt (`git add`);
# give-up or unset: touches nothing and ends `UNRESOLVED: stub gives up`. It never commits (N2-04).
# STUB_RESOLVE_LIMIT=<n>: the first <n> resolve sessions are the real usage-limit refusal (fixtures/usage-limit.jsonl).
# STUB_REBASE_VERIFY_FAIL=1: M2's second verify session (a re-base's round) un-passes C.
# STUB_IGNORED=<path>: every coding session appends "<id> present|absent" (<path> before it works) to
# $STUB_DIR/ignored.log; the run's first writes <path> (an ignored install: a reused slot keeps it, P2-04).
# STUB_INBOX_IN_COMMENT=<id>: that feature's first coding session asks inside INBOX.md's steering comment, splitting its
# line after "under " with "## Questions" and "**Q1 (<id>, stub).** …" (n8n-home's 4632d1c shape), and parks (U2-02).
# STUB_GIVE_UP=<id>: every coding session of that feature ends not passing (U2-05's given_up).
# STUB_MAIN_TOUCH=<id|verify-<m>|resolve-<m>>:<path>: that feature's first coding session (or <m>'s first verify or resolve session) lands a
# merge on origin's main adding <path> ("main's <path>"), subject "Merge pull request #7 from test/harness-merge/other-M3"
# as GitHub writes it: another run's PR merged meanwhile (U2-06's main and merge conflicts); <path>'s directories are made.
# STUB_FIX_BROKEN=<id>: that feature's first coding session removes BROKEN (a red main's fix, R3-03's green-only count).
# STUB_RUN_SUITE=<id>: that feature's first coding session runs $HARNESS_CHECK in full twice (the second answers cached),
# then as a subset (`x`), before its commit (R3-04's "suite ran" note).
# STUB_THIN_VERIFY=all: every verify round is thin (the escalated one too), so the milestone needs Michael (U2-06).
# STUB_BARRIER=<id>:<name>: that feature's first coding session touches $STUB_DIR/barriers/<name>.held, then waits
# (≤ 180 s by the clock) for $STUB_DIR/barriers/<name> before its entry and its end, and then touches <name>.released
# (or <name>.timedout, given up): tests/lib.sh's stub_wait <name>.held and stub_go <name> order a check's steps around
# the session (R1-02).
# Every headless session prints first the init line of fixtures/claude-resume/first.jsonl with its cwd and a fresh
# session_id, and keeps $STUB_DIR/sessions/<id> (its last result line). `--resume <id>` (R2) appends argv to
# $STUB_DIR/resume.log: an id it never ran gets unknown-id.out's stderr line and result line, exit 1; a known one gets
# resumed.jsonl with that session_id and its result's total_cost_usd and modelUsage cumulative, as the CLI's are.
# STUB_NO_ENTRY=<id>: that feature's first coding session writes no entry.json. STUB_RESUME_ENTRY=good|bad|good-edits:
# a resumed session (`# Entry resume`) writes a valid entry with one dead_ends item (good), `{not json` (bad), or the
# good entry and an uncommitted resumed.txt in the worktree (good-edits); unset, it writes nothing. good-overreach:
# the good entry, and it toggles the feature's passes, commits overreach.txt and (an init's) writes a feature list, the
# edits entry_resume must undo. STUB_INIT_NO_LIST=1: the initializer ends, not refused, with no list and no entry.
# STUB_NO_INIT_LINE=1: no session prints its init line (a transcript with no session id: never resumed).
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
ARGS=("$@"); prompt="" headless=0 rc="" resume=""
while (( $# )); do
  [[ $1 == -p || $1 == --print ]] && headless=1
  [[ $1 == --remote-control ]] && rc=${2:-}
  [[ $1 == --resume ]] && resume=${2:-}
  [[ $1 == -p && -n ${2:-} && ${2:-} != -* ]] && { prompt=$2; shift; }; shift; done
if (( ! headless )) && [[ -n $rc ]]; then   # interactive (a desk): the pane line Remote Control prints, then each typed line to <name>.in
  mkdir -p "$STUB_DIR/desk"; n=$(( $(cat "$STUB_DIR/desk/count" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$STUB_DIR/desk/count"
  name=$n-$(printf '%s' "$rc" | LC_ALL=C tr -cs 'A-Za-z0-9._-' _); name=${name%_}
  { printf '%s\n' "${ARGS[@]}"; echo "PWD=$PWD"; } > "$STUB_DIR/desk/$name.args"
  env | cut -d= -f1 | sort > "$STUB_DIR/desk/$name.env"
  [[ ${STUB_DESK_NO_URL:-} == 1 ]] || sed -n "2s/session_[^[:space:]]*/session_TEST$n/p" "$HERE/fixtures/remote-control-pane.txt"
  while IFS= read -r line; do
    printf '%s\n' "$line" >> "$STUB_DIR/desk/$name.in"
    [[ ${STUB_DESK_MENU:-} == 1 && $(wc -l < "$STUB_DIR/desk/$name.in") == 1 ]] && sed 1d "$HERE/fixtures/permission-menu.txt"
  done
  exit 0
fi
[[ -n $prompt ]] || prompt=$(cat)   # `claude -p` with the prompt on stdin
first=$(head -1 <<< "$prompt")
RES=$HERE/fixtures/claude-resume SESS=${STUB_DIR:-/nonexistent}/sessions
if [[ -n $resume ]]; then   # the CLI resumes a session it ran, by id, or says it has none (unknown-id.out, exit 1)
  [[ -n ${STUB_DIR:-} ]] && { printf '%q ' "${ARGS[@]}"; echo; } >> "$STUB_DIR/resume.log"
  if [[ ! -f $SESS/$resume ]]; then
    sed -n "1s/00000000-0000-0000-0000-000000000000/$resume/p" "$RES/unknown-id.out" >&2
    sed -n "2s/00000000-0000-0000-0000-000000000000/$resume/p" "$RES/unknown-id.out"; exit 1
  fi
  sid=$resume
else   # the session starts before anything else, a refused one too: its init line comes first
  sid=$(cat /proc/sys/kernel/random/uuid)
  [[ -n ${STUB_DIR:-} ]] && mkdir -p "$SESS" && : > "$SESS/$sid"
  [[ ${STUB_NO_INIT_LINE:-} ]] || sed -n 3p "$RES/first.jsonl" | jq -c --arg id "$sid" --arg cwd "$PWD" '.session_id = $id | .cwd = $cwd | .original_cwd = $cwd'
fi
[[ -n ${STUB_DIR:-} ]] && echo "${HARNESS_RUN_ID:-} ${HARNESS_CACHE:-unset}" >> "$STUB_DIR/cache.log"   # what each headless session sees (L3-02); not in scratch, which finish deletes
L=${HARNESS_RUN_DIR:-.}/feature_list.json
after_session() { awk '/^# This session$/ { s = 1 } s && '"$1" <<< "$prompt"; }   # an awk rule, applied below `# This session` only (a brief can't fake an id)
RS=${HARNESS_SCRATCH:-}; RS=${RS%%/lanes/*}   # the run's scratch, not a lane's: the stub's own bookkeeping is run-wide (STUB_LIMIT_HITS counts across lanes)
count() { local f=$RS/count-$1 n; n=$(( $(cat "$f" 2>/dev/null || echo 0) + 1 )); echo "$n" > "$f"; echo "$n"; }
set_passes() { node -e 'const fs=require("fs"),[f,id,v]=process.argv.slice(1),l=JSON.parse(fs.readFileSync(f));for(const x of l.features)if(x.id===id)x.passes=v==="true";fs.writeFileSync(f,JSON.stringify(l,null,2))' "$L" "$1" "$2"; }
# <id> <n> <jq args…> → the session's journal entry, built by jq (E4-03); STUB_BAD_ENTRY=<id>: that id's first session writes `{not json`;
# STUB_LONG_SUMMARY=<id>: that id's first coding session's summary is 410 characters, "<id>: " padded with x (R2-02)
entry() { local id=$1 n=$2 long=; shift 2
  [[ ${STUB_LONG_SUMMARY:-} == "$id" && $n == 1 ]] && long=$id
  if [[ ${STUB_NO_ENTRY:-} == "$id" && $n == 1 && $first == "# Coding session" ]]; then return 0
  elif [[ ${STUB_BAD_ENTRY:-} == "$id" && $n == 1 ]]; then printf '{not json' > "$HARNESS_RUN_DIR/entry.json"
  else jq -n "$@" | jq --arg long "$long" 'if $long != "" and .kind == "coding" then .summary = ("\($long): " | . + "x" * (410 - length)) else . end' > "$HARNESS_RUN_DIR/entry.json"; fi; }
main_touch() {   # <who>: STUB_MAIN_TOUCH's merge, once, when <who> is its session
  [[ ${STUB_MAIN_TOUCH:-} && ${STUB_MAIN_TOUCH%%:*} == "$1" ]] || return 0
  local p=${STUB_MAIN_TOUCH#*:} d; d=$(mktemp -d)
  ( g() { git -C "$d" -c user.name=other -c user.email=o@test "$@"; }
    git clone -q "$STUB_DIR/origin.git" "$d" 2> /dev/null && g checkout -q -b harness-merge/other-M3 origin/main && mkdir -p "$(dirname "$d/$p")" && echo "main's $p" > "$d/$p" \
      && g add -A && g commit -qm "other: $p" && g checkout -q main \
      && g merge -q --no-ff -m "Merge pull request #7 from test/harness-merge/other-M3" -m "other: M3 (verified)" harness-merge/other-M3 && g push -q origin main )
  rm -rf "$d"
}
# A finished session: the real capture's assistant, tool-result and result events (fixtures/usage-tokens.jsonl, so every
# session carries tokens), with cost, final text, turns and duration substituted. --argjson: callers' \\n become newlines.
# The result line is kept as the session's figures so far (a resume adds to them).
ok() { local out; out=$(jq -c --argjson c "${1:-0.25}" --argjson r "\"${2:-done}\"" 'if .type == "result" then .total_cost_usd = $c | .result = $r | .num_turns = 12 | .duration_ms = 60000 else . end' "$HERE/fixtures/usage-tokens.jsonl")
  keep "$out"; }
keep() { printf '%s\n' "$1"; if [[ -f $SESS/$sid ]]; then jq -c 'select(.type == "result")' <<< "$1" > "$SESS/$sid"; fi; }   # print it, keep its result line

case $first in
  "# Initializer session")
    [[ ${STUB_SLOW_INIT:-} ]] && sleep "$STUB_SLOW_INIT"
    [[ ${STUB_INIT_LIMIT:-} ]] && { cat "$HERE/fixtures/usage-limit.jsonl"; exit 1; }   # refused before the list exists
    [[ ${STUB_INIT_NO_LIST:-} ]] && { ok 1.5 "out of turns"; exit 0; }   # ended, not refused, with nothing written
    case ${STUB_CLI_STOP:-} in "") ;; -) "$HERE/../bin/harness" stop "$HARNESS_RUN_ID" > /dev/null ;;   # Michael runs `harness stop` meanwhile
      *) "$HERE/../bin/harness" stop "$HARNESS_RUN_ID" --why "$STUB_CLI_STOP" > /dev/null ;; esac
    [[ ${STUB_CLI_REQUEST:-} ]] && "$HERE/../bin/harness" queue add --continue "$HARNESS_RUN_ID" --brief "$STUB_CLI_REQUEST" > /dev/null
    [[ ${STUB_QUEUE_STOP:-} ]] && touch "$HARNESS_STATE/queue/STOP"   # Michael runs `harness queue stop` meanwhile
    [[ ${STUB_MEM_DROP:-} ]] && sed -i 's/^MemAvailable: .*/MemAvailable:    2097152 kB/' "$STUB_MEM_DROP"   # the box runs low on memory meanwhile (2 GB)
    after=""; [[ ${STUB_INDEPENDENT_M2:-} ]] && after=', "after": []'
    z=""; [[ ${STUB_DEFAULT_FEATURE:-} ]] && z='{ "id": "Z", "kind": "build", "description": "z, in no milestone", "steps": ["v"], "passes": false },'   # the default lane
    if [[ ${STUB_REVIEW_LIST:-} ]]; then cat > "$L" <<JSON
{ "run": "test", "features": [
  { "id": "A", "milestone": "M1", "kind": "build", "model": "sonnet", "description": "a", "steps": ["x", "y"], "passes": false },
  { "id": "B", "milestone": "M1", "kind": "build", "description": "b", "steps": ["y"], "passes": false },
  { "id": "D", "milestone": "M1", "kind": "build", "description": "d", "steps": ["w"], "passes": false },
  { "id": "R", "milestone": "M1", "kind": "review", "model": "sonnet", "description": "review M1", "steps": ["r"], "passes": false } ] }
JSON
    else cat > "$L" <<JSON
{ "run": "test", "features": [ $z
  { "id": "A", "milestone": "M1", "kind": "build", "model": "sonnet", "description": "a", "steps": ["x", "y"], "passes": false },
  { "id": "B", "milestone": "M1", "kind": "build", "description": "b", "steps": ["y"], "passes": false },
  { "id": "C", "milestone": "M2", "kind": "build", "model": "opus", "description": "c", "steps": ["z"]$after, "passes": false } ] }
JSON
    fi
    entry init 1 '{feature: "init", kind: "init", outcome: "passes", summary: "3 features: M1 2, M2 1", header: "# progress"}'
    git add -A && git commit -qm "HARNESS: feature list" && git push -q -u origin "$HARNESS_BRANCH"
    if [[ ${STUB_PHONE_STOP:-} ]]; then   # Michael edits INBOX.md on GitHub: status: stop [<why>]
      tmp=$(mktemp -d); git clone -q "$(git remote get-url origin)" "$tmp" -b "$HARNESS_BRANCH"
      why=""; [[ $STUB_PHONE_STOP == 1 ]] || why=" $STUB_PHONE_STOP"
      sed -i "1s/.*/status: stop$why/" "$tmp/$HARNESS_RUN_DIR/INBOX.md"
      git -C "$tmp" commit -qam "phone: stop" && git -C "$tmp" push -q origin "$HARNESS_BRANCH"
    fi
    ok 1.5 ;;
  "# Coding session")
    [[ ${STUB_SLOW_CODING:-} ]] && { touch "$STUB_DIR/slow-coding"; sleep "$STUB_SLOW_CODING"; }   # a session to interrupt
    # a file, not an env flag: it reaches tmux-started runs. With $STUB_DIR/hold-coding, a run's coding sessions say
    # held-<run> and held-<run>-<id> and wait (≤ 180 s) for release-<run> (all of them) or release-<run>-<id> (that
    # feature's): the suite decides when each run of a parallel queue ends (L5), and which lane goes first (P2)
    if [[ -f $STUB_DIR/hold-coding ]]; then
      hid=$(after_session '/^Feature: `/ { sub(/^Feature: `/, ""); sub(/`.*/, ""); print; exit }')
      touch "$STUB_DIR/held-$HARNESS_RUN_ID" "$STUB_DIR/held-$HARNESS_RUN_ID-$hid"
      for _ in $(seq 900); do [[ -f $STUB_DIR/release-$HARNESS_RUN_ID || -f $STUB_DIR/release-$HARNESS_RUN_ID-$hid ]] && break; sleep 0.2; done; fi
    if [[ ${STUB_WEEKLY:-} ]]; then   # the rate-limit event every real session carries: this one reports the 7-day window
      now=$(date +%s); echo "{\"type\":\"rate_limit_event\",\"rate_limit_info\":{\"status\":\"allowed\",\"resetsAt\":$(( now + 3600 )),\"rateLimitType\":\"five_hour\",\"unifiedWindows\":{\"five_hour\":{\"utilization\":0.2,\"resetsAt\":$(( now + 3600 ))},\"seven_day\":{\"utilization\":$STUB_WEEKLY,\"resetsAt\":$(( now + 259200 ))}}}}"
    fi
    if [[ ${STUB_LIMIT_HITS:-} ]] && (( $(count limit) <= STUB_LIMIT_HITS )); then   # the real 2026-10-17 limit, nothing done
      cat "$HERE/fixtures/usage-limit.jsonl"; exit 1
    fi
    if [[ ${STUB_NOWORK:-} ]] && (( $(count nowork) == 1 )); then   # an error that isn't a limit: $0, one turn
      echo '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":0,"num_turns":1,"duration_ms":400,"result":""}'; exit 0
    fi
    id=$(after_session '/^Feature: `/ { sub(/^Feature: `/, ""); sub(/`.*/, ""); print; exit }'); n=$(count "$id")
    echo "$id attempt $n" >> "$RS/sessions.log"
    if [[ ${STUB_BARRIER:-} == "$id":* && $n == 1 ]]; then   # at a barrier the check opens with stub_go (ordered, not timed)
      bn=${STUB_BARRIER#*:}; mkdir -p "$STUB_DIR/barriers" && touch "$STUB_DIR/barriers/$bn.held"
      bend=$(( $(date +%s) + 180 )) bout=timedout   # by the clock: a loaded box's slow rounds must not stretch it
      while (( $(date +%s) < bend )); do [[ -e $STUB_DIR/barriers/$bn ]] && { bout=released; break; }; sleep 0.1; done
      touch "$STUB_DIR/barriers/$bn.$bout"; fi
    if [[ ${STUB_IGNORED:-} ]]; then
      [[ -e $STUB_IGNORED ]] && echo "$id present" >> "$STUB_DIR/ignored.log" || echo "$id absent" >> "$STUB_DIR/ignored.log"
      [[ -f $RS/ignored-made ]] || { mkdir -p "$(dirname "$STUB_IGNORED")" && echo "$id" > "$STUB_IGNORED" && touch "$RS/ignored-made"; }
    fi
    if [[ ${STUB_EDIT:-} ]]; then   # edits only that path, passes nothing; keeps the init output it was started with (the suite cache, S3)
      cp "$HARNESS_SCRATCH/init.out" "$STUB_DIR/init-$HARNESS_RUN_ID-$n.out"
      mkdir -p "$(dirname "$STUB_EDIT")" && echo "$id $n" >> "$STUB_EDIT"
      entry "$id" "$n" --arg id "$id" --arg f "$STUB_EDIT" '{feature: $id, kind: "coding", outcome: "not yet", summary: "\($id): edited \($f)", files: [$f]}'
      git add -A && git commit -qm "$id: edit $STUB_EDIT ($n)" && git push -q origin "$HARNESS_BRANCH"
      ok; exit 0
    fi
    if [[ ${STUB_PAUSE:-} == "$id" && $n == 1 ]]; then   # `harness pause` mid-session: the driver pauses after it
      st=$(compgen -G "$HARNESS_STATE/*/$HARNESS_RUN_ID") && touch "$st/PAUSE"
    fi
    if [[ ${STUB_OOM:-} == "$id" && $n == 1 ]]; then   # killed at its memory cap: the stream cut off before its result, exit 137
      [[ -n ${STUB_SCOPE_UNIT:-} ]] && touch "$STUB_DIR/scope/$STUB_SCOPE_UNIT.oom"   # the stub systemctl then reports the cap as its peak
      jq -c 'select(.type != "result")' "$HERE/fixtures/usage-tokens.jsonl"; exit 137
    fi
    if [[ ${STUB_LEAVE_PROCESS:-} == 1 ]]; then   # backgrounds a process it never stops: its scope holds it (and $STUB_DIR/left.pids remembers it)
      sleep 300 > /dev/null 2>&1 & echo $! >> "$STUB_DIR/left.pids"
      [[ -n ${STUB_SCOPE_UNIT:-} ]] && echo $! >> "$STUB_DIR/scope/$STUB_SCOPE_UNIT.pids"
    fi
    if [[ ${STUB_ADD_TEARDOWN:-} && ! -f $RS/teardown-added ]]; then   # the first coding session adds a hook mid-run (a lane commit)
      printf '#!/usr/bin/env bash\ntouch "${HARNESS_SCRATCH%%%%/lanes/*}/teardown-late.marker"\n' > .harness/teardown.sh && chmod +x .harness/teardown.sh; touch "$RS/teardown-added"
      git add -A && git commit -qm "$id: a teardown hook" && git push -q origin "$HARNESS_BRANCH"
      if [[ ${STUB_PHONE_STOP_CODING:-} ]]; then   # then Michael stops the run from his phone, as STUB_PHONE_STOP does
        tmp=$(mktemp -d); git clone -q "$(git remote get-url origin)" "$tmp" -b "harness/$HARNESS_RUN_ID"
        sed -i "1s/.*/status: stop/" "$tmp/$HARNESS_RUN_DIR/INBOX.md"; git -C "$tmp" commit -qam "phone: stop" && git -C "$tmp" push -q origin "harness/$HARNESS_RUN_ID"; rm -rf "$tmp"
      fi
    fi
    if [[ ${STUB_COMMIT_RECORD:-} == "$id" && $n == 1 ]]; then   # beats the slot's exclude: commits a file into the run record
      echo x > "$HARNESS_RUN_DIR/x"; git add -f "$HARNESS_RUN_DIR/x" && git commit -qm "$id: into the record" && git push -q origin "$HARNESS_BRANCH"
    fi
    if [[ ${STUB_RECORD_MOVE:-} == "$id" && $n == 1 ]]; then   # Michael edits INBOX.md on GitHub meanwhile: the record moves under the session
      tmp=$(mktemp -d); git clone -q "$(git remote get-url origin)" "$tmp" -b "harness/$HARNESS_RUN_ID"
      sed -i '2s/$/ (phone edit)/' "$tmp/$HARNESS_RUN_DIR/INBOX.md"
      git -C "$tmp" commit -qam "phone: comment" && git -C "$tmp" push -q origin "harness/$HARNESS_RUN_ID"; rm -rf "$tmp"
    fi
    if [[ ${STUB_INBOX_IN_COMMENT:-} == "$id" && $n == 1 ]]; then   # asks where GitHub hides it, then parks
      node -e 'const fs=require("fs"),[f,id]=process.argv.slice(1),t=fs.readFileSync(f,"utf8"),i=t.indexOf("under ")+6;fs.writeFileSync(f,t.slice(0,i)+"## Questions\n\n**Q1 ("+id+", stub).** set the gatus vars, then answer\n\n"+t.slice(i))' "$HARNESS_RUN_DIR/INBOX.md" "$id"
      ok 0.3 "Not done: needs two values only Michael can set.\\nPARKED: set the gatus vars"; exit 0
    fi
    if [[ ${STUB_PARK:-} == "$id" && $n == 1 ]]; then   # can't go on without Michael: asks in INBOX.md, parks
      sed -i '/^## Answers/i ### '"$id"': set the gatus vars, then answer\n' "$HARNESS_RUN_DIR/INBOX.md"
      # STUB_PARK_FILES=<value>: the question's Files: line (U2-08); STUB_PARK_TOUCH=<path>: the session changes it too
      [[ ${STUB_PARK_FILES:-} ]] && sed -i "/^### $id: set the gatus vars/a Files: $STUB_PARK_FILES" "$HARNESS_RUN_DIR/INBOX.md"
      [[ ${STUB_PARK_TOUCH:-} ]] && mkdir -p "$(dirname "$STUB_PARK_TOUCH")" && echo "$id" > "$STUB_PARK_TOUCH"
      git add -A && git commit -qm "$id: question for Michael" && git push -q origin "$HARNESS_BRANCH"
      ok 0.3 "Not done: needs two values only Michael can set.\\nPARKED: set the gatus vars"; exit 0
    fi
    if [[ ${STUB_GIVE_UP:-} == "$id" ]]; then   # never passes: given up once its attempts are used
      entry "$id" "$n" --arg id "$id" '{feature: $id, kind: "coding", outcome: "not yet", summary: "\($id): stub never passes"}'; ok 0.3 "$id: not done"; exit 0
    fi
    if [[ ${STUB_LIMIT_MIDWAY:-} ]] && (( $(count midway) == 1 )); then   # real work, then the limit cuts the session off
      echo "half of $id" > "half-$id.txt"; git add -A && git commit -qm "$id: half"
      ok 1.4 "working"; sed -n 2p "$HERE/fixtures/usage-limit.jsonl" | sed 's/"total_cost_usd":0/"total_cost_usd":1.4/'
      echo '{"type":"result","subtype":"success","is_error":false,"total_cost_usd":1.4,"num_turns":0,"duration_ms":0,"result":""}'   # as 22-T4-09: a background task's empty result after the cut
      exit 1
    fi
    if [[ $id == R && $n == 2 && ${STUB_REVIEW_ROUND:-} == limit ]]; then cat "$HERE/fixtures/usage-limit.jsonl"; exit 1; fi
    if [[ $id == R && $n == 2 && ${STUB_REVIEW_ROUND:-} == fail ]]; then
      entry R 2 '{feature: "R", kind: "coding", outcome: "not yet", summary: "R: the round did not finish"}'; ok 0.5 "R: not done"; exit 0
    fi
    set_passes "$id" true
    if [[ ${STUB_PASS_THEN_LIMIT:-} && $id == A && $n == 1 ]]; then   # claims the feature, then the limit cuts it off
      echo "A $n" > "work-A.txt"; git add -A && git commit -qm "A: claimed"; sed -n 2p "$HERE/fixtures/usage-limit.jsonl"; exit 1
    fi
    if [[ $id == B && $n == 1 && ! ${STUB_NO_TAMPER:-} ]]; then   # tampers: flips C and rewrites its description
      node -e 'const fs=require("fs"),f=process.argv[1],l=JSON.parse(fs.readFileSync(f));const c=l.features.find(x=>x.id==="C");if(!c)process.exit(0);c.passes=true;c.description="easier";fs.writeFileSync(f,JSON.stringify(l))' "$L"
    fi
    if [[ $id == C ]]; then [[ $n == 1 && ! ${STUB_NO_RED:-} ]] && touch BROKEN || rm -f BROKEN; fi   # first try leaves the suite red
    [[ ${STUB_FIX_BROKEN:-} == "$id" && $n == 1 ]] && rm -f BROKEN
    echo "$id $n" > "work-$id.txt"
    [[ ${STUB_RUN_SUITE:-} == "$id" && $n == 1 ]] && { "$HARNESS_CHECK"; "$HARNESS_CHECK"; "$HARNESS_CHECK" x; true; } > /dev/null 2>&1
    (( n == 1 )) && main_touch "$id"
    if [[ ${STUB_SHARED:-} && $n == 1 ]]; then case $id in A) sed -i '1s/.*/A/' "$STUB_SHARED" ;; C) sed -i '$s/.*/C/' "$STUB_SHARED" ;; esac; fi
    if [[ ${STUB_CONFLICT:-} && $n == 1 && $id == [AC] ]]; then sed -i "2s/.*/line two, from $id/" "$STUB_CONFLICT"; fi
    if [[ ${STUB_SORTED:-} && $n == 1 && $id == [AC] ]]; then printf '%s\n' "b $id check" >> "$STUB_SORTED"; LC_ALL=C sort -o "$STUB_SORTED" "$STUB_SORTED"; fi
    [[ ${STUB_BIG_DIFF:-} && $id == A && $n == 1 ]] && seq 500 > big-A.txt   # a milestone diff over REVIEW_OPUS_LINES (M6)
    tns=${STUB_TESTS_N:-}; for tn in ${tns//,/ }; do if [[ ${tn%%:*} == "$id" && $n == 1 ]]; then echo "${tn#*:}" > tests.n; fi; done   # the suite's count moves (M5-02)
    if [[ ${STUB_SNAPSHOT:-} == "$id" && $n == 1 ]]; then   # what Michael sees between sessions, before finish (M5-02)
      st=$(compgen -G "$HARNESS_STATE/*/$HARNESS_RUN_ID") && mkdir -p "$STUB_DIR/snap-$HARNESS_RUN_ID" && (set +e; cd "$STUB_DIR/snap-$HARNESS_RUN_ID"
        HARNESS_GLYPHS=unicode "$HERE/../bin/harness" status "$HARNESS_RUN_ID" > status.txt; "$HERE/../bin/harness" report "$HARNESS_RUN_ID" > report.md
        cp "$st/summary.json" "$st/tests-start" .; cp "$st/tests-end" . 2> /dev/null; true)
    fi
    if [[ ${STUB_GOTCHA:-} == "$id" && $n == 1 ]]; then   # a fact a fresh session would rediscover, as the Finish step asks
      grep -qx '## Gotchas' CLAUDE.md 2> /dev/null || printf '\n## Gotchas\n\n' >> CLAUDE.md
      echo "- the stub's work files sit at the repo root, one per feature ($HARNESS_RUN_ID $(date +%F))" >> CLAUDE.md
    fi
    # main may already have work-<id>.txt as written here (run demo merged it): a file only this run adds, for the minimal entry's files
    [[ ${STUB_BAD_ENTRY:-} == "$id" && $n == 1 ]] && echo "$HARNESS_RUN_ID" > "$id-$HARNESS_RUN_ID.txt"
    # STUB_ASK_TOUCH=<path>: the session that asks (STUB_ASK) changes it too, outside its entry's files (U2-08's fill)
    [[ ${STUB_ASK_TOUCH:-} && ${STUB_ASK:-} == "$id" && $n == 1 ]] && mkdir -p "$(dirname "$STUB_ASK_TOUCH")" && echo "$id" > "$STUB_ASK_TOUCH"
    entry "$id" "$n" --arg id "$id" --arg n "$n" --arg ask "${STUB_ASK:-}" --arg resolve "${STUB_RESOLVE:-}" --arg two "${STUB_ASK_TWO:-}" --arg again "${STUB_ASK_AGAIN:-}" --arg fact "${STUB_PROJECT_FACT:-}" --arg failrow "${STUB_VERIFY_FAIL_ROW:-}" --arg rf "${STUB_REVIEW_FINDINGS:-}" --argjson broken "$([[ -f BROKEN ]] && echo true || echo false)" '{feature: $id, kind: "coding",
      outcome: "passes", summary: (if $id == "R" and $rf != "" then "R: stub review (\($n)): \($rf | split(",")[0]) Critical, \($rf | split(",")[1]) Important, 0 Minor" else "\($id): stub work (\($n))" end), files: ["work-\($id).txt"], verified_how: "stub", tests_before: 1, tests_after: 1}
      + if $broken then {dead_ends: [{tried: "left BROKEN in the tree", why: "the suite goes red"}]} else {} end
      + if $failrow == "1" and $id == "A" then {dead_ends: [{tried: "A by the first approach (\($n))", why: "verify M1 may find step 1 failing"}]} else {} end
      + ({questions: ((if $ask == $id and $n == "1" then ["Should \($id) default to off?"] else [] end)
          + (if $two == $id and $n == "1" then ["Should \($id) keep the old cache? (default: kept) Files: /srv/q/lib/a.sh:12", "Should \($id) log at debug? (default: info) Files: /srv/q/lib/b.sh"] else [] end)
          + (if $again == $id and $n == "1" and $ask != "" then ["Should \($ask) default to off?"] else [] end))} | if .questions == [] then {} else . end)
      + if $resolve == $id and $n != "1" then {resolved: ["Should \($id) default to off?"]} else {} end
      + if $fact == $id and $n == "1" then {discoveries: [{text: "the stub'"'"'s work files sit at the repo root, one per feature", affects: ["project"]}]} else {} end'
    git add -A && git commit -qm "$id: stub work ($n)" && git push -q origin "$HARNESS_BRANCH"
    if [[ ${STUB_STALE_GREEN:-} == "$id" && $n == 1 ]]; then   # red tree, cached green: only a full run catches it
      touch BROKEN && git add -A && git commit -qm "$id: left BROKEN" && git push -q origin "$HARNESS_BRANCH"
      mkdir -p "$HARNESS_CHECK_CACHE" && : > "$HARNESS_CHECK_CACHE/green-$(node "$HERE/../lib/treekey.mjs")"
    fi
    ok ;;
  "# Verify session")
    m=$(after_session '/^Milestone: / { print $2; exit }'); n=$(count "verify-$m")
    echo "verify $m $n" >> "$RS/sessions.log"
    if [[ ${STUB_VERIFY_WAIT:-} && ${STUB_VERIFY_WAIT%%:*} == "$m" ]]; then   # another lane merges meanwhile
      touch "$STUB_DIR/vwait-$HARNESS_RUN_ID-$m"
      for _ in $(seq 600); do git fetch -q origin main 2> /dev/null && git cat-file -e "origin/main:${STUB_VERIFY_WAIT#*:}" 2> /dev/null && break; sleep 0.2; done
    fi
    (( n == 1 )) && main_touch "verify-$m"
    if [[ ${STUB_VERIFY_LIMIT:-} && $m == M1 && $n == 1 ]]; then cat "$HERE/fixtures/usage-limit.jsonl"; exit 1; fi   # refused
    if [[ ${STUB_VERIFY_EDITS:-} && $n == 1 ]]; then echo hack > "hack-$m.txt"; echo "edited" >> CLAUDE.md; echo null >> "$HARNESS_RUN_DIR/entries.jsonl"; fi   # a verifier "fixing" code and the journal
    [[ $m == M1 && ( $n == 1 || ${STUB_STRICT_VERIFIER:-} ) && ! ${STUB_LENIENT:-} ]] && set_passes A false   # catches a false pass
    [[ ${STUB_REBASE_VERIFY_FAIL:-} && $m == M2 && $n == 2 ]] && set_passes C false   # the re-base's verify round finds C failing
    # one evidence row per step of every feature of m (none in a thin round 1); passes when every feature of m still passes
    ev=$(node -e 'const [f,m,full]=process.argv.slice(1),fs=JSON.parse(require("fs").readFileSync(f)).features.filter(x=>x.milestone===m);console.log(JSON.stringify({done:fs.every(x=>x.passes),
      rows:full==="1"?fs.flatMap(x=>x.steps.map((s,i)=>({feature:x.id,step:i+1,ran:"check",saw:"ok",holds:true}))):[]}))' "$L" "$m" "$([[ ! ${STUB_THIN_VERIFY:-} || ( $n -gt 1 && $STUB_THIN_VERIFY != all ) ]] && echo 1)")
    fail='[]'; [[ ${STUB_VERIFY_FAIL_ROW:-} == 1 && $m == M1 && $n == 1 ]] && fail='[{"feature":"A","step":1,"ran":"check","saw":"A fails: work-A.txt holds the line \"A 1\" the first approach wrote, where step 1 expects the session after the verify to rewrite it; the check read the stale line twice, so step 1 does not hold on this tree","holds":false}]'
    entry "$m" "$n" --arg m "$m" --arg n "$n" --argjson ev "$ev" --argjson fail "$fail" '{feature: $m, kind: "verify", outcome: (if $ev.done then "passes" else "not yet" end),
      summary: "verify \($m) (\($n))", evidence: ($ev.rows + $fail)}'
    git add -A && git commit -qm "verify $m ($n)" --allow-empty && git push -q origin "$HARNESS_BRANCH"
    ok 0.1 ;;
  "# Resolve session")   # the merge in progress in the slot: its conflicted files as git lists them (fixtures/git-conflict/diff-name-only-U.txt)
    m=$(after_session '/^Milestone: / { print $2; exit }'); n=$(count "resolve-$m")
    echo "resolve $m $n" >> "$RS/sessions.log"
    (( n == 1 )) && main_touch "resolve-$m"   # main moves again during the session's turn
    [[ ${STUB_RESOLVE_LIMIT:-} ]] && (( n <= STUB_RESOLVE_LIMIT )) && { cat "$HERE/fixtures/usage-limit.jsonl"; exit 1; }   # refused before it touches a file
    mapfile -t cf < <(git -c core.quotePath=false diff --name-only --diff-filter=U)
    case ${STUB_MERGE_RESOLVE:-} in
      both|markers|stray)
        fin=""; for f in "${cf[@]}"; do sed -i -E '/^(<<<<<<<|=======|>>>>>>>)( |$)/d' "$f"; git add -- "$f"; fin+="RESOLVED: $f: kept both sides\\n"; done
        out=passes
        [[ $STUB_MERGE_RESOLVE == markers ]] && { sed -i '1i <<<<<<< HEAD' README.md; git add README.md; fin="RESOLVED: README.md: kept both sides"; }
        [[ $STUB_MERGE_RESOLVE == stray ]] && { echo stray >> work-A.txt; echo stray > stray.txt; echo added > stray-added.txt; git add stray-added.txt; } ;;
      *) fin="UNRESOLVED: stub gives up" out="not yet" ;;
    esac
    entry "$m" "$n" --arg m "$m" --arg n "$n" --arg o "$out" '{feature: $m, kind: "resolve", outcome: $o, summary: "resolve \($m) (\($n))", files: $ARGS.positional}' --args "${cf[@]}"
    ok 0.3 "$fin" ;;
  "# Retro")
    echo "retro" >> "$RS/sessions.log"
    if [[ ${STUB_LEAVE_RETRO:-} == 1 ]]; then sleep 300 > /dev/null 2>&1 & echo $! >> "$STUB_DIR/left.pids"   # as STUB_LEAVE_PROCESS, for the read-only retro
      [[ -n ${STUB_SCOPE_UNIT:-} ]] && echo $! >> "$STUB_DIR/scope/$STUB_SCOPE_UNIT.pids"; fi
    [[ ${STUB_RETRO_EDITS:-} ]] && { echo "retro was here" > retro-hack.txt; echo x >> "$HARNESS_RUN_DIR/progress.md"
      mkdir -p ledger && echo '{"id":"retro-hack"}' > ledger/retro-backlog.jsonl; }   # a retro editing the backlog itself (M1-04)
    case ${STUB_RETRO_PROPOSALS:-} in "") ;; bad) printf '{not json' > "$HARNESS_RUN_DIR/retro-proposals.json" ;;
      link) ln -s feature_list.json "$HARNESS_RUN_DIR/retro-proposals.json" ;;
      *) tr , '\n' <<< "$STUB_RETRO_PROPOSALS" | jq -R '{id: ., title: "stub proposal \(.)", evidence: "stub retro"}' | jq -s . > "$HARNESS_RUN_DIR/retro-proposals.json" ;; esac
    ok 0.2 "## Outcome\\nStub retro.\\n\\n## Proposed harness changes\\n1. none" ;;
  "# Entry resume")   # resumed.jsonl on the session's figures: cost plus the fixture's increment, modelUsage plus its usage
    id=$(after_session '/^Feature: `/ { sub(/^Feature: `/, ""); sub(/`.*/, ""); print; exit }')
    kind=$(after_session '/^Kind: `/ { sub(/^Kind: `/, ""); sub(/`.*/, ""); print; exit }')
    case ${STUB_RESUME_ENTRY:-} in
      good|good-edits|good-overreach) jq -n --arg id "$id" --arg k "$kind" '{feature: $id, kind: $k, outcome: "not yet", summary: "\($id): written on a resume",
        dead_ends: [{tried: "ending without an entry", why: "the harness resumed the session to write it"}]}' > "$HARNESS_RUN_DIR/entry.json"
        [[ $STUB_RESUME_ENTRY == good-edits ]] && echo "$id" > resumed.txt
        if [[ $STUB_RESUME_ENTRY == good-overreach ]]; then
          if [[ $kind == init ]]; then echo '{ "run": "test", "features": [ { "id": "A", "kind": "build", "description": "a", "steps": ["x"], "passes": false } ] }' > "$L"
          else set_passes "$id" "$(jq --arg i "$id" '[.features[] | select(.id == $i).passes] | .[0] | not' "$L")"; echo "$id" > overreach.txt && git add overreach.txt && git commit -qm "resume: $id" -- overreach.txt; fi
        fi ;;
      bad) printf '{not json' > "$HARNESS_RUN_DIR/entry.json" ;;
    esac
    prev=$SESS/$sid; [[ -f $prev ]] || prev=/dev/null
    out=$(jq -c --arg id "$sid" --arg cwd "$PWD" --slurpfile prev "$prev" --slurpfile f "$RES/first.jsonl" --slurpfile r "$RES/resumed.jsonl" '
      def res(x): x | map(select(.type == "result"))[-1]; (res($r).total_cost_usd - res($f).total_cost_usd) as $inc | res($r).usage as $u
      | ($prev[0] // {}) as $p | (($p.modelUsage // {}) | if length == 0 then res($r).modelUsage | map_values(.inputTokens = 0 | .outputTokens = 0 | .cacheReadInputTokens = 0 | .cacheCreationInputTokens = 0 | .costUSD = 0) else . end) as $m
      | (if has("session_id") then .session_id = $id else . end) | if .type == "system" and .subtype == "init" then .cwd = $cwd | .original_cwd = $cwd else . end
      | if .type == "result" then .total_cost_usd = ($p.total_cost_usd // 0) + $inc
          | .modelUsage = ($m | to_entries | (.[0].value |= (.inputTokens += $u.input_tokens | .outputTokens += $u.output_tokens
              | .cacheReadInputTokens += $u.cache_read_input_tokens | .cacheCreationInputTokens += $u.cache_creation_input_tokens | .costUSD += $inc)) | from_entries)
        else . end' "$RES/resumed.jsonl")
    keep "$out" ;;
  "# Probe session"*)   # records its command line, $PWD and prompt; for t2, Q1 (T2a's files) is right and Q2 (T2b's deps) wrong
    { printf '%s\n' "${ARGS[@]}"; echo "PWD=$PWD"; echo "HARNESS_EVAL=${HARNESS_EVAL:-}"; } > "$STUB_DIR/probe-args"; printf '%s\n' "$prompt" > "$STUB_DIR/probe-prompt"
    [[ ${STUB_PROBE_ERROR:-} ]] && { echo "warning: noise on stderr" >&2
      cat "$HERE/fixtures/usage-limit.jsonl"; exit 1; }   # the real capture of a refused session
    ok 0.01 "Q1: work-T2a.txt\\nQ2: nothing" ;;
  "# Debrief"*)   # records its command line and prompt; STUB_DEBRIEF_CONTINUE="<run>…": asks to continue each
    printf '%s\n' "${ARGS[@]}" > "$STUB_DIR/debrief-args"; printf '%s\n' "$prompt" > "$STUB_DIR/debrief-prompt"
    [[ ${STUB_DEBRIEF_LIMIT:-} ]] && { cat "$HERE/fixtures/usage-limit.jsonl"; exit 1; }
    if [[ ${STUB_DEBRIEF_ERROR:-} ]]; then
      echo '{"type":"result","subtype":"error_max_turns","is_error":true,"total_cost_usd":0.4,"num_turns":40,"result":"Error: reached max turns"}'; exit 1
    fi
    [[ ${STUB_DEBRIEF_DEAD:-} ]] && { echo "Error: unknown option '--whatever'" >&2; exit 1; }   # dies at startup
    [[ ${STUB_DEBRIEF_TOUCH:-} ]] && echo x > "$STUB_DEBRIEF_TOUCH"   # writes a file while it runs
    echo "debrief" >> "$STUB_DIR/debriefs.log"
    note=$'## Headline\nLanded: proj M1, M2 on main.\nBlocked: nothing.\nSpend $1.20; window open.\nFOURTH headline line\n\n## Runs\nstub runs <i>raw</i>\n\n## Needs Michael\n_Nothing._\n'
    [[ ${STUB_DEBRIEF_NEEDS:-} ]] && note=${note/Blocked: nothing./Blocked: parky B waits on Michael.} note=${note/_Nothing._/parky B: set the gatus vars (progress.md)}
    lead="- "; for r in ${STUB_DEBRIEF_CONTINUE:-}; do note+=$'\n'"${lead}CONTINUE: $r :: do C next"; lead=""; done
    jq -cn --arg r "$note" '{type:"result",subtype:"success",is_error:false,total_cost_usd:0.3,duration_ms:1000,num_turns:5,result:$r}' ;;
esac
