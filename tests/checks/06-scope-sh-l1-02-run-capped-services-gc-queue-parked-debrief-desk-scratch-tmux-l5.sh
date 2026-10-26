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
    && ! scope_owns demo harness-demo-x-svc.scope && ! scope_owns demo harness-demo-svc && ! scope_owns test harness-test-1-probe.scope && ! scope_owns demo harness-demo-s.scope )'
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
check "init model resolved to fable"      'grep -q "initializer · claude-fable-5-1" "$HARNESS_STATE/proj/demo/run.log"'
check "summary end reason is how the run ended" '[[ $(jq -r .end_reason "$RD/summary.json") == done ]]'
check "a milestone without an after list is noted" 'hlog demo | grep -q "dependencies: M2 has no after list"'
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
# gclive and demo-x have a live driver (demo-x also shows demo's prefix can't claim it); oth is another project's
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

# ---- run 2: Michael sets "status: stop" in INBOX.md from the phone (and only NOTIFY_CMD is configured) ----
printf '%s\n' 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' "NOTIFY_CMD='{ printf \"%s\\n\" \"\$1\"; env | grep ^HARNESS_NOTIFY_; echo ===; } >> \"$T/notify-env.log\"'" > "$T/user-config.sh"
STUB_PHONE_STOP=1 "$H" start "$T/proj" stoppy --spec SPEC.md --foreground > "$T/run2.out" 2>&1
cp "$T/base-config.sh" "$T/user-config.sh"
check "NOTIFY_CMD-only: \$1 unchanged, fields as env" 'grep -q "^\[stoppy\] started: 0/3 passing$" "$T/notify-env.log" && grep -qx "HARNESS_NOTIFY_TITLE=harness" "$T/notify-env.log" && grep -qx "HARNESS_NOTIFY_PRIORITY=" "$T/notify-env.log" && [[ -s $T/curl.log ]] && ! grep -q "\[stoppy\]" "$T/curl.log"'
check "phone stop honoured before any coding session" 'hlog stoppy | grep -q "stopped by Michael" && ! grep -q attempt "$T/scratch/proj/stoppy/sessions.log"'
check "a stop from the phone stops the services through finish" 'hlog stoppy | grep -q "· services stopped (stopped by Michael)$" && [[ -f $T/scratch/proj/stoppy/teardown-stopped-by-Michael.marker ]]'
check "second run got its own port"       '[[ $(cat "$HARNESS_STATE/proj/stoppy/port") != $(cat "$HARNESS_STATE/proj/demo/port") ]]'

# ---- run 3: a verifier that always rejects; C is independent of M1 ----
SPY3='printf "%s · %s\n" "$(printf "%s\n" "$@" | sed -n "s/^Title: //p")" "$(git -C "$STUB_DIR/origin.git" log -1 --format=%s harness/strict)" >> "$STUB_DIR/spy-strict.log"'
STUB_CURL_SPY=$SPY3 STUB_STRICT_VERIFIER=1 STUB_INDEPENDENT_M2=1 "$H" start "$T/proj" strict --spec SPEC.md --foreground > "$T/run3.out" 2>&1
check "verify ping-pong capped, needs Michael" 'hlog strict | grep -q "M1 needs Michael" && (( $(grep -c "^A attempt" "$T/scratch/proj/strict/sessions.log") <= 2 ))'
check "verify needs Michael: priority high, click = progress.md (GitHub-shaped origin)" 'Bv=$(curl_with "[strict] M1 needs Michael: A fails verification"); grep -qx "Title: \[strict\] M1 needs you" <<< "$Bv" \
  && grep -qx "Priority: high" <<< "$Bv" && grep -qx "Click: $GHP/blob/harness/strict/.harness/runs/strict/progress.md" <<< "$Bv"'
check "verify needs Michael goes out after the verify entry is pushed" 'grep -qxF "[strict] M1 needs you · HARNESS: verify M1" "$T/spy-strict.log"'
check "independent M2 verified, not merged (M1 isn't)" 'git -C "$T/origin.git" tag | grep -qx run/strict/M2 && ! on_main run/strict/M2'
check "no dependency note when every milestone has after" '! hlog strict | grep -q "dependencies:"'

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

# ---- run 10: merges refused (MERGE_POLICY=auto but GitHub says no) → `harness merge` later ----
STUB_REFUSE_MERGE=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" later --spec SPEC.md --foreground > "$T/run10.out" 2>&1
check "refused merge leaves the PR, needs Michael" 'hlog later | grep -q "merge was refused" && ! on_main run/later/M1'
check "a refused merge: priority high, click = the PR" 'Br=$(curl_with "[later] M1 needs Michael: merge refused"); U=$(grep -o "https://example.test/pr/[0-9]*" <<< "$Br" | head -1) \
  && [[ -n $U ]] && grep -qx "Title: \[later\] M1 needs you" <<< "$Br" && grep -qx "Priority: high" <<< "$Br" && grep -qx "Click: $U" <<< "$Br"'
echo old1234 > "$HARNESS_STATE/proj/later/harness-version"
"$H" merge later > "$T/run10b.out" 2>&1
check "harness merge keeps the harness version of the run (E1 review)" '[[ $(cat "$HARNESS_STATE/proj/later/harness-version") == old1234 ]]'
check "harness merge merges verified milestones afterwards" 'on_main run/later/M2 && grep -q "^done" "$HARNESS_STATE/proj/later/ended"'

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
"$H" queue add --continue stoppy > /dev/null   # Michael stopped stoppy: the runner skips it, so it starts nothing
HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$T/queue2.out" 2>&1; settle
check "a runner that started nothing (a skipped continuation): no debrief" '[[ $(ndb) == 1 ]] && grep -q "skipping queued continuation of stoppy" "$Q/runner.log" && ! grep -q "harness debrief (detached" "$T/queue2.out"'
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
"$H" queue add "$T/proj" --spec SPEC.md > /dev/null; "$H" queue add --continue stoppy-o > /dev/null
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
check "continuation queued: keeps attempts, brief marked as the debrief's" 'f=$(compgen -G "$Q/*-continue-stoppy.args") && grep -qx -- --keep-attempts "$f" && grep -q "do C next" "$f" && grep -qi "suggested by the debrief" "$f" && grep -q "Queued: .*stoppy" "$NOTE" && ! grep -q "debrief: queued" "$NOTE"'
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

# ---- run 16: a feature waiting on Michael parks (no attempt); independent work goes on; an answer unparks it ----
{ cat "$T/base-config.sh"; echo 'DESK_URL=https://claude.ai/code/env-test'; } > "$T/user-config.sh"
STUB_PARK=B STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" parky --spec SPEC.md --foreground > "$T/run16.out" 2>&1
S16=$T/wt/proj/parky/.harness/runs/parky/summary.json
check "parked: not an attempt, not retried" 'hlog parky | grep -q "B parked (waiting on Michael): set the gatus vars" && [[ $(jq -r ".B // 0" "$HARNESS_STATE/proj/parky/attempts.json") == 0 && $(grep -c "^B attempt" "$T/scratch/proj/parky/sessions.log") == 1 ]]'
check "independent work goes on past a parked feature" 'grep -q "^C attempt" "$T/scratch/proj/parky/sessions.log"'
check "ends waiting on Michael; the summary says so" 'grep -q "^waiting on Michael: B" "$HARNESS_STATE/proj/parky/ended" && [[ $(jq -r .end_reason "$S16") == "waiting on Michael: B" && $(jq -r ".features_detail[1].cause" "$S16") == "waiting on Michael" ]]'
# two short parks without DESK_URL (A parks; B and C wait on it): one with the GitHub origin, one with a local origin
# whose posts fail (both runs stay behind, ended waiting on Michael)
cp "$T/base-config.sh" "$T/user-config.sh"
SPY='printf "%s · %s\n" "$(printf "%s\n" "$@" | sed -n "s/^Title: //p")" "$(git -C "$STUB_DIR/origin.git" log -1 --format=%s harness/parkn)" >> "$STUB_DIR/spy.log"'
STUB_CURL_SPY=$SPY STUB_PARK=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" parkn --spec SPEC.md --foreground > "$T/run16n.out" 2>&1
git -C "$T/proj" config remote.origin.url "$T/origin.git"
STUB_CURL_FAIL=1 STUB_PARK=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" parkl --spec SPEC.md --foreground > "$T/run16l.out" 2>&1
git -C "$T/proj" config remote.origin.url git@github.com:test/proj.git
{ cat "$T/base-config.sh"; echo 'DESK_URL=https://claude.ai/code/env-test'; } > "$T/user-config.sh"
B16=$(curl_with "Title: [parky] B needs you"); BB16=$(curl_body "Title: [parky] B needs you")
check "a park notification: title, question, answer command, click and Edit INBOX action" 'grep -qx "Priority: high" <<< "$B16" && grep -qx "Tags: question" <<< "$B16" \
  && grep -qx "Click: $GHP/blob/harness/parky/.harness/runs/parky/INBOX.md" <<< "$B16" && grep "^Actions: " <<< "$B16" | grep -qF "view, Edit INBOX, $GHP/edit/harness/parky/.harness/runs/parky/INBOX.md" \
  && grep "^Actions: " <<< "$B16" | grep -qF "view, Progress, $GHP/blob/harness/parky/.harness/runs/parky/progress.md" \
  && grep -qx "PARKED: set the gatus vars" <<< "$BB16" && grep -qx "### B: set the gatus vars, then answer" <<< "$BB16" && grep -q "^Answer: harness answer parky \"" <<< "$BB16" \
  && grep -q "notified: \[parky\] B needs you" "$HARNESS_STATE/proj/parky/run.log"'
check "Answer with Claude only when DESK_URL is set" 'grep "^Actions: " <<< "$B16" | grep -qF "view, Answer with Claude, https://claude.ai/code/env-test" \
  && grep -q "^Actions: .*Edit INBOX" <<< "$(curl_with "Title: [parkn] A needs you")" && ! grep -q "Answer with Claude" <<< "$(curl_with "Title: [parkn] A needs you")"'
check "the park goes out after the run branch is pushed (the link shows the question)" 'grep -qx "\[parkn\] A needs you · HARNESS: after A (passes=false)" "$T/spy.log"'
check "the run end goes out before the retro, once report.md is pushed" 'grep -qxF "[parkn] ended: waiting on Michael: A · HARNESS: run ended (waiting on Michael: A)" "$T/spy.log" \
  && git -C "$T/origin.git" cat-file -e "$(git -C "$T/origin.git" log -1 --format=%H --grep="^HARNESS: run ended" harness/parkn):.harness/runs/parkn/report.md" \
  && awk "/notified: \[parky\] ended:/ { n = NR } /retro · / && !r { r = NR } END { exit !(n && r && n < r) }" "$HARNESS_STATE/proj/parky/run.log"'
check "a failed park post is noted and committed at once" 'hlog parkl | grep -q "notification failed (curl exit 22): \[parkl\] A needs you" && git -C "$T/origin.git" log --format=%s harness/parkl | grep -x "HARNESS: park notification failed" > /dev/null'
check "no URLs for a non-GitHub origin" 'Bl=$(curl_with "Title: [parkl] A needs you"); grep -qx "Priority: high" <<< "$Bl" && grep -q "^Answer: harness answer parkl \"" <<< "$(curl_body "Title: [parkl] A needs you")" \
  && ! grep -q "^Click: " <<< "$Bl" && ! grep -q "^Actions: " <<< "$Bl" && ! grep -q "https://github.com" <<< "$Bl"'
check "a waiting-on-Michael run end: priority high, click = report.md" 'Be=$(curl_with "[parky] ended (waiting on Michael: B)"); grep -qx "Title: \[parky\] ended: waiting on Michael: B" <<< "$Be" \
  && grep -qx "Priority: high" <<< "$Be" && grep -qx "Click: $GHP/blob/harness/parky/.harness/runs/parky/report.md" <<< "$Be" \
  && grep "^Actions: " <<< "$Be" | grep -qF "view, Edit INBOX, $GHP/edit/harness/parky/.harness/runs/parky/INBOX.md"'
check "one notification per run end" '[[ $(curl_count "[parky] ended (") == 1 && $(curl_count "needs Michael: waiting on Michael") == 0 && $(curl_count "needs Michael: blocked on") == 0 ]] \
  && ! grep -q "Priority:" <<< "$(curl_with "[demo] ended (done)")" && grep -q "^Click: .*/demo/report.md" <<< "$(curl_with "[demo] ended (done)")"'
# harness parked: parky, parkn and parkl are all parked and ended; no queue runner
touch "$T/parked.stamp"; "$H" parked > "$T/parked.out" 2>&1; "$H" parked parky --json > "$T/parked.json" 2>&1
check "harness parked: id, why, question, both commands" 'P=$(cat "$T/parked.out"); [[ $P == *"parky · proj · B"* && $P == *"why:      set the gatus vars"* && $P == *"question: ### B: set the gatus vars, then answer"* \
  && $P == *"harness answer parky \"…\""* && $P == *"harness continue parky"* && $P == *"parkn · proj · A"* && $P == *"parkl · proj · A"* ]]'
check "harness parked is read-only" '[[ -z $(find "$HARNESS_STATE" "$T/wt/proj/parky" -newer "$T/parked.stamp") && -z $(git -C "$T/wt/proj/parky" status --porcelain) ]]'
check "harness parked --json parses" 'jq -e ".[0].feature == \"B\" and .[0].running == false and (.[0].commands | length) == 2" "$T/parked.json" > /dev/null'
RP=$HARNESS_STATE/queue/runner.pid; mkdir -p "$HARNESS_STATE/queue"; [[ -f $RP ]] && mv "$RP" "$RP.keep"; echo $$ > "$RP"
check "with a queue runner going, the continue command is a queue add" 'P=$("$H" parked parky); [[ $P == *"harness queue add --continue parky"* && $P != *"harness continue parky"* ]]'
rm -f "$RP"; [[ -f $RP.keep ]] && mv "$RP.keep" "$RP"
# parky's driver still alive (our pid): wrapping up after "ended" (finish: merge, suite, retro), then mid-run
DP=$HARNESS_STATE/proj/parky/driver.pid; echo $$ > "$DP"
check "a run still ending: answer now, continue once it has ended" 'P=$("$H" parked parky); [[ $P == *"running:  ending"* && $P == *"harness continue parky"* ]] \
  && "$H" parked parky --json | jq -e ".[0].running == false and .[0].ending == true and (.[0].commands | length) == 2" > /dev/null'
mv "$HARNESS_STATE/proj/parky/ended" "$T/parky.ended"
check "a run still going: only the answer command" 'P=$("$H" parked parky); [[ $P == *"running:  yes"* && $P == *"harness answer parky"* && $P != *"continue parky"* ]]'
mv "$T/parky.ended" "$HARNESS_STATE/proj/parky/ended"; rm -f "$DP"
check "harness parked: an unknown or glob run id is an error" '! "$H" parked nosuch 2> /dev/null && ! "$H" parked "parky*" > /dev/null 2>&1 \
  && ! "$H" answer "park*" "a glob answers no run" > /dev/null 2>&1 && ! grep -rqs "a glob answers" "$HARNESS_STATE"/proj/park*/inbox.md'
# a session-cap end queues its own continuation (finish): a second one would restart the run twice
touch "$HARNESS_STATE/queue/9999-continue-parky.args"
check "a queued continuation: only the answer command" 'P=$("$H" parked parky); [[ $P == *"continuation queued"* && $P == *"harness answer parky"* && $P != *"continue parky"* ]] \
  && "$H" parked parky --json | jq -e ".[0].queued == true and (.[0].commands | length) == 1" > /dev/null'
rm -f "$HARNESS_STATE/queue/9999-continue-parky.args"
# demo's worktree is gc'd: a parked.json left in its state dir names nothing that can be answered or continued
echo '{"Z":{"answers":"x","why":"stale","at":"2026-10-19T01:00:00.000Z"}}' > "$HARNESS_STATE/proj/demo/parked.json"
check "nothing parked"                    '[[ $("$H" parked demo) == "nothing parked in demo" ]] && ! "$H" parked | grep -q "^demo "'
check "the answer skill exists and names the commands and the never-list" 'S=$HH/skills/harness-answer/SKILL.md; [[ $(head -1 "$S") == --- ]] && grep -q "^name: harness-answer$" "$S" && grep -q "harness parked" "$S" && grep -q "harness answer" "$S" && grep -qi "never edit INBOX.md" "$S" && grep -q sudo "$S"'
check "the answer skill passes Michael's words through a quoted heredoc" 'S=$HH/skills/harness-answer/SKILL.md; grep -qF "\"\$(cat <<'"'"'HARNESS_ANSWER_END'"'"'" "$S" && grep -qi "never let his words reach the shell" "$S"'
check "the user config template sets nothing" 'bash -n "$HH/templates/user/config.sh" && ( unset NTFY_URL NTFY_TOKEN DESK_URL NOTIFY_CMD; source "$HH/templates/user/config.sh"; [[ -z ${NTFY_URL:-}${NTFY_TOKEN:-}${DESK_URL:-}${NOTIFY_CMD:-} ]] )'
rm -f "$HARNESS_STATE/proj/demo/parked.json"
"$H" answer parky "gatus vars set" > /dev/null
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue parky --keep-attempts --foreground > "$T/run16b.out" 2>&1
check "an INBOX answer unparks it; the run finishes" 'hlog parky | grep -q "B unparked" && [[ $($F summary "$(list parky)") == "3/3 passing" ]]'

# ---- the desk: a Remote Control claude in a tmux window briefs Michael (stub claude's interactive mode, private server) ----
cp "$T/base-config.sh" "$T/user-config.sh"   # NTFY_URL: the checks read curl.log
# every run so far (parky parked and ended, strict and later needed Michael) had the default DESK=0
check "DESK=0: no desk" '[[ -z $(compgen -G "$HARNESS_STATE/*/*/desk") && -z $(wins) && ! -e $T/desk/count ]] && ! grep -rqs "desk started\|desk: " "$T"/wt/proj/*/.harness/runs/*/harness-log.md'
SU=$T/stubunit; mkdir -p "$SU"   # its own counter: the suite's first desk stays session_TEST1
BIG=$(printf '# Retro\n%0122880d' 0)   # > the 64 KB pipe buffer, < the 128 KB argument limit
check "the stub claude's interactive mode prints the pane line and records input" 'O=$(printf "hello\n" | STUB_DIR=$SU "$HERE/stub-claude.sh" --remote-control "desk · u · x" --model m) \
  && [[ $O == "/remote-control is active · Continue here, on your phone, or at https://claude.ai/code/session_TEST1" && $(cat "$SU/desk/1-desk_u_x.in") == hello ]] \
  && grep -qx -- --remote-control "$SU/desk/1-desk_u_x.args" && [[ $(tail -1 "$SU/desk/1-desk_u_x.args") == "PWD=$PWD" ]] \
  && [[ -z $(STUB_DESK_NO_URL=1 STUB_DIR=$SU "$HERE/stub-claude.sh" --remote-control "desk · v" < /dev/null) && $(cat "$SU/desk/count") == 2 ]] \
  && STUB_DIR=$SU HARNESS_SCRATCH=$SU "$HERE/stub-claude.sh" -p "$BIG" --model m < /dev/null | grep -q "Stub retro" && [[ $(cat "$SU/desk/count") == 2 ]]'
check "DESK=0 by default, DESK_MODEL=opus" '( source "$HH/lib/config.sh"; harness_config /nonexistent; [[ $DESK == 0 && $DESK_MODEL == opus ]] )'
"$H" desk parky --why "B parked: set the gatus vars" > "$T/desk1.out" 2> "$T/desk1.err"; D1=$?
DS=$HARNESS_STATE/proj/parky/desk; DP1=$(ls "$DS"/*.md 2> /dev/null | head -1)
check "harness desk: one window, the Read line, the prompt, the notification click" '[[ $D1 == 0 && $(cat "$T/desk1.out") == https://claude.ai/code/session_TEST1 && $(wins) == parky && -n $DP1 ]] \
  && in_has "$(desk_of parky | sed "s/\.args$/.in/")" "Read" && [[ $(cat "$(desk_of parky | sed "s/\.args$/.in/")") == "Read $DP1 and follow it." ]] \
  && grep -q parky "$DP1" && grep -qF "$T/wt/proj/parky/.harness/runs/parky/INBOX.md" "$DP1" && grep -q "harness answer parky" "$DP1" \
  && [[ $(cat "$DS/url") == https://claude.ai/code/session_TEST1 && $DP1 == "$DS"/[0-9]*-[0-9]*.md ]]'
check "the desk notification" 'Bd=$(curl_last "Title: [parky] needs you"); grep -qx "Title: \[parky\] needs you: B parked: set the gatus vars" <<< "$Bd" \
  && grep -qx "Priority: high" <<< "$Bd" && grep -qx "Click: https://claude.ai/code/session_TEST1" <<< "$Bd" && ! grep -q tok-secret "$DP1"'
check "the desk's claude: --remote-control, the model id, --add-dir the worktree, in the project directory" 'A=$(desk_of parky); [[ -n $A ]] && grep -qx -- --remote-control "$A" \
  && grep -qx "desk · parky · B parked: set the gatus vars" "$A" && grep -qx -- --model "$A" && grep -qx "$($F model opus)" "$A" && grep -qx -- --add-dir "$A" \
  && grep -qx "$T/wt/proj/parky" "$A" && [[ $(tail -1 "$A") == "PWD=$T/proj" ]]'
check "the desk prompt names the run, its commands and the never-list" '( for k in "harness parked parky" "harness status parky" progress.md "by name only" .env sudo "1 yes" "harness answer parky" \
  "harness queue add --continue parky" CLAUDE.md; do grep -qF -- "$k" "$DP1" || exit 1; done ) && grep -qi "never edit INBOX.md" "$DP1" && ! grep -qF "{{" "$DP1" && ! grep -qF "<!--" "$DP1" && ! grep -q "Needs Michael" "$DP1"'
check "harness desk notes 'desk started:' in the run record" 'hlog parky | grep -qF "desk started: https://claude.ai/code/session_TEST1 (B parked: set the gatus vars)" && [[ -z $(git -C "$T/wt/proj/parky" status --porcelain) ]]'
"$H" desk parky --why "C parked: db url" > "$T/desk2.out" 2> "$T/desk2.err"; D2=$?
DP2=$(ls -t "$DS"/*.md 2> /dev/null | head -1)
check "a second event reuses the desk window" 'I=$(desk_of parky | sed "s/\.args$/.in/"); [[ $D2 == 0 && $(cat "$T/desk2.out") == https://claude.ai/code/session_TEST1 && $(wins) == parky && $DP2 != "$DP1" ]] \
  && in_has "$I" "New since" && [[ $(tail -1 "$I") == "New since your last brief: C parked: db url. Re-read $DP2." && $(head -1 "$I") == "Read $DP1 and follow it." ]] \
  && Bd=$(curl_last "Title: [parky] needs you") && grep -qx "Title: \[parky\] needs you: C parked: db url" <<< "$Bd" && grep -qx "Click: https://claude.ai/code/session_TEST1" <<< "$Bd" \
  && hlog parky | grep -qF "desk: sent to the open desk: https://claude.ai/code/session_TEST1 (C parked: db url)" && [[ $(hlog parky | grep -c "desk started:") == 1 && -z $(git -C "$T/wt/proj/parky" status --porcelain) ]]'
STUB_DESK_NO_URL=1 HARNESS_DESK_WAIT=2 "$H" desk stoppy --why "x" > "$T/desk3.out" 2> "$T/desk3.err"; D3=$?
check "no URL in time: no window, the plain notification" '[[ $D3 == 0 && ! -s $T/desk3.out && -z $(win stoppy) ]] && grep -q "no session URL" "$T/desk3.err" \
  && hlog stoppy | grep -qF "desk: no session URL within 2 s; killed the window; plain notification" && [[ ! -s $HARNESS_STATE/proj/stoppy/desk/url ]] \
  && Bn=$(curl_last "Title: [stoppy] needs you") && grep -qx "Title: \[stoppy\] needs you: x" <<< "$Bn" && grep -qx "Priority: high" <<< "$Bn" && ! grep -q "Click: https://claude.ai" <<< "$Bn" \
  && ! grep -q "Open the desk" <<< "$Bn" && grep -qx "Or by hand: harness parked stoppy" <<< "$Bn" && grep -q "; notified)$" "$T/desk3.err" \
  && [[ -z $(git -C "$T/wt/proj/stoppy" status --porcelain -- .harness/runs/stoppy/harness-log.md) ]]'   # committed (the debrief checks planted the INBOX and report edits)
W=$(win parky); [[ -n $W ]] && tmux kill-window -t "$W"   # the session goes with its last window (an empty -t would hit the current window)
"$H" desk parky --why "again" > "$T/desk4.out" 2> "$T/desk4.err"; D4=$?
check "a dead desk is replaced" 'I=$(desk_of parky | sed "s/\.args$/.in/"); [[ $D4 == 0 && $(cat "$T/desk4.out") == https://claude.ai/code/session_TEST3 && $(wins | grep -cx parky) == 1 && $I == */3-desk_parky_again.in ]] \
  && in_has "$I" "Read" && [[ $(head -1 "$I") == "Read "*" and follow it." ]] && ! grep -q "New since" "$I" && [[ $(cat "$DS/url") == https://claude.ai/code/session_TEST3 ]]'
"$H" desk --debrief > "$T/desk5.out" 2> "$T/desk5.err"; D5=$?
QP=$(ls -t "$HARNESS_STATE"/queue/desk/*.md 2> /dev/null | head -1)
check "harness desk --debrief" 'A=$(desk_of debrief); [[ $D5 == 0 && $(cat "$T/desk5.out") == https://claude.ai/code/session_TEST4 && -n $(win debrief) && -n $QP && -n $A ]] \
  && grep -qF "ledger/debrief.md" "$QP" && grep -q "Needs Michael" "$QP" && ! grep -qF "{{" "$QP" && ! grep -qF "<!--" "$QP" && ! grep -q "harness parked parky" "$QP" \
  && in_has "${A%.args}.in" "Read" && [[ $(cat "${A%.args}.in") == "Read $QP and follow it." && $(tail -1 "$A") == "PWD=$HH" ]] && grep -qx "$T/wt" "$A" && grep -qx "$T/ledger" "$A" \
  && grep -qx "Title: \[debrief\] needs you" <<< "$(curl_last "Title: [debrief]")" && grep -qx "Click: https://claude.ai/code/session_TEST4" <<< "$(curl_last "Title: [debrief]")" \
  && grep -qF "desk started: https://claude.ai/code/session_TEST4" "$HARNESS_STATE/queue/runner.log"'
W0=$(wins | sort)
rc() { "$@" > /dev/null 2>&1; echo $?; }
check "harness desk: an unknown run or a bad option is an error, nothing started" '[[ $(rc "$H" desk nosuch) == 1 && $(rc "$H" desk "park*") == 1 && $(rc "$H" desk debrief) == 1 && $(rc "$H" desk desk) == 1 ]] \
  && [[ $(rc "$H" desk parky --nope) == 2 && $(rc "$H" desk --debrief parky) == 2 && $(rc "$H" start "$T/proj" desk --spec SPEC.md) == 1 ]] \
  && [[ ! -d $HARNESS_STATE/proj/nosuch && ! -d $HARNESS_STATE/proj/desk && ! -d $T/wt/proj/desk && $(wins | sort) == "$W0" ]]'
W=$(win parky); [[ -n $W ]] && tmux kill-window -t "$W"; tmux new-window -d -t "=$HARNESS_DESK_SESSION:" -n parky sleep 600; rm -f "$DS/url"   # a window of that name that is no desk
"$H" desk parky --why "stale" > "$T/desk6.out" 2> /dev/null; D6=$?
check "a window of the run's name that never showed a URL is replaced" '[[ $D6 == 0 && $(cat "$T/desk6.out") == https://claude.ai/code/session_TEST5 && $(wins | grep -cx parky) == 1 ]] \
  && in_has "$(desk_of parky | sed "s/\.args$/.in/")" "Read" && ! tmux list-panes -a -F "#{pane_start_command}" | grep -q "sleep 600"'
# DESK=1: the driver and the debrief start desks themselves (a park, a run end needing Michael, verify, the debrief)
{ cat "$T/base-config.sh"; echo 'DESK=1'; } > "$T/user-config.sh"
STUB_PARK=B STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" desky --spec SPEC.md --foreground > "$T/run18.out" 2>&1
check "DESK=1: a park starts one desk, the run end reuses it" 'I=$(desk_of desky | sed "s/\.args$/.in/"); grep -q "^waiting on Michael: B" "$HARNESS_STATE/proj/desky/ended" && [[ $(wins | grep -cx desky) == 1 ]] \
  && in_has "$I" "New since" && [[ $(sed -n 1p "$I") == "Read $HARNESS_STATE/proj/desky/desk/"*".md and follow it." ]] \
  && [[ $(sed -n 2p "$I") == "New since your last brief: ended: waiting on Michael: B. Re-read $HARNESS_STATE/proj/desky/desk/"*.md. && $(wc -l < "$I") == 2 ]] \
  && [[ $(hlog desky | grep -c "desk started:") == 1 ]] && hlog desky | grep -qF "(B parked: set the gatus vars)" && hlog desky | grep -q "desk: sent to the open desk: .* (ended: waiting on Michael: B)" \
  && [[ -n $(curl_with "Title: [desky] B needs you") && -n $(curl_with "Title: [desky] needs you: B parked: set the gatus vars") && -z $(git -C "$T/wt/proj/desky" status --porcelain) ]]'
STUB_DESK_NO_URL=1 HARNESS_DESK_WAIT=2 STUB_PARK=B STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" deskno --spec SPEC.md --foreground > "$T/run19.out" 2>&1
check "a desk that cannot start never changes the run" 'grep -q "^waiting on Michael: B" "$HARNESS_STATE/proj/deskno/ended" && [[ -n $(curl_with "Title: [deskno] B needs you") && -z $(win deskno) ]] \
  && [[ $(hlog deskno | grep -c "desk: no session URL within 2 s; killed the window; plain notification") == 2 ]] && ! hlog deskno | grep -q "desk: could not start" \
  && [[ $($F summary "$(list deskno)") == "2/3 passing" && -z $(git -C "$T/wt/proj/deskno" status --porcelain) ]]'
STUB_STRICT_VERIFIER=1 STUB_INDEPENDENT_M2=1 "$H" continue strict --foreground > "$T/run3b.out" 2>&1   # clears needs-M1: M1 fails its re-checks again
check "verify needs Michael starts a desk" 'I=$(desk_of strict | sed "s/\.args$/.in/"); [[ -n $(win strict) ]] && in_has "$I" "Read" && P=$(sed -n "1s/^Read \(.*\) and follow it\.$/\1/p" "$I") \
  && [[ $P == "$HARNESS_STATE/proj/strict/desk/"*.md ]] && grep -q "M1 needs Michael: A fails verification" "$P" && hlog strict | grep -q "desk started: .* (M1 needs Michael: A fails verification)"'
W=$(win debrief); [[ -n $W ]] && tmux kill-window -t "$W"   # the by-hand one above (an empty -t would hit the current window)
ran stoppy; "$H" debrief > "$T/ddesk1.out" 2>&1; DW1=$(win debrief)
ran stoppy; STUB_DEBRIEF_NEEDS=1 "$H" debrief > "$T/ddesk2.out" 2>&1
check "the debrief starts a desk when Needs Michael is non-empty" '[[ -z $DW1 && -n $(win debrief) ]] && grep -q "debrief written" "$T/ddesk1.out" && grep -q "debrief written" "$T/ddesk2.out" \
  && [[ $(grep -c "desk started: .*session_TEST" "$HARNESS_STATE/queue/runner.log") == 2 ]]'
# housekeeping: list, close, gc's 24 h rule, close them all (open now: parky, desky, strict, debrief)
tmux new-window -d -t "=$HARNESS_DESK_SESSION:" -n odd sleep 600   # a window that is no desk
"$H" desk --list > "$T/dlist.out" 2>&1; DL=$?
check "harness desk --list" '"$H" help | grep -qF -- "harness desk --list | --close <run>|--all" && [[ $DL == 0 && $(wins | wc -l) == 5 && $(wc -l < "$T/dlist.out") == 5 ]] && grep -qE "^parky +parky +$(cat "$DS/url") +[0-9]+ min$" "$T/dlist.out" \
  && ( for w in desky strict; do grep -qE "^$w +$w +https://claude\.ai/code/session_TEST[0-9]+ +[0-9]+ min$" "$T/dlist.out" || exit 1; done ) \
  && grep -qE "^debrief +\(debrief\) +https://claude\.ai/code/session_TEST[0-9]+ +[0-9]+ min$" "$T/dlist.out" && grep -qE "^odd +- +- +-$" "$T/dlist.out"'
"$H" desk --close desky > "$T/dclose1.out" 2>&1; DC1=$?; "$H" desk --close parkn > "$T/dclose2.out" 2>&1; DC2=$?
check "harness desk --close <run>" '[[ $DC1 == 0 && $(cat "$T/dclose1.out") == "closed desk desky" && -z $(win desky) && ! -e $HARNESS_STATE/proj/desky/desk/url ]] \
  && [[ $DC2 == 0 && $(cat "$T/dclose2.out") == "no desk for parkn" && $(rc "$H" desk --close) == 2 && $(wins | wc -l) == 4 ]]'
ago() { echo $(( $(date +%s) - $1 * 3600 )); }   # an epoch <n> hours ago
ago 25 > "$HARNESS_STATE/proj/strict/desk/last-event"; ago 23 > "$DS/last-event"; ago 25 > "$HARNESS_STATE/proj/stoppy/desk/last-event"   # stoppy: idle, no window
"$H" gc "$T/proj" --dry-run > "$T/dgc1.out" 2>&1; DG1=$(win strict)
"$H" gc "$T/proj" > "$T/dgc2.out" 2>&1; DG2=$?
check "harness gc closes idle desks" '[[ -n $DG1 && $DG2 == 0 && -z $(win strict) && -n $(win parky) && -n $(win debrief) ]] && grep -qx "would close idle desk strict" "$T/dgc1.out" \
  && grep -qx "closed idle desk strict" "$T/dgc2.out" && [[ $(grep -c "idle desk" "$T/dgc2.out") == 1 && ! -e $HARNESS_STATE/proj/strict/desk/url ]] && grep -q "desk: closed" "$HARNESS_STATE/proj/strict/run.log"'
check "harness gc keeps the worktree of a run whose desk is open" '[[ -d $T/wt/proj/parky ]] && grep -qx "keeps $T/wt/proj/parky: its desk is open (harness desk --close parky)" "$T/dgc2.out"'
"$H" desk --all > "$T/dall1.out" 2>&1; DA1=$?; "$H" desk --all > "$T/dall2.out" 2>&1; DA2=$?
check "harness desk --all" '[[ $DA1 == 0 && $(cat "$T/dall1.out") == "closed every desk (3)" ]] && ! tmux has-session -t "=$HARNESS_DESK_SESSION" 2> /dev/null \
  && [[ -z $(compgen -G "$HARNESS_STATE/*/*/desk/url") && ! -e $HARNESS_STATE/queue/desk/url && $DA2 == 0 && $(cat "$T/dall2.out") == "no desks" && $("$H" desk --list) == "no desks" ]] && grep -q "desk: closed every desk (3" "$HARNESS_STATE/queue/runner.log"'
# review (P3-06): an open desk showing a dialog gets nothing typed; the token never reaches a desk; a refused merge
# tells Michael (and his desk) once, and `harness merge` starts no desk
NTFY_TOKEN=tok-env-456 STUB_DESK_MENU=1 "$H" desk parky --why "menu one" > "$T/dmenu1.out" 2>&1
IM=$(desk_of parky | sed 's/\.args$/.in/'); in_has "$IM" Read; sleep 1   # the stub draws its dialog after the Read line
STUB_DESK_MENU=1 "$H" desk parky --why "menu two" > "$T/dmenu2.out" 2> "$T/dmenu2.err"; DM=$?; sleep 1
check "an open desk showing a dialog gets nothing typed" '[[ $DM == 0 && -n $(cat "$T/dmenu1.out") && $(cat "$T/dmenu2.out") == "$(cat "$T/dmenu1.out")" && $(wc -l < "$IM") == 1 ]] \
  && hlog parky | grep -qF "desk: the open desk shows a dialog; nothing typed (menu two)" && Bm=$(curl_last "Title: [parky] needs you: menu two") \
  && grep -qx "Click: $(cat "$T/dmenu1.out")" <<< "$Bm" && grep -q "answer its dialog" <<< "$Bm" && [[ $(wins | grep -cx parky) == 1 ]]'
check "the desk's environment has no NTFY_TOKEN" 'E=$(desk_of parky | sed "s/\.args$/.env/"); [[ -s $E ]] && grep -qx HARNESS_STATE "$E" && ! grep -qx NTFY_TOKEN "$E" \
  && ! tmux show-environment -g 2> /dev/null | grep -q tok-env'
"$H" desk --all > /dev/null
STUB_REFUSE_MERGE=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" refusy --spec SPEC.md --foreground > "$T/run20.out" 2>&1
check "a refused merge tells Michael and his desk once" '[[ $(hlog refusy | grep -c "merge was refused") == 1 && $(curl_count "Title: [refusy] M1 needs you") == 1 ]] \
  && [[ $(hlog refusy | grep -c "M1: merge refused") == 1 && $(wins | grep -cx refusy) == 1 ]] && hlog refusy | grep -q "desk started: .* (M1: merge refused)"'
"$H" desk --close refusy > /dev/null
STUB_REFUSE_MERGE=1 "$H" merge refusy > "$T/run20b.out" 2>&1   # Michael retries at the terminal: still refused
check "harness merge says it was refused again, and starts no desk" '[[ $(hlog refusy | grep -c "merge was refused") == 2 && $(curl_count "Title: [refusy] M1 needs you") == 2 ]] \
  && [[ -z $(win refusy) && $(hlog refusy | grep -c "desk started:") == 1 ]]'
check "the dialog guard: the CLI's dialog words, not the desk's own questions" 'DG=$(sed -n "s/^DIALOG=\x27\(.*\)\x27$/\1/p" "$HH/lib/desk.sh"); [[ -n $DG ]] \
  && sed 1d "$HERE/fixtures/permission-menu.txt" | grep -qE "$DG" && ! printf "%s\n" "Do you want to merge M1 now?" "1. yes  2. no" "Enter the value" | grep -qE "$DG"'
"$H" desk --all > /dev/null
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

# ---- L5: the queue runner re-reads its config each poll: MAX_PARALLEL_RUNS 1 → 2 starts a second run, 2 → 1 stops none ----
# two projects (proj2: a clone with its own origin) and a third entry (stoppy-o: the runner starts it, harness skips it).
# The runs are tmux-started (parallel) on the private server: their STUB_* flags go through its global environment, and
# the stub holds each run's coding sessions until the suite releases it (hold-coding / release-<run>)
git clone -q --bare "$T/origin.git" "$T/origin2.git" && git clone -q "$T/origin2.git" "$T/proj2" && git -C "$T/proj2" config url."$T/origin2.git".insteadOf git@github.com:test/proj2.git \
  && git -C "$T/proj2" remote set-url origin git@github.com:test/proj2.git
mkdir -p "$HARNESS_STATE/other/stoppy-o" && echo 'stopped by Michael' > "$HARNESS_STATE/other/stoppy-o/ended" && : > "$HARNESS_STATE/other/stoppy-o/meta.env"
tmux new-session -d -s h-l5-hold sleep 600; for v in STUB_NO_TAMPER STUB_NO_RED STUB_LENIENT; do tmux set-environment -g "$v" 1; done
cfg() { { cat "$T/base-config.sh"; echo "MAX_PARALLEL_RUNS=$1"; } > "$T/user-config.new" && mv "$T/user-config.new" "$T/user-config.sh"; }   # whole, at once: the runner may source it any moment
waitf() { local i; for i in $(seq $(( $2 * 5 ))); do eval "$1" && return 0; sleep 0.2; done; return 1; }   # <bash expr> <s>
RL5=$T/queue-reload.out; st5() { grep -qF "starting: harness $1" "$RL5"; }
pid_up() { local p; p=$(cat "$HARNESS_STATE/$1/driver.pid" 2> /dev/null) && kill -0 "$p" 2> /dev/null; }
# a typo (2x, then 08, octal to bash: `(( a >= 2x ))` fails) keeps the old value, said once each; nothing starts: a fake live run fills the one slot
mkdir -p "$HARNESS_STATE/other/busy5" && : > "$HARNESS_STATE/other/busy5/meta.env"; sleep 60 & BP5=$!; echo $BP5 > "$HARNESS_STATE/other/busy5/driver.pid"
"$H" queue add "$T/proj" --spec SPEC.md > /dev/null; RB5=$T/queue-badmax.out
HARNESS_QUEUE_POLL=0.2 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$RB5" 2>&1 & RP5=$!
sleep 1; echo 'MAX_PARALLEL_RUNS=2x' >> "$T/user-config.sh"; waitf 'grep -q "=2x in the config is not" "$RB5"' 10; sleep 1
echo 'MAX_PARALLEL_RUNS=08' >> "$T/user-config.sh"; waitf 'grep -q "=08 in the config is not" "$RB5"' 10; sleep 1
cfg 1; sleep 1; touch "$HARNESS_STATE/queue/STOP"; waitf '! kill -0 $RP5 2> /dev/null' 10
check "queue runner: a MAX_PARALLEL_RUNS that is no whole number keeps the old value, said once; nothing starts" '[[ $(grep -c "MAX_PARALLEL_RUNS=2x in the config is not a whole number: keeping 1$" "$RB5") == 1 ]] \
  && [[ $(grep -c "MAX_PARALLEL_RUNS=08 in the config is not a whole number: keeping 1$" "$RB5") == 1 ]] \
  && ! grep -q "starting:\|config reloaded" "$RB5" && grep -q "stopped by harness queue stop" "$RB5"'
kill "$BP5" "$RP5" 2> /dev/null; rm -rf "$HARNESS_STATE/other/busy5" "$HARNESS_STATE"/queue/*.args
cfg 1; : > "$T/hold-coding"; rm -f "$T"/held-l5? "$T"/release-l5?
"$H" queue add "$T/proj" l5a --spec SPEC.md > /dev/null; "$H" queue add "$T/proj2" l5b --spec SPEC.md > /dev/null; "$H" queue add --continue stoppy-o > /dev/null
HARNESS_QUEUE_POLL=1 HARNESS_QUEUE_SETTLE=5 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$RL5" 2>&1 & RP5=$!
waitf '[[ -f $T/held-l5a ]]' 90; sleep 3; l5_early=$(st5 "start $T/proj2" && echo started)   # three polls at 1: the second waits
cfg 2; waitf 'st5 "start $T/proj2"' 15; l5_up=$(grep -c "MAX_PARALLEL_RUNS 1 → 2 (config reloaded)" "$RL5")
waitf '[[ -f $T/held-l5b ]]' 90; l5_both=$(pid_up proj/l5a && pid_up proj2/l5b && echo yes)
cfg 1; waitf 'grep -q "MAX_PARALLEL_RUNS 2 → 1 (config reloaded)" "$RL5"' 15; sleep 3
l5_low=$(pid_up proj/l5a && pid_up proj2/l5b && ! st5 "continue stoppy-o" && echo yes)   # lowering stops neither; the third waits
touch "$T/release-l5a"; waitf '! pid_up proj/l5a' 120; sleep 3; l5_one=$(pid_up proj2/l5b && ! st5 "continue stoppy-o" && echo yes)   # 1 alive, at 1: still waits
touch "$T/release-l5b"; waitf '! kill -0 $RP5 2> /dev/null' 180; settle
check "queue runner: MAX_PARALLEL_RUNS 1 → 2 in the config starts the second entry without a restart, and says so" '[[ -z $l5_early && $l5_up == 1 && $l5_both == yes ]] \
  && [[ $(grep -c "runner up" "$RL5") == 1 ]] && [[ $(grep -c "config reloaded" "$RL5") == 2 ]]'
check "queue runner: MAX_PARALLEL_RUNS 2 → 1 stops no running run; the third entry waits until under it, then starts" '[[ $l5_low == yes && $l5_one == yes ]] && st5 "continue stoppy-o" \
  && [[ $($F summary "$T/ledger/proj/l5a/feature_list.json") == "3/3 passing" && $($F summary "$T/ledger/proj2/l5b/feature_list.json") == "3/3 passing" ]] && grep -q "queue empty, nothing running: done" "$RL5"'
for v in STUB_NO_TAMPER STUB_NO_RED STUB_LENIENT; do tmux set-environment -gu "$v"; done; tmux kill-session -t =h-l5-hold 2> /dev/null
kill "$RP5" 2> /dev/null; rm -f "$T/hold-coding"; rm -rf "$HARNESS_STATE/other"; cp "$T/base-config.sh" "$T/user-config.sh"

suite_end
