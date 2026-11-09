#!/usr/bin/env bash
# tier: slow
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the curator (M2-03): one read-only session after the retro and before the record PR, under MEMORY_POLICY ----
# The base config sets MEMORY_POLICY=off (a curator on every stub run would move other files' counts); this file sets pr
# per run. The four pr cases share one run (cu); [], bad and off are three more. Each run gets its own gh.log.
st() { echo "$HARNESS_STATE/proj/$1"; }
rec() { echo "$T/wt/proj/$1/.harness/runs/$1"; }
rline() { grep -n -m1 -E -- "$2" "$(st "$1")/run.log" | cut -d: -f1; }   # <run> <ERE>: run.log's first line matching
titles() { cat "$T"/prs/pr-*.title 2> /dev/null; }
main0=$(git -C "$T/origin.git" rev-parse main)
cp "$T/base-config.sh" "$T/user-config.sh" && echo 'MEMORY_POLICY=pr RECORD_PR=end' >> "$T/user-config.sh"

# cu: the curator edits CLAUDE.md and lib/ and writes three ops
STUB_CURATOR_EDITS=1 STUB_CURATOR_OPS=three-ops STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" cu --spec SPEC.md --foreground > "$T/cu.out" 2>&1
mv "$T/gh.log" "$T/gh-cu.log" 2> /dev/null
E=$(rec cu)/entries.jsonl; la=$(jq -s 'map(.feature == "A" and .kind == "coding") | index(true) + 1' "$E" 2> /dev/null) lb=$(jq -s 'map(.feature == "B" and .kind == "coding") | index(true) + 1' "$E" 2> /dev/null)
cday=$(sed -n 's/^done · \([0-9-]*\) .*/\1/p' "$(st cu)/ended")   # the day finish began, as the curator saw it (a run over midnight)
sed -e "s/{{RUN}}/cu/g" -e "s/{{DATE}}/$cday/g" -e "s/{{LINE:A}}/$la/g" -e "s/{{LINE:B}}/$lb/g" "$HERE/fixtures/memory/stub-three-ops.json" > "$T/cu-ops.json"
check "curator: a run under MEMORY_POLICY=pr ends done with one zz-curator transcript and a curator metrics row" \
  'grep -q "^done" "$(st cu)/ended" && [[ $(ls "$(st cu)"/logs/zz-curator-*.jsonl 2> /dev/null | wc -l) == 1 ]] \
  && [[ $(jq -s "map(select(.role == \"curator\" and .kind == \"curator\")) | length" "$(rec cu)/metrics.jsonl") == 1 ]]'
check "curator: its run.log line comes after the retro's, its notes before the record PR's" \
  'r=$(rline cu "[0-9] retro · ") c=$(rline cu "[0-9] curator · ") n=$(ats cu " · curator: ") p=$(ats cu " · record PR "); [[ -n $r && -n $c && -n $n && -n $p ]] && (( r < c && n < p ))'
check "curator: memory-ops.json is kept in the run record" \
  '[[ $la =~ ^[0-9]+$ && $lb =~ ^[0-9]+$ ]] && (( la > 1 && lb > 1 )) && git -C "$T/origin.git" show harness/cu:.harness/runs/cu/memory-ops.json > "$T/cu-kept.json" && cmp -s "$T/cu-ops.json" "$T/cu-kept.json"'
check "curator: a curator's edits to CLAUDE.md and lib/ are reverted with one note, its memory-ops.json kept and the record PR opened" \
  '[[ $(hlog cu | grep -c " · curator: reverted edits (it is read-only): ") == 1 ]] && hlog cu | grep -x -- "- .* · curator: reverted edits (it is read-only): CLAUDE.md lib/curator-hack.sh" > /dev/null \
  && git -C "$T/origin.git" show harness/cu:.harness/runs/cu/retro.md > /dev/null 2>&1 \
  && ! git -C "$T/origin.git" show harness/cu:lib/curator-hack.sh > /dev/null 2>&1 && ! git -C "$T/origin.git" show harness/cu:CLAUDE.md 2> /dev/null | grep -F "curator was here" > /dev/null \
  && [[ ! -e $T/wt/proj/cu/lib/curator-hack.sh ]] && ! hlog cu | grep " · curator: reverted edits" | grep -F memory-ops.json > /dev/null && [[ -s $(rec cu)/memory-ops.json ]] \
  && titles | grep -x "cu: run record" > /dev/null && ! hlog cu | grep -F "record PR: none (" > /dev/null'
check "curator: the rendered prompt names memory-ops.json, the three ops, the write gate and that it writes no project file" \
  'P=$(st cu)/prompt-curator.md; grep -F ".harness/runs/cu/memory-ops.json" "$P" > /dev/null && grep -F "/memory-base/CLAUDE.md" "$P" > /dev/null && grep -F "\"add\"|\"replace\"|\"delete\"" "$P" > /dev/null && grep -F "write gate" "$P" > /dev/null \
  && grep -F "never a file" "$P" > /dev/null && [[ $(grep -c "{{" "$P") == 0 ]]'

# ce: an empty list
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
STUB_CURATOR_OPS='[]' STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" ce --spec SPEC.md --foreground > "$T/ce.out" 2>&1
mv "$T/gh.log" "$T/gh-ce.log" 2> /dev/null
check "curator: an empty memory-ops.json notes no operations; no memory branch, no memory PR" \
  '[[ $(hlog ce | grep -c " · curator: no operations$") == 1 ]] && [[ -z $(git -C "$T/origin.git" ls-remote --heads . "harness-memory/ce") ]] && ! titles | grep "^memory: " > /dev/null'
HARNESS_TTY=0 "$H" report ce > "$T/ce-report.out" 2>&1; HARNESS_TTY=0 "$H" memory > "$T/ce-memory.out" 2>&1; mv "$T/gh.log" "$T/gh-ce-memory.log" 2> /dev/null
check "curator: an empty memory-ops.json counts zeros and PR none (summary.json, the Memory row), and harness memory lists no PR for it" \
  'jq -e ".memory == {ops: 0, applied: 0, dropped: 0, proposed: 0, pr: null, rules: 0, rules_pr: null, sections: {facts: [], rules: []}}" "$(rec ce)/summary.json" > /dev/null \
  && grep -xF "| Memory | 0 applied · 0 rules · 0 dropped · 0 proposals · PR none · rules PR none |" "$T/ce-report.out" > /dev/null \
  && [[ $(cat "$T/ce-memory.out") == "(none)" ]] && ! grep -F "\"run\":\"ce\"" "$T/ledger/memory.jsonl" > /dev/null 2>&1'

# cb: not JSON
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
STUB_CURATOR_OPS=bad STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" cb --spec SPEC.md --foreground > "$T/cb.out" 2>&1
mv "$T/gh.log" "$T/gh-cb.log" 2> /dev/null
check "curator: an invalid memory-ops.json is one note; the run ends done and its record PR opens" \
  '[[ $(hlog cb | grep -c " · curator: memory-ops.json invalid: not JSON") == 1 ]] && grep -q "^done" "$(st cb)/ended" && titles | grep -x "cb: run record" > /dev/null'

# co: MEMORY_POLICY=off (the memory gate's notes, lib/scope.sh, are not the curator's)
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
cp "$T/base-config.sh" "$T/user-config.sh" && echo 'MEMORY_POLICY=off' >> "$T/user-config.sh"
STUB_CURATOR_OPS=three-ops STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" co --spec SPEC.md --foreground > "$T/co.out" 2>&1
check "curator: MEMORY_POLICY=off runs no curator and writes no curator or memory note" \
  'grep -q "^done" "$(st co)/ended" && ! grep " curator · " "$(st co)/run.log" > /dev/null && ! grep -x curator "$T/scratch/proj/co/sessions.log" > /dev/null \
  && ! hlog co | grep -E " · (curator|memory)" | grep -vE " · memory(: [0-9]+ GB| still at )" > /dev/null && grep -x retro "$T/scratch/proj/co/sessions.log" > /dev/null'

# cx: a MEMORY_POLICY that is none of the three: one note, then the curator as under pr (the safe value)
git -C "$T/origin.git" update-ref refs/heads/main "$main0"
cp "$T/base-config.sh" "$T/user-config.sh" && echo 'MEMORY_POLICY=always RECORD_PR=end' >> "$T/user-config.sh"
STUB_CURATOR_OPS=three-ops STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" cx --spec SPEC.md --foreground > "$T/cx.out" 2>&1
mv "$T/gh.log" "$T/gh-cx.log" 2> /dev/null
check "curator: an unknown MEMORY_POLICY is one note and the curator runs as under pr" \
  'grep -q "^done" "$(st cx)/ended" && [[ $(hlog cx | grep -c " · memory PR: MEMORY_POLICY=always is none of pr, auto, off; treated as pr$") == 1 ]] \
  && [[ $(grep -cx curator "$T/scratch/proj/cx/sessions.log") == 1 ]] && hlog cx | grep " · memory: 3 ops · " > /dev/null \
  && ! hlog cx | grep -F " · memory PR merged" > /dev/null'

suite_end
