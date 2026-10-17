#!/usr/bin/env bash
# End-to-end test of the driver and CLI with stub claude/gh, a throwaway project and a local bare "origin".
#   tests/run.sh        → prints PASS/FAIL per check, exit 1 on any failure
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd); H=$HERE/../bin/harness
T=$(mktemp -d); [[ ${KEEP:-} ]] || trap 'rm -rf "$T"' EXIT; echo "tmp: $T"
export HARNESS_STATE=$T/state HARNESS_WORKTREES=$T/wt HARNESS_SCRATCH_ROOT=$T/scratch HARNESS_PAUSE_POLL=1 \
  HARNESS_CLAUDE=$HERE/stub-claude.sh HARNESS_GH=$HERE/stub-gh.sh STUB_DIR=$T
fails=0
check() { if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fails=$((fails + 1)); fi; }

git init -q --bare -b main "$T/origin.git"
git init -q -b main "$T/proj" && cd "$T/proj"
mkdir .harness && cat > .harness/config.sh <<'EOF'
SPEC_FILES="SPEC.md"
CHECK_CMD="test ! -f BROKEN"
INIT_CMD="echo init ok"
BASE_PORT=7950
HOURS=1 MAX_SESSIONS=12
EOF
echo "# rules" > .harness/project.md; echo spec > SPEC.md
git add -A && git commit -qm init && git remote add origin "$T/origin.git" && git push -q -u origin main

# ---- run 1: misbehaving sessions, two milestones ----
"$H" start "$T/proj" demo --foreground > "$T/run1.out" 2>&1
WT=$T/wt/proj/demo RD=$T/wt/proj/demo/.harness/runs/demo
L=$RD/feature_list.json
check "all features pass"                 '[[ $(node "$HERE/../lib/features.mjs" summary "$L") == "3/3 passing" ]]'
check "tampered list restored"            'grep -q "restored the feature list after B" "$RD/harness-log.md"'
check "tampered text reverted"            '[[ $(jq -r ".features[2].description" "$L") == c ]]'
check "red suite un-passes C"             'grep -q "C un-passed: suite red" "$RD/harness-log.md"'
check "C retried and passed"              'grep -q "C attempt 2" "$T/scratch/proj/demo/sessions.log"'
check "verifier caught A, re-queued"      'grep -q "verify M1: A failed the re-check" "$RD/harness-log.md" && grep -q "A attempt 2" "$T/scratch/proj/demo/sessions.log"'
check "M1 and M2 verified + tagged"       'git -C "$T/origin.git" tag | grep -qx run/demo/M1 && git -C "$T/origin.git" tag | grep -qx run/demo/M2'
check "one PR created, then refreshed"    '[[ $(grep -c "pr create" "$T/gh.log") == 1 ]] && grep -q "pr edit" "$T/gh.log"'
check "main untouched by the harness"     '[[ $(git -C "$T/origin.git" rev-list --count main) == 1 ]]'
check "run branch pushed and complete"    '[[ $(git -C "$T/origin.git" rev-parse harness/demo) == $(git -C "$WT" rev-parse HEAD) ]]'
check "metrics recorded per session"      '(( $(wc -l < "$RD/metrics.jsonl") >= 8 ))'
check "cost summary in the log"           'grep -q "sessions · 3 features passed · [$]" "$RD/harness-log.md"'
check "init model resolved to fable"      'grep -q "initializer · claude-fable-5-1" "$HARNESS_STATE/proj/demo/run.log"'

# ---- Michael merges the PR; gc cleans up ----
git -C "$T/proj" fetch -q origin && git -C "$T/proj" merge -q --no-edit origin/harness/demo && git -C "$T/proj" push -q origin main
"$H" gc "$T/proj" > "$T/gc.out" 2>&1
check "gc removed the merged worktree"    '[[ ! -d $WT ]]'
check "gc deleted the branch everywhere"  '! git -C "$T/proj" rev-parse -q --verify harness/demo >/dev/null && ! git -C "$T/origin.git" rev-parse -q --verify harness/demo >/dev/null'
check "gc kept the tags"                  'git -C "$T/origin.git" tag | grep -qx run/demo/M2'

# ---- run 2: Michael sets "status: stop" in INBOX.md from the phone ----
STUB_PHONE_STOP=1 "$H" start "$T/proj" stoppy --foreground > "$T/run2.out" 2>&1
check "phone stop honoured before any coding session" 'grep -q "stopped by Michael" "$T/wt/proj/stoppy/.harness/runs/stoppy/harness-log.md" && [[ ! -f $T/scratch/proj/stoppy/sessions.log ]]'
check "second run got its own port"       '[[ $(cat "$HARNESS_STATE/proj/stoppy/port") != $(cat "$HARNESS_STATE/proj/demo/port") ]]'

# ---- run 3: a verifier that always rejects must not loop forever ----
STUB_STRICT_VERIFIER=1 "$H" start "$T/proj" strict --foreground > "$T/run3.out" 2>&1
R3=$T/wt/proj/strict/.harness/runs/strict
check "verify ping-pong capped, needs Michael" 'grep -q "M1 needs Michael" "$R3/harness-log.md" && (( $(grep -c "^A attempt" "$T/scratch/proj/strict/sessions.log") <= 2 ))'
check "M2 still done after M1 stalls"     'git -C "$T/origin.git" tag | grep -qx run/strict/M2'

(( fails )) && { echo "--- run1 output"; tail -30 "$T/run1.out"; echo "--- harness-log"; cat "$RD/harness-log.md" 2>/dev/null; }
echo "$(( 20 - fails ))/20 checks passed"
exit $(( fails > 0 ))
