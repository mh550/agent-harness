#!/usr/bin/env bash
# tier: slow
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the memory PRs (M2-04, N1-01): the curator's ops applied from main's texts, tier 1 one commit under the cap on
# harness-memory/<run> (`memory: <run>`), tier 2 one commit on harness-rules/<run> (`memory rules: <run>`, never merged by
# the driver), tier 3 and every dropped op in both bodies ----
# Origin's main gets a CLAUDE.md with Code rules, Live system and Gotchas (3 lines; 15 for the cap runs) before each run.
# mp carries the three ops (two facts, one rule) and its continue; mq meets a rules branch it would not write; mx's continue meets a main that moved; mc drops its 16th add at the cap and lands its replace; me evicts, with a Live system op and an
# unmatched anchor beside it; mn, mk, mf and mz meet a memory branch already on origin. Each run gets its own gh.log.
st() { echo "$HARNESS_STATE/proj/$1"; }
rec() { echo "$T/wt/proj/$1/.harness/runs/$1"; }
titles() { cat "$T"/prs/pr-*.title 2> /dev/null; }
mpr() { local f; f=$(grep -lx "memory: $1" "$T"/prs/pr-*.title 2> /dev/null | head -1); [[ -n $f ]] && echo "${f%.title}"; }   # <run> → prs/pr-N of its memory PR
rpr() { local f; f=$(grep -lx "memory rules: $1" "$T"/prs/pr-*.title 2> /dev/null | head -1); [[ -n $f ]] && echo "${f%.title}"; }   # <run> → prs/pr-N of its rules PR
url() { echo "https://example.test/pr/${1##*-}"; }   # prs/pr-N → its URL
gotchas() { sed -n '/^## Gotchas$/,/^## /{/^- /p}'; }   # a CLAUDE.md on stdin → its Gotchas lines
lineof() { jq -s --arg i "$2" 'map(.feature == $i and .kind == "coding") | (index(true) // -1) + 1' "$(rec "$1")/entries.jsonl" 2> /dev/null; }   # <run> <id>
O=$T/origin.git
seed() {   # <n gotchas> → origin main's new tip: the project's CLAUDE.md with three sections
  local w=$T/seed-$1 i; rm -rf "$w"; git clone -q "$O" "$w"
  { printf '# proj\nrules\n\n## Code rules\n\n- bash, set -uo pipefail\n\n## Live system\n\n- the box serves the live site\n\n## Gotchas\n\n'
    for i in $(seq -w 1 "$1"); do echo "- seeded gotcha $i: the seeded project keeps its fact number $((10#$i)) (seed 2026-11-01)"; done; } > "$w/CLAUDE.md"
  git -C "$w" -c user.name=m -c user.email=m@test commit -qam "CLAUDE.md with $1 gotchas" && git -C "$w" push -q origin HEAD:main && git -C "$w" rev-parse HEAD
}
main0=$(git -C "$O" rev-parse main)
seed3=$(seed 3); git -C "$O" update-ref refs/heads/main "$main0"; seed15=$(seed 15)
cp "$T/base-config.sh" "$T/user-config.sh" && echo 'MEMORY_POLICY=pr RECORD_PR=end LEDGER_COMMIT=1' >> "$T/user-config.sh"
git init -q -b main "$T/ledger" && git -C "$T/ledger" config user.name t && git -C "$T/ledger" config user.email t@t   # the ledger commits its memory.jsonl
run() { local r=$1; shift; env "$@" STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" "$r" --spec SPEC.md --foreground > "$T/$r.out" 2>&1; mv "$T/gh.log" "$T/gh-$r.log" 2> /dev/null; }

# mp: two project facts and a workflow line, three ops
git -C "$O" update-ref refs/heads/main "$seed3"
run mp STUB_FACTS=A,B,C STUB_PROPOSE=A STUB_CURATOR_OPS=three-ops
la=$(lineof mp A)
git -C "$O" show harness-memory/mp:CLAUDE.md > "$T/mp-claude.md" 2> /dev/null
check "memory PR: the two project facts land under Gotchas in one commit on harness-memory/<run>, with their suffix" \
  'grep -q "^done" "$(st mp)/ended" && [[ $(git -C "$O" log --oneline main..harness-memory/mp | wc -l) == 1 ]] \
  && gotchas < "$T/mp-claude.md" | grep -x -- "- the stub'"'"'s A work sits in work-A\.txt at the root (mp [0-9-]*)" > /dev/null \
  && gotchas < "$T/mp-claude.md" | grep -x -- "- the stub'"'"'s B work sits in work-B\.txt at the root (mp [0-9-]*)" > /dev/null && [[ $(gotchas < "$T/mp-claude.md" | wc -l) == 5 ]]'
check "memory PR: the commit changes CLAUDE.md alone" \
  '[[ $(git -C "$O" diff --name-only main...harness-memory/mp) == CLAUDE.md ]] && [[ $(git -C "$O" diff main...harness-memory/mp | grep -c "^+[^+]") == 2 ]] \
  && ! git -C "$O" diff main...harness-memory/mp | grep "^-[^-]" > /dev/null'
check "memory rules PR: the workflow line is one commit on harness-rules/<run>, absent from harness-memory/<run>, in a PR left for Michael, each body naming the other PR" \
  'p=$(mpr mp) && q=$(rpr mp) && [[ -s $p.body && -s $q.body && $la =~ ^[0-9]+$ ]] && (( la >= 1 )) && ! grep -F "stub proposal: run the stub suite" "$T/mp-claude.md" > /dev/null \
  && [[ $(git -C "$O" log --format=%s main..harness-rules/mp) == "memory: mp: 1 rules" && $(git -C "$O" diff --name-only main...harness-rules/mp) == CLAUDE.md ]] \
  && [[ $(git -C "$O" diff main...harness-rules/mp | grep "^+[^+]") == "+- stub proposal: run the stub suite before each commit" ]] \
  && git -C "$O" show harness-rules/mp:CLAUDE.md | sed -n "/^## Code rules$/,/^## /p" | grep -xF -- "- stub proposal: run the stub suite before each commit" > /dev/null \
  && [[ $(cat "$q") == harness-rules/mp && ! -f $q.merged ]] && grep -x "gh pr create --base main --head harness-rules/mp --title memory rules: mp --body-file .*" "$T/gh-mp.log" > /dev/null \
  && [[ $(hlog mp | grep -c " · memory rules PR opened; left for Michael · $(url "$q")$") == 1 ]] \
  && grep -xF "### 1 · \`add\` CLAUDE.md · ## Code rules (entries.jsonl:$la)" "$q.body" > /dev/null && grep -xF -- "- stub proposal: run the stub suite before each commit" "$q.body" > /dev/null \
  && grep -xF "Facts of this run: $(url "$p")" "$q.body" > /dev/null && grep -xF "Rules of this run: $(url "$q")" "$p.body" > /dev/null && ! grep -F "stub proposal" "$p.body" > /dev/null \
  && [[ $(hlog mp | grep -c " · memory PR: its body names the rules PR · $(url "$p")$") == 1 ]] \
  && grep -x "## Applied (tier 1)" "$(rec mp)/memory.md" > /dev/null && grep -x "## Rules (tier 2)" "$(rec mp)/memory.md" > /dev/null'
check "memory PR: the PR is opened and left for Michael under MEMORY_POLICY=pr" \
  'p=$(mpr mp) && [[ $(cat "$p") == harness-memory/mp && ! -f $p.merged ]] \
  && grep -x "gh pr create --base main --head harness-memory/mp --title memory: mp --body-file .*" "$T/gh-mp.log" > /dev/null \
  && [[ $(hlog mp | grep -c " · memory PR opened; left for Michael (MEMORY_POLICY=pr) · https://example.test/pr/${p##*-}$") == 1 ]]'
check "memory PR: the run's record PR opens too" \
  'titles | grep -x "mp: run record" > /dev/null && ! hlog mp | grep -F "record PR: none (" > /dev/null && hlog mp | grep -F " · record PR merged into main · " > /dev/null'
check "memory PR: the notes count the ops, re-derived tiers and each dropped op; memory.json holds the counts" \
  '[[ $(hlog mp | grep -c " · memory: 3 ops · 2 facts · 1 rules · 0 dropped · 0 proposals$") == 1 && $(hlog mp | grep -c " · memory: tier re-derived for 1 ops$") == 1 ]] \
  && ! hlog mp | grep " · memory: dropped " > /dev/null \
  && jq -e "{ops, applied, rules, dropped, proposed, sections} == {ops: 3, applied: 2, rules: 1, dropped: 0, proposed: 0, sections: {facts: [\"## Gotchas\"], rules: [\"## Code rules\"]}} and (.pr | startswith(\"https://example.test/pr/\")) and (.rules_pr | startswith(\"https://example.test/pr/\")) and .pr != .rules_pr" "$(st mp)/memory.json" > /dev/null'

check "memory PR: MERGE_POLICY=auto merges the milestones and leaves the memory PR open under MEMORY_POLICY=pr" \
  'p=$(mpr mp) && on_main run/mp/M1 && ! on_main harness-memory/mp && [[ ! -f $p.merged ]] \
  && hlog mp | grep -F " · M1 merged" > /dev/null && ! hlog mp | grep -F " · memory PR merged" > /dev/null && ! grep "^gh pr merge https://example.test/pr/${p##*-} " "$T/gh-mp.log" > /dev/null'

HARNESS_TTY=0 "$H" report mp > "$T/mp-report.out" 2>&1; HARNESS_TTY=0 "$H" memory > "$T/mp-memory.out" 2>&1; mv "$T/gh.log" "$T/gh-mp-memory.log" 2> /dev/null
check "memory PR: summary.json's memory holds the counts and both URLs, harness report prints the Memory row, and memory-result.json is in the run record" \
  'p=$(mpr mp) && u=$(url "$p") && ru=$(url "$(rpr mp)") && [[ $(jq .memory.applied "$(rec mp)/summary.json") == 2 && $(jq -r .memory.pr "$(rec mp)/summary.json") == "$u" ]] \
  && [[ $(jq .memory.rules "$(rec mp)/summary.json") == 1 && $(jq -r .memory.rules_pr "$(rec mp)/summary.json") == "$ru" ]] \
  && grep -xF "| Memory | 2 applied · 1 rules · 0 dropped · 0 proposals · PR $u · rules PR $ru |" "$T/mp-report.out" > /dev/null \
  && [[ -s $(rec mp)/memory-ops.json ]] && jq -e "(.rules | map(.n)) == [1] and (.ruleFiles == [\"CLAUDE.md\"]) and (has(\"ruleTexts\") | not)" "$(rec mp)/memory-result.json" > /dev/null'

# mp's continue: the open memory PR's head is the base; A's and B's are already there, C's is the one new line
STUB_CURATOR_OPS=continue STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue mp --foreground > "$T/mp2.out" 2>&1
mv "$T/gh.log" "$T/gh-mp2.log" 2> /dev/null
check "memory PR: a continued run reuses its open memory PR and its open rules PR" \
  'p=$(mpr mp) && q=$(rpr mp) && [[ $(cat "$T/gh-mp.log" "$T/gh-mp2.log" | grep -c "^gh pr create .*--head harness-memory/mp ") == 1 ]] \
  && [[ $(cat "$T/gh-mp.log" "$T/gh-mp2.log" | grep -c "^gh pr create .*--head harness-rules/mp ") == 1 ]] \
  && grep -x "gh pr edit https://example.test/pr/${p##*-} --body-file .*" "$T/gh-mp2.log" > /dev/null && grep -x "gh pr edit $(url "$q") --body-file .*" "$T/gh-mp2.log" > /dev/null \
  && [[ $(hlog mp | grep -c " · memory rules PR updated (no tier-2 change) · $(url "$q")$") == 1 && $(git -C "$O" log --oneline main..harness-rules/mp | wc -l) == 1 ]] \
  && [[ $(hlog mp | grep -c " · memory PR updated · https://example.test/pr/${p##*-}$") == 1 && $(hlog mp | grep -c " · memory: 4 ops · 1 facts · 0 rules · 3 dropped · 0 proposals$") == 1 ]] \
  && [[ $(git -C "$O" log --oneline main..harness-memory/mp | wc -l) == 2 ]] \
  && git -C "$O" show harness-memory/mp:CLAUDE.md | gotchas | grep -F -- "- the stub'"'"'s C work sits in work-C.txt at the root (mp " > /dev/null \
  && [[ $(git -C "$O" show harness-memory/mp:CLAUDE.md | gotchas | wc -l) == 6 ]] \
  && sed -n "/^_An earlier segment of this run:_$/,\$p" "$p.body" | grep -F "## Gotchas: the stub'"'"'s A work sits in work-A.txt" > /dev/null'

# mp's memory PR merged by hand (stub-gh's pr merge): harness memory reads its state from gh again
HARNESS_TTY=0 "$H" memory > "$T/mp-memory2.out" 2>&1
p=$(mpr mp); (cd "$T/proj" && "$HARNESS_GH" pr merge "https://example.test/pr/${p##*-}" --merge --match-head-commit "$(git -C "$O" rev-parse harness-memory/mp)") > /dev/null 2>&1
HARNESS_TTY=0 "$H" memory --last 5 proj > "$T/mp-memory3.out" 2>&1; mv "$T/gh.log" "$T/gh-mp-merge.log" 2> /dev/null
check "harness memory: the run's facts and rules PRs are a line each with its tier, then one tally line per tier; the facts PR merged unchanged after its merge" \
  'p=$(mpr mp) && u=$(url "$p") && ru=$(url "$(rpr mp)") && [[ -f $p.merged ]] && nl=$'"'"'\n'"'"' \
  && [[ $(cat "$T/mp-memory.out") == "mp · proj · rules · 1 · ## Code rules · $ru · open${nl}mp · proj · facts · 2/0/0 · $u · open${nl}facts: merged unchanged 0 · edited 0 · closed 0 · open 1${nl}rules: merged unchanged 0 · edited 0 · closed 0 · open 1" ]] \
  && [[ $(cat "$T/mp-memory2.out") == "mp · proj · rules · 0 · — · $ru · open${nl}mp · proj · facts · 1/3/0 · $u · open${nl}facts: merged unchanged 0 · edited 0 · closed 0 · open 1${nl}rules: merged unchanged 0 · edited 0 · closed 0 · open 1" ]] \
  && [[ $(cat "$T/mp-memory3.out") == "mp · proj · rules · 0 · — · $ru · open${nl}mp · proj · facts · 1/3/0 · $u · merged unchanged${nl}facts: merged unchanged 1 · edited 0 · closed 0 · open 0${nl}rules: merged unchanged 0 · edited 0 · closed 0 · open 1" ]] \
  && grep -x "gh pr view $u --json state,mergedAt,commits" "$T/gh-mp-merge.log" > /dev/null'
check "ledger: each memory PR is one row of memory.jsonl with its tier and sections, committed with the ledger's paths" \
  'p=$(mpr mp) && ru=$(url "$(rpr mp)") && [[ $(jq -sc "map(select(.run == \"mp\")) | map({project, tier, url, ops, applied, rules, dropped, proposed, sections})" "$T/ledger/memory.jsonl") == "[{\"project\":\"proj\",\"tier\":\"facts\",\"url\":\"https://example.test/pr/${p##*-}\",\"ops\":4,\"applied\":1,\"rules\":null,\"dropped\":3,\"proposed\":0,\"sections\":[\"## Gotchas\"]},{\"project\":\"proj\",\"tier\":\"rules\",\"url\":\"$ru\",\"ops\":4,\"applied\":null,\"rules\":0,\"dropped\":3,\"proposed\":0,\"sections\":[]}]" ]] \
  && [[ $(git -C "$T/ledger" log --format=%s -- memory.jsonl | grep -c "^ledger: mp (proj): ") == 2 && -z $(git -C "$T/ledger" status --porcelain -- memory.jsonl) ]] \
  && [[ $(hlog mp | grep -c " · ledger: memory PR https://example.test/pr/${p##*-} in memory.jsonl (2 applied · 0 dropped · 0 proposals)$") == 1 ]] \
  && [[ $(hlog mp | grep -c " · ledger: memory rules PR $ru in memory.jsonl (1 rules · ## Code rules)$") == 1 ]]'

# mc: a project at 15 Gotchas lines, a 16th add without an anchor and a replace of the 2nd line beside it
git -C "$O" update-ref refs/heads/main "$seed15"
run mc STUB_FACTS=A,B STUB_CURATOR_OPS=cap
git -C "$O" show harness-memory/mc:CLAUDE.md > "$T/mc-claude.md" 2> /dev/null
check "memory PR: a 16th Gotchas add without an anchor is dropped naming the cap; the replace beside it lands and its PR opens" \
  'p=$(mpr mc) && grep -q "^done" "$(st mc)/ended" && [[ $(hlog mc | grep -c " · memory: dropped add ## Gotchas (over the cap: ## Gotchas: 16 entries, over 15)$") == 1 ]] \
  && [[ $(hlog mc | grep -c " · memory: dropped ") == 1 ]] && ! hlog mc | grep -F "tier-1 commit refused" > /dev/null \
  && [[ $(git -C "$O" log --oneline main..harness-memory/mc | wc -l) == 1 && $(gotchas < "$T/mc-claude.md" | wc -l) == 15 ]] \
  && gotchas < "$T/mc-claude.md" | grep -x -- "- the stub'"'"'s B work sits in work-B\.txt at the root (mc [0-9-]*)" > /dev/null && ! grep -F "seeded gotcha 02" "$T/mc-claude.md" > /dev/null \
  && [[ $(cat "$p") == harness-memory/mc && ! -f $p.merged ]] && sed -n "/^## Dropped$/,\$p" "$p.body" | grep -F "## Gotchas: 16 entries, over 15" > /dev/null \
  && ! grep -F "refused" "$p.body" > /dev/null && jq -e ".applied == 1 and .dropped == 1" "$(st mc)/memory.json" > /dev/null'

# me: the same add with an anchor (the eviction), an op on Live system and a replace whose anchor matches no line
git -C "$O" update-ref refs/heads/main "$seed15"
run me STUB_FACTS=A,B STUB_PROPOSE=A STUB_CURATOR_OPS=cap-evict
git -C "$O" show harness-memory/me:CLAUDE.md > "$T/me-claude.md" 2> /dev/null
check "memory PR: an op on Live system is dropped with a note and carried as a proposal; an unmatched anchor is dropped naming it" \
  'p=$(mpr me) && [[ $(hlog me | grep -c " · memory: dropped add ## Live system (protected section: a proposal for Michael)$") == 1 ]] \
  && [[ $(hlog me | grep -c " · memory: dropped replace ## Gotchas (anchor \"a gotcha no line of this CLAUDE.md has ever said\" matches no line)$") == 1 ]] \
  && sed -n "/^## Proposals (protected, tier 3)$/,/^## Dropped$/p" "$p.body" | grep -F "### 1 · \`add\` CLAUDE.md · ## Live system" > /dev/null \
  && sed -n "/^## Proposals (protected, tier 3)$/,/^## Dropped$/p" "$p.body" | grep -xF -- "- stub proposal: run the stub suite before each commit" > /dev/null \
  && sed -n "/^## Dropped$/,\$p" "$p.body" | grep -F "a gotcha no line of this CLAUDE.md has ever said" > /dev/null \
  && ! sed -n "/^## Live system$/,/^## /p" "$T/me-claude.md" | grep -F "stub proposal" > /dev/null'
check "memory PR: the same add with an anchor lands as one edit" \
  'p=$(mpr me) && [[ $(gotchas < "$T/me-claude.md" | wc -l) == 15 ]] && ! grep -F "seeded gotcha 03" "$T/me-claude.md" > /dev/null \
  && sed -n "/^## Applied (tier 1)$/,/^## /p" "$p.body" | grep -F "(in place of: - seeded gotcha 03: the seeded project keeps its fact number 3 (seed 2026-11-01))" > /dev/null \
  && [[ $(hlog me | grep -c " · memory: evicted \"- seeded gotcha 03: the seeded project keeps its fact number 3 (seed 2026-11-01)\" for add ## Gotchas$") == 1 ]] \
  && [[ $(hlog me | grep -c " · memory: 3 ops · 1 facts · 0 rules · 2 dropped · 1 proposals$") == 1 ]] \
  && [[ $(git -C "$O" show "$seed15:CLAUDE.md" > "$T/me-main.md" && node -e "import(\"'$HERE'/../lib/memlint.mjs\").then(m => { const f = require(\"fs\"); console.log(JSON.stringify(m.gotchasDiff(f.readFileSync(process.argv[1], \"utf8\"), f.readFileSync(process.argv[2], \"utf8\")))) })" "$T/me-main.md" "$T/me-claude.md") == "{\"added\":0,\"edited\":1,\"deleted\":0}" ]]'

# mn: harness-memory/mn already on origin with no PR (an earlier push whose pr create failed): it is the base, its PR opens
hand() {   # <run> [<path>] → harness-memory/<run> pushed by hand, one commit past seed3 (that also adds <path>: not the driver's)
  local w=$T/hand-$1; rm -rf "$w"; git clone -q "$O" "$w" && git -C "$w" checkout -q --detach "$seed3" \
    && echo "- an earlier push of this memory branch keeps its own line ($1 2026-11-01)" >> "$w/CLAUDE.md" \
    && { [[ -z ${2:-} ]] || { mkdir -p "$(dirname "$w/$2")" && echo "# not memory" > "$w/$2" && git -C "$w" add -- "$2"; }; } \
    && git -C "$w" -c user.name=m -c user.email=m@test commit -qam "memory: $1: 1 facts" && git -C "$w" push -q origin "HEAD:refs/heads/harness-memory/$1" && git -C "$w" rev-parse HEAD
}
git -C "$O" update-ref refs/heads/main "$seed3"; mn0=$(hand mn)
run mn STUB_FACTS=A,B STUB_PROPOSE=A STUB_CURATOR_OPS=three-ops
check "memory PR: a memory branch on origin with no PR is the base, and its PR opens on it" \
  'p=$(mpr mn) && [[ -n $mn0 && $(git -C "$O" rev-parse harness-memory/mn~1) == "$mn0" ]] \
  && git -C "$O" show harness-memory/mn:CLAUDE.md | gotchas | grep -F "an earlier push of this memory branch" > /dev/null \
  && [[ $(git -C "$O" show harness-memory/mn:CLAUDE.md | gotchas | wc -l) == 6 ]] && [[ $(hlog mn | grep -c " · memory PR opened; left for Michael (MEMORY_POLICY=pr) · ") == 1 ]]'

# mk: harness-memory/mk on origin, its memory PR closed by Michael: no curator, the branch as it was
git -C "$O" update-ref refs/heads/main "$seed3"; mk0=$(hand mk)
k=$(( $(ls "$T/prs" | grep -c '^pr-[0-9]*$') + 1 )); echo harness-memory/mk > "$T/prs/pr-$k"; echo "memory: mk" > "$T/prs/pr-$k.title"; touch "$T/prs/pr-$k.closed"
run mk STUB_FACTS=A,B STUB_PROPOSE=A STUB_CURATOR_OPS=three-ops
check "memory PR: a memory branch whose PR Michael closed stops the curator with one note; nothing pushed" \
  'grep -q "^done" "$(st mk)/ended" && [[ $(hlog mk | grep -c " · memory PR: none (harness-memory/mk is on origin and main lacks it, its PR CLOSED; delete the branch to curate again)$") == 1 ]] \
  && [[ $(git -C "$O" rev-parse harness-memory/mk) == "$mk0" ]] && ! grep -x curator "$T/scratch/proj/mk/sessions.log" > /dev/null \
  && ! grep "^gh pr create .*--head harness-memory/mk " "$T/gh-mk.log" > /dev/null && titles | grep -x "mk: run record" > /dev/null'
# mf: harness-memory/mf on origin, no PR, its commit also adds lib/hack.sh (a session's push, say): never a base
git -C "$O" update-ref refs/heads/main "$seed3"; mf0=$(hand mf lib/hack.sh)
run mf STUB_FACTS=A,B STUB_PROPOSE=A STUB_CURATOR_OPS=three-ops
check "memory PR: a memory branch with a commit the driver would not write stops the curator with one note; nothing pushed" \
  'grep -q "^done" "$(st mf)/ended" && [[ $(hlog mf | grep -c " · memory PR: none (harness-memory/mf has a commit the driver would not write, ${mf0:0:12} \"memory: mf: 1 facts\" (lib/hack.sh); delete the branch to curate again)$") == 1 ]] \
  && [[ -n $mf0 && $(git -C "$O" rev-parse harness-memory/mf) == "$mf0" ]] && ! grep -x curator "$T/scratch/proj/mf/sessions.log" > /dev/null \
  && ! grep "^gh pr create .*--head harness-memory/mf " "$T/gh-mf.log" > /dev/null && titles | grep -x "mf: run record" > /dev/null'

# mq: harness-rules/mq on origin, no PR, its commit also adds lib/hack.sh: the rules half stops, the facts half lands
git -C "$O" update-ref refs/heads/main "$seed3"
w=$T/hand-mq; rm -rf "$w"; git clone -q "$O" "$w" && git -C "$w" checkout -q --detach "$seed3" && echo "# not memory" > "$w/hack.sh" && git -C "$w" add hack.sh \
  && git -C "$w" -c user.name=m -c user.email=m@test commit -qm "memory: mq: 1 rules" && git -C "$w" push -q origin HEAD:refs/heads/harness-rules/mq; mq0=$(git -C "$w" rev-parse HEAD)
run mq STUB_FACTS=A,B STUB_PROPOSE=A STUB_CURATOR_OPS=three-ops
check "memory rules PR: a rules branch with a commit the driver would not write stops the rules half with one note; the facts half lands" \
  'p=$(mpr mq) && grep -q "^done" "$(st mq)/ended" && [[ $(hlog mq | grep -c " · memory rules PR: none (harness-rules/mq has a commit the driver would not write, ${mq0:0:12} \"memory: mq: 1 rules\" (hack.sh); delete the branch to curate again)$") == 1 ]] \
  && [[ -n $mq0 && $(git -C "$O" rev-parse harness-rules/mq) == "$mq0" ]] && [[ -z $(rpr mq) ]] && ! grep "^gh pr create .*--head harness-rules/mq " "$T/gh-mq.log" > /dev/null \
  && [[ $(git -C "$O" log --oneline main..harness-memory/mq | wc -l) == 1 && $(hlog mq | grep -c " · memory PR opened; left for Michael (MEMORY_POLICY=pr) · $(url "$p")$") == 1 ]] \
  && grep -xF "Rules of this run: none" "$p.body" > /dev/null && jq -e ".rules_pr == null and .rules == 0 and .dropped == 1" "$(st mq)/memory.json" > /dev/null \
  && [[ $(hlog mq | grep -c " · memory: dropped add ## Code rules (the rules half stopped; its note says why)$") == 1 ]]'

# mx: main gains five Code rules lines under mx's open rules PR (another PR merged); the continue's new rule fits the
# stale rules tip but the merge would take CLAUDE.md past the cap (24 lines): the union counts main's lines, the rule drops
git -C "$O" update-ref refs/heads/main "$seed3"
run mx STUB_FACTS=A,B,C STUB_PROPOSE=A STUB_CURATOR_OPS=three-ops
w=$T/hand-mx; rm -rf "$w"; git clone -q "$O" "$w" && sed -i 's/^- bash, set -uo pipefail$/&\n- later rule 1\n- later rule 2\n- later rule 3\n- later rule 4\n- later rule 5/' "$w/CLAUDE.md" \
  && git -C "$w" -c user.name=m -c user.email=m@test commit -qam "five more rules" && git -C "$w" push -q origin HEAD:main
MEMLINT_LINES=24 STUB_CURATOR_OPS=drift STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue mx --foreground > "$T/mx2.out" 2>&1
mv "$T/gh.log" "$T/gh-mx2.log" 2> /dev/null
check "memory rules PR: a continue after main gained lines outside Gotchas drops the tier-2 add the merge would take past the cap" \
  '[[ $(hlog mx | grep -c " · memory: dropped add ## Code rules (over the cap: CLAUDE.md: 25 lines, over 24)$") == 1 ]] \
  && [[ $(git -C "$O" log --oneline main..harness-rules/mx | wc -l) == 1 && $(hlog mx | grep -c " · memory: 1 ops · 0 facts · 0 rules · 1 dropped · 0 proposals$") == 1 ]]'

# mz: harness-memory/mz on origin with no PR, and this segment's one op a protected proposal: the PR still opens on it
git -C "$O" update-ref refs/heads/main "$seed3"; mz0=$(hand mz)
run mz STUB_FACTS=A STUB_PROPOSE=A STUB_CURATOR_OPS=proposal
check "memory PR: a memory branch on origin with no PR gets its PR when nothing new reaches tier 1" \
  'p=$(mpr mz) && [[ -n $mz0 && $(git -C "$O" rev-parse harness-memory/mz) == "$mz0" ]] && [[ $(hlog mz | grep -c " · memory: 1 ops · 0 facts · 0 rules · 1 dropped · 1 proposals$") == 1 ]] \
  && grep -x "gh pr create --base main --head harness-memory/mz --title memory: mz --body-file .*" "$T/gh-mz.log" > /dev/null \
  && [[ $(hlog mz | grep -c " · memory PR opened; left for Michael (MEMORY_POLICY=pr) · https://example.test/pr/${p##*-}$") == 1 ]] \
  && sed -n "/^## Proposals (protected, tier 3)$/,\$p" "$p.body" | grep -xF -- "- stub proposal: run the stub suite before each commit" > /dev/null \
  && jq -e ".pr == \"https://example.test/pr/${p##*-}\"" "$(st mz)/memory.json" > /dev/null'
# ma: MEMORY_POLICY=auto, the driver merges the memory PR at the tier-1 commit; mr: that merge refused (MERGE_POLICY=pr,
# so no milestone or record PR merge meets the refusing stub)
git -C "$O" update-ref refs/heads/main "$seed3"
cp "$T/base-config.sh" "$T/user-config.sh" && echo 'MEMORY_POLICY=auto RECORD_PR=end' >> "$T/user-config.sh"
run ma STUB_FACTS=A,B STUB_PROPOSE=A STUB_CURATOR_OPS=three-ops
mah=$(git -C "$O" rev-parse -q --verify harness-memory/ma)
check "memory PR: MEMORY_POLICY=auto merges the memory PR into main and notes it" \
  'p=$(mpr ma) && grep -q "^done" "$(st ma)/ended" && [[ -n $mah && -f $p.merged ]] && on_main "$mah" \
  && grep -x "gh pr merge https://example.test/pr/${p##*-} --merge --match-head-commit $mah" "$T/gh-ma.log" > /dev/null \
  && [[ $(hlog ma | grep -c " · memory PR merged into main · https://example.test/pr/${p##*-}$") == 1 ]] && ! hlog ma | grep -F "left for Michael (MEMORY_POLICY" > /dev/null \
  && git -C "$O" show main:CLAUDE.md | gotchas | grep -F -- "- the stub'"'"'s B work sits in work-B.txt at the root (ma " > /dev/null \
  && jq -e ".pr == \"https://example.test/pr/${p##*-}\"" "$(st ma)/memory.json" > /dev/null'
check "memory rules PR: MEMORY_POLICY=auto merges the facts PR alone and leaves the rules PR for Michael" \
  'q=$(rpr ma) && [[ -n $q && $(cat "$q") == harness-rules/ma && ! -f $q.merged ]] && ! on_main harness-rules/ma \
  && [[ $(hlog ma | grep -c " · memory rules PR opened; left for Michael · $(url "$q")$") == 1 ]] && ! grep "^gh pr merge $(url "$q") " "$T/gh-ma.log" > /dev/null \
  && ! git -C "$O" show main:CLAUDE.md | grep -F "stub proposal" > /dev/null'
git -C "$O" update-ref refs/heads/main "$seed3"
cp "$T/base-config.sh" "$T/user-config.sh" && echo 'MEMORY_POLICY=auto MERGE_POLICY=pr RECORD_PR=end' >> "$T/user-config.sh"
run mr STUB_FACTS=A,B STUB_PROPOSE=A STUB_CURATOR_OPS=three-ops STUB_REFUSE_MERGE=1
check "memory PR: a refused auto merge leaves the memory PR open with one note" \
  'p=$(mpr mr) && [[ ! -f $p.merged ]] && ! on_main harness-memory/mr \
  && [[ $(hlog mr | grep -c " · memory PR: the merge was refused; left open · https://example.test/pr/${p##*-}$") == 1 ]] \
  && [[ $(grep -c "^gh pr merge https://example.test/pr/${p##*-} " "$T/gh-mr.log") == 1 ]] && ! hlog mr | grep -F " · memory PR merged" > /dev/null'
# mw: auto, harness-memory/mw on origin with no PR and this segment's one op a proposal: the PR opens, nothing to merge
git -C "$O" update-ref refs/heads/main "$seed3"; mw0=$(hand mw)
cp "$T/base-config.sh" "$T/user-config.sh" && echo 'MEMORY_POLICY=auto RECORD_PR=end' >> "$T/user-config.sh"
run mw STUB_FACTS=A,B,C STUB_PROPOSE=A STUB_CURATOR_OPS=proposal
check "memory PR: under MEMORY_POLICY=auto a PR opened with no new tier-1 commit is left open with one note" \
  'p=$(mpr mw) && [[ -n $mw0 && ! -f $p.merged && $(git -C "$O" rev-parse harness-memory/mw) == "$mw0" ]] \
  && [[ $(hlog mw | grep -c " · memory PR opened; left open (MEMORY_POLICY=auto: no new tier-1 commit to merge) · https://example.test/pr/${p##*-}$") == 1 ]] \
  && ! grep "^gh pr merge https://example.test/pr/${p##*-} " "$T/gh-mw.log" > /dev/null'
# mw's continues reuse the open PR, one new fact each (N2-02): the first's body refresh fails, so no merge; the second's lands and merges
rm -f "$T"/gh-down-*
STUB_GH_DOWN=1 STUB_GH_DOWN_ONLY=edit STUB_CURATOR_OPS=fact-b STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue mw --foreground > "$T/mw2.out" 2>&1
mv "$T/gh.log" "$T/gh-mw2.log" 2> /dev/null; mw2=$(git -C "$O" rev-parse -q --verify harness-memory/mw)
HARNESS_TTY=0 "$H" memory > "$T/mw-memory.out" 2>&1; mv "$T/gh.log" "$T/gh-mw-memory.log" 2> /dev/null
check "memory PR: under MEMORY_POLICY=auto a reused PR whose body refresh failed gets its commit but no merge, with one note" \
  'p=$(mpr mw) && u=$(url "$p") && [[ -n $mw2 && ! -f $p.merged && $(git -C "$O" rev-list --count "$mw0..$mw2") == 1 && $(git -C "$O" log -1 --format=%s "$mw2") == "memory: mw: 1 facts" ]] \
  && grep -x "gh pr edit $u --body-file .*" "$T/gh-mw2.log" > /dev/null && ! grep "^gh pr merge $u " "$T/gh-mw2.log" > /dev/null \
  && [[ $(hlog mw | grep -c " · memory PR: its body was not updated (see run.log); not merged (MEMORY_POLICY=auto), left open · $u$") == 1 ]] \
  && ! hlog mw | grep -F " · memory PR: its body was not updated (see run.log) · " > /dev/null && ! hlog mw | grep -F " · memory PR merged" > /dev/null \
  && grep -E "^mw · proj · facts · .* · $u · open$" "$T/mw-memory.out" > /dev/null'
STUB_CURATOR_OPS=fact-c STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue mw --foreground > "$T/mw3.out" 2>&1
mv "$T/gh.log" "$T/gh-mw3.log" 2> /dev/null; mw3=$(git -C "$O" rev-parse -q --verify harness-memory/mw)
check "memory PR: the next segment refreshes the reused PR's body and merges it at the commit it pushed" \
  'p=$(mpr mw) && u=$(url "$p") && [[ -n $mw3 && -f $p.merged && $(git -C "$O" rev-list --count "$mw2..$mw3") == 1 ]] && on_main "$mw3" \
  && grep -x "gh pr edit $u --body-file .*" "$T/gh-mw3.log" > /dev/null && grep -x "gh pr merge $u --merge --match-head-commit $mw3" "$T/gh-mw3.log" > /dev/null \
  && [[ $(hlog mw | grep -c " · memory PR updated · $u$") == 1 && $(hlog mw | grep -c " · memory PR merged into main · $u$") == 1 ]] \
  && [[ $(cat "$T/gh-mw.log" "$T/gh-mw2.log" "$T/gh-mw3.log" | grep -c "^gh pr create .*--head harness-memory/mw ") == 1 ]]'
# md: the project's memory is .claude/CLAUDE.md alone (no root CLAUDE.md): the facts land there (N1-02)
w=$T/seed-dot; rm -rf "$w"; git clone -q "$O" "$w" && git -C "$w" checkout -q --detach "$seed3" && mkdir -p "$w/.claude" \
  && git -C "$w" mv CLAUDE.md .claude/CLAUDE.md && git -C "$w" -c user.name=m -c user.email=m@test commit -qm "memory in .claude/CLAUDE.md" \
  && git -C "$w" push -q origin HEAD:refs/heads/seed-dot && git -C "$O" update-ref refs/heads/main "$(git -C "$w" rev-parse HEAD)"
cp "$T/base-config.sh" "$T/user-config.sh" && echo 'MEMORY_POLICY=pr RECORD_PR=end' >> "$T/user-config.sh"
run md STUB_FACTS=A,B STUB_CURATOR_OPS=dot-claude
check "memory PR: a project whose memory is .claude/CLAUDE.md alone gets its facts there on harness-memory/<run>, and no root CLAUDE.md" \
  'grep -q "^done" "$(st md)/ended" && [[ $(git -C "$O" diff --name-only main...harness-memory/md) == .claude/CLAUDE.md ]] \
  && git -C "$O" show harness-memory/md:.claude/CLAUDE.md > "$T/md-claude.md" && [[ $(gotchas < "$T/md-claude.md" | wc -l) == 5 ]] \
  && gotchas < "$T/md-claude.md" | grep -x -- "- the stub'"'"'s B work sits in work-B\.txt at the root (md [0-9-]*)" > /dev/null \
  && ! git -C "$O" cat-file -e harness-memory/md:CLAUDE.md 2> /dev/null && [[ $(hlog md | grep -c " · memory: 2 ops · 2 facts · 0 rules · 0 dropped · 0 proposals$") == 1 ]]'
check "memory PR: no run leaves a local harness-memory or harness-rules branch or a registered scratch worktree" \
  '! git -C "$T/proj" worktree list --porcelain | grep "/memory$" > /dev/null && [[ -z $(git -C "$T/proj" branch --list "harness-memory/*" "harness-rules/*") ]] \
  && [[ $(git -C "$T/proj" worktree list --porcelain | grep -c "^worktree ") == 14 ]]'

suite_end
