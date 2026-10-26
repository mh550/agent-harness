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
# ---- run 2b: a stop records why (R7): `harness stop --why` and `status: stop <why>`; the retro prompt carries it ----
check "a stop without a reason says just: stopped by Michael (the note and ended)" 'hlog stoppy | grep -q "· stopped by Michael$" && grep -q "^stopped by Michael · [0-9-]* [0-9:]*$" "$HARNESS_STATE/proj/stoppy/ended"'
STUB_CLI_STOP="the spec changed" "$H" start "$T/proj" whycli --spec SPEC.md --foreground > "$T/run2b.out" 2>&1
check "harness stop --why: the note and ended say stopped by Michael: <why>" 'hlog whycli | grep -q "· stopped by Michael: the spec changed$" \
  && grep -q "^stopped by Michael: the spec changed · " "$HARNESS_STATE/proj/whycli/ended" && grep -qx "the spec changed" "$HARNESS_STATE/proj/whycli/STOP"'
STUB_CLI_STOP=- "$H" start "$T/proj" whybare --spec SPEC.md --foreground > "$T/run2b-bare.out" 2>&1
check "harness stop without --why: an empty STOP, and stopped by Michael as before" '[[ -f $HARNESS_STATE/proj/whybare/STOP && ! -s $HARNESS_STATE/proj/whybare/STOP ]] \
  && hlog whybare | grep -q "· stopped by Michael$" && grep -q "^stopped by Michael · " "$HARNESS_STATE/proj/whybare/ended" \
  && ! "$H" stop whybare --why "" 2> /dev/null && ! "$H" stop whybare --because x 2> /dev/null && [[ ! -s $HARNESS_STATE/proj/whybare/STOP ]] \
  && ! "$H" pause whybare --why x 2> /dev/null && [[ ! -f $HARNESS_STATE/proj/whybare/PAUSE ]]'
STUB_PHONE_STOP="the spec changed" "$H" start "$T/proj" whyphone --spec SPEC.md --foreground > "$T/run2b-phone.out" 2>&1
check "status: stop <why> from the phone: the same note, ended and services note" 'hlog whyphone | grep -q "· stopped by Michael: the spec changed$" \
  && grep -q "^stopped by Michael: the spec changed · " "$HARNESS_STATE/proj/whyphone/ended" && hlog whyphone | grep -q "· services stopped (stopped by Michael: the spec changed)$"'
check "the retro prompt carries the end reason" 'grep -q "{{END_REASON}}" "$HERE/../prompts/retro.md" && grep -q "stopped by Michael: the spec changed" "$HARNESS_STATE/proj/whyphone/prompt-retro.md"'
STUB_PHONE_STOP=", blocked · 2026-11 usage limit" "$H" start "$T/proj" whyodd --spec SPEC.md --foreground > "$T/run2b-odd.out" 2>&1
check "a reason after any separator is kept whole, \" · 2026-\" in it included" 'S=$T/wt/proj/whyodd/.harness/runs/whyodd/summary.json \
  && [[ $(jq -r .end_reason "$S") == "stopped by Michael: blocked · 2026-11 usage limit" ]] && hlog whyodd | grep -q "· stopped by Michael: blocked · 2026-11 usage limit$"'
check "the debrief page never reads a stop reason's words as its tone" 'node --input-type=module -e "import { card } from \"$HERE/../lib/page.mjs\"; const c = r => card({ run: \"r\", project: \"p\", end_reason: r }, \"\");
  process.exit(c(\"stopped by Michael: blocked, failed\").includes(\"pill muted\") && c(\"blocked on A\").includes(\"pill warn\") ? 0 : 1)"'
check "a stop with a reason: an automatic continuation is still skipped; summary.json has the whole end_reason" '[[ $("$H" continue whycli --queued) == "skipping queued continuation of whycli: Michael stopped it" ]] \
  && [[ $(jq -r .end_reason "$T/wt/proj/whycli/.harness/runs/whycli/summary.json") == "stopped by Michael: the spec changed" ]] \
  && "$H" queue add --continue whycli > /dev/null && grep -qx -- --requested "$(compgen -G "$HARNESS_STATE/queue/*-continue-whycli.args")"'
rm -f "$HARNESS_STATE"/queue/*-continue-whycli.args
# F1-06 review: the order is when Michael spoke, the INBOX stop belongs to its segment, a reason's | is text
STUB_CLI_STOP=- STUB_CLI_REQUEST="from Michael, after the stop" "$H" start "$T/proj" whylate --spec SPEC.md --foreground > "$T/run2b-late.out" 2>&1
check "a request queued after the stop (before the driver acts on it) stays requested" 'f=$(compgen -G "$HARNESS_STATE/queue/*-continue-whylate.args") \
  && grep -qx -- --requested "$f" && grep -qx "from Michael, after the stop" "$f" && hlog whylate | grep -q "· stopped by Michael$" && ! hlog whylate | grep -q "is automatic now"'
rm -f "$HARNESS_STATE"/queue/*-continue-whylate.args
STUB_PHONE_STOP="A failed the re-check" "$H" start "$T/proj" whyback --spec SPEC.md --foreground > "$T/run2b-back.out" 2>&1
check "a stop reason's words are never read as a feature's cause (A failed the re-check)" 'S=$T/wt/proj/whyback/.harness/runs/whyback/summary.json \
  && [[ $(jq -r .end_reason "$S") == "stopped by Michael: A failed the re-check" ]] && [[ $(jq -c .rework "$S") == "[]" ]] && [[ $(jq -r "[.features_detail[] | select(.cause == \"failed verify\")] | length" "$S") == 0 ]]'
echo MAX_SESSIONS=1 > "$HARNESS_STATE/proj/whyback/run.env"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue whyback --foreground > "$T/run2b-back2.out" 2>&1
check "harness continue of a run stopped from the phone: INBOX.md's status: stop goes back to run, so it doesn't stop again" 'I=$T/wt/proj/whyback/.harness/runs/whyback/INBOX.md \
  && ! grep -q "^stopped by Michael" "$HARNESS_STATE/proj/whyback/ended" && [[ $(head -1 "$I") == "status: run" ]] \
  && hlog whyback | grep -qF "INBOX.md: \`status: stop A failed the re-check\` set back to \`status: run\` (that stop ended the last segment; harness continue started this one)" \
  && [[ $(git -C "$T/origin.git" show harness/whyback:.harness/runs/whyback/INBOX.md | head -1) == "status: run" ]]'
rm -f "$HARNESS_STATE"/queue/*-continue-whyback.args
check "a stop reason with | keeps its card on the debrief page and is one cell in report.md and trends" 'S=$T/wt/proj/whyback/.harness/runs/whyback/summary.json \
  && echo note > "$T/pipe-note.md" && node "$HERE/../lib/page.mjs" "$T/pipe-note.md" "$T/pipe.html" "$S|stopped by Michael: a|b" && grep -q "whyback" "$T/pipe.html" \
  && jq ".end_reason = \"stopped by Michael: a|b\"" "$S" > "$T/pipe.json" && node "$HERE/../lib/summary.mjs" report "$T/pipe.json" | grep -qF "| Ended | stopped by Michael: a\|b " \
  && jq -nc "{run: \"r\", project: \"p\", passing: 0, total: 1, merged: 0, cost: 0, per_passing: null, wall_h: 0, end_reason: \"stopped by Michael: a|b\", causes: {}}" > "$T/pipe.jsonl" \
  && node "$HERE/../lib/summary.mjs" trends "$T/pipe.jsonl" | grep -qF "| stopped by Michael: a\|b |"'

suite_end
