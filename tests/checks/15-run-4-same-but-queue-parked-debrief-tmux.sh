#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
REPLAY=1   # replayed for their state, checked in their own files (tests/split.sh REPLAYS_)
# ---- run 1: misbehaving sessions, two milestones; verified milestones merge themselves ----
"$H" start "$T/proj" demo --spec SPEC.md --brief "only A–C" --foreground > "$T/run1.out" 2>&1
WT=$T/wt/proj/demo RD=$T/wt/proj/demo/.harness/runs/demo; hlog demo > "$T/demo-hlog.md"   # gc removes the worktree; run 15e reads it
check "all features pass"                 '[[ $($F summary "$(list demo)") == "3/3 passing" ]]'
check "tampered list restored"            'hlog demo | grep -q "restored the feature list after B"'
check "tampered text reverted"            '[[ $(jq -r ".features[2].description" "$(list demo)") == c ]]'
check "red suite un-passes C"             'hlog demo | grep -q "C un-passed: suite red"'
check "C retried and passed"              'grep -q "C attempt 2" "$T/scratch/proj/demo/sessions.log"'
check "verifier caught A, re-queued"      'hlog demo | grep -q "verify M1: A failed the re-check" && grep -q "A attempt 2" "$T/scratch/proj/demo/sessions.log"'
check "M1 and M2 tagged"                  'git -C "$T/origin.git" tag | grep -qx run/demo/M1 && git -C "$T/origin.git" tag | grep -qx run/demo/M2'
check "M1 and M2 merged into main by PRs" '[[ $(grep -c "pr merge" "$T/gh.log") == 2 ]] && on_main run/demo/M2 && hlog demo | grep -q "M2 merged into main"'
check "no final tag, no false 'verified'" '! git -C "$T/origin.git" tag | grep -q final && ! hlog demo | grep -q "final verified"'
check "the verify prompt says the suite runs in full" 'grep -q "cleared the suite'"'"'s cached result" "$HARNESS_STATE/proj/demo/prompt-verify.md"'
check "brief committed with the run"      'grep -q "only A–C" "$RD/brief.md"'
check "brief, rules and policy in the prompt" 'P=$HARNESS_STATE/proj/demo/prompt-coding.md; grep -q "only A–C" "$P" && grep -qx "# Project rules" "$P" && grep -q "\`CLAUDE.md\`" "$P" && grep -q "Policy: build-only" "$P"'
check "coding prompt names CLAUDE.md but doesn't paste it" 'P=$HARNESS_STATE/proj/demo/prompt-coding.md; grep -q CLAUDE.md "$P" && ! grep -qx rules "$P"'
check "the rendered coding prompt has the deepEqual and bounded-rerun rule" 'P=$(bash "$HERE/../lib/prompt.sh" "$HARNESS_STATE/proj/demo" coding A 2> /dev/null) && grep -q "deepEqual" <<< "$P" && grep -q "exit 137" <<< "$P" && grep -q -- "--test-name-pattern" <<< "$P"'
# each session's prompt is kept beside its transcript; two coding sessions share everything up to and past the policy (E3-03)
off() { grep -bo "$1" "$2" 2> /dev/null | head -1 | cut -d: -f1; }   # the 0-based byte offset of the first $1 in $2
PA=$(ls "$HARNESS_STATE"/proj/demo/logs/*-A.prompt.md 2> /dev/null | head -1) PB=$(ls "$HARNESS_STATE"/proj/demo/logs/*-B.prompt.md 2> /dev/null | head -1)
CB=$(cmp "$PA" "$PB" 2> /dev/null | sed -n 's/.* differ: \(byte\|char\) \([0-9]*\),.*/\2/p')
check "two coding prompts share a byte-identical prefix that includes the policy" '[[ -s $PA && -s $PB && -n $CB && -n $(off "Policy: build-only" "$PA") ]] \
  && (( CB - 1 > $(off "Policy: build-only" "$PA") && CB - 1 > $(off "Policy: build-only" "$PB") )) \
  && (( $(off "Policy: build-only" "$PA") < $(off "only A–C" "$PA") && $(off "only A–C" "$PA") < $(off "# This session" "$PA") )) \
  && (( CB - 1 > $(off "# This session" "$PA") && $(off "Clock:" "$PA") > $(off "# This session" "$PA") ))'
# the clock line: time, deadline, budget, turns, attempt or verify round (E3-04); C's later prompt is its second attempt
PC=$(ls "$HARNESS_STATE"/proj/demo/logs/*-C.prompt.md 2> /dev/null | tail -1)
check "the prompt says the time, the budget and the attempt" '[[ -s $PC ]] && grep -Eqx "Clock: [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2} · run [0-9]+h[0-9]{2}m of [0-9]+h([0-9]{2}m)?, ends [0-9]{2}:[0-9]{2} · this session: \\\$20 budget, 250 turns, 100m timeout · attempt 2 of 2" "$PC" \
  && [[ $(grep -l "verify round 2 of 2" "$HARNESS_STATE"/proj/demo/logs/*-verify-M1.prompt.md 2> /dev/null | wc -l) == 1 ]]'
check "metrics: wall time and roles"      'jq -e "select(.kind==\"coding\") | .wall_s != null and .role == \"build\"" "$RD/metrics.jsonl" > /dev/null'
check "metrics: coding rows carry tokens, cache rate and context peak" 'jq -se "map(select(.kind==\"coding\")) | length > 0 and all(.tokens_in > 0 and .cache_hit_rate >= 0 and .cache_hit_rate <= 1 and .context_peak > 0)" "$RD/metrics.jsonl" > /dev/null'
check "metrics.jsonl: every session line has mem_peak_mb from its scope" 'jq -se "length >= 9 and all(.mem_peak_mb == 2)" "$RD/metrics.jsonl" > /dev/null && ! grep -q "Memory peaks" "$RD/report.md"'
check "metrics: orientation recorded per session" 'jq -se "map(select(.kind==\"coding\")) | length > 0 and all(.orient_tokens > 0 and .orient_turns >= 1 and (.orient_s | type) == \"number\")" "$RD/metrics.jsonl" > /dev/null'
# the journal (E4-03): one line per session in session order, stamped by the driver, and no entry.json left behind;
# C's first attempt (it left the suite red) carries its dead end; the tree a milestone is tagged (and merged) with has its verify's line
check "entries: the driver appends each session's entry" '[[ $(jq -r .feature "$RD/entries.jsonl" 2> /dev/null | paste -sd" ") == "init A B M1 A M1 C C M2" ]] \
  && [[ $(jq -r .session "$RD/entries.jsonl" | sed "s/^[0-9]\{6\}-verify-/verify-/" | paste -sd" ") == "00-init 01-A 02-B verify-M1 03-A verify-M1 04-C 05-C verify-M2" ]] \
  && jq -se "all(.at | test(\"^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}$\")) and all(.model | startswith(\"claude-\")) and all(has(\"minimal\") | not) \
    and (map(select(.session == \"04-C\"))[0].dead_ends[0].tried == \"left BROKEN in the tree\")" "$RD/entries.jsonl" > /dev/null && [[ ! -e $RD/entry.json ]] \
  && ! git -C "$T/origin.git" cat-file -e run/demo/M2:.harness/runs/demo/entry.json 2> /dev/null \
  && [[ $(git -C "$T/origin.git" show run/demo/M2:.harness/runs/demo/entries.jsonl 2> /dev/null | tail -1 | jq -r .feature) == M2 ]]'
# progress.md is rendered from the journal (E4-04): its entry headers are entries.jsonl's, newest first; the newest verify
# M1 entry carries its evidence table; the archive has every entry; the M2 PR quotes its verify entry with its rows
check "progress.md is rendered from the journal" 'head -1 "$RD/progress.md" | grep -q "^<!-- harness: rendered from entries.jsonl" \
  && [[ $(grep "^### " "$RD/progress.md") == "$(jq -r "\"### \" + .at + \" · \" + (if .kind == \"verify\" then \"verify \" else \"\" end) + .feature + \" · \" + .outcome" "$RD/entries.jsonl" | tac)" ]] \
  && awk "index(\$0, \"### \") == 1 { if (on) exit; if (index(\$0, \"verify M1\")) on = 1 } on" "$RD/progress.md" | grep -q "^| A | 1 |" \
  && [[ $(grep -c "^### " "$RD/progress-archive.md") == $(wc -l < "$RD/entries.jsonl") ]] \
  && grep -q "^### .* · verify M2 · passes$" "$HARNESS_STATE/proj/demo/pr-body.md" && grep -q "^| C | 1 |" "$HARNESS_STATE/proj/demo/pr-body.md"'
# the context pack before each coding and verify session (E4-05): C's second attempt got its first attempt's dead end,
# both prompts send the session there first, and the pack is committed with the run record (so it merges)
check "context.md carries the earlier attempt's dead end" 'C5=$HARNESS_STATE/proj/demo/logs/05-C.context.md; grep -q "left BROKEN in the tree" "$C5" && (( $(wc -c < "$C5") <= 8192 )) \
  && grep -q "^# Context pack for \`M1\`" "$(ls "$HARNESS_STATE"/proj/demo/logs/*-verify-M1.context.md | head -1)" \
  && grep -qx "Read context.md first; the full record is entries.jsonl / progress-archive.md (all in the run directory)." "$HARNESS_STATE/proj/demo/prompt-coding.md" \
  && grep -qx "Read context.md first; the full record is entries.jsonl / progress-archive.md (all in the run directory)." "$HARNESS_STATE/proj/demo/prompt-verify.md" \
  && git -C "$T/origin.git" cat-file -e run/demo/M2:.harness/runs/demo/context.md && hlog demo | grep -q "context.md for C: [0-9]* bytes"'
check "ended: done; status says so"       'grep -q "^done" "$HARNESS_STATE/proj/demo/ended" && grep -q "ended: done" <<< "$("$H" status demo)"'
check "summary, report and retro written" '[[ $(jq .features.merged "$RD/summary.json") == 3 ]] && grep -q "per passing feature" "$RD/report.md" && grep -q "Stub retro" "$RD/retro.md"'
check "summary: tokens, per verified feature, first-attempt rate, rework" 'jq -e ".tokens.in > 0 and .per_verified_feature.cost > 0 and .rework == [\"A\", \"C\"] and .first_attempt_pass_rate == 0.33 and .verify_fail_rate > 0" "$RD/summary.json" > /dev/null'
check "report shows tokens and quality"   'R=$("$H" report demo); grep -q "^| Tokens | .* in (cache hit .*context peak .*per verified feature " <<< "$R" && grep -q "^| Quality | first-attempt pass rate 0.33 · rework A, C · verify-fail rate " <<< "$R"'
check "ledger has the run"                'grep -q "\"run\":\"demo\"" "$T/ledger/runs.jsonl" && [[ -f $T/ledger/proj/demo/summary.json ]]'
HV=$(git -C "$HERE/.." log -1 --format=%h -- . ":(exclude)ledger")   # the demo run's harness is this checkout; its own ledger commits don't count
check "ledger row has harness_version and harness_dirty" 'jq -se --arg v "$HV" "map(select(.run == \"demo\"))[0] | .harness_version == \$v and (.harness_dirty | type == \"boolean\")" "$T/ledger/runs.jsonl" > /dev/null \
  && grep -q " run demo on .* · harness $HV\(+dirty\)\?$" "$HARNESS_STATE/proj/demo/run.log" && [[ $(cat "$HARNESS_STATE/proj/demo/harness-version") == "$HV" ]]'
# the live harness commits its ledger/ after every run: such a commit is not a new version, nor ledger files dirt
VR=$T/vrepo; mkdir -p "$VR/lib" "$VR/ledger"; vg() { git -C "$VR" -c user.name=t -c user.email=t@t "$@"; }
vg init -q -b main; echo a > "$VR/lib/x"; vg add -A; vg commit -qm code; VC=$(vg rev-parse --short HEAD)
echo r > "$VR/ledger/runs.jsonl"; vg add -A; vg commit -qm ledger; echo r2 >> "$VR/ledger/runs.jsonl"; echo n > "$VR/ledger/new"
check "harness version skips ledger commits" 'V1=$(source "$HERE/../lib/version.sh"; harness_version "$VR"; echo "$HARNESS_VERSION $HARNESS_DIRTY") \
  && echo b >> "$VR/lib/x" && V2=$(source "$HERE/../lib/version.sh"; harness_version "$VR"; echo "$HARNESS_VERSION $HARNESS_DIRTY") \
  && V3=$(source "$HERE/../lib/version.sh"; harness_version "$T/nonexistent"; echo "$HARNESS_VERSION $HARNESS_DIRTY") && [[ $V1 == "$VC 0" && $V2 == "$VC 1" && $V3 == "unknown 0" ]]'
check "harness report prints the writeup" 'grep -q "Spend by role" <<< "$("$H" report demo)"'
# reviews sized to the milestone (R2): the demo has no review feature, so a copy of its summary gets a review cost
check "the report lists the review role when a review ran" 'jq ".cost.by_role.review = 1.25" "$RD/summary.json" > "$T/summary-review.json" \
  && grep -q "^| Spend by role | .*build \$[0-9.]* · review \$1.25 · .*manager (the bash driver) \$0.00 |$" <<< "$(node "$HERE/../lib/summary.mjs" report "$T/summary-review.json")"'
check "init model resolved to fable"      'grep -q "initializer · claude-fable-5-1" "$HARNESS_STATE/proj/demo/run.log"'
check "summary end reason is how the run ended" '[[ $(jq -r .end_reason "$RD/summary.json") == done ]]'
check "a milestone without an after list is noted" 'hlog demo | grep -q "dependencies: M2 has no after list"'
# the step lint (R3) and the after rule (R10): the initializer runs the live harness's lint; the driver notes what is left, once
check "the initializer prompt has the resolved lint command" 'grep -qF "\`node $(readlink -f "$HERE/..")/lib/features.mjs lint <run directory>/feature_list.json\`" "$HARNESS_STATE/proj/demo/prompt-initializer.md"'
check "the initializer prompt sizes reviews to the milestone" 'grep -q "folds its review" "$HARNESS_STATE/proj/demo/prompt-initializer.md" \
  && grep -q "milestone'\''s size doesn'\''t call for). No output means clean." "$HARNESS_STATE/proj/demo/prompt-initializer.md"'
check "the initializer prompt asks for after on independent features and on every milestone's first" 'grep -qF "Give \`after\` on any feature that doesn'\''t need its predecessor in the same milestone, and on every milestone'\''s first feature (\`[]\` when independent)" "$HARNESS_STATE/proj/demo/prompt-initializer.md"'
check "the driver notes the lint once after the initializer" '[[ $(hlog demo | grep -c "lint: ") == 1 ]] \
  && hlog demo | grep -q "lint: 5 findings (no-anchor: 4, undeclared: 1); the list is not edited — first: A step 1 no-anchor$" && hlog demo | grep -q "dependencies: M2 has no after list"'
LF=$(git -C "$T/origin.git" log harness/demo --format=%H --grep="^HARNESS: feature list" -1) LI=$(git -C "$T/origin.git" log harness/demo --format=%H --grep="^HARNESS: initializer done" -1)
check "the driver never edits the list: the initializer's feature_list.json is byte for byte the stub's" '[[ -n $LF && -n $LI ]] \
  && git -C "$T/origin.git" show "$LF:.harness/runs/demo/feature_list.json" > "$T/list-stub.json" && git -C "$T/origin.git" show "$LI:.harness/runs/demo/feature_list.json" > "$T/list-init.json" \
  && [[ -s $T/list-stub.json ]] && cmp -s "$T/list-stub.json" "$T/list-init.json"'
check "NTFY_URL: curl posts the fields as headers, NOTIFY_CMD not called" 'B=$(curl_with "[demo] started:"); [[ $(tail -1 <<< "$B") == https://ntfy.example/t ]] && grep -A1 -x -- -H <<< "$B" | grep -qx "Title: harness" && grep -A1 -x -- --data-binary <<< "$B" | grep -qx "\[demo\] started: 0/3 passing" && [[ ! -e $T/notify-cmd.log ]]'
check "NTFY_TOKEN: bearer header sent, never logged" 'grep -qx "Authorization: Bearer tok-secret-123" "$T/curl.log" && [[ -d $HARNESS_STATE/proj/demo && -d $RD ]] && ! grep -rq tok-secret-123 "$HARNESS_STATE/proj/demo" "$RD"'
check "a successful post: a line in run.log only" 'grep -q "notified: harness" "$HARNESS_STATE/proj/demo/run.log" && ! hlog demo | grep -q "notified\|notification failed"'
check "routine notifications keep the default priority" 'Bs=$(curl_with "[demo] started:") Bm=$(curl_with "[demo] M1 merged") && [[ -n $Bs && -n $Bm ]] && ! grep -q "^Priority:" <<< "$Bs$Bm" \
  && grep -qx "Click: $GHP/blob/harness/demo/.harness/runs/demo/progress.md" <<< "$Bs" && U=$(grep -o "https://example.test/pr/[0-9]*" <<< "$Bm" | head -1) && [[ -n $U ]] && grep -qx "Click: $U" <<< "$Bm"'

# ---- run 2: Michael sets "status: stop" in INBOX.md from the phone (and only NOTIFY_CMD is configured) ----
printf '%s\n' 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' "NOTIFY_CMD='{ printf \"%s\\n\" \"\$1\"; env | grep ^HARNESS_NOTIFY_; echo ===; } >> \"$T/notify-env.log\"'" > "$T/user-config.sh"
# a continuation Michael requested before this stop (state_of needs a meta.env; the start writes the real one)
mkdir -p "$HARNESS_STATE/proj/stoppy" && printf 'RUN_ID=stoppy\n' > "$HARNESS_STATE/proj/stoppy/meta.env" && "$H" queue add --continue stoppy > /dev/null
STUB_PHONE_STOP=1 "$H" start "$T/proj" stoppy --spec SPEC.md --foreground > "$T/run2.out" 2>&1
cp "$T/base-config.sh" "$T/user-config.sh"
check "NOTIFY_CMD-only: \$1 unchanged, fields as env" 'grep -q "^\[stoppy\] started: 0/3 passing$" "$T/notify-env.log" && grep -qx "HARNESS_NOTIFY_TITLE=harness" "$T/notify-env.log" && grep -qx "HARNESS_NOTIFY_PRIORITY=" "$T/notify-env.log" && [[ -s $T/curl.log ]] && ! grep -q "\[stoppy\]" "$T/curl.log"'
check "phone stop honoured before any coding session" 'hlog stoppy | grep -q "stopped by Michael" && ! grep -q attempt "$T/scratch/proj/stoppy/sessions.log"'
check "a stop from the phone stops the services through finish" 'hlog stoppy | grep -q "· services stopped (stopped by Michael)$" && [[ -f $T/scratch/proj/stoppy/teardown-stopped-by-Michael.marker ]]'
check "a stop makes a queued requested continuation of its run automatic (the later word wins)" 'f=$(compgen -G "$HARNESS_STATE/queue/*-continue-stoppy.args") && grep -qx -- --queued "$f" \
  && ! grep -qx -- --requested "$f" && hlog stoppy | grep -qF "stop: the queued continuation ${f##*/} is automatic now (the stop came after the request)"'
rm -f "$HARNESS_STATE"/queue/*.args
check "second run got its own port"       '[[ $(cat "$HARNESS_STATE/proj/stoppy/port") != $(cat "$HARNESS_STATE/proj/demo/port") ]]'

REPLAY=
# ---- run 4: the same, but C depends on M1 (default): gated ----
STUB_CURL_FAIL=1 STUB_STRICT_VERIFIER=1 "$H" start "$T/proj" gated --spec SPEC.md --foreground > "$T/run4.out" 2>&1
check "a failed post is noted and the run goes on" 'hlog gated | grep -q "notification failed (curl exit 22): harness"'
check "a failed run-end post is committed: the worktree stays clean for gc" '[[ -d $T/wt/proj/gated && -z $(git -C "$T/wt/proj/gated" status --porcelain) ]]'
check "a given-up feature blocks what depends on it" 'grep -q "^blocked on A" "$HARNESS_STATE/proj/gated/ended" && ! grep -q "^C attempt" "$T/scratch/proj/gated/sessions.log"'

# ---- run 5: the real usage-limit message (2026-10-17) for 3 sessions, then a $0 no-work session ----
STUB_LIMIT_HITS=3 STUB_NOWORK=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 "$H" start "$T/proj" limited --spec SPEC.md --foreground > "$T/run5.out" 2>&1
check "real limit message: not counted, run completes" '[[ $(hlog limited | grep -c "hit a limit (You.ve hit your session limit") == 3 ]] && [[ $($F summary "$(list limited)") == "3/3 passing" ]]'
check "a \$0 one-turn session is not counted" 'hlog limited | grep -q "hit a limit (no work done"'
check "the limit window is shared"        '[[ -f $HARNESS_STATE/LIMIT_UNTIL ]]'
check "refused sessions recorded as env"  '(( $(jq -s "map(select(.env)) | length" "$T/wt/proj/limited/.harness/runs/limited/metrics.jsonl") == 4 ))'

# ---- run 9: endless limit pauses; then `harness continue` finishes it ----
STUB_LIMIT_HITS=99 timeout 60 "$H" start "$T/proj" walled --spec SPEC.md --foreground > "$T/run9.out" 2>&1
check "endless limit ends the run (frees the queue)" 'hlog walled | grep -q "sessions in a row refused" && grep -q "^usage limit (6 sessions refused" "$HARNESS_STATE/proj/walled/ended"'
rm -f "$HARNESS_STATE/LIMIT_UNTIL"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue walled --foreground > "$T/run9b.out" 2>&1
check "continue finishes a paused run"    '[[ $($F summary "$(list walled)") == "3/3 passing" ]] && on_main run/walled/M2'
check "one ledger row per run"            '[[ $(grep -c "\"run\":\"walled\"" "$T/ledger/runs.jsonl") == 1 ]]'

# ---- queue: start queues behind a running run; the runner runs entries in order ----
mkdir -p "$HARNESS_STATE/proj/busy" && echo $$ > "$HARNESS_STATE/proj/busy/driver.pid" && printf 'WT=/x\nRUN_ID=busy\nSTATE=%s\nPROJECT_DIR=/x\n' "$HARNESS_STATE/proj/busy" > "$HARNESS_STATE/proj/busy/meta.env"
check "start queues when MAX_PARALLEL_RUNS are going" 'grep -q "is queued" <<< "$("$H" start "$T/proj" --spec SPEC.md)"'
check "continue refuses a running run"     '! "$H" continue busy 2> "$T/busy.err" && grep -q "is running" "$T/busy.err"'
rm -rf "$HARNESS_STATE/proj/busy"
"$H" queue add "$T/proj" --spec SPEC.md > /dev/null
D=$(date +%F)
# the sessions a tmux start would have left for the runner's two runs (their ended comes later), and two it must spare
for s in "h-proj-$D" "h-proj-$D-2" h-queue "$HARNESS_DESK_SESSION"; do tmux new-session -d -s "$s" sleep 600; done
# a runner's gc (L4-04) collects what it can: the worktrees later checks read are kept dirty (untracked) until its debrief is done
keep_wts() { local w; for w in "$T"/wt/proj/*/; do : > "$w/.keep-for-later-checks"; done; }
unkeep_wts() { rm -f "$T"/wt/proj/*/.keep-for-later-checks; }
keep_wts
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$T/queue.out" 2>&1
has_s() { tmux has-session -t "=$1" 2> /dev/null; }
check "the queue runner reaps its ended runs' tmux sessions before the debrief; h-queue and the desk untouched" '! has_s "h-proj-$D" && ! has_s "h-proj-$D-2" \
  && has_s h-queue && has_s "$HARNESS_DESK_SESSION" && grep -qF "+ reaped tmux session h-proj-$D-2 (proj-$D-2 ended)" "$HARNESS_STATE/queue/runner.log" \
  && awk -v r="+ reaped tmux session h-proj-$D (proj-$D ended)" "index(\$0, r) && !a { a = NR } /harness debrief \\(detached/ && !b { b = NR } END { exit !(a && b && a < b) }" "$HARNESS_STATE/queue/runner.log"'
# the runner collects as it drains (L4-04): one gc per project it started a run in, its lines prefixed, before the debrief
check "the queue runner runs harness gc <project> --all-merged --deps once per project, before the debrief" 'RL=$HARNESS_STATE/queue/runner.log; [[ $(grep -c "gc proj: harness gc .* --all-merged --deps$" "$RL") == 1 ]] \
  && grep -qE "gc proj: harness gc ([^ ]*/)?proj --all-merged --deps$" "$RL" && grep -qE "gc proj: \+ (git -C .* (branch -d|push -q origin --delete|worktree remove --force)|freed)" "$RL" \
  && awk "/gc proj: harness gc / && !a { a = NR } /harness debrief \\(detached/ && !b { b = NR } END { exit !(a && b && a < b) }" "$RL" && ! grep -q "gc proj failed" "$RL"'
for s in "h-proj-$D" "h-proj-$D-2" h-queue "$HARNESS_DESK_SESSION"; do tmux kill-session -t "=$s" 2> /dev/null; done   # the desk checks start with no desk session and no sleep 600
check "queue ran both entries, distinct run ids (their merged worktrees gone with the runner's gc: the ledger has the records)" 'LR=$T/ledger/proj; [[ $($F summary "$LR/proj-$D/feature_list.json") == "3/3 passing" && $($F summary "$LR/proj-$D-2/feature_list.json") == "3/3 passing" ]] \
  && [[ ! -e $T/wt/proj/proj-$D && ! -e $T/wt/proj/proj-$D-2 ]] && grep -q "queue empty" "$HARNESS_STATE/queue/runner.log"'
check "trends lists every run"            'grep -q "| proj-$D-2 | proj |" <<< "$("$H" trends)"'
# one row per harness version (this checkout, +dirty while it has uncommitted changes); a row from before E1-07 groups as –
printf '%s\n' '{"run":"old","passing":1,"total":2,"cost":3}' '{"run":"v1","harness_version":"abc1234","harness_dirty":false,"passing":2,"total":2,"cost":4,"cache_hit_rate":0.5,"orient_tokens":100,"first_attempt_pass_rate":1}' \
  '{"run":"v1d","harness_version":"abc1234","harness_dirty":true,"passing":1,"total":3,"cost":2,"cache_hit_rate":0.9,"orient_tokens":null,"first_attempt_pass_rate":0}' > "$T/bv.jsonl"
check "trends --by version groups the runs" 'BV=$("$H" trends --by version) && grep -qE "^\| $HV(\+dirty)? \| [0-9]+ \| [0-9]+/[0-9]+ \| " <<< "$BV" && grep -q "^| Harness | Runs | Passing |" <<< "$BV" && ! grep -q "Harness" <<< "$("$H" trends)" \
  && P=$(node "$HERE/../lib/summary.mjs" trends "$T/bv.jsonl" --by version) && grep -qxF "| – | 1 | 1/2 | \$3.00 | – | – | – |" <<< "$P" \
  && grep -qxF "| abc1234 | 1 | 2/2 | \$2.00 | 0.50 | 100 | 1.00 |" <<< "$P" && grep -qxF "| abc1234+dirty | 1 | 1/3 | \$2.00 | 0.90 | – | 0.00 |" <<< "$P" && [[ $(wc -l <<< "$P") == 5 ]]'
DB=$T/debriefs.log Q=$HARNESS_STATE/queue NOTE=$T/ledger/debrief.md
ndb() { cat "$DB" 2>/dev/null | grep -c .; }
settle() {   # the runner's debrief is detached: wait until no debrief process is left
  local i; sleep 0.5
  for i in $(seq 150); do pgrep -f "$HH/lib/debrief\.sh|$HH/bin/harness debrief" > /dev/null || return 0; sleep 0.2; done; return 1
}
HH=$(cd "$HERE/.." && pwd); settle; unkeep_wts
check "queue end triggers one debrief, detached" '[[ $(ndb) == 1 && -s $NOTE && -s $Q/last-debrief ]] && grep -q "debrief written" "$Q/runner.log" && grep -q "harness debrief (detached" "$Q/runner.log"'
check "the debrief saw the queue's runs"  'grep -q "### proj-$D-2 (proj)" "$T/debrief-prompt" && grep -q "### proj-$D (proj)" "$T/debrief-prompt"'
PAGE=$T/ledger/debrief.html
check "a debrief page beside the note: a card per run, the note escaped" '[[ -s $PAGE ]] && grep -q "proj-$D-2" "$PAGE" && grep -q "3/3 passing" "$PAGE" && grep -q "Landed: proj M1, M2 on main" "$PAGE" && grep -q "&lt;i&gt;raw" "$PAGE" && ! grep -q "<i>raw" "$PAGE"'
"$H" debrief > "$T/again.out" 2>&1
check "by hand right after: nothing new, no session" '[[ $(ndb) == 1 ]] && grep -q "no runs started since the last debrief" "$T/again.out"'
"$H" queue add --continue stoppy --automatic > /dev/null   # Michael stopped stoppy: the runner skips an automatic continuation, so it starts nothing
HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$T/queue2.out" 2>&1; settle
check "a runner that started nothing (a skipped continuation): no debrief" '[[ $(ndb) == 1 ]] && grep -q "skipping queued continuation of stoppy" "$Q/runner.log" && ! grep -q "harness debrief (detached" "$T/queue2.out"'
# R6: a continuation queued through the CLI is a request, so it starts even after Michael's stop; the driver's and the
# debrief's are automatic and skipped after one. Both runs' PROJECT_DIR is no checkout: a start dies at once
for r in stopreq stopauto; do mkdir -p "$HARNESS_STATE/other/$r" && echo "stopped by Michael · $(date '+%F %T')" > "$HARNESS_STATE/other/$r/ended" \
  && printf 'WT=/x\nRUN_ID=%s\nSTATE=%s\nPROJECT_DIR=%s\n' "$r" "$HARNESS_STATE/other/$r" "$T/no-checkout" > "$HARNESS_STATE/other/$r/meta.env"; done
"$H" queue add --continue stopreq > /dev/null; "$H" queue add --continue stopauto --automatic > /dev/null
check "queue add --continue marks its entry --requested; --automatic (the driver's, the debrief's) doesn't" 'fr=$(compgen -G "$Q/*-continue-stopreq.args") && fa=$(compgen -G "$Q/*-continue-stopauto.args") \
  && grep -qx -- --queued "$fr" && grep -qx -- --requested "$fr" && grep -qx -- --queued "$fa" && ! grep -qx -- --requested "$fa" && ! grep -qx -- --automatic "$fa"'
check "queue list marks continuations (requested) or (automatic)" 'L=$("$H" queue list) && grep -q "^  [0-9]*\. continue stopreq .*(requested)$" <<< "$L" && grep -q "^  [0-9]*\. continue stopauto .*(automatic)$" <<< "$L"'
B=$(ndb); HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$T/queue2r.out" 2>&1; settle
check "a requested continuation of a run Michael stopped starts; an automatic one is skipped (both logged)" 'grep -q "starting: harness continue stopreq" "$Q/runner.log" && ! grep -q "skipping queued continuation of stopreq" "$Q/runner.log" \
  && grep -q "skipping queued continuation of stopauto: Michael stopped it" "$Q/runner.log" && grep -q "no-checkout is not a git repository" "$Q/runner.log" && [[ $(ndb) == "$B" ]]'
"$H" queue add --continue stopauto --automatic > /dev/null
check "a request for a run with an automatic continuation queued makes that one requested; parked entries are marked too" '[[ $("$H" queue add --continue stopauto) == "already queued: continue stopauto (now requested, with this request'"'"'s options)" ]] \
  && grep -qx -- --requested "$(compgen -G "$Q/*-continue-stopauto.args")" && "$H" queue park 1 > /dev/null && grep -q "^  1\. continue stopauto .*(requested)$" <<< "$("$H" queue list | sed -n "/^parked/,\$p")"'
"$H" queue add --continue stopreq --automatic --keep-attempts --until-epoch 1 > /dev/null
check "a request replaces a queued automatic continuation's options with its own (no stale --until-epoch)" '[[ $("$H" queue add --continue stopreq --brief "from Michael") == "already queued: continue stopreq (now requested, with this request'"'"'s options)" ]] \
  && [[ $(cat "$(compgen -G "$Q/*-continue-stopreq.args")") == "$(printf "%s\n" continue stopreq --queued --requested --brief "from Michael")" ]]'
rm -rf "$HARNESS_STATE/other" "$Q"/*.args "$Q"/held/*
# the driver's own continuation, after a session cap (run.env outlasts start: MAX_SESSIONS=1 is the initializer alone)
mkdir -p "$HARNESS_STATE/proj/capped" && echo MAX_SESSIONS=1 > "$HARNESS_STATE/proj/capped/run.env"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" capped --spec SPEC.md --foreground > "$T/capped-run.out" 2>&1
check "the driver's continuation after a session cap is automatic" 'grep -q "^session cap (1)" "$HARNESS_STATE/proj/capped/ended" && hlog capped | grep -q "continuation queued (1 of 3, automatic;" \
  && f=$(compgen -G "$Q/*-continue-capped.args") && grep -qx -- --queued "$f" && grep -qx -- --keep-attempts "$f" && ! grep -qx -- --requested "$f" && grep -q "continue capped .*(automatic)$" <<< "$("$H" queue list)"'
rm -rf "$HARNESS_STATE/proj/capped" "$Q"/*.args   # later debriefs cover runs by their state dir: this one is gone
# a gc that fails and hangs (a git whose fetch waits on a prompt, for this runner only: only gc runs that argv) is
# killed at HARNESS_GC_TIMEOUT and logged; the debrief starts anyway (L4-05 review)
mkdir -p "$T/gcfail"; printf '%s\n' '#!/usr/bin/env bash' '[[ $1 == -C && $3 == fetch && "${*:4}" == "-q --prune origin" ]] && { echo "fatal: stub fetch failure" >&2; sleep 60; exit 1; }' \
  "exec $(command -v git) \"\$@\"" > "$T/gcfail/git"; chmod +x "$T/gcfail/git"
"$H" queue add "$T/proj" --spec SPEC.md > /dev/null
B=$(ndb); SECONDS=0; STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 PATH=$T/gcfail:$PATH HARNESS_GC_TIMEOUT=2s HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$T/queue-gcfail.out" 2>&1; settle
GFS=$SECONDS
check "a failed or hung runner gc is logged (killed at HARNESS_GC_TIMEOUT) and never stops the debrief" '[[ $GFS -lt 55 ]] && grep -q "starting: harness start" "$T/queue-gcfail.out" && grep -qx "[0-9-]* [0-9:]* gc proj failed (exit 124)" "$T/queue-gcfail.out" \
  && grep -q "gc proj: fatal: stub fetch failure" "$T/queue-gcfail.out" && grep -q "harness debrief (detached" "$T/queue-gcfail.out" && [[ $(ndb) == $(( B + 1 )) ]]'
# one run per project at a time: proj has a live run, so its entry is held and the next entry (another project) goes first
cp "$T/user-config.sh" "$T/user-config.keep"; echo 'MAX_PARALLEL_RUNS=2' >> "$T/user-config.sh"
mkdir -p "$HARNESS_STATE/proj/busy3" "$HARNESS_STATE/other/stoppy-o" && echo 'stopped by Michael' > "$HARNESS_STATE/other/stoppy-o/ended" && : > "$HARNESS_STATE/other/stoppy-o/meta.env"
sleep 5 & echo $! > "$HARNESS_STATE/proj/busy3/driver.pid"   # outlives the --until below, which gives the runner 3 s to start stoppy-o
"$H" queue add "$T/proj" --spec SPEC.md > /dev/null; "$H" queue add --continue stoppy-o --automatic > /dev/null
HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" $(( $(date +%s) + 3 )) > "$T/queue2b.out" 2>&1
check "queue holds an entry whose project has a live run, starts the next one" '[[ $(grep -c "holding .*(proj)" "$T/queue2b.out") == 1 ]] && grep -q "starting: harness continue stoppy-o" "$T/queue2b.out" \
  && ! grep -q "starting: harness start $T/proj" "$T/queue2b.out" && grep -q "1 left queued" "$T/queue2b.out" && grep -qx start "$(ls "$Q"/*.args)"'
rm -rf "$HARNESS_STATE/proj/busy3" "$HARNESS_STATE/other" "$Q"/*.args; mv "$T/user-config.keep" "$T/user-config.sh"

# ---- parked entries: listed with their reason, skipped by the runner, back at the end when unparked ----
check "the runner syncs before a start with nothing alive (this ledger is no checkout: skipped, said so)" 'grep -q "sync: .* is not in a git checkout; skipped" "$Q/runner.log"'
"$H" queue add "$T/proj" --spec SPEC.md > /dev/null
check "queue park sets an entry aside with its reason" 'grep -q "^parked 0" <<< "$("$H" queue park 1 waiting on the measure PRs)" && ! compgen -G "$Q/*.args" > /dev/null \
  && L=$("$H" queue list) && grep -q "^parked (the runner skips" <<< "$L" && grep -q "why: waiting on the measure PRs" <<< "$L" && grep -q "  (empty)" <<< "$L"'
HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$T/queue2c.out" 2>&1
check "the runner skips a parked entry and says so" 'grep -q "1 parked entry skipped until unparked" "$T/queue2c.out" && ! grep -q "starting:" "$T/queue2c.out" && grep -q "queue empty" "$T/queue2c.out"'
check "queue unpark puts it back at the end, its reason gone" 'grep -q "^unparked .* as 0" <<< "$("$H" queue unpark 1)" && [[ $(ls "$Q"/*.args | wc -l) == 1 ]] && ! compgen -G "$Q/held/*" > /dev/null && grep -qx start "$(ls "$Q"/*.args)"'
rm -f "$Q"/*.args
# R11: numbers count the parked entries too, and a park never overwrites one of the same name
mkdir -p "$Q/held" && printf '%s\n' start "$T/proj" > "$Q/held/0004-start-proj.args" && echo "why · x" > "$Q/held/0004-start-proj.why"
check "queue add numbers past a parked entry" '[[ $("$H" queue add "$T/proj" --spec SPEC.md) == "queued: 0005-start-proj.args" ]]'
rm -f "$Q"/*.args "$Q"/held/*
echo held-marker > "$Q/held/0006-start-proj.args"; printf '%s\n' start "$T/proj" > "$Q/0006-start-proj.args"
check "queue park refuses to overwrite a parked entry; both survive" '! "$H" queue park 1 > /dev/null 2> "$T/park.err" && grep -q "^harness: 0006-start-proj.args already parked" "$T/park.err" \
  && [[ -f $Q/0006-start-proj.args && $(cat "$Q/held/0006-start-proj.args") == held-marker && ! -e $Q/held/0006-start-proj.why ]]'
rm -f "$Q"/*.args "$Q"/held/*

# ---- debrief: the runner's other exits ----
rm -f "$HARNESS_STATE/LIMIT_UNTIL"
"$H" queue add "$T/proj" --spec SPEC.md > /dev/null; "$H" queue add "$T/proj" --spec SPEC.md > /dev/null
keep_wts; B=$(ndb); STUB_QUEUE_STOP=1 STUB_PHONE_STOP=1 HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$T/queue3.out" 2>&1; settle
check "queue stop after a run: one debrief" '[[ $(ndb) == $((B + 1)) ]] && grep -q "stopped by harness queue stop" "$T/queue3.out" && [[ $(ls "$Q"/*.args | wc -l) == 1 ]]'
"$H" queue add "$T/proj" --spec SPEC.md > /dev/null
B=$(ndb); STUB_SLOW_INIT=3 STUB_PHONE_STOP=1 HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" $(( $(date +%s) + 2 )) > "$T/queue4.out" 2>&1; settle; unkeep_wts
check "past --until after a run: one debrief" '[[ $(ndb) == $((B + 1)) ]] && grep -q "past the --until time" "$T/queue4.out"'
rm -f "$Q"/*.args

# ---- debrief: since the last success; failed and killed debriefs; continuations; notification ----
printf '%s\n' 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' "NOTIFY_CMD='printf \"%s\\n===\\n\" \"\$1\" >> \"$T/notify.log\"'" \
  "DEBRIEF_PAGE_CMD='cp \"\$1\" \"$T/page-copy.html\"'" > "$T/user-config.sh"
ran() { local r; sleep 1; for r; do echo "$(date '+%F %T') run $r on harness/$r in $T/wt/proj/$r · port 7999" >> "$HARNESS_STATE/proj/$r/run.log"; done; }   # runs since
ran stoppy demo walled limited gated
for r in stoppy limited gated; do echo "deadline · $(date '+%F %T')" > "$HARNESS_STATE/proj/$r/ended"; done
echo "usage limit (6 sessions refused in a row) · $(date '+%F %T')" > "$HARNESS_STATE/proj/walled/ended"
LD=$(cat "$Q/last-debrief") B=$(ndb)
STUB_DEBRIEF_LIMIT=1 "$H" debrief > "$T/refused.out" 2>&1
check "a refused debrief: no note, nothing marked done, LIMIT_UNTIL set, one line to NOTIFY_CMD" '[[ $(cat "$Q/last-debrief") == "$LD" && -f $HARNESS_STATE/LIMIT_UNTIL ]] && ! grep -q "stoppy" "$NOTE" && grep -q "refused" "$T/refused.out" && grep -q "^\[debrief\] refused" "$T/notify.log"'
rm -f "$HARNESS_STATE/LIMIT_UNTIL"
STUB_DEBRIEF_DEAD=1 "$H" debrief > "$T/dead.out" 2>&1
check "a session that dies at startup: failed, and no usage-limit window for the box" '[[ ! -f $HARNESS_STATE/LIMIT_UNTIL && $(cat "$Q/last-debrief") == "$LD" ]] && grep -q "the session failed" "$T/dead.out" && grep -q "^\[debrief\] failed" "$T/notify.log"'
STUB_DEBRIEF_ERROR=1 "$H" debrief > "$T/error.out" 2>&1
check "a failed session: its error text is never the note" '[[ $(cat "$Q/last-debrief") == "$LD" ]] && ! grep -q "max turns" "$NOTE" && ! grep -qs "max turns" "$T/notify.log"'
echo $(( $(date +%s) + 3600 )) > "$HARNESS_STATE/LIMIT_UNTIL"
HARNESS_LIMIT_SLEEP=60 setsid "$H" debrief > "$T/killed.out" 2>&1 & P=$!
for i in $(seq 50); do grep -q "waiting" "$T/killed.out" && break; sleep 0.2; done; kill -- -"$P"; wait "$P" 2> /dev/null
rm -f "$HARNESS_STATE/LIMIT_UNTIL"
check "a killed debrief changes nothing" '[[ $(cat "$Q/last-debrief") == "$LD" && $(ndb) == $B ]] && grep -q "waiting" "$T/killed.out"'
touch "$Q/0099-continue-walled.args"; echo $$ > "$HARNESS_STATE/proj/gated/driver.pid"
"$H" debrief --dry-run > "$T/dry.out" 2>&1
check "--dry-run prints the context, launches nothing" '[[ $(ndb) == $B && -f $(head -1 "$T/dry.out") && $(cat "$Q/last-debrief") == "$LD" ]] && grep -q "^## harness status" "$T/dry.out" && grep -q "^### stoppy (proj)" "$T/dry.out" && grep -q "ended: deadline" "$T/dry.out"'
cp "$NOTE" "$T/note-before.md"; echo "{{LEDGER}} stays literal" >> "$T/wt/proj/stoppy/.harness/runs/stoppy/INBOX.md"
STUB_DEBRIEF_TOUCH=$T/wt/proj/gated/still-working.txt STUB_DEBRIEF_CONTINUE="stoppy demo walled limited gated" "$H" debrief > "$T/next.out" 2>&1
check "placeholders inside the context are not filled" 'grep -q "{{LEDGER}} stays literal" "$T/debrief-prompt"'
check "a still-running run changing its worktree is not flagged" '! grep -q "changed during the debrief session" "$NOTE"'
check "the allowlist runs nothing that writes or executes" 'A=$T/debrief-args; sed -n "/^--allowedTools$/,/^--disallowedTools$/p" "$A" > "$T/allow"; ! grep -qE "^Bash\((rg|git grep|git branch:|harness report|.*/bin/harness report)" "$T/allow" && grep -qxF "Bash(harness report:*)" "$A" && grep -qxF "Bash(git branch --list:*)" "$A" && grep -qxF "Bash(git diff --output:*)" "$A" && grep -qxF "Bash(git log --output:*)" "$A" && grep -qxF "Bash(git show --output:*)" "$A"'
check "the session may read each run's state dir and the queue" 'A=$T/debrief-args; grep -qxF "$HARNESS_STATE/proj/stoppy" "$A" && grep -qxF "$Q" "$A"'
check "the next debrief covers what the failed and killed ones missed" '[[ $(ndb) == $((B + 1)) && $(cat "$Q/last-debrief") != "$LD" ]] && ! for r in stoppy demo walled limited gated; do grep -q "^### $r (proj)" "$T/debrief-prompt" || echo missing; done | grep -q missing'
check "one note, overwritten: ledger/debrief.md" '! cmp -s "$NOTE" "$T/note-before.md" && [[ $(grep -c "^# Debrief" "$NOTE") == 1 && ! -e $T/ledger/debriefs ]] && grep -q "stub runs" "$NOTE"'
check "the session: an allowlist (dontAsk) and the never-list" 'A=$T/debrief-args; grep -qx dontAsk "$A" && ! grep -qx auto "$A" && grep -qx -- --allowedTools "$A" && grep -qx Read "$A" && grep -qxF "Bash(git log:*)" "$A" && grep -qx -- --disallowedTools "$A" && grep -qx Edit "$A" && grep -qx Write "$A" && grep -qxF "Bash(git push:*)" "$A" && grep -qxF "Bash(gh pr merge:*)" "$A" && grep -qxF "Bash(harness queue start:*)" "$A" && grep -qxF "Bash(harness merge:*)" "$A" && grep -qxF "Bash(harness continue:*)" "$A" && grep -qx "$($F model sonnet)" "$A"'
check "the prompt goes in on stdin, not as an argument" 'grep -q "^# Debrief" "$T/debrief-prompt" && ! grep -q "# Debrief" "$T/debrief-args"'
check "continuation queued: keeps attempts, brief marked as the debrief's" 'f=$(compgen -G "$Q/*-continue-stoppy.args") && grep -qx -- --keep-attempts "$f" && ! grep -qx -- --requested "$f" && grep -q "do C next" "$f" && grep -qi "suggested by the debrief" "$f" && grep -q "Queued: .*stoppy" "$NOTE" && ! grep -q "debrief: queued" "$NOTE"'
check "not queued: ended done / already queued / no work left / still running" 'grep -q "Not queued: demo (it ended .done." "$NOTE" && grep -q "Not queued: walled (a continuation is already queued)" "$NOTE" && grep -q "Not queued: limited (no work left)" "$NOTE" && grep -q "Not queued: gated (still running)" "$NOTE" && ! compgen -G "$Q/*-continue-demo.args" > /dev/null && ! compgen -G "$Q/*-continue-limited.args" > /dev/null && ! compgen -G "$Q/*-continue-gated.args" > /dev/null && ! grep -q "CONTINUE:" "$NOTE"'
msg_with() { awk -v k="$1" 'BEGIN { RS = "===\n" } index($0, k) { printf "%s", $0; exit }' "$T/notify.log"; }
check "NOTIFY_CMD gets 3 headline lines and the note path" 'M=$(msg_with Landed); (( $(wc -l <<< "$M") <= 4 )) && grep -q "Landed: proj M1" <<< "$M" && grep -qF "$NOTE" <<< "$M" && ! grep -q FOURTH <<< "$M"'
check "DEBRIEF_PAGE_CMD gets the page"     'cmp -s "$PAGE" "$T/page-copy.html"'
check "a run still going is covered again next time" 'S=$(cut -f2 "$Q/last-debrief"); "$H" debrief --dry-run | grep -q "^### gated (proj)" && [[ $S < $(date "+%F %T") ]]'
rm -f "$HARNESS_STATE/proj/gated/driver.pid" "$Q"/*.args "$T/wt/proj/gated/still-working.txt"
echo 'NTFY_URL=https://ntfy.example/t' >> "$T/user-config.sh"   # from here on the debrief posts to ntfy (NOTIFY_CMD not called)
N=$(grep -c . "$T/notify.log"); STUB_DEBRIEF_DEAD=1 "$H" debrief > "$T/dead2.out" 2>&1
check "debrief notifications go to NTFY_URL when set" 'Bd=$(curl_with "[debrief] failed"); grep -qx "Title: harness debrief" <<< "$Bd" && ! grep -q "^Click:" <<< "$Bd" \
  && [[ $(grep -c . "$T/notify.log") == "$N" ]]'

# ---- debrief: a big record, a session that writes, the limit window, no node, git history as the archive ----
ran stoppy; head -c 300000 /dev/zero | tr '\0' x | fold -w 100 > "$T/wt/proj/stoppy/.harness/runs/stoppy/report.md"
B=$(ndb); STUB_DEBRIEF_CONTINUE=demo STUB_DEBRIEF_TOUCH=$T/wt/proj/stoppy/debrief-tamper.txt "$H" debrief > "$T/tamper.out" 2>&1
C=$(ls -td "$HARNESS_STATE"/debrief/*/ | head -1)context.md
check "a 300 KB report: the context stays small, the session runs" '(( $(wc -c < "$C") < 200000 )) && [[ $(ndb) == $((B + 1)) ]]'
check "files changed during the session are flagged in the note" 'grep -q "changed during the debrief session" "$NOTE" && grep -q "debrief-tamper.txt" "$NOTE"'
check "a debrief headline over ntfy: no Click (the note is a path), default priority when nothing needs Michael (a Not queued line isn't)" 'Bh=$(curl_last "[debrief] Landed: proj M1"); grep -qx "Title: harness debrief" <<< "$Bh" \
  && grep -qxF "$NOTE" <<< "$Bh" && ! grep -q "^Click:\|^Priority:" <<< "$Bh" && grep -q "^- Not queued: demo" "$NOTE"'
rm -f "$T/wt/proj/stoppy/debrief-tamper.txt"
ran stoppy; echo $(( $(date +%s) + 3600 )) > "$HARNESS_STATE/LIMIT_UNTIL"
B=$(ndb); t0=$(date +%s); STUB_DEBRIEF_NEEDS=1 HARNESS_LIMIT_SLEEP=3 "$H" debrief > "$T/limit1.out" 2>&1 & P=$!
for i in $(seq 50); do grep -q "waiting" "$T/limit1.out" && break; sleep 0.2; done; ran demo; wait "$P"; t1=$(date +%s)   # demo starts meanwhile
check "debrief waits for the usage-limit window, then runs" 'grep -q "usage-limit window" "$T/limit1.out" && (( t1 - t0 >= 3 )) && [[ $(ndb) == $((B + 1)) ]] && (( $(stat -c %Y "$T/debrief-prompt") >= t0 + 3 ))'
check "a run that starts during the wait is covered by the next debrief" '! grep -q "^### demo (proj)" "$T/debrief-prompt" && "$H" debrief --dry-run | grep -q "^### demo (proj)"'
check "a debrief whose note needs Michael: priority high" 'Bn=$(curl_with "Blocked: parky B waits on Michael"); grep -qx "Title: harness debrief" <<< "$Bn" && grep -qx "Priority: high" <<< "$Bn"'
ran stoppy; echo $(( $(date +%s) + 6 * 3600 )) > "$HARNESS_STATE/LIMIT_UNTIL"
B=$(ndb); "$H" debrief > "$T/limit2.out" 2>&1
check "a window past the 5 h cap: no session (the next debrief covers it)" 'grep -q "5 h cap" "$T/limit2.out" && [[ $(ndb) == $B ]]'
rm -f "$HARNESS_STATE/LIMIT_UNTIL"
NP=$(tr : '\n' <<< "$PATH" | while read -r d; do [[ -x $d/node ]] || printf '%s:' "$d"; done)
B=$(ndb); PATH=${NP%:} NVM_DIR=$T/no-nvm HOME=$T/nohome "$H" debrief > "$T/nonode.out" 2>&1; rc=$?
check "preflight: no node anywhere, a clear failure and no session" '(( rc != 0 )) && grep -q "missing: node" "$T/nonode.out" && [[ $(ndb) == $B ]]'
( flock "$HARNESS_STATE/debrief.lock" sleep 2 ) & HOLD=$!; sleep 0.3
"$H" debrief > "$T/locked.out" 2>&1; wait "$HOLD"
check "by hand while another debrief runs: it says it is waiting" 'grep -q "waiting for the debrief already running" "$T/locked.out"'
ran stoppy; HARNESS_DEBRIEF_CONTEXT_MAX=8000 "$H" debrief --dry-run > "$T/capped.out" 2>&1
check "the whole context is capped too" 'C=$(head -1 "$T/capped.out"); (( $(wc -c < "$C") <= 8000 )) && grep -q "context cut" "$C"'
git -C "$T/ledger" init -q -b main && git -C "$T/ledger" add -A && git -C "$T/ledger" -c user.name=t -c user.email=t@t commit -qm ledger
printf '%s\n' 'KEEP_SCRATCH=1 LEDGER_COMMIT=1 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"
for i in 1 2; do ran stoppy; GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t "$H" debrief > "$T/commit$i.out" 2>&1; done
check "each debrief is a commit of ledger/debrief.md" '[[ $(git -C "$T/ledger" log --oneline -- debrief.md | grep -c "ledger: debrief") == 2 && -z $(git -C "$T/ledger" status --porcelain) ]]'
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
staged() { git -C "$T/ledger" diff --cached --name-only; }
git -C "$T/ledger" checkout -qb side; ran stoppy; "$H" debrief > "$T/side.out" 2>&1; git -C "$T/ledger" checkout -q main
check "a ledger checkout on another branch: the note is written, not committed" 'grep -q "not committed" "$T/side.out" && [[ $(git -C "$T/ledger" log --oneline side -- debrief.md | grep -c "ledger: debrief") == 2 && -z $(staged) ]] && grep -q "^# Debrief" "$NOTE"'
touch "$T/ledger/.git/index.lock"; ran stoppy; "$H" debrief > "$T/ilock.out" 2>&1; rm -f "$T/ledger/.git/index.lock"
check "a held index.lock: written, not committed, nothing left staged" 'grep -q "not committed" "$T/ilock.out" && [[ -z $(staged) ]]'
printf '#!/bin/sh\nexit 1\n' > "$T/ledger/.git/hooks/pre-commit"; chmod +x "$T/ledger/.git/hooks/pre-commit"
ran stoppy; "$H" debrief > "$T/hook.out" 2>&1; rm -f "$T/ledger/.git/hooks/pre-commit"
check "a refused commit: the note is unstaged again" 'grep -q "not committed" "$T/hook.out" && [[ -z $(staged) ]]'
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
echo 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"

# ---- run 17: the 7-day window past WEEKLY_STOP_AT: the run stops before its next session; the queue starts nothing ----
STUB_WEEKLY=0.9 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" weekly --spec SPEC.md --foreground > "$T/run17.out" 2>&1
check "the weekly budget ends a run after the session that crossed it" 'grep -q "^weekly budget (7-day window at 90%" "$HARNESS_STATE/proj/weekly/ended" && [[ $(grep -c attempt "$T/scratch/proj/weekly/sessions.log") == 1 ]]'
"$H" queue add "$T/proj" --spec SPEC.md > /dev/null
HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$T/queue5.out" 2>&1
check "the queue starts no run past the weekly budget" 'grep -q "7-day window at 90%" "$T/queue5.out" && [[ $(ls "$Q"/*.args | wc -l) == 1 ]]'
echo 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1 WEEKLY_STOP_AT=95' > "$T/user-config.sh"
check "WEEKLY_STOP_AT raises the bar"     '( source "$HERE/../lib/config.sh" && harness_config /nonexistent && [[ $WEEKLY_STOP_AT == 95 ]] && ! weekly_over "$HARNESS_STATE/USAGE_7D" > /dev/null )'
rm -f "$Q"/*.args "$HARNESS_STATE/USAGE_7D"; echo 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"

# ---- tmux (L3-04): harness gc reaps the sessions of its project's ended runs, run → session, never the other way ----
# sessions first, then the markers: a session created after its run ended stands for a resume's (fresh), spared
RS="h-gone1 h-gone2 h-livey h-pausy h-pausx h-fresh h-held-x h-queue h-odone"   # held.x (ended) shares h-held-x with held-x (live, other project); odone: another project's ended run
for s in $RS; do tmux new-session -d -s "$s" sleep 600; done
has_s "$HARNESS_DESK_SESSION" || tmux new-session -d -s "$HARNESS_DESK_SESSION" sleep 600
for r in gone1 gone2 livey pausy pausx fresh held.x; do mkdir -p "$HARNESS_STATE/proj/$r" && : > "$HARNESS_STATE/proj/$r/meta.env"; done
mkdir -p "$HARNESS_STATE/other/held-x" && : > "$HARNESS_STATE/other/held-x/meta.env" && echo $$ > "$HARNESS_STATE/other/held-x/driver.pid"
mkdir -p "$HARNESS_STATE/other/odone" && : > "$HARNESS_STATE/other/odone/meta.env" && echo done > "$HARNESS_STATE/other/odone/ended"
true & tp=$!; wait "$tp"; echo "$tp" > "$HARNESS_STATE/proj/gone2/driver.pid"; echo $$ > "$HARNESS_STATE/proj/livey/driver.pid"
echo done | tee "$HARNESS_STATE/proj/"{gone1,gone2,livey,pausx,held.x}/ended > /dev/null
touch "$HARNESS_STATE/proj/"{pausy,pausx}/PAUSE; echo done > "$HARNESS_STATE/proj/fresh/ended"; touch -d '1 hour ago' "$HARNESS_STATE/proj/fresh/ended"
all_s() { local s; for s in $RS "$HARNESS_DESK_SESSION"; do has_s "$s" || return 1; done; }
"$H" gc "$T/proj" --dry-run > "$T/gcr-dry.out" 2>&1; gcr_dry_all=$(all_s && echo yes)
"$H" gc "$T/proj" > "$T/gcr.out" 2>&1
check "harness gc --dry-run kills no tmux session" '[[ $gcr_dry_all == yes ]] && grep -qxF "would: tmux kill-session -t =h-gone1 (gone1 ended)" "$T/gcr-dry.out" \
  && grep -qxF "would: tmux kill-session -t =h-gone2 (gone2 ended)" "$T/gcr-dry.out" && [[ $(grep -c "tmux kill-session" "$T/gcr-dry.out") == 2 ]]'
check "harness gc reaps only the ended runs' tmux sessions (h-queue, the desk, a live driver, a paused run, a resume's session, a live run sharing the name survive)" '! has_s h-gone1 && ! has_s h-gone2 \
  && grep -qxF "+ reaped tmux session h-gone1 (gone1 ended)" "$T/gcr.out" && grep -qxF "+ reaped tmux session h-gone2 (gone2 ended)" "$T/gcr.out" && [[ $(grep -c "tmux session" "$T/gcr.out") == 2 ]] \
  && RS="h-livey h-pausy h-pausx h-fresh h-held-x h-queue h-odone" all_s \
  && ! "$H" start "$T/proj" queue --spec SPEC.md --foreground 2> "$T/gcr-q.err" && grep -q "run-id .queue. is taken by the queue runner" "$T/gcr-q.err"'
# L3-05 review: a start never kills another live run's session (a-b vs a.b, or one id in two projects); h-queue and attach are exact targets
"$H" start "$T/proj" held-x --foreground > "$T/coll.out" 2>&1; coll_rc=$?
mkdir -p "$T/tmuxlog" && printf '#!/usr/bin/env bash\necho "$*" >> %q\n' "$T/tmux-calls" > "$T/tmuxlog/tmux" && chmod +x "$T/tmuxlog/tmux"
PATH=$T/tmuxlog:$PATH HARNESS_NO_RUNNER= "$H" queue start > /dev/null 2>&1; PATH=$T/tmuxlog:$PATH "$H" attach proj-x > /dev/null 2>&1
check "harness start refuses a run id whose tmux session another live run holds; its session lives" '(( coll_rc )) && has_s h-held-x \
  && grep -qF "run id held-x shares tmux session h-held-x with $HARNESS_STATE/other/held-x, which has not ended" "$T/coll.out" && [[ ! -e $HARNESS_WORKTREES/proj/held-x ]]'
check "the queue runner and attach target their tmux sessions exactly (=h-queue, =h-<run>), never by prefix" 'grep -qxF "has-session -t =h-queue" "$T/tmux-calls" \
  && grep -qxF "kill-session -t =h-queue" "$T/tmux-calls" && grep -qxF "attach -t =h-proj-x" "$T/tmux-calls" && ! grep -qE -- "-t h-" "$T/tmux-calls"'
for s in $RS; do tmux kill-session -t "=$s" 2> /dev/null; done
rm -rf "$HARNESS_STATE/proj/"{gone1,gone2,livey,pausy,pausx,fresh,held.x} "$HARNESS_STATE/other/held-x" "$HARNESS_STATE/other/odone"   # livey and held-x name the suite's own pid: alive_count would count it

suite_end
