#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- entries that survive (R2): the session checks its own entry, ends with no background work, and a long summary is
# trimmed at the ingest instead of dropping the entry (docs/plans/2026-10-29-R2-entries.md) ----
STUB_LONG_SUMMARY=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" longsum --spec SPEC.md --foreground > "$T/longsum.out" 2>&1
for t in coding verify initializer; do bash "$HERE/../lib/prompt.sh" "$HARNESS_STATE/proj/longsum" "$t" A > "$T/prompt-$t.md" 2> "$T/prompt-$t.err"; done
check "entries survive: {{ENTRY_CHECK}} renders as lib/entries.mjs validate in the coding, verify and initializer prompts" 'ok=1; for t in coding verify initializer; do
    grep -E "node [^ ]*/lib/entries\.mjs validate " "$T/prompt-$t.md" > /dev/null && ! grep -F "{{ENTRY_CHECK}}" "$T/prompt-$t.md" > /dev/null || { echo "no entry check in $t"; ok=0; }; done; (( ok ))'
check "entries survive: the coding, verify and initializer prompts say no background work at the end" 'ok=1; for t in coding verify initializer; do
    grep -E "Never end your turn while a background task or subagent is still running" "$HERE/../prompts/$t.md" > /dev/null || { echo "no rule in $t"; ok=0; }; done; (( ok ))'
check "entries survive: STUB_LONG_SUMMARY=A keeps A's entry whole with the cut-to-400 note" 'hlog longsum | grep -E " · A: entry\.json summary 410 characters; cut to 400 and kept$" > /dev/null \
  && jq -se "map(select(.feature == \"A\"))[0] | (.minimal | not) and (.summary | length) == 400 and (.summary | startswith(\"A: x\")) and (.summary | endswith(\"…\"))" \
    "$T/wt/proj/longsum/.harness/runs/longsum/entries.jsonl" > /dev/null'

# The stub run directly (R2-03): its own repo, origin and STUB_DIR, so the stub runs above and below keep $T's resume.log
D=$T/direct; mkdir -p "$D/stub" "$D/scratch" && git init -q --bare -b main "$D/origin.git" && git init -q -b main "$D/wt" && (cd "$D/wt"
  mkdir -p run && echo '{ "run": "direct", "features": [ { "id": "A", "kind": "build", "description": "a", "steps": ["x"], "passes": false } ] }' > run/feature_list.json
  git add -A && git -c user.name=t -c user.email=t@test commit -qm init && git remote add origin "$D/origin.git" && git push -q -u origin main)
direct() { (cd "$D/wt" && STUB_DIR=$D/stub HARNESS_RUN_DIR=run HARNESS_SCRATCH=$D/scratch HARNESS_BRANCH=main GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@test \
  GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@test "$HERE/stub-claude.sh" -p "$1" --output-format stream-json --verbose "${@:2}"); }
CODING=$'# Coding session\n\nwork\n\n# This session\n\nFeature: `A`\n'
STUB_NO_ENTRY=A direct "$CODING" > "$D/first.jsonl" 2> "$D/first.err"; echo "$?" > "$D/first.exit"
SID=$(jq -r 'select(.type == "system" and .subtype == "init").session_id' "$D/first.jsonl" 2> /dev/null)
direct $'# Entry resume\n\nwrite it\n\n# This session\n\nFeature: `A`\nKind: `coding`\n' --resume "$SID" > "$D/resumed.jsonl" 2> "$D/resumed.err"; echo "$?" > "$D/resumed.exit"
direct $'# Entry resume\n\n# This session\n\nFeature: `A`\nKind: `coding`\n' --resume 00000000-0000-0000-0000-000000000001 > "$D/unknown.out" 2> "$D/unknown.err"; echo "$?" > "$D/unknown.exit"
U=$HERE/fixtures/claude-resume
check "entries survive: a headless stub session prints an init line with a 36-character session id" '[[ $(jq -sr "map(select(.type == \"system\" and .subtype == \"init\")) | length" "$D/first.jsonl") == 1 ]] \
  && [[ $SID =~ ^[0-9a-f-]{36}$ ]] && [[ $(head -1 "$D/first.jsonl" | jq -r ".subtype") == init ]] && [[ $(cat "$D/first.exit") == 0 ]]'
check "entries survive: the stub answers --resume of an unknown id with the CLI's two lines and exit 1" '[[ $(cat "$D/unknown.exit") == 1 ]] \
  && diff <(sed -n 1p "$U/unknown-id.out" | sed "s/00000000-0000-0000-0000-000000000000/00000000-0000-0000-0000-000000000001/") "$D/unknown.err" \
  && diff <(sed -n 2p "$U/unknown-id.out" | sed "s/00000000-0000-0000-0000-000000000000/00000000-0000-0000-0000-000000000001/") "$D/unknown.out" \
  && grep -F -- "--resume 00000000-0000-0000-0000-000000000001" "$D/stub/resume.log" > /dev/null && [[ $(wc -l < "$D/stub/resume.log") == 2 ]]'
check "entries survive: the stub's resume keeps the session id and a cumulative total_cost_usd" '[[ $(cat "$D/resumed.exit") == 0 ]] \
  && [[ $(jq -r "select(.type == \"system\" and .subtype == \"init\").session_id" "$D/resumed.jsonl") == "$SID" ]] \
  && jq -ne --slurpfile a "$D/first.jsonl" --slurpfile b "$D/resumed.jsonl" --slurpfile f "$U/first.jsonl" --slurpfile r "$U/resumed.jsonl" "def c(x): x | map(select(.type == \"result\"))[-1].total_cost_usd;
      def u(x): x | map(select(.type == \"result\"))[-1].modelUsage | [.[]] | map(.cacheReadInputTokens) | add;
      c(\$b) == c(\$a) + (c(\$r) - c(\$f)) and c(\$b) > c(\$a) and u(\$b) == u(\$a) + (\$r | map(select(.type == \"result\"))[0].usage.cache_read_input_tokens)" > /dev/null'
check "entries survive: STUB_NO_ENTRY=A writes no entry.json" '[[ ! -e $D/wt/run/entry.json ]] && grep -F "A attempt 1" "$D/scratch/sessions.log" > /dev/null'

# The resume (R2-04): a stub run per case, main reset between them, each run's resume.log kept as resume-<run>.log
main0=$(git -C "$T/origin.git" rev-parse main)
rrun() { local r=$1; shift; rm -f "$T/resume.log"; env "$@" STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" "$r" --spec SPEC.md --foreground > "$T/$r.out" 2>&1
  [[ -e $T/resume.log ]] && mv "$T/resume.log" "$T/resume-$r.log"; git -C "$T/origin.git" update-ref refs/heads/main "$main0"; }
rrun rlimit STUB_LIMIT_MIDWAY=1
rrun rgood STUB_NO_ENTRY=A STUB_RESUME_ENTRY=good
rrun rplain
rrun rbad STUB_NO_ENTRY=A STUB_RESUME_ENTRY=bad
rrun redits STUB_NO_ENTRY=A STUB_RESUME_ENTRY=good-edits
RL=$HARNESS_STATE/proj/rgood/logs
tj() { jq -Rr "fromjson? | $1" "$2"; }   # <filter> <transcript>: its JSON lines only (stderr shares the file)
ent() { jq -sc "map(select(.feature == \"A\"))[0]" "$T/wt/proj/$1/.harness/runs/$1/entries.jsonl"; }
check "entries survive: STUB_NO_ENTRY=A is resumed once with the init line's session id, beside 01-A.resume.jsonl" '[[ $(grep -c -- "--resume" "$T/resume-rgood.log") == 1 ]] \
  && sid=$(tj "select(.type == \"system\" and .subtype == \"init\").session_id" "$RL/01-A.jsonl") && [[ $sid =~ ^[0-9a-f-]{36}$ ]] \
  && grep -F -- "--resume $sid" "$T/resume-rgood.log" > /dev/null && [[ -s $RL/01-A.resume.jsonl && -s $RL/01-A.resume.prompt.md ]] \
  && [[ $(head -1 "$RL/01-A.resume.prompt.md") == "# Entry resume" ]] && grep -E -- "--max-turns 8 .*--resume $sid" "$T/resume-rgood.log" > /dev/null'
check "entries survive: the resumed entry has its dead_ends, no minimal, and the written-on-a-resume note" 'ent rgood | jq -e "(.dead_ends | length) == 1 and (.minimal | not)" > /dev/null \
  && hlog rgood | grep -E " · A: entry\.json written on a resume$" > /dev/null'
check "entries survive: one entry-resume metrics row for A holds the resume's cost minus the session's" 'jq -se --argjson s "$(tj "select(.type == \"result\").total_cost_usd" "$RL/01-A.jsonl" | tail -1)" \
    --argjson r "$(tj "select(.type == \"result\").total_cost_usd" "$RL/01-A.resume.jsonl" | tail -1)" "map(select(.kind == \"entry-resume\")) as \$m
    | (\$m | length) == 1 and \$m[0].feature == \"A\" and \$m[0].role == \"coding\" and \$m[0].cost_usd == \$r - \$s and \$m[0].cost_usd > 0" \
    "$T/wt/proj/rgood/.harness/runs/rgood/metrics.jsonl" > /dev/null'
check "entries survive: a resume leaves summary.json's session count as the same run without it" 'a=$(jq -r .sessions.total "$HARNESS_STATE/proj/rgood/summary.json") \
  && b=$(jq -r .sessions.total "$HARNESS_STATE/proj/rplain/summary.json") && [[ $a =~ ^[0-9]+$ && $a == "$b" ]] && [[ ! -e $T/resume-rplain.log ]] \
  && jq -e ".cost.total > 0" "$HARNESS_STATE/proj/rgood/summary.json" > /dev/null'
check "entries survive: STUB_RESUME_ENTRY=bad is minimal with the after-one-resume note" 'ent rbad | jq -e ".minimal | startswith(\"invalid\")" > /dev/null \
  && hlog rbad | grep -E " · A: entry\.json still invalid \(not JSON: .*\) after one resume; recorded a minimal entry$" > /dev/null'
check "entries survive: a session refused by a usage limit is not resumed (no resume.log)" 'hlog rlimit | grep "hit a limit" > /dev/null && [[ ! -e $T/resume-rlimit.log ]]'
check "entries survive: a resume's edit outside the run record is in no commit and the entry is still written" '[[ -s $T/resume-redits.log ]] \
  && [[ -z $(git -C "$T/origin.git" log --all --oneline -- resumed.txt) && -z $(git -C "$T/proj" log --all --oneline -- resumed.txt) ]] \
  && ent redits | jq -e "(.dead_ends | length) == 1 and (.minimal | not)" > /dev/null && hlog redits | grep -E " · A: entry\.json written on a resume$" > /dev/null'

suite_end
