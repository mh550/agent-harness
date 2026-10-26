#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- scope.sh (L1-02): capped transient user scopes, through the stub systemd-run/systemctl; one real 64M scope ----
SC=$HERE/../lib/scope.sh
sd_with() { awk -v k="$1" 'BEGIN { RS = "===\n" } index($0, k) { printf "%s", $0; exit }' "$T/systemd.log" 2>/dev/null; }   # the first stub systemd call containing $1
gone() { local i; for i in $(seq 20); do [[ $(ps -o stat= -p "$1" 2> /dev/null) == [^Z]* ]] || return 0; sleep 0.1; done; return 1; }   # dead or a zombie, within 2 s
sd_count() { awk -v k="$1" 'BEGIN { RS = "===\n" } index($0, k) { n++ } END { print n + 0 }' "$T/systemd.log" 2>/dev/null; }   # how many calls contain $1
( unset SESSION_SWAP_MAX; source "$SC"; HARNESS_SCRATCH=$T/sc scope_run harness-x-s1 5G 6G bash -c 'exit 3' ); sc_rc=$?
SCARGV=$'systemd-run\n--user\n--scope\n--collect\n--quiet\n--unit=harness-x-s1\n--description=harness-x-s1\n-p\nMemoryHigh=5G\n-p\nMemoryMax=6G\n-p\nMemorySwapMax=1G\n-p\nOOMPolicy=continue\nbash\n-c'
check "scope.sh: scope_run wraps the command in systemd-run with the caps and returns its exit" \
  '[[ $sc_rc == 3 && $(sd_with --unit=harness-x-s1 | head -17) == "$SCARGV" && $(sd_with --unit=harness-x-s1 | tail -3) == $'"'"'bash\n-c\nexit 3'"'"' ]]'
sc_out=$( source "$SC"; export HARNESS_SCRATCH=$T/sc; scope_stop harness-x-s1; echo "stop=$? peak=$(scope_peak harness-x-s1) left=$(scope_left harness-x-s1)"
  scope_capped harness-x-s1 6G && echo capped
  scope_run harness-x-s2 "" 64M bash -c 'sleep 300 > /dev/null 2>&1 & echo $! >> "$STUB_DIR/scope/$STUB_SCOPE_UNIT.pids"'
  echo "left2=$(scope_left harness-x-s2) units=$("$HARNESS_SYSTEMCTL" --user list-units 'harness-x-*' --plain --no-legend | cut -d" " -f1)"
  scope_stop harness-x-s2; echo "stop2=$? units2=$("$HARNESS_SYSTEMCTL" --user list-units 'harness-x-*' --plain --no-legend | wc -l)" )
check "scope.sh: scope_stop stops <unit>.scope; scope_peak and scope_left read the fixture" \
  '[[ $sc_out == $'"'"'stop=0 peak=2 left=0\nleft2=1 units=harness-x-s2.scope\nstop2=0 units2=0'"'"' ]] && sd_with $'"'"'stop\nharness-x-s1.scope'"'"' | grep -qx -- --user && gone "$(cat "$T/scope/harness-x-s2.pids" 2> /dev/null || echo 0)"'
check "scope.sh: a run id becomes a unit name of [A-Za-z0-9_-]" \
  '( source "$SC"; [[ $(scope_unit "a.b/c d" s1) == harness-a-b-c-d-s1 && $(scope_unit demo "") == harness-demo && $(scope_bytes 6G) == 6442450944 && $(scope_bytes 64M) == 67108864 && $(scope_bytes 4096) == 4096 ]] )'
check "scope.sh: scope_owns matches a unit to a run by its rebuilt prefix and a role the harness starts" \
  '( source "$SC"; scope_owns demo harness-demo-svc.scope && scope_owns a.b harness-a-b-s12.scope && scope_owns demo harness-demo-check-4711.scope \
    && ! scope_owns demo harness-demo-x-y-svc.scope && ! scope_owns demo harness-demo-svc && ! scope_owns test harness-test-1-probe.scope && ! scope_owns demo harness-demo-s.scope )'
sc_bare=$( export STUB_NO_SYSTEMD=1 HARNESS_SCRATCH=$T/sc; source "$SC"; scope_available; echo "avail=$?"
  scope_run harness-x-bare "" 64M bash -c 'echo ran > "$0"; exit 4' "$T/sc-bare.out"; echo "rc=$?"; scope_stop harness-x-bare; echo "stop=$?"; scope_peak harness-x-bare; echo "peak=$?" )
check "scope.sh: mem_available_gb reads the real meminfo fixture" '( source "$SC"; [[ $(mem_available_gb) == 9 && $(mem_available_gb "$HERE/fixtures/meminfo.txt") == 9 ]] && ! mem_available_gb /dev/null )'
# the memory gate (L1-06): the real fixture with only its MemAvailable line rewritten to 2 GB; services_down frees it in one run
sed 's/^MemAvailable: .*/MemAvailable:    2097152 kB/' "$HERE/fixtures/meminfo.txt" > "$T/meminfo-2g.txt"
mg=$( source "$SC"; note() { echo "note: $*"; }; MEM_MIN_AVAILABLE_GB=5 MEM_WAIT_MAX=2s; export HARNESS_MEMINFO=$T/meminfo-2g.txt
  services_down() { echo "down: $*"; }; mem_gate; echo ===
  services_down() { echo "down: $*"; cp "$HERE/fixtures/meminfo.txt" "$T/meminfo-mg.txt"; }; cp "$T/meminfo-2g.txt" "$T/meminfo-mg.txt"; MEM_WAIT_MAX=30m HARNESS_MEMINFO=$T/meminfo-mg.txt mem_gate; echo ===
  HARNESS_MEMINFO=$HERE/fixtures/meminfo.txt mem_gate; echo end )
MGOUT='note: memory: 2 GB available, under MEM_MIN_AVAILABLE_GB=5; waiting up to 2s
down: memory wait
note: memory still at 2 GB after 2s; starting the session anyway (its cap protects the box)
===
note: memory: 2 GB available, under MEM_MIN_AVAILABLE_GB=5; waiting up to 30m
down: memory wait
note: memory: 9 GB available after 0 s; starting the session
===
end'
check "scope.sh: mem_gate notes, frees, waits, then starts anyway or once memory is back" '[[ $(diff "$HERE/fixtures/meminfo.txt" "$T/meminfo-2g.txt" | grep -c "^[<>]") == 2 && $mg == "$MGOUT" ]]'
# HARNESS_MEM_POLL=0 (as the suite sets HARNESS_QUEUE_POLL=0) must still end at MEM_WAIT_MAX; exit 0 at once, 1 after a wait
mg0() { timeout 5 bash -c 'source "$1"; note() { :; }; MEM_MIN_AVAILABLE_GB=5 MEM_WAIT_MAX=1s HARNESS_MEM_POLL=0 HARNESS_MEMINFO=$2 mem_gate' _ "$SC" "$1"; }
check "scope.sh: mem_gate ends with HARNESS_MEM_POLL=0, exit 1 after a wait and 0 when it passed at once" 'mg0 "$T/meminfo-2g.txt"; [[ $? == 1 ]] && mg0 "$HERE/fixtures/meminfo.txt"'
check "scope.sh: dur_s reads timeout(1) durations as seconds" '( source "$SC"; [[ $(dur_s 15m) == 900 && $(dur_s 2s) == 2 && $(dur_s 1h) == 3600 && $(dur_s 90) == 90 && $(dur_s 1d) == 86400 ]] && ! dur_s 1.5m && ! dur_s "" )'
check "scope.sh: without user systemd scope_run runs bare (STUB_NO_SYSTEMD=1)" \
  '[[ $sc_bare == $'"'"'avail=1\nrc=4\nstop=0\npeak=1'"'"' && $(cat "$T/sc-bare.out") == ran && $(sd_count --unit=harness-x-bare) == 0 ]]'
# the bus goes away after a good probe: systemd-run fails (its own line on stderr), the wrapper never ran, so the
# command runs bare, with a line of its own
sc_late=$( export STUB_NO_SYSTEMD=1 HARNESS_SCRATCH=$T/sc SCOPE_OK=1; source "$SC"; scope_run harness-x-late "" 64M bash -c 'exit 6' 2>&1; echo "rc=$?" )
check "scope.sh: systemd-run failing after a good probe runs the command bare, with a line" \
  '[[ $sc_late == $'"'"'Failed to connect to bus: No medium found\nscope_run: systemd-run failed (exit 1); running bare\nrc=6'"'"' && $(sd_count --unit=harness-x-late) == 1 ]]'
# a scratch dir it can't write: the wrapper runs nothing, so the command runs once, bare, never a second time in the scope
mkdir -p "$T/ro/scopes" && chmod 555 "$T/ro/scopes"
sc_ro=$( export HARNESS_SCRATCH=$T/ro; source "$SC"; scope_run harness-x-ro "" 64M bash -c 'echo ran >> "$0"' "$T/sc-ro.out" 2>&1; echo "rc=$?" ); chmod 755 "$T/ro/scopes"
check "scope.sh: a scratch dir it can't write runs the command once, bare" \
  '[[ $sc_ro == "scope_run: $T/ro/scopes is not writable; running bare"$'"'"'\nrc=0'"'"' && $(wc -l < "$T/sc-ro.out") == 1 ]]'
# a unit name still loaded: the real systemd-run refuses it (fixtures/systemd-run-unit-exists.txt, exit 1), so the
# command runs bare; stopped first, the same name starts again (L2-02: run_init stops the old svc scope before its init)
sc_dup=$( export HARNESS_SCRATCH=$T/sc; source "$SC"; scope_run harness-x-dup "" 64M bash -c 'sleep 300 > /dev/null 2>&1 & echo $! >> "$STUB_DIR/scope/$STUB_SCOPE_UNIT.pids"'
  scope_run harness-x-dup "" 64M bash -c 'echo "in=${STUB_SCOPE_UNIT:-none}"' 2>&1; echo "bare=$SCOPE_BARE"
  scope_stop harness-x-dup; scope_run harness-x-dup "" 64M bash -c 'echo "in=${STUB_SCOPE_UNIT:-none}"'; echo "bare=$SCOPE_BARE" )
check "scope.sh: a unit still loaded is refused as systemd refuses it; stopped first, it starts" \
  '[[ $sc_dup == $'"'"'Failed to start transient scope unit: Unit harness-x-dup.scope was already loaded or has a fragment file.\nscope_run: systemd-run failed (exit 1); running bare\nin=none\nbare=systemd-run failed (exit 1)\nin=harness-x-dup\nbare='"'"' ]]'
# The one real scope (spec Rules): harness-test-<suite pid>-oom, MemoryMax 64M, no MemoryHigh (it throttles instead of
# killing), no swap, under an outer timeout; stopped whatever happens, and no harness-test-<pid>-* unit is left.
if systemd-run --user --scope --quiet true > /dev/null 2>&1; then
  SU=harness-test-$$-oom
  sc_real=$( cd "$T" && HARNESS_SYSTEMD_RUN=systemd-run HARNESS_SYSTEMCTL=systemctl HARNESS_SCRATCH=$T/sc SESSION_SWAP_MAX=0 timeout 30s bash -c 'source "$1"
    scope_run "$2" "" 64M node -e "const a = []; for (let i = 0; i < 256; i++) a.push(Buffer.alloc(1 << 20, 1))"; echo "rc=$? peak=$(scope_peak "$2")"; scope_capped "$2" 64M && echo capped' _ "$SC" "$SU" 2> "$T/sc-real.err" )   # its stderr (bash's "Killed") kept for a failure
  systemctl --user stop "$SU.scope" 2> /dev/null
  check "scope.sh: a real 64M scope kills a 256 MB allocation with exit 137 and leaves no unit" \
    '[[ $sc_real == $'"'"'rc=137 peak=64\ncapped'"'"' && -z $(systemctl --user list-units "harness-test-$$-*" --plain --no-legend) ]]'
else check "scope.sh: a real 64M scope kills a 256 MB allocation with exit 137 and leaves no unit (skipped: no user systemd)" true; fi
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

# ---- capped sessions (L1-03): every claude session in harness-<run>-s<n> under timeout -k 30s, stopped after it returns ----
sd_units() { grep -x -- "--unit=harness-$1-s[0-9]*" "$T/systemd.log" | sed 's/^--unit=//' | sort; }   # the session scopes run <run> started
sd_stops() { grep -A1 -x stop "$T/systemd.log" | grep -x "harness-$1-s[0-9]*\.scope" | sed 's/\.scope$//' | sort; }   # and the ones it stopped
check "sessions run in harness-<run>-s<n> with the three caps and timeout -k 30s" 'C1=$(sd_with --unit=harness-demo-s1); ( for a in --user --scope -p MemoryHigh=5G MemoryMax=6G MemorySwapMax=1G \
  timeout -k 30s 100m "$HERE/stub-claude.sh" "# Initializer session"; do grep -qxF -- "$a" <<< "$C1" || exit 1; done ) && grep -A4 -x timeout <<< "$C1" | paste -sd" " | grep -qxF "timeout -k 30s 100m $HERE/stub-claude.sh"'
check "each session's scope is stopped after it returns" 'U=$(sd_units demo); [[ $(wc -l <<< "$U") -ge 9 && $U == "$(sd_stops demo)" ]] \
  && [[ $(grep -cE "^[0-9-]+ [0-9:]+   (init|coding|verify|retro) exit [0-9]+ · " "$HARNESS_STATE/proj/demo/run.log") == $(wc -l <<< "$U") ]]'
check "a run whose sessions leave nothing gets no leftover or cap note" '[[ -s $T/demo-hlog.md ]] && ! grep -q "process(es) running\|hit its memory cap\|no user systemd" "$T/demo-hlog.md"'
# L1-07: headless sessions load only the project's MCP servers; demo commits no .mcp.json, so no --mcp-config (run mp1 below has one)
check "every session passes --strict-mcp-config and, without a .mcp.json, no --mcp-config" 'awk "BEGIN { RS = \"===\\n\" } /--unit=harness-demo-s[0-9]+\\n/ { n++; if (/\\n--strict-mcp-config\\n/) s++; if (/\\n--mcp-config\\n/) m++ } END { exit !(n >= 9 && s == n && !m) }" "$T/systemd.log" \
  && grep -q "  MCP servers: none (--strict-mcp-config; no .mcp.json)" "$HARNESS_STATE/proj/demo/run.log"'
STUB_LEAVE_PROCESS=1 STUB_LEAVE_RETRO=1 STUB_OOM=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" leftover --spec SPEC.md --foreground > "$T/run-left.out" 2>&1
check "a session that leaves a process gets the left-1-process note (STUB_LEAVE_PROCESS=1)" '[[ $(hlog leftover | grep -c "coding session left 1 process(es) running; stopped with its scope") -ge 3 ]] \
  && ! hlog leftover | grep -q "\(init\|verify\) session left" && [[ -s $T/left.pids ]] \
  && hlog leftover | grep -q "retro session left 1 process(es) running; stopped with its scope$" && ! hlog leftover | grep -q "retro: reverted edits" && ( for p in $(cat "$T/left.pids"); do gone "$p" || exit 1; done )'
check "a session killed at its memory cap is noted and spends the attempt (STUB_OOM=A)" '[[ $(hlog leftover | grep -c "· A: the session hit its memory cap (6G)$") == 1 ]] \
  && [[ $(jq .A "$HARNESS_STATE/proj/leftover/attempts.json") == 2 ]] && grep -q "A attempt 2" "$T/scratch/proj/leftover/sessions.log" && [[ $($F summary "$(list leftover)") == "3/3 passing" ]] \
  && grep -q "  coding exit 137 · " "$HARNESS_STATE/proj/leftover/run.log"'
STUB_NO_SYSTEMD=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" bare --spec SPEC.md --foreground > "$T/run-bare.out" 2>&1
check "no user systemd: the run goes bare with one uncapped note (STUB_NO_SYSTEMD=1)" '[[ $(sd_count --unit=harness-bare) == 0 && $($F summary "$(list bare)") == "3/3 passing" ]] \
  && [[ $(hlog bare | grep -c "· no user systemd: sessions and suites run uncapped$") == 1 ]] && grep -q "  coding exit 0 · " "$HARNESS_STATE/proj/bare/run.log"'
# ---- the services scope (L2-02): run_init stops harness-<run>-svc, then runs the init in it under timeout -k 10s ----
sd_at() { awk -v k="$1" 'BEGIN { RS = "===\n" } index($0, k) { print NR; exit }' "$T/systemd.log" 2>/dev/null; }   # the index of the first stub call containing $1
check "run_init stops harness-<run>-svc, then runs the init in it at 3G under timeout -k 10s 10m" 'S=$(sd_at $'"'"'stop\nharness-demo-svc.scope\n'"'"'); R=$(sd_at $'"'"'--unit=harness-demo-svc\n'"'"')
  C=$(sd_with $'"'"'--unit=harness-demo-svc\n'"'"'); [[ -n $S && -n $R ]] && (( S < R )) && [[ $(head -1 <<< "$C") == systemd-run ]] && grep -qxF MemoryMax=3G <<< "$C" && ! grep -q MemoryHigh <<< "$C" \
  && grep -A6 -x timeout <<< "$C" | paste -sd" " | grep -q "^timeout -k 10s 10m bash -c echo init ok;"'
check "no user systemd: the init runs bare, and the run's one uncapped note stays the only one" 'grep -qx "(init exit 0)" "$T/scratch/proj/bare/init.out" && [[ $(sd_count harness-bare-svc) == 0 ]] \
  && ! hlog bare | grep -q "init ran uncapped" && [[ $(hlog bare | grep -c "uncapped") == 1 ]]'
check "metrics.jsonl: mem_peak_mb is null when uncapped" 'jq -se "length >= 5 and all(has(\"mem_peak_mb\") and .mem_peak_mb == null)" "$T/wt/proj/bare/.harness/runs/bare/metrics.jsonl" > /dev/null'
# ---- services_down (L2-03): the project's teardown, then the svc scope, then one note; on finish and in the EXIT trap ----
sd_last() { awk -v k="$1" 'BEGIN { RS = "===\n" } index($0, k) { n = NR } END { print n + 0 }' "$T/systemd.log" 2>/dev/null; }   # the index of the last stub call containing $1
check "finish runs the teardown hook, then stops harness-<run>-svc, and notes it once (the EXIT trap after it is silent)" '[[ -f $T/scratch/proj/demo/teardown-done.marker ]] \
  && D=$(sd_at $'"'"'teardown\ndemo\ndone\n'"'"') && [[ -n $D ]] && (( D < $(sd_last $'"'"'stop\nharness-demo-svc.scope\n'"'"') )) && [[ $(grep -c "· services stopped (done)$" "$T/demo-hlog.md") == 1 ]] \
  && [[ $(grep -c "services stopped" "$HARNESS_STATE/proj/demo/run.log") == 1 && $(sd_count $'"'"'teardown\ndemo\n'"'"') == 1 ]]'
# a TERM to the driver mid-session: bash runs the EXIT trap at once and the session would live on, so the trap stops
# the session's scope first (killing the slow stub claude), then the teardown and the svc scope
rm -f "$T/slow-coding"
STUB_SLOW_CODING=30 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" termed --spec SPEC.md --foreground > "$T/run-termed.out" 2>&1 & TP=$!
t_mid=0; for _ in $(seq 300); do [[ -e $T/slow-coding ]] && { t_mid=1; break; }; sleep 0.1; done
STUB_MEM_CURRENT=52428800 "$H" status termed > "$T/status-termed.out" 2>&1; TSR=$?   # the slow session's scope is live (L2-05)
kill -TERM "$(cat "$HARNESS_STATE/proj/termed/driver.pid")"; wait "$TP"
touch "$T/scope/harness-termed-s99".{alive,running}; TSL=$(sd_count list-units)   # a unit left behind: an ended run still lists none
"$H" status termed > "$T/status-termed2.out" 2>&1; TSR2=$?; TSL2=$(sd_count list-units); rm -f "$T/scope/harness-termed-s99".*
check "harness status lists a running run's units with MemoryCurrent; an ended run's none" '[[ $TSR == 0 && $TSR2 == 0 ]] && grep -q "^termed (proj) · running" "$T/status-termed.out" \
  && grep -Eqx "    harness-termed-s[0-9]+ · MemoryCurrent 50 MB" "$T/status-termed.out" && [[ $(grep -c "MemoryCurrent" "$T/status-termed.out") == 1 ]] \
  && grep -q "^termed (proj) · ended: driver exited" "$T/status-termed2.out" && ! grep -q MemoryCurrent "$T/status-termed2.out" && [[ $TSL2 == "$TSL" ]]'
termed_left() { local p; for p in $(pgrep -f "$HERE/stub-claude.sh"); do [[ $(readlink "/proc/$p/cwd") == "$T/wt/proj/termed"* ]] && echo "$p"; done; }
check "the EXIT trap commits its services note: harness-log.md is clean after a TERM" '[[ -z $(git -C "$T/wt/proj/termed" status --porcelain -- .harness/runs/termed/harness-log.md) ]] \
  && git -C "$T/wt/proj/termed" show HEAD:.harness/runs/termed/harness-log.md | grep -q "· services stopped (driver exited)$"'
check "a TERM to the driver mid-session stops the session's scope, runs the teardown, stops the svc scope and notes it" 'U=$(grep -x -- "--unit=harness-termed-s[0-9]*" "$T/systemd.log" | tail -1 | sed "s/^--unit=//")
  D=$(sd_at $'"'"'teardown\ntermed\ndriver exited\n'"'"'); SS=$(sd_last "stop"$'"'"'\n'"'"'"$U.scope"$'"'"'\n'"'"'); [[ $t_mid == 1 && -n $U && -n $D && -f $T/scratch/proj/termed/teardown-driver-exited.marker ]] \
  && (( SS > 0 && SS < D && D < $(sd_last $'"'"'stop\nharness-termed-svc.scope\n'"'"') )) && sleep 1 && [[ -z $(termed_left) ]] \
  && grep -q " services stopped (driver exited)$" "$HARNESS_STATE/proj/termed/run.log" && grep -q "^driver exited unexpectedly" "$HARNESS_STATE/proj/termed/ended" && [[ ! -e $HARNESS_STATE/proj/termed/driver.pid ]]'
# a TERM during an init (L2-06): the trap stops the init (the svc scope) before the teardown, or the init goes on
# starting what the teardown just stopped; a TERM during finish's own teardown waits for it, never runs a second
sd_before() { awk -v k="$1" -v n="$2" 'BEGIN { RS = "===\n" } NR < n && index($0, k) { c++ } END { print c + 0 }' "$T/systemd.log"; }   # calls containing $1 before index $2
STUB_SLOW_INITCMD=31 STUB_PHONE_STOP=1 "$H" start "$T/proj" initterm --spec SPEC.md --foreground > "$T/run-initterm.out" 2>&1 & TP=$!
for _ in $(seq 300); do [[ -e $T/scratch/proj/initterm/init-begin ]] && break; sleep 0.1; done
kill -TERM "$(cat "$HARNESS_STATE/proj/initterm/driver.pid")"; wait "$TP"
check "a TERM during an init stops the init's scope before the teardown runs" 'D=$(sd_at $'"'"'teardown\ninitterm\ndriver exited\n'"'"') \
  && [[ -e $T/scratch/proj/initterm/init-begin && -n $D ]] && [[ $(sd_before $'"'"'stop\nharness-initterm-svc.scope\n'"'"' "$D") == 2 ]] \
  && ! pgrep -fx "sleep 31" > /dev/null && [[ $(grep -c "services stopped" "$HARNESS_STATE/proj/initterm/run.log") == 1 ]]'
STUB_SLOW_TEARDOWN=3 STUB_PHONE_STOP=1 "$H" start "$T/proj" tdterm --spec SPEC.md --foreground > "$T/run-tdterm.out" 2>&1 & TP=$!
for _ in $(seq 300); do [[ -e $T/scratch/proj/tdterm/teardown-begin ]] && break; sleep 0.1; done
kill -TERM "$(cat "$HARNESS_STATE/proj/tdterm/driver.pid")"; wait "$TP"
check "a TERM during finish's teardown runs no second teardown: the trap waits for it, then stops the svc scope, one note" 'D=$(sd_at $'"'"'teardown\ntdterm\n'"'"') \
  && [[ -e $T/scratch/proj/tdterm/teardown-begin && -n $D && $(sd_count $'"'"'teardown\ntdterm\n'"'"') == 1 ]] && (( D < $(sd_last $'"'"'stop\nharness-tdterm-svc.scope\n'"'"') )) \
  && [[ $(grep -c "services stopped" "$HARNESS_STATE/proj/tdterm/run.log") == 1 ]]'
# PAUSE mid-run (L2-04): A's first session touches PAUSE as `harness pause` would; the pause stops the services before
# its poll, and the init after `harness resume` starts them again
STUB_PAUSE=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" paused --spec SPEC.md --foreground > "$T/run-paused.out" 2>&1 & PP=$!
p_seen=0; for _ in $(seq 600); do hlog paused | grep -q "· services stopped (paused)$" && { p_seen=1; break; }; sleep 0.1; done
"$H" resume paused > /dev/null; wait "$PP"
check "PAUSE stops the services before its poll, and the next init starts them again" 'D=$(sd_at $'"'"'teardown\npaused\npaused\n'"'"') \
  && [[ $p_seen == 1 && -n $D && -f $T/scratch/proj/paused/teardown-paused.marker && $(hlog paused | grep -c "· services stopped (paused)$") == 1 ]] \
  && (( $(sd_last $'"'"'--unit=harness-paused-svc\n'"'"') > D )) && grep -q "^paused (INBOX.md" <(cut -d" " -f3- "$HARNESS_STATE/proj/paused/run.log") && [[ $($F summary "$(list paused)") == "3/3 passing" ]]'
# systemd refusing the scope after the probe passed (a MemoryMax it can't parse): each session runs bare, and says so
{ cat "$T/base-config.sh"; echo SESSION_MEMORY_MAX=bogus; } > "$T/user-config.sh"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" refused --spec SPEC.md --foreground > "$T/run-refused.out" 2>&1
cp "$T/base-config.sh" "$T/user-config.sh"
check "a scope systemd refuses after the probe: the session runs bare and harness-log.md says so" 'S=$(grep -cE "^[0-9-]+ [0-9:]+   (init|coding|verify|retro) exit " "$HARNESS_STATE/proj/refused/run.log") \
  && (( S >= 5 )) && [[ $(hlog refused | grep -cE "· (init|coding|verify|retro) session ran uncapped: systemd-run failed \(exit 1\)$") == "$S" && $($F summary "$(list refused)") == "3/3 passing" ]] \
  && grep -q "^Failed to parse MemoryMax=bogus: Invalid argument$" "$HARNESS_STATE/proj/refused/logs/00-init.jsonl"'
# the memory gate on a whole run: 2 GB available, MEM_WAIT_MAX=2s, polls every second; every non-retro session waits first
{ cat "$T/base-config.sh"; echo MEM_WAIT_MAX=2s; } > "$T/user-config.sh"
HARNESS_MEMINFO=$T/meminfo-2g.txt STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" lowmem --spec SPEC.md --foreground > "$T/run-lowmem.out" 2>&1
cp "$T/base-config.sh" "$T/user-config.sh"
check "memory gate: under 5 GB the driver waits, then starts the session anyway (HARNESS_MEMINFO, HARNESS_MEM_POLL)" 'S=$(grep -cE "^[0-9-]+ [0-9:]+   (init|coding|verify) exit " "$HARNESS_STATE/proj/lowmem/run.log") \
  && (( S >= 5 )) && [[ $(hlog lowmem | grep -c "· memory: 2 GB available, under MEM_MIN_AVAILABLE_GB=5; waiting up to 2s$") == "$S" \
  && $(hlog lowmem | grep -c "· memory still at 2 GB after 2s; starting the session anyway (its cap protects the box)$") == "$S" && $($F summary "$(list lowmem)") == "3/3 passing" ]]'
check "memory gate: the wait stops the services (services stopped (memory wait))" 'hlog lowmem | grep -q "· services stopped (memory wait)$"'
# the memory wait stops the services (L2-03 made services_down real): every session before finish's teardown starts
# with harness-<run>-svc up, verify's included (its gate came after its run_init: now `mem_gate || run_init`)
svc_gaps() { awk -v r="$1" 'BEGIN { RS = "===\n" } index($0, "teardown\n" r "\ndone\n") { exit } index($0, "stop\nharness-" r "-svc.scope\n") { up = 0 }
  index($0, "--unit=harness-" r "-svc\n") { up = 1 } $0 ~ "--unit=harness-" r "-s[0-9]+\n" { n++; if (!up) bad++ } END { print n + 0, bad + 0 }' "$T/systemd.log"; }
check "memory gate: every session starts with the services up, a verify after its wait included" 'read -r n bad <<< "$(svc_gaps lowmem)"; (( n >= 5 && bad == 0 ))'
# the gate comes before the feature is picked, not inside session(): a status: stop set during the wait is seen before
# any coding session, no attempt is spent, and the prompt's clock comes after the wait (the L1 review's Important finding)
cp "$HERE/fixtures/meminfo.txt" "$T/meminfo-gate.txt"; { cat "$T/base-config.sh"; echo MEM_WAIT_MAX=60s; } > "$T/user-config.sh"
HARNESS_MEMINFO=$T/meminfo-gate.txt STUB_MEM_DROP=$T/meminfo-gate.txt STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 \
  "$H" start "$T/proj" gatestop --spec SPEC.md --foreground > "$T/run-gatestop.out" 2>&1 & GP=$!
for _ in $(seq 300); do hlog gatestop | grep -q "waiting up to 60s$" && break; sleep 0.1; done
touch "$HARNESS_STATE/proj/gatestop/STOP"; cp "$HERE/fixtures/meminfo.txt" "$T/meminfo-gate.txt"; wait "$GP"
cp "$T/base-config.sh" "$T/user-config.sh"
check "memory gate: a stop set while the driver waits for memory starts no coding session and spends no attempt" '[[ $(hlog gatestop | grep -c "· memory: 2 GB available, under MEM_MIN_AVAILABLE_GB=5; waiting up to 60s$") == 1 ]] \
  && hlog gatestop | grep -q "· memory: 9 GB available after [0-9]* s; starting the session$" && hlog gatestop | grep -q "· stopped by Michael$" \
  && ! grep -q "coding exit" "$HARNESS_STATE/proj/gatestop/run.log" && [[ $(jq "[.[]] | add // 0" "$HARNESS_STATE/proj/gatestop/attempts.json" 2> /dev/null || echo 0) == 0 ]]'
check "memory gate: the real fixture's 9 GB passes without a note" '[[ -s $T/demo-hlog.md ]] && ! grep -q "· memory" "$T/demo-hlog.md"'
# A's cap kill peaks at the cap (6G): report.md beside it, and harness report's rebuild in the state dir, list it
check "report.md lists the session that peaked at its cap among the peaks over 2 GB" 'L=$T/wt/proj/leftover/.harness/runs/leftover; M=$(jq -r "select(.feature==\"A\" and .exit==137) | .model" "$L/metrics.jsonl") \
  && [[ -n $M ]] && grep -qxFe "- A · $M · 6144 MB" "$L/report.md" && [[ $(grep -c " MB$" <<< "$(sed -n "/^### Memory peaks over 2 GB/,\$p" "$L/report.md")") == 1 ]] \
  && HR=$("$H" report leftover) && grep -qxFe "- A · $M · 6144 MB" <<< "$HR"'

# ---- capped suites (L1-05): check.sh runs full and subset in harness-<run>-check-<pid> at 3G under timeout -k 30s ----
check "check.sh runs the suite in harness-<run>-check-<pid> at 3G under timeout -k 30s" 'C=$(sd_with --unit=harness-demo-check-); U=$(grep -x -- "--unit=harness-demo-check-[0-9]*" <<< "$C" | sed "s/^--unit=//") \
  && [[ -n $U ]] && grep -qxF MemoryMax=3G <<< "$C" && ! grep -q MemoryHigh <<< "$C" && grep -A6 -x timeout <<< "$C" | paste -sd" " | grep -qxF "timeout -k 30s 15m bash -c test ! -f BROKEN" \
  && [[ $(sd_count $'"'"'stop\n'"'"'"$U.scope") == 1 ]]'
ck() { ( cd "$T/proj" && HARNESS_SCRATCH=$T/ck HARNESS_CHECK_CACHE=$T/ck-cache HARNESS_SCOPE_PREFIX=${CKP:-harness-ck} HARNESS_CHECK_CMD=$1 "$HERE/../lib/check.sh" "${@:2}" ); }   # check.sh called directly, as a session would
ck_137=$(ck 'echo started; touch "$STUB_DIR/scope/$STUB_SCOPE_UNIT.oom"; exit 137'; echo "rc=$?")   # .oom: the stub's MemoryPeak is the cap
check "check.sh: exit 137 prints the memory-cap RED line" 'grep -qx "check: RED (killed at its 3G memory cap, exit 137 after [0-9]* s) — last lines of $T/ck/check.out:" <<< "$ck_137" \
  && grep -qx started <<< "$ck_137" && [[ $(tail -1 <<< "$ck_137") == rc=137 && $(sd_count --unit=harness-ck-check-) == 1 ]] && ! ls "$T"/ck/scopes/harness-ck-check-* 2> /dev/null'
ck_124=$(ck 'exit 124') ck_3=$(ck 'exit 3') ck_hung=$(HARNESS_CHECK_TIMEOUT=1s ck 'trap "" TERM; sleep 2; kill -9 $$') ck_bare=$(STUB_NO_SYSTEMD=1 ck 'exit 137') ck_own=$(ck 'exit 137')
check "check.sh: exit 124 prints the timed-out RED line" 'grep -qx "check: RED (timed out after 15m, exit 124 after [0-9]* s) — last lines of $T/ck/check.out:" <<< "$ck_124" \
  && grep -qx "check: RED (timed out after 1s, exit 137 after [0-9]* s) — last lines of $T/ck/check.out:" <<< "$ck_hung" \
  && grep -qx "check: RED (exit 3 after [0-9]* s) — last lines of $T/ck/check.out:" <<< "$ck_3" && grep -qx "check: RED (exit 137 after [0-9]* s) — last lines of $T/ck/check.out:" <<< "$ck_bare" \
  && grep -qx "check: RED (exit 137 after [0-9]* s) — last lines of $T/ck/check.out:" <<< "$ck_own"'   # a 137 short of the cap is the suite's own
ck_sub=$(CKP=harness-cks ck 'echo sub' -k foo; CKP=harness-cks ck 'echo sub' -k foo; echo "rc=$?"; CKP=harness-cks ck 'touch "$STUB_DIR/scope/$STUB_SCOPE_UNIT.oom"; sh -c "exit 137"' -k foo; echo "rc=$?")
check "check.sh: a subset call is scoped too and never cached" '[[ $(sed 3q <<< "$ck_sub") == $'"'"'sub -k foo\nsub -k foo\nrc=0'"'"' && $(sd_count --unit=harness-cks-check-) == 3 ]] \
  && [[ $(sed 1,3d <<< "$ck_sub" | sed "s/after [0-9]* s/after <n> s/") == $'"'"'check: RED (killed at its 3G memory cap, exit 137 after <n> s)\nrc=137'"'"' ]] \
  && sd_with --unit=harness-cks-check- | grep -A9 -x timeout | paste -sd" " | grep -qxF "timeout -k 30s 15m bash -c echo sub \"\$@\" _ -k foo" && ! ls "$T"/ck-cache/green-* 2> /dev/null'
# the calling session's scope is stopped (systemctl sends TERM) while its check.sh runs: the suite's scope goes with it
( cd "$T/proj" && HARNESS_SCRATCH=$T/ck HARNESS_CHECK_CACHE=$T/ck-cache HARNESS_SCOPE_PREFIX=harness-ckt HARNESS_CHECK_CMD='echo $$ >> "$STUB_DIR/scope/$STUB_SCOPE_UNIT.pids"; exec sleep 60' exec "$HERE/../lib/check.sh" > "$T/ckt.out" 2>&1 ) & ckt=$!
for i in $(seq 50); do [[ -s $T/scope/harness-ckt-check-$ckt.pids ]] && break; sleep 0.1; done; ckt_sleep=$(cat "$T/scope/harness-ckt-check-$ckt.pids" 2> /dev/null)
SECONDS=0; kill -TERM "$ckt"; wait "$ckt"; ckt_rc=$? ckt_s=$SECONDS
check "check.sh: a TERM stops the suite's scope with it" '[[ $ckt_rc == 143 && $ckt_s -le 3 && -n $ckt_sleep ]] && gone "$ckt_sleep" && [[ $(sd_count $'"'"'stop\nharness-ckt-check-'"'"'"$ckt.scope") == 1 ]]'

# ---- gc: main has every milestone; only run-record commits are left on the branch ----
"$H" gc "$T/proj" > "$T/gc.out" 2>&1
check "gc removed the finished worktree"  '[[ ! -d $WT ]]'
check "gc deleted the run branch"         '! git -C "$T/origin.git" rev-parse -q --verify harness/demo >/dev/null'
check "gc kept the tags"                  'git -C "$T/origin.git" tag | grep -qx run/demo/M2'
# gc's unit step (L2-05): units a SIGKILLed driver left. demo ended; killed's driver.pid is dead and it wrote no ended;
# gclive and demo-x have a live driver (demo's prefix also claims demo-x's unit, as lane x's: the live owner keeps it); oth is another project's
# c.d (proj, ended) and c-d (other, live) share harness-c-d-: the live one keeps the unit. 999999999 is over any pid_max
sleep 60 & GL1=$!; sleep 60 & GL2=$!; sleep 60 & GL3=$!; GLD=999999999
for r in gclive:$GL1 demo-x:$GL2 killed:$GLD other/oth: c.d: other/c-d:$GL3; do d=$HARNESS_STATE/${r%%:*}; [[ $d == */other/* ]] || d=$HARNESS_STATE/proj/${r%%:*}
  mkdir -p "$d"; cp "$HARNESS_STATE/proj/demo/meta.env" "$d/"; [[ -n ${r#*:} ]] && echo "${r#*:}" > "$d/driver.pid"; done
echo done > "$HARNESS_STATE/other/oth/ended"; echo done > "$HARNESS_STATE/proj/c.d/ended"
GCU="harness-demo-svc harness-demo-s99 harness-killed-svc harness-gclive-svc harness-demo-x-svc harness-oth-svc harness-nosuch-svc harness-c-d-svc"
for u in $GCU; do touch "$T/scope/$u".{alive,running}; done
gc_stops() { awk 'BEGIN { RS = "===\n" } /^systemctl\n--user\nstop\n/ { sub(/^systemctl\n--user\nstop\n/, ""); printf "%s", $0 }' "$T/systemd.log" 2>/dev/null | sort; }
GS0=$(gc_stops); "$H" gc "$T/proj" --dry-run > "$T/gcu1.out" 2>&1; GS1=$(gc_stops)
"$H" gc "$T/proj" > "$T/gcu2.out" 2>&1; GS2=$(comm -13 <(echo "$GS1") <(gc_stops) | paste -sd" ")
GCL=$("$HARNESS_SYSTEMCTL" --user list-units 'harness-*' --plain --no-legend | cut -d" " -f1 | sort | paste -sd" ")
check "harness gc stops the units of this project's runs with no live driver; --dry-run stops none" '[[ $GS1 == "$GS0" ]] \
  && grep -qx "would: systemctl --user stop harness-demo-svc.scope (demo ended)" "$T/gcu1.out" && grep -qx "would: systemctl --user stop harness-demo-s99.scope (demo ended)" "$T/gcu1.out" \
  && grep -qx "would: systemctl --user stop harness-killed-svc.scope (killed: driver gone)" "$T/gcu1.out" && [[ $(grep -c "^would: systemctl" "$T/gcu1.out") == 3 ]] \
  && grep -qx "? harness-nosuch-svc.scope (no run of this project)" "$T/gcu1.out" && grep -qx "? harness-oth-svc.scope (no run of this project)" "$T/gcu1.out" \
  && grep -qx "+ stopped harness-demo-svc.scope (demo ended)" "$T/gcu2.out" && grep -qx "+ stopped harness-demo-s99.scope (demo ended)" "$T/gcu2.out" \
  && grep -qx "+ stopped harness-killed-svc.scope (killed: driver gone)" "$T/gcu2.out" && [[ $(grep -c "^+ stopped" "$T/gcu2.out") == 3 ]] \
  && [[ $GS2 == "harness-demo-s99.scope harness-demo-svc.scope harness-killed-svc.scope" ]] \
  && ! grep -q harness-c-d-svc "$T/gcu1.out" "$T/gcu2.out" && ( for u in harness-demo-x-svc harness-gclive-svc harness-nosuch-svc harness-oth-svc harness-c-d-svc; do [[ " $GCL " == *" $u.scope "* ]] || exit 1; done )'
kill "$GL1" "$GL2" "$GL3" 2> /dev/null; wait "$GL1" "$GL2" "$GL3" 2> /dev/null
rm -rf "$HARNESS_STATE"/proj/{gclive,demo-x,killed,c.d} "$HARNESS_STATE/other"; for u in $GCU; do rm -f "$T/scope/$u".*; done   # a live fake driver.pid counts against MAX_PARALLEL_RUNS
# gc's branch passes (L4-01): a `*` doesn't cross a `/` in for-each-ref, so --all-merged must list by prefix and run
# every pass. Five merged branches (at origin/main) and an unmerged spec/u, each pushed to the origin with -u, as runs
# push. harness/noup has no upstream and this checkout's main is behind origin/main, so its `branch -d` is refused:
# gc says so and goes on (it used to end under set -e, before harness-merge/w).
git -C "$T/proj" fetch -q origin; GB=$(git -C "$T/proj" rev-parse origin/main)
gb_make() { local b; for b; do git -C "$T/proj" branch -f "$b" "$GB"; done; git -C "$T/proj" push -q -u origin "$@" 2> /dev/null; }
gb_has() { git -C "$1" rev-parse -q --verify "refs/heads/$2" > /dev/null; }   # gb_has <repo> <branch>
gb_both() { gb_has "$T/proj" "$1" && gb_has "$T/origin.git" "$1"; }; gb_none() { ! gb_has "$T/proj" "$1" && ! gb_has "$T/origin.git" "$1"; }
gb_make spec/x docs/y harness/z harness-merge/w flat
git -C "$T/proj" branch -f spec/u "$(git -C "$T/proj" commit-tree "$GB^{tree}" -p "$GB" -m unmerged)" && git -C "$T/proj" push -q -u origin spec/u 2> /dev/null
git -C "$T/proj" branch -f harness/noup "$GB" && git -C "$T/proj" push -q origin harness/noup
"$H" gc "$T/proj" > "$T/gcb1.out" 2>&1; GBR=$?
check "plain gc deletes only the merged harness/ and harness-merge/ branches, locally and on the origin" '[[ $GBR == 0 ]] && gb_none harness/z && gb_none harness-merge/w \
  && gb_both spec/x && gb_both docs/y && gb_both flat && gb_both spec/u && grep -qx "+ git -C $T/proj push -q origin --delete harness/z" "$T/gcb1.out"'
check "a refused branch -d (merged into origin/main, not into HEAD, no upstream) is logged and gc goes on" '! git -C "$T/proj" merge-base --is-ancestor origin/main main \
  && gb_has "$T/proj" harness/noup && ! gb_has "$T/origin.git" harness/noup && grep -qx "! failed: git -C $T/proj branch -d harness/noup" "$T/gcb1.out"'
git -C "$T/proj" branch -qD harness/noup
gb_make harness/z harness-merge/w
"$H" gc "$T/proj" --all-merged --dry-run > "$T/gcb2.out" 2>&1; GBD=$(for b in spec/x docs/y harness/z harness-merge/w flat; do gb_both "$b" || echo "$b"; done)
"$H" gc "$T/proj" --all-merged > "$T/gcb3.out" 2>&1
check "gc --all-merged deletes every merged branch whatever its name, locally and on the origin; an unmerged one survives" '[[ -z $GBD ]] \
  && [[ $(grep -c "^would: git -C $T/proj branch -d " "$T/gcb2.out") == 5 && $(grep -c "^would: git -C $T/proj push -q origin --delete " "$T/gcb2.out") == 5 ]] \
  && gb_none spec/x && gb_none docs/y && gb_none harness/z && gb_none harness-merge/w && gb_none flat && gb_both spec/u && gb_both main \
  && grep -qx "+ git -C $T/proj branch -d docs/y" "$T/gcb3.out" && grep -qx "+ git -C $T/proj push -q origin --delete spec/x" "$T/gcb3.out"'
git -C "$T/proj" branch -qD spec/u; git -C "$T/proj" push -q origin --delete spec/u
# gc's worktree removal finishes (L4-02, R9): merged, clean worktrees in path order (git worktree list sorts by path).
# gcw-a holds gitignored build output; gcw-c-ro/wt can't go (its parent is read-only) and gcw-d after it still must
gw_add() { local w; for w; do gb_make "harness/${w##*/}"; git -C "$T/proj" worktree add -q "$HARNESS_WORKTREES/proj/$w" "harness/${w##*/}"; done; }
gw_listed() { git -C "$T/proj" worktree list --porcelain | grep -qx "worktree $HARNESS_WORKTREES/proj/$1"; }
echo .next/ >> "$T/proj/.git/info/exclude"; mkdir -p "$HARNESS_WORKTREES/proj/gcw-c-ro"
gw_add gcw-a gcw-b gcw-c-ro/wt gcw-d; mkdir "$HARNESS_WORKTREES/proj/gcw-a/.next"; echo built > "$HARNESS_WORKTREES/proj/gcw-a/.next/f"
"$H" gc "$T/proj" --dry-run > "$T/gcw1.out" 2>&1
GWD=$(for w in gcw-a gcw-b gcw-c-ro/wt gcw-d; do gw_listed "$w" && [[ -d $HARNESS_WORKTREES/proj/$w ]] || echo "$w"; done)
chmod a-w "$HARNESS_WORKTREES/proj/gcw-c-ro"; "$H" gc "$T/proj" > "$T/gcw2.out" 2>&1; GWR=$?; chmod u+w "$HARNESS_WORKTREES/proj/gcw-c-ro"
check "gc removes merged, clean worktrees holding ignored build output (--force, then rm -rf)" '! gw_listed gcw-a && ! gw_listed gcw-b \
  && [[ ! -e $HARNESS_WORKTREES/proj/gcw-a && ! -e $HARNESS_WORKTREES/proj/gcw-b ]] \
  && grep -qx "+ git -C $T/proj worktree remove --force $HARNESS_WORKTREES/proj/gcw-a" "$T/gcw2.out" \
  && grep -qx "+ git -C $T/proj worktree remove --force $HARNESS_WORKTREES/proj/gcw-b" "$T/gcw2.out"'
check "a worktree gc can't remove is logged and the next one still goes; --dry-run removes none" '[[ -z $GWD && $GWR == 0 ]] \
  && [[ $(grep -c "^would: git -C $T/proj worktree remove --force $HARNESS_WORKTREES/proj/gcw-" "$T/gcw1.out") == 4 ]] \
  && grep -qx "! could not remove $HARNESS_WORKTREES/proj/gcw-c-ro/wt: .*Permission denied" "$T/gcw2.out" \
  && ! gw_listed gcw-d && [[ ! -e $HARNESS_WORKTREES/proj/gcw-d ]] && grep -qx "+ git -C $T/proj worktree remove --force $HARNESS_WORKTREES/proj/gcw-d" "$T/gcw2.out"'
rm -rf "$HARNESS_WORKTREES/proj/gcw-c-ro"; git -C "$T/proj" worktree prune
for w in gcw-a gcw-b wt gcw-d; do git -C "$T/proj" branch -qD "harness/$w" 2> /dev/null; git -C "$T/proj" push -q origin --delete "harness/$w" 2> /dev/null; done
# what gc must never remove, from the L4 review (L4-05), in one unattended --all-merged run: a worktree that is no run's
# (Michael's own session's: its branch isn't harness/<run>); a locked one (git refuses: no rm -rf after); one holding
# an untracked file that status.showUntrackedFiles=no hides; a locked one whose directory is gone (gc goes on past it);
# the origin's default branch (trunk here); a live run's merged branch
GWM=$HARNESS_WORKTREES/proj/mine; git -C "$T/proj" worktree add -q -b mine "$GWM" "$GB"
gw_add gcw-lk gcw-u gcw-gone; git -C "$T/proj" worktree lock "$HARNESS_WORKTREES/proj/gcw-lk"; echo note > "$HARNESS_WORKTREES/proj/gcw-u/notes.txt"
git -C "$T/proj" worktree lock "$HARNESS_WORKTREES/proj/gcw-gone"; rm -rf "$HARNESS_WORKTREES/proj/gcw-gone"
gb_make trunk harness/gcw-live harness/gcw-tail; git -C "$T/origin.git" symbolic-ref HEAD refs/heads/trunk; git -C "$T/proj" remote set-head origin trunk > /dev/null
mkdir -p "$HARNESS_STATE/proj/gcw-live"; echo $$ > "$HARNESS_STATE/proj/gcw-live/driver.pid"
git -C "$T/proj" config status.showUntrackedFiles no
"$H" gc "$T/proj" --all-merged > "$T/gcw3.out" 2>&1; GW3=$?
git -C "$T/proj" config --unset status.showUntrackedFiles
check "gc never removes a worktree that is no run's (its branch isn't harness/<run>), even merged and clean" '[[ -d $GWM ]] && gw_listed mine && gb_has "$T/proj" mine \
  && grep -qx "keeps $GWM: not a run worktree (branch mine)" "$T/gcw3.out"'
check "gc never rm -rfs a worktree git refused to remove (locked): it is said and stays" '[[ -f $HARNESS_WORKTREES/proj/gcw-lk/.git ]] && gw_listed gcw-lk \
  && grep -qx "! could not remove $HARNESS_WORKTREES/proj/gcw-lk: .*locked.*" "$T/gcw3.out" && ! grep -qx "+ rm -rf $HARNESS_WORKTREES/proj/gcw-lk" "$T/gcw3.out"'
check "gc keeps a worktree with an untracked file even when status.showUntrackedFiles=no hides it" '[[ $(cat "$HARNESS_WORKTREES/proj/gcw-u/notes.txt" 2> /dev/null) == note ]] && gw_listed gcw-u'
check "a listed worktree whose directory is gone never ends gc: every later step still runs" '[[ $GW3 == 0 ]] && gb_none harness/gcw-tail'
check "gc --all-merged keeps the origin default branch and a live run branch, merged or not" 'gb_both trunk && gb_both harness/gcw-live'
git -C "$T/origin.git" symbolic-ref HEAD refs/heads/main; git -C "$T/proj" remote set-head origin main > /dev/null; rm -rf "$HARNESS_STATE/proj/gcw-live"
for w in gcw-lk gcw-gone; do git -C "$T/proj" worktree unlock "$HARNESS_WORKTREES/proj/$w"; done
git -C "$T/proj" worktree remove --force "$GWM"; git -C "$T/proj" worktree remove --force --force "$HARNESS_WORKTREES/proj/gcw-lk" 2> /dev/null
git -C "$T/proj" worktree remove --force "$HARNESS_WORKTREES/proj/gcw-u" 2> /dev/null; git -C "$T/proj" worktree prune
for b in mine trunk harness/gcw-lk harness/gcw-u harness/gcw-gone harness/gcw-live harness/gcw-tail; do
  git -C "$T/proj" branch -qD "$b" 2> /dev/null; git -C "$T/proj" push -q origin --delete "$b" 2> /dev/null; done
# gc --deps (L4-03, B8): the dependency directories in the worktrees of ended runs go, merged or not (the branch keeps
# the work); a live run's (driver.pid = this shell), one with a queued continuation and the project checkout keep theirs
gd_run() { local r=$1 wt=${2:-$HARNESS_WORKTREES/proj/$1} d=$HARNESS_STATE/proj/$1; mkdir -p "$d"; touch "$d/ended"
  printf 'PROJECT_DIR=%q\nWT=%q\nRUN_ID=%q\nSTATE=%q\n' "$T/proj" "$wt" "$r" "$d" > "$d/meta.env"
  [[ $wt == "$T/proj" ]] || git -C "$T/proj" worktree add -q -b "harness/$r" "$wt" "$GB"; mkdir -p "$wt/node_modules"; echo x > "$wt/node_modules/x.js"; }
gd_run deps-end; gd_run deps-live; gd_run deps-q; gd_run deps-co "$T/proj"
GDE=$HARNESS_WORKTREES/proj/deps-end; mkdir "$GDE/.venv"; echo y > "$GDE/.venv/y"
echo kept > "$GDE/work.txt"; git -C "$GDE" add work.txt; git -C "$GDE" commit -qm "unmerged work"; GDH=$(git -C "$GDE" rev-parse HEAD)
echo $$ > "$HARNESS_STATE/proj/deps-live/driver.pid"; mkdir -p "$HARNESS_STATE/queue"; : > "$HARNESS_STATE/queue/x-continue-deps-q.args"
"$H" gc "$T/proj" --dry-run --deps > "$T/gcd1.out" 2>&1
GDD=$(for w in deps-end deps-live deps-q; do [[ -f $HARNESS_WORKTREES/proj/$w/node_modules/x.js ]] || echo "$w"; done; [[ -f $GDE/.venv/y ]] || echo venv)
"$H" gc "$T/proj" --deps > "$T/gcd2.out" 2>&1; GDR=$?
check "gc --deps empties an ended, unmerged run's worktree of its DEPS_DIRS; its branch and committed files stay; --dry-run deletes none" '[[ -z $GDD && $GDR == 0 ]] \
  && grep -qx "would: freed [0-9]* MB in $GDE: node_modules .venv" "$T/gcd1.out" && [[ $(grep -c "freed" "$T/gcd1.out") == 1 ]] \
  && [[ ! -e $GDE/node_modules && ! -e $GDE/.venv ]] && grep -qx "+ freed [0-9]* MB in $GDE: node_modules .venv" "$T/gcd2.out" \
  && [[ $(git -C "$T/proj" rev-parse harness/deps-end) == "$GDH" && $(cat "$GDE/work.txt") == kept && -z $(git -C "$GDE" status --porcelain) ]]'
check "gc --deps keeps the worktree of a live run and the project checkout" '[[ -f $HARNESS_WORKTREES/proj/deps-live/node_modules/x.js && -f $T/proj/node_modules/x.js ]] \
  && [[ $(grep -c "freed" "$T/gcd2.out") == 1 ]]'
check "gc --deps keeps the worktree of a run with a queued continuation" '[[ -f $HARNESS_WORKTREES/proj/deps-q/node_modules/x.js ]] && ! grep -q "freed .* in $HARNESS_WORKTREES/proj/deps-q:" "$T/gcd1.out" "$T/gcd2.out"'
# a deps dir gc can't read or delete (root-owned in real life: a mode-000 subdirectory here) is said and gc goes on; a
# symlinked .next pointing out of the tree is never followed (L4-05 review)
gd_run deps-ro; GDO=$HARNESS_WORKTREES/proj/deps-ro; mkdir -p "$GDO/node_modules/sub" "$T/outside"; echo k > "$GDO/node_modules/sub/f"; echo keep > "$T/outside/f"
ln -s "$T/outside" "$GDO/.next"; chmod 000 "$GDO/node_modules/sub"
"$H" gc "$T/proj" --deps > "$T/gcd3.out" 2>&1; GD3=$?; chmod 755 "$GDO/node_modules/sub"
check "a deps dir gc can't measure or delete is said and gc goes on; a symlinked deps dir is never followed" '[[ $GD3 == 0 ]] && grep -qx "! could not free $GDO: .*" "$T/gcd3.out" \
  && [[ $(cat "$T/outside/f") == keep && -L $GDO/.next ]]'
rm -f "$GDO/.next"; rm -rf "$T/outside"
rm -f "$HARNESS_STATE/queue/x-continue-deps-q.args"; rm -rf "$T/proj/node_modules"
for w in deps-end deps-live deps-q deps-ro; do git -C "$T/proj" worktree remove --force "$HARNESS_WORKTREES/proj/$w"; git -C "$T/proj" branch -qD "harness/$w"; done
rm -rf "$HARNESS_STATE"/proj/deps-{end,live,q,co,ro}   # a live fake driver.pid counts against MAX_PARALLEL_RUNS

# ---- run 15e: deploy guards at the run start (E0b): once per run, read from origin/main; projects of their own ----
dproj() {   # <name> [<file> <content>]: a project with its own bare origin behind a GitHub-style URL, <file> on its main
  git init -q --bare -b main "$T/$1-origin.git" && git init -q -b main "$T/$1" && mkdir "$T/$1/.harness" \
    && printf 'CHECK_CMD="true"\nINIT_CMD="true"\n' > "$T/$1/.harness/config.sh" && printf '# %s\n' "$1" > "$T/$1/CLAUDE.md" && echo spec > "$T/$1/SPEC.md" \
    && { [[ -z ${2:-} ]] || printf '%s\n' "$3" > "$T/$1/$2"; } && git -C "$T/$1" add -A && git -C "$T/$1" commit -qm init \
    && git -C "$T/$1" config url."$T/$1-origin.git".insteadOf "git@github.com:test/$1.git" && git -C "$T/$1" remote add origin "git@github.com:test/$1.git" && git -C "$T/$1" push -q -u origin main
}
cp "$T/user-config.sh" "$T/user-config.bak"; cp "$T/base-config.sh" "$T/user-config.sh"   # NTFY_URL: the checks read curl.log
# a teardown hook added mid-run (L2-06): services_down looks for .harness/teardown.sh when it runs, not at load_config
dproj lt && STUB_ADD_TEARDOWN=1 STUB_PHONE_STOP=1 "$H" start "$T/lt" lt1 --spec SPEC.md --foreground > "$T/run-lt1.out" 2>&1
check "a .harness/teardown.sh added after the run started is run at its stop points" '[[ -f $T/scratch/lt/lt1/teardown-late.marker ]] && hlog lt1 lt | grep -q "· services stopped (stopped by Michael)$"'
dstart() { STUB_INIT_LIMIT=1 "$H" "${@:2}" --foreground > "$T/$1.out" 2>&1; rm -f "$HARNESS_STATE/LIMIT_UNTIL"; }   # <out> <harness args>: a run that ends at once (the initializer is refused)
dproj vp vercel.json '{"framework":"nextjs"}' && dstart vp1 start "$T/vp" vp1 --spec SPEC.md && dstart vp1b continue vp1
check "run start without the deploy guard: one note, one notification" '[[ $(hlog vp1 vp | grep -c "initializer refused") == 2 && $(hlog vp1 vp | grep -c "preview deploy per session") == 1 ]] \
  && hlog vp1 vp | grep -q "deploy guard: vercel.json on origin/main has no git.deploymentEnabled" && [[ $(curl_count "[vp1] no deploy guard (vercel): this run will create a preview deploy per session") == 1 ]]'
dproj mp .mcp.json '{"mcpServers":{}}' && dstart mp1 start "$T/mp" mp1 --spec SPEC.md   # L1-07: a committed .mcp.json is what run worktrees load
check "a worktree with .mcp.json: sessions get --strict-mcp-config --mcp-config <wt>/.mcp.json" 'C=$(sd_with --unit=harness-mp1-s1); grep -qx -- --strict-mcp-config <<< "$C" \
  && [[ $(grep -A1 -x -- --mcp-config <<< "$C" | tail -1) == "$T/wt/mp/mp1/.mcp.json" ]] && grep -q "  MCP servers: .mcp.json (--strict-mcp-config --mcp-config)" "$HARNESS_STATE/mp/mp1/run.log"'
dproj np netlify.toml $'[build]\n  command = "make"' && dstart np1 start "$T/np" np1 --spec SPEC.md
check "run start without the netlify guard: one note, one notification" '[[ $(hlog np1 np | grep -c "preview deploy per session") == 1 ]] && hlog np1 np | grep -q "deploy guard: netlify.toml on origin/main has no \[build\] ignore" \
  && [[ $(curl_count "[np1] no deploy guard (netlify): this run will create a preview deploy per session") == 1 ]]'
dproj dp && STUB_DEPLOYMENTS=vercel dstart dp1 start "$T/dp" dp1 --spec SPEC.md
check "run start: Vercel deployments on the repo count (STUB_DEPLOYMENTS=vercel)" 'grep -q "gh api repos/test/dp/deployments?per_page=20" "$T/gh.log" && hlog dp1 dp | grep -q "deploy guard: vercel.json on origin/main" \
  && [[ $(curl_count "[dp1] no deploy guard (vercel)") == 1 ]]'
dproj gp vercel.json '{"git":{"deploymentEnabled":{"harness/**":false}}}' && dstart gp1 start "$T/gp" gp1 --spec SPEC.md
check "run start with the guard: nothing" 'grep -q "gh api repos/test/proj/deployments?per_page=20" "$T/gh.log" && [[ -s $T/demo-hlog.md && -n $(hlog gp1 gp) ]] && ! grep -q "preview deploy" "$T/demo-hlog.md" && ! hlog gp1 gp | grep -q "preview deploy" \
  && [[ $(curl_count "[demo] no deploy guard") == 0 && $(curl_count "[gp1] no deploy guard") == 0 ]]'
# the init output a session sees: the last 40 lines and the full log's path (E3-02)
dproj ip .harness/config.sh $'CHECK_CMD="true"\nINIT_CMD="seq 1 100"' && dstart ip1 start "$T/ip" ip1 --spec SPEC.md --brief 'keep {{RUN_ID}} as written'
IB=$(awk '/^## Init output$/ { s = 1; next } s && /^```$/ { if (f) exit; f = 1; next } f' "$HARNESS_STATE/ip/ip1/prompt-initializer.md" 2> /dev/null)
check "init output is capped at 40 lines with the log path" '[[ -n $IB ]] && (( $(wc -l <<< "$IB") == 41 )) && [[ $(tail -1 <<< "$IB") == "full output: $T/scratch/ip/ip1/init.out" ]] \
  && cmp -s <(head -n 40 <<< "$IB") <(tail -n 40 "$T/scratch/ip/ip1/init.out") && grep -qx 100 <<< "$IB" && ! grep -qx 1 <<< "$IB"'
check "a brief is pasted as written: its {{X}} isn't filled (E3 review F7)" 'grep -qx "keep {{RUN_ID}} as written" "$HARNESS_STATE/ip/ip1/prompt-initializer.md"'
# an init that backgrounds a server (L2-02): the foreground returns at once, the server stays in harness-<run>-svc,
# and the next run_init's stop of that scope is what ends it (a server the init lost would run on)
BPCFG=$(cat <<'EOF'
CHECK_CMD="true"
INIT_CMD='date +%s > "$STUB_DIR/svcbg.t0"; sleep 300 > /dev/null 2>&1 & echo $! >> "$STUB_DIR/scope/$STUB_SCOPE_UNIT.pids"; echo $! >> "$STUB_DIR/svcbg.pids"; exit 0'
EOF
)
rm -f "$T/svcbg.pids"; dproj bp .harness/config.sh "$BPCFG" && dstart bp1 start "$T/bp" bp1 --spec SPEC.md
bp_dt=$(( $(stat -c %Y "$T/scratch/bp/bp1/init.out" 2> /dev/null || echo 999) - $(cat "$T/svcbg.t0" 2> /dev/null || echo 0) )); dstart bp1b continue bp1
check "an init that backgrounds a server returns at once; stopping the scope that kept it (finish, the next init) kills it" 'grep -qx "(init exit 0)" "$T/scratch/bp/bp1/init.out" && (( bp_dt <= 2 )) \
  && [[ $(wc -l < "$T/svcbg.pids") == 2 ]] && gone "$(head -1 "$T/svcbg.pids")" && (( $(sd_count $'"'"'stop\nharness-bp1-svc.scope'"'"') >= 2 )) && [[ $(sd_count --unit=harness-bp1-svc) == 2 ]]'
for p in $(cat "$T/svcbg.pids" 2> /dev/null); do kill "$p" 2> /dev/null; done
mv "$T/user-config.bak" "$T/user-config.sh"

# ---- scratch (L3-02): finish keeps the record's outputs in the state dir and deletes the run's scratch, never the project's ----
{ cat "$T/base-config.sh"; echo KEEP_SCRATCH=0; } > "$T/scrub-config.sh"
mkdir -p "$T/scratch/proj" "$HARNESS_STATE/proj/scrub" && echo lock > "$T/scratch/proj/live.lock"   # a live project's flock file beside the runs' scratch
echo "CHECK_CMD='echo \"# pass 7\"'" > "$HARNESS_STATE/proj/scrub/run.env"   # a suite with a test count (run.env outlasts start and continue)
HARNESS_CONFIG=$T/scrub-config.sh "$H" start "$T/proj" scrub --spec SPEC.md --until-epoch $(( $(date +%s) - 1 )) --foreground > "$T/scrub.out" 2>&1   # init, initializer, deadline
scrub_end1=$(cat "$HARNESS_STATE/proj/scrub/tests-end" 2> /dev/null)
HARNESS_CONFIG=$T/scrub-config.sh "$H" continue scrub --until-epoch $(( $(date +%s) - 1 )) --foreground > "$T/scrub2.out" 2>&1   # same tree, cached green, new empty scratch
check "finish keeps check-last.out and init.out in the state dir and deletes the run's scratch, not the project's (live.lock stays)" \
  '[[ -f $HARNESS_STATE/proj/scrub/check-last.out && -s $HARNESS_STATE/proj/scrub/init.out && ! -e $T/scratch/proj/scrub && $(cat "$T/scratch/proj/live.lock") == lock ]] \
  && hlog scrub | grep -qF "scratch removed: $T/scratch/proj/scrub" && grep -qx "# pass 7" "$HARNESS_STATE/proj/scrub/check-last.out"'
check "a continued run whose suite is cached green keeps its test count (the green marker holds it, not scratch)" '[[ $scrub_end1 == 7 && $(cat "$HARNESS_STATE/proj/scrub/tests-end" 2> /dev/null) == 7 ]] \
  && [[ $(hlog scrub | grep -c "scratch removed: ") == 2 && ! -e $T/scratch/proj/scrub ]]'   # the second segment ran no init: its scratch held no suite output
# R1: a suite that prints text with no count, over two segments: the first ends at its deadline after the initializer,
# the second runs the features (an init and a suite before each session) to the end
mkdir -p "$HARNESS_STATE/proj/nocount" && echo "CHECK_CMD='echo \"lint: clean\"'" > "$HARNESS_STATE/proj/nocount/run.env"
"$H" start "$T/proj" nocount --spec SPEC.md --until-epoch $(( $(date +%s) - 1 )) --foreground > "$T/nocount.out" 2>&1
"$H" continue nocount --foreground > "$T/nocount2.out" 2>&1
check "test count: no match is noted once per run (demo: no output; nocount: text with no count), never for a counted or cached suite (scrub)" \
  '[[ $(grep -c "test count: no match in the suite'"'"'s output (tests start/end stay unknown)" "$T/demo-hlog.md") == 1 ]] \
  && [[ $(hlog nocount | grep -c "test count: no match") == 1 && $(hlog nocount | grep -c "run ended") == 2 ]] \
  && hlog nocount | grep -m1 -e "test count: no match" -e "run ended" | grep -q "test count" && hlog nocount | grep -q "run ended (done)" && ! hlog scrub | grep -q "test count: no match"'
check "KEEP_SCRATCH=1 keeps the run's scratch; the default is 0" '[[ -d $T/scratch/proj/demo ]] && grep -qF "scratch kept (KEEP_SCRATCH=1): $T/scratch/proj/demo" "$T/demo-hlog.md" \
  && ( source "$HERE/../lib/config.sh" && HARNESS_CONFIG=/dev/null harness_config /nonexistent && [[ $KEEP_SCRATCH == 0 ]] ) && grep -q "^# KEEP_SCRATCH=0 " "$HERE/../templates/user/config.sh"'
git init -q "$T/ck2" && ( cd "$T/ck2" && echo a > f && git add f && git -c user.name=t -c user.email=t@t commit -qm a )
ck2() { ( cd "$T/ck2" && HARNESS_SCRATCH=$T/ck2s HARNESS_CHECK_CACHE=$T/ck2c HARNESS_CHECK_CMD='echo "# pass 1"' "$HERE/../lib/check.sh" ); }
ck2 > /dev/null; ck2k1=$(cd "$T/ck2" && node "$HERE/../lib/treekey.mjs"); echo b > "$T/ck2/f"; ck2 > /dev/null; ck2k2=$(cd "$T/ck2" && node "$HERE/../lib/treekey.mjs")
echo a > "$T/ck2/f"; ck2_back=$(ck2)   # back to the first tree: green from its marker, its output gone
check "check.sh keeps one check-<key>.out; the green markers stay" '[[ $(ls "$T"/ck2s/check-*.out | wc -l) == 1 && -f $T/ck2s/check-$ck2k2.out && $ck2k1 != "$ck2k2" ]] \
  && [[ $(cat "$T/ck2c/green-$ck2k1") == "1 tests" && -f $T/ck2c/green-$ck2k2 && $ck2_back == "check: green (cached for this code tree, 1 tests)" ]]'
check "the init and the sessions see HARNESS_CACHE (XDG_CACHE_HOME/harness/<project>), created" 'grep -qxF "cache: $T/cache/harness/proj" "$HARNESS_STATE/proj/scrub/init.out" \
  && grep -qxF "scrub $T/cache/harness/proj" "$T/cache.log" && [[ -d $T/cache/harness/proj ]]'
mkdir -p "$T/guard/proj/r1" "$T/guard/proj/x"; for g in "$T/guard" "$T/guard/proj" "$T/guard/proj/r1" "$T/guard/proj/x"; do : > "$g/marker"; done
guard() { ( source "$HERE/../lib/prompt.sh"; HARNESS_SCRATCH_ROOT=${SR_ROOT-$T/guard} PROJECT_NAME=${SR_PROJ-proj} RUN_ID=${SR_RUN-r1} scratch_rm "$1" ) && echo removed || echo refused; }
guard_bad=$(for d in / "" "$T/guard" "$T/guard/proj" "$T/guard/proj/" "$T/guard/proj/.." "$T/guard/proj/x/.." "$T/guard/proj/r1/" "$T/guard/proj/r1/.."; do guard "$d"; done
  SR_RUN="" guard "$T/guard/proj/"; SR_RUN=.. guard "$T/guard/proj/.."; SR_PROJ="" guard "$T/guard//r1"; SR_PROJ=.. guard "$T/guard/../r1"; SR_PROJ=. guard "$T/guard/./r1"
  SR_ROOT=relative guard "relative/proj/r1")
mkdir -p "$T/groot" && ln -s "$T/guard/proj" "$T/groot/lp" && ln -s "$T/guard/proj/x" "$T/guard/proj/lx"   # a symlinked project dir, a symlinked run dir
guard_bad+=$'\n'$(SR_ROOT=$T/groot SR_PROJ=lp guard "$T/groot/lp/r1"; SR_RUN=lx guard "$T/guard/proj/lx")
check "scratch_rm refuses anything but the run's own scratch directory (symlinks in its path too)" '! grep -q removed <<< "$guard_bad" && [[ $(grep -c refused <<< "$guard_bad") == 17 ]] \
  && [[ -f $T/guard/marker && -f $T/guard/proj/marker && -f $T/guard/proj/r1/marker && -f $T/guard/proj/x/marker && -L $T/guard/proj/lx ]] \
  && [[ $(guard "$T/guard/proj/r1") == removed && ! -e $T/guard/proj/r1 && -f $T/guard/proj/marker ]]'
# scratch_done on its own (L3-05 review): what it copied in the note, the final tree's output as check-last.out, scratch kept when a copy fails
sd() { ( source "$HERE/../lib/prompt.sh"; note() { echo "note: $*"; }; HARNESS_SCRATCH_ROOT=$T/sdr PROJECT_NAME=proj RUN_ID=$1 SCRATCH=${SD_SCRATCH-$T/sdr/proj/$1} \
  STATE=$T/sds/$1 KEEP_SCRATCH=0; mkdir -p "$STATE"; scratch_done "$2" ) 2>&1; }
mkdir -p "$T"/sdr/proj/{sd1,sd2,sd3,sd4}; echo init > "$T/sdr/proj/sd1/init.out"; echo old > "$T/sdr/proj/sd1/check.out"; echo final > "$T/sdr/proj/sd1/check-k1.out"
sd1=$(sd sd1 k1); echo x > "$T/sdr/proj/sd2/check.out"; mkdir -p "$T/sds/sd2" && chmod 555 "$T/sds/sd2"; sd2=$(sd sd2 k2); chmod 755 "$T/sds/sd2"
mkdir -p "$T/sdr/proj/sd3/lk" && : > "$T/sdr/proj/sd3/lk/f" && chmod 555 "$T/sdr/proj/sd3/lk"; sd3=$(sd sd3 k3); chmod 755 "$T/sdr/proj/sd3/lk"
sd4=$(SD_SCRATCH=$T/sdr/proj sd sd4 k4)
check "scratch_done: the final tree's output is check-last.out, the note names what it kept" '[[ $(cat "$T/sds/sd1/check-last.out") == final && $(cat "$T/sds/sd1/init.out") == init && ! -e $T/sdr/proj/sd1 ]] \
  && [[ $sd1 == "note: scratch removed: $T/sdr/proj/sd1 (in the state dir: init.out check-last.out)" ]]'
check "scratch_done keeps scratch when a copy fails, and says why when rm fails or the guard refuses" '[[ -f $T/sdr/proj/sd2/check.out && $sd2 == "note: scratch kept: copying check-last.out into $T/sds/sd2 failed" ]] \
  && [[ $sd3 == "note: scratch not fully removed: $T/sdr/proj/sd3 (rm exit 1)" && $sd4 == "note: scratch not removed: $T/sdr/proj is not this run'"'"'s scratch directory" && -d $T/sdr/proj ]]'
check "the tmpfiles template holds the 3-day age rule; README has its install command" 'grep -qx "e /tmp/harness - - - 3d" "$HERE/../templates/user/harness-tmpfiles.conf" \
  && grep -qx "x /tmp/harness/\*/live.lock" "$HERE/../templates/user/harness-tmpfiles.conf" && grep -q "user-tmpfiles.d" "$HERE/../README.md" && grep -q "HARNESS_CACHE" "$HERE/../README.md"'

suite_end
