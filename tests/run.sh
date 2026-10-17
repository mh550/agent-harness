#!/usr/bin/env bash
# End-to-end test of the driver and CLI with stub claude/gh, a throwaway project and a local bare "origin".
#   tests/run.sh        → prints PASS/FAIL per check, exit 1 on any failure (KEEP=1 keeps the temp dir)
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd); H=$HERE/../bin/harness F="node $HERE/../lib/features.mjs"
T=$(mktemp -d); [[ ${KEEP:-} ]] || trap 'rm -rf "$T"' EXIT; echo "tmp: $T"
export HARNESS_STATE=$T/state HARNESS_WORKTREES=$T/wt HARNESS_SCRATCH_ROOT=$T/scratch HARNESS_PAUSE_POLL=1 \
  HARNESS_CLAUDE=$HERE/stub-claude.sh HARNESS_GH=$HERE/stub-gh.sh STUB_DIR=$T HARNESS_LEDGER=$T/ledger \
  HARNESS_CONFIG=$T/user-config.sh HARNESS_LIMIT_SLEEP=0 HARNESS_NO_RUNNER=1 HARNESS_QUEUE_POLL=0 HARNESS_QUEUE_SETTLE=0
fails=0 total=0
check() { total=$((total + 1)); if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fails=$((fails + 1)); fi; }
hlog() { cat "$T/wt/proj/$1/.harness/runs/$1/harness-log.md" 2>/dev/null; }
list() { echo "$T/wt/proj/$1/.harness/runs/$1/feature_list.json"; }
on_main() { git -C "$T/origin.git" merge-base --is-ancestor "$(git -C "$T/origin.git" rev-parse "$1^{commit}")" main; }

echo 'LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"
git init -q --bare -b main "$T/origin.git"
git init -q -b main "$T/proj" && cd "$T/proj"
mkdir .harness && cat > .harness/config.sh <<'EOF'
CHECK_CMD="test ! -f BROKEN"
INIT_CMD="echo init ok"
BASE_PORT=7950
EOF
printf '# proj\nrules\n' > CLAUDE.md; echo spec > SPEC.md
git add -A && git commit -qm init && git remote add origin "$T/origin.git" && git push -q -u origin main

# ---- run 1: misbehaving sessions, two milestones; verified milestones merge themselves ----
"$H" start "$T/proj" demo --spec SPEC.md --brief "only A–C" --foreground > "$T/run1.out" 2>&1
WT=$T/wt/proj/demo RD=$T/wt/proj/demo/.harness/runs/demo
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
check "brief, rules and policy in the prompt" 'P=$HARNESS_STATE/proj/demo/prompt-coding.md; grep -q "only A–C" "$P" && grep -q "Project rules (CLAUDE.md)" "$P" && grep -q "Policy: build-only" "$P"'
check "metrics: wall time and roles"      'jq -e "select(.kind==\"coding\") | .wall_s != null and .role == \"build\"" "$RD/metrics.jsonl" > /dev/null'
check "ended: done; status says so"       'grep -q "^done" "$HARNESS_STATE/proj/demo/ended" && grep -q "ended: done" <<< "$("$H" status demo)"'
check "summary, report and retro written" '[[ $(jq .features.merged "$RD/summary.json") == 3 ]] && grep -q "per passing feature" "$RD/report.md" && grep -q "Stub retro" "$RD/retro.md"'
check "ledger has the run"                'grep -q "\"run\":\"demo\"" "$T/ledger/runs.jsonl" && [[ -f $T/ledger/proj/demo/summary.json ]]'
check "harness report prints the writeup" 'grep -q "Spend by role" <<< "$("$H" report demo)"'
check "init model resolved to fable"      'grep -q "initializer · claude-fable-5-1" "$HARNESS_STATE/proj/demo/run.log"'

# ---- gc: main has every milestone; only run-record commits are left on the branch ----
"$H" gc "$T/proj" > "$T/gc.out" 2>&1
check "gc removed the finished worktree"  '[[ ! -d $WT ]]'
check "gc deleted the run branch"         '! git -C "$T/origin.git" rev-parse -q --verify harness/demo >/dev/null'
check "gc kept the tags"                  'git -C "$T/origin.git" tag | grep -qx run/demo/M2'

# ---- run 2: Michael sets "status: stop" in INBOX.md from the phone ----
STUB_PHONE_STOP=1 "$H" start "$T/proj" stoppy --spec SPEC.md --foreground > "$T/run2.out" 2>&1
check "phone stop honoured before any coding session" 'hlog stoppy | grep -q "stopped by Michael" && ! grep -q attempt "$T/scratch/proj/stoppy/sessions.log"'
check "second run got its own port"       '[[ $(cat "$HARNESS_STATE/proj/stoppy/port") != $(cat "$HARNESS_STATE/proj/demo/port") ]]'

# ---- run 3: a verifier that always rejects; C is independent of M1 ----
STUB_STRICT_VERIFIER=1 STUB_INDEPENDENT_M2=1 "$H" start "$T/proj" strict --spec SPEC.md --foreground > "$T/run3.out" 2>&1
check "verify ping-pong capped, needs Michael" 'hlog strict | grep -q "M1 needs Michael" && (( $(grep -c "^A attempt" "$T/scratch/proj/strict/sessions.log") <= 2 ))'
check "independent M2 verified, not merged (M1 isn't)" 'git -C "$T/origin.git" tag | grep -qx run/strict/M2 && ! on_main run/strict/M2'

# ---- run 4: the same, but C depends on M1 (default): gated ----
STUB_STRICT_VERIFIER=1 "$H" start "$T/proj" gated --spec SPEC.md --foreground > "$T/run4.out" 2>&1
check "a given-up feature blocks what depends on it" 'grep -q "^blocked on A" "$HARNESS_STATE/proj/gated/ended" && ! grep -q "^C attempt" "$T/scratch/proj/gated/sessions.log"'

# ---- run 5: the real usage-limit message (2026-10-17) for 3 sessions, then a $0 no-work session ----
STUB_LIMIT_HITS=3 STUB_NOWORK=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 "$H" start "$T/proj" limited --spec SPEC.md --foreground > "$T/run5.out" 2>&1
check "real limit message: not counted, run completes" '[[ $(hlog limited | grep -c "hit a limit (You.ve hit your session limit") == 3 ]] && [[ $($F summary "$(list limited)") == "3/3 passing" ]]'
check "a \$0 one-turn session is not counted" 'hlog limited | grep -q "hit a limit (no work done"'
check "the limit window is shared"        '[[ -f $HARNESS_STATE/LIMIT_UNTIL ]]'
check "refused sessions recorded as env"  '(( $(jq -s "map(select(.env)) | length" "$T/wt/proj/limited/.harness/runs/limited/metrics.jsonl") == 4 ))'

# ---- run 6: a limit cuts a session off midway: work kept, attempt given back ----
STUB_LIMIT_MIDWAY=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" midway --spec SPEC.md --foreground > "$T/run6.out" 2>&1
check "mid-session limit: attempt given back, work kept" 'hlog midway | grep -q "hit a limit" && [[ $(jq -r .A "$HARNESS_STATE/proj/midway/attempts.json") == 1 ]] && [[ -f $T/wt/proj/midway/half-A.txt ]]'

# ---- run 7: a future window set by another run makes this one wait first ----
echo $(( $(date +%s) + 3600 )) > "$HARNESS_STATE/LIMIT_UNTIL"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" waiter --spec SPEC.md --foreground > "$T/run7.out" 2>&1
check "waits for another run's limit window" 'hlog waiter | grep -q "usage-limit window (shared by all runs): waiting"'
rm -f "$HARNESS_STATE/LIMIT_UNTIL"

# ---- run 8: thin verify evidence → one more verify on the stronger model ----
STUB_THIN_VERIFY=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" thin --spec SPEC.md --foreground > "$T/run8.out" 2>&1
check "thin evidence escalates the verify" 'hlog thin | grep -q "evidence short of the steps" && grep -q "verify M1 · claude-opus-5-5" "$HARNESS_STATE/proj/thin/run.log"'

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
"$H" merge later > "$T/run10b.out" 2>&1
check "harness merge merges verified milestones afterwards" 'on_main run/later/M2 && grep -q "^done" "$HARNESS_STATE/proj/later/ended"'

# ---- queue: start queues behind a running run; the runner runs entries in order ----
mkdir -p "$HARNESS_STATE/proj/busy" && echo $$ > "$HARNESS_STATE/proj/busy/driver.pid" && printf 'WT=/x\nRUN_ID=busy\nSTATE=%s\nPROJECT_DIR=/x\n' "$HARNESS_STATE/proj/busy" > "$HARNESS_STATE/proj/busy/meta.env"
check "start queues when MAX_PARALLEL_RUNS are going" 'grep -q "is queued" <<< "$("$H" start "$T/proj" --spec SPEC.md)"'
check "continue refuses a running run"     '! "$H" continue busy 2> "$T/busy.err" && grep -q "is running" "$T/busy.err"'
rm -rf "$HARNESS_STATE/proj/busy"
"$H" queue add "$T/proj" --spec SPEC.md > /dev/null
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$T/queue.out" 2>&1
D=$(date +%F)
check "queue ran both entries, distinct run ids" '[[ $($F summary "$(list proj-$D)") == "3/3 passing" && $($F summary "$(list proj-$D-2)") == "3/3 passing" ]] && grep -q "queue empty" "$HARNESS_STATE/queue/runner.log"'
check "trends lists every run"            'grep -q "| proj-$D-2 | proj |" <<< "$("$H" trends)"'
DB=$T/debriefs.log Q=$HARNESS_STATE/queue
check "queue end triggers one debrief"    '[[ $(grep -c . "$DB") == 1 ]] && compgen -G "$T/ledger/debriefs/*.md" > /dev/null && grep -q "debrief written" "$Q/runner.log"'
check "the debrief saw the queue's runs"  'grep -q "### proj-$D-2 (proj)" "$T/debrief-prompt" && grep -q "### proj-$D (proj)" "$T/debrief-prompt"'
"$H" debrief --if-missed > "$T/missed1.out" 2>&1
check "--if-missed: no-op after the queue's own debrief" '[[ $(grep -c . "$DB") == 1 ]] && grep -q "already debriefed" "$T/missed1.out"'
sleep 1; HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$T/queue2.out" 2>&1
check "a runner that started nothing: no debrief" '[[ $(grep -c . "$DB") == 1 ]] && grep -q "queue empty" "$T/queue2.out"'
"$H" debrief --if-missed > "$T/missed2.out" 2>&1
check "--if-missed: no-op when the last runner started nothing" '[[ $(grep -c . "$DB") == 1 ]] && grep -q "no runs started" "$T/missed2.out"'

# ---- run 11: a verify refused by the usage limit is deferred, never a "holds" ----
STUB_VERIFY_LIMIT=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" vlimit --spec SPEC.md --foreground > "$T/run11.out" 2>&1
check "refused verify: deferred, then verified, then merged" 'hlog vlimit | grep -q "verify M1 refused" && [[ $(hlog vlimit | grep -n "verify M1 refused" | cut -d: -f1) -lt $(hlog vlimit | grep -n "M1 verified and tagged" | cut -d: -f1) ]] && on_main run/vlimit/M1'

# ---- run 12: a session claims its feature, then the limit cuts it off: the claim is reverted ----
STUB_PASS_THEN_LIMIT=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" claim --spec SPEC.md --foreground > "$T/run12.out" 2>&1
check "a limit-cut session's passes is reverted, A retried" 'grep -q "A attempt 2" "$T/scratch/proj/claim/sessions.log" && grep -qx "HARNESS: usage limit" <<< "$(git -C "$T/wt/proj/claim" log --format=%s -- .harness/runs/claim/feature_list.json)"'

# ---- run 13: verify and retro may not change code ----
STUB_VERIFY_EDITS=1 STUB_RETRO_EDITS=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" meddle --spec SPEC.md --foreground > "$T/run13.out" 2>&1
check "verifier code edits reverted, never merged" 'hlog meddle | grep -q "reverted code edits the verifier may not make" && ! git -C "$T/origin.git" show main:hack-M1.txt > /dev/null 2>&1 && ! git -C "$T/origin.git" show main:CLAUDE.md | grep -q edited'
check "retro edits reverted"              'hlog meddle | grep -q "retro: reverted" && [[ ! -f $T/wt/proj/meddle/retro-hack.txt ]]'

# ---- run 14: v2-style tags don't merge on a resume; `harness merge` merges them ----
echo 'LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1 MERGE_POLICY=off' > "$T/user-config.sh"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" legacy --spec SPEC.md --foreground > "$T/run14.out" 2>&1
echo 'LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"
for m in M1 M2; do git -C "$T/wt/proj/legacy" tag -f -a "run/legacy/$m" "run/legacy/$m^{commit}" -m "harness run legacy: $m verified" > /dev/null
  git -C "$T/wt/proj/legacy" push -q -f origin "run/legacy/$m"; done
mkdir -p "$T/prs" && touch "$T/prs/branch-harness_legacy"   # its v2 whole-run PR
"$H" continue legacy --foreground > "$T/run14b.out" 2>&1
check "v2 tags don't merge on resume"     'hlog legacy | grep -q "verified by harness v2" && ! on_main run/legacy/M1 && [[ -f $T/prs/branch-harness_legacy ]]'
"$H" merge legacy > "$T/run14c.out" 2>&1
check "harness merge merges v2 tags, closes the v2 PR" 'on_main run/legacy/M2 && [[ ! -f $T/prs/branch-harness_legacy ]]'

# ---- run 15: a resumed run reloads its configuration after merging main (here: a new POLICY) ----
STUB_PHONE_STOP=1 "$H" start "$T/proj" flip --spec SPEC.md --foreground > "$T/run15.out" 2>&1
(cd "$T/proj" && git pull -q origin main && echo "POLICY=live-staged" >> .harness/config.sh && git commit -qam "policy: live-staged" && git push -q origin main)
"$H" continue flip --foreground > "$T/run15b.out" 2>&1
check "resume reloads config merged from main" 'hlog flip | grep -q "configuration reloaded after merging main: policy live-staged"'

# ---- debrief: a runner that died without one; --dry-run, --if-missed, continuations, notification, limits ----
printf '%s\n' 'LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' "NOTIFY_CMD='printf \"%s\\n===\\n\" \"\$1\" >> \"$T/notify.log\"'" > "$T/user-config.sh"
sleep 1; echo "$(date '+%F %T') runner up · MAX_PARALLEL_RUNS=1" >> "$Q/runner.log"   # …and then it was killed
echo "$(date '+%F %T') run stoppy on harness/stoppy in $T/wt/proj/stoppy · port 7951" >> "$HARNESS_STATE/proj/stoppy/run.log"
echo "deadline · $(date '+%F %T')" > "$HARNESS_STATE/proj/stoppy/ended"
"$H" debrief --dry-run > "$T/dry.out" 2>&1
check "--dry-run prints the context, launches nothing" '[[ $(grep -c . "$DB") == 1 && -f $(head -1 "$T/dry.out") ]] && grep -q "^## harness status" "$T/dry.out" && grep -q "^### stoppy (proj)" "$T/dry.out" && grep -q "ended: deadline" "$T/dry.out" && grep -q "runner up" "$T/dry.out"'
STUB_DEBRIEF_CONTINUE=1 "$H" debrief --if-missed > "$T/missed3.out" 2>&1
N=$(ls -t "$T/ledger/debriefs/"*.md | head -1)
check "--if-missed fires after a runner that never debriefed" '[[ $(grep -c . "$DB") == 2 ]] && grep -q "stub runs" "$N"'
check "the session carries the never-list as disallowed tools" 'A=$T/debrief-args; grep -qx -- --disallowedTools "$A" && grep -qx Edit "$A" && grep -qx Write "$A" && grep -qxF "Bash(git push:*)" "$A" && grep -qxF "Bash(gh pr merge:*)" "$A" && grep -qxF "Bash(harness queue start:*)" "$A" && grep -qxF "Bash(harness merge:*)" "$A" && grep -qxF "Bash(harness continue:*)" "$A" && grep -qx "$($F model sonnet)" "$A"'
check "continuation queued for a run out of time" 'f=$(compgen -G "$Q/*-continue-stoppy.args") && grep -qx "do C next" "$f" && grep -q "Queued: .*stoppy" "$N" && ! grep -q "debrief: queued" "$N"'
check "no continuation for an ineligible run" '! compgen -G "$Q/*-continue-demo.args" > /dev/null && grep -q "Not queued: demo" "$N" && ! grep -q "^CONTINUE:" "$N"'
check "NOTIFY_CMD gets 3 headline lines and the note path" 'M=$(sed "/^===$/q" "$T/notify.log" | grep -v "^===$"); (( $(wc -l <<< "$M") <= 4 )) && grep -q "Landed: proj M1" <<< "$M" && grep -qF "$N" <<< "$M" && ! grep -q FOURTH <<< "$M"'
"$H" debrief --if-missed > "$T/missed4.out" 2>&1
check "--if-missed: no-op once debriefed" '[[ $(grep -c . "$DB") == 2 ]] && grep -q "already debriefed" "$T/missed4.out"'
echo $$ > "$Q/runner.pid"; echo $(( $(date +%s) - 600 )) > "$Q/runner.until"   # a runner still going
"$H" debrief --if-missed > "$T/missed5.out" 2>&1
check "--if-missed: a runner within 1 h of its --until is left alone" '[[ $(grep -c . "$DB") == 2 ]] && grep -q "still running" "$T/missed5.out"'
echo $(( $(date +%s) - 7200 )) > "$Q/runner.until"
"$H" debrief --if-missed > "$T/missed6.out" 2>&1
N=$(ls -t "$T/ledger/debriefs/"*.md | head -1)
check "--if-missed: a stuck runner gets a 'queue looks stuck' debrief" '[[ $(grep -c . "$DB") == 3 ]] && grep -qi "queue looks stuck" "$N" && grep -qi "queue looks stuck" "$T/debrief-prompt" && tail -n 6 "$T/notify.log" | grep -qi "queue looks stuck"'
rm -f "$Q/runner.pid" "$Q/runner.until"
echo $(( $(date +%s) + 3600 )) > "$HARNESS_STATE/LIMIT_UNTIL"
"$H" debrief > "$T/limit1.out" 2>&1
check "debrief waits for the usage-limit window, then runs" 'grep -q "usage-limit window" "$T/limit1.out" && [[ $(grep -c . "$DB") == 4 ]]'
echo $(( $(date +%s) + 6 * 3600 )) > "$HARNESS_STATE/LIMIT_UNTIL"
"$H" debrief > "$T/limit2.out" 2>&1
check "a window past the 5 h cap: no session, left to the fallback" 'grep -q "5 h cap" "$T/limit2.out" && [[ $(grep -c . "$DB") == 4 ]]'
rm -f "$HARNESS_STATE/LIMIT_UNTIL"
check "fallback timer units: daily 09:00, --if-missed" 'U=$HERE/../contrib/systemd; grep -q "OnCalendar=.*09:00" "$U/harness-debrief.timer" && grep -q "harness debrief --if-missed" "$U/harness-debrief.service"'

(( fails )) && { echo "--- run1 output"; tail -30 "$T/run1.out"; echo "--- harness-log"; hlog demo; }
echo "$(( total - fails ))/$total checks passed"
exit $(( fails > 0 ))
