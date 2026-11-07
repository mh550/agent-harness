#!/usr/bin/env bash
# tier: slow
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the memory PR (M2-04): the curator's ops applied on harness-memory/<run> cut from main, tier 1 one commit under
# the cap, tier 2 and 3 and every dropped op in the body of a `memory: <run>` PR left for Michael ----
# Origin's main gets a CLAUDE.md with Code rules, Live system and Gotchas (3 lines; 15 for the cap runs) before each run.
# mp carries the three ops and its continue; mc is refused at the cap; me evicts, with a Live system op and an
# unmatched anchor beside it; mn, mk, mf and mz meet a memory branch already on origin. Each run gets its own gh.log.
st() { echo "$HARNESS_STATE/proj/$1"; }
rec() { echo "$T/wt/proj/$1/.harness/runs/$1"; }
titles() { cat "$T"/prs/pr-*.title 2> /dev/null; }
mpr() { local f; f=$(grep -lx "memory: $1" "$T"/prs/pr-*.title 2> /dev/null | head -1); [[ -n $f ]] && echo "${f%.title}"; }   # <run> → prs/pr-N of its memory PR
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
cp "$T/base-config.sh" "$T/user-config.sh" && echo 'MEMORY_POLICY=pr RECORD_PR=end' >> "$T/user-config.sh"
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
check "memory PR: the workflow line is not committed and is in the PR body with its entries.jsonl line" \
  'p=$(mpr mp) && [[ -s $p.body && $la =~ ^[0-9]+$ ]] && (( la >= 1 )) && ! grep -F "stub proposal: run the stub suite" "$T/mp-claude.md" > /dev/null \
  && grep -xF -- "- stub proposal: run the stub suite before each commit" "$p.body" > /dev/null && grep -F "## Code rules (entries.jsonl:$la)" "$p.body" > /dev/null && cmp -s "$p.body" "$(rec mp)/memory.md"'
check "memory PR: the PR is opened and left for Michael under MEMORY_POLICY=pr" \
  'p=$(mpr mp) && [[ $(cat "$p") == harness-memory/mp && ! -f $p.merged ]] \
  && grep -x "gh pr create --base main --head harness-memory/mp --title memory: mp --body-file .*" "$T/gh-mp.log" > /dev/null \
  && [[ $(hlog mp | grep -c " · memory PR opened; left for Michael (MEMORY_POLICY=pr) · https://example.test/pr/${p##*-}$") == 1 ]]'
check "memory PR: the run's record PR opens too" \
  'titles | grep -x "mp: run record" > /dev/null && ! hlog mp | grep -F "record PR: none (" > /dev/null && hlog mp | grep -F " · record PR merged into main · " > /dev/null'
check "memory PR: the notes count the ops, re-derived tiers and each dropped op; memory.json holds the counts" \
  '[[ $(hlog mp | grep -c " · memory: 3 ops · 2 applied · 0 dropped · 1 proposals$") == 1 && $(hlog mp | grep -c " · memory: tier re-derived for 1 ops$") == 1 ]] \
  && ! hlog mp | grep " · memory: dropped " > /dev/null \
  && jq -e "{ops, applied, dropped, proposed} == {ops: 3, applied: 2, dropped: 0, proposed: 1} and (.pr | startswith(\"https://example.test/pr/\"))" "$(st mp)/memory.json" > /dev/null'

check "memory PR: MERGE_POLICY=auto merges the milestones and leaves the memory PR open under MEMORY_POLICY=pr" \
  'p=$(mpr mp) && on_main run/mp/M1 && ! on_main harness-memory/mp && [[ ! -f $p.merged ]] \
  && hlog mp | grep -F " · M1 merged" > /dev/null && ! hlog mp | grep -F " · memory PR merged" > /dev/null && ! grep "^gh pr merge https://example.test/pr/${p##*-} " "$T/gh-mp.log" > /dev/null'

# mp's continue: the open memory PR's head is the base; A's and B's are already there, C's is the one new line
STUB_CURATOR_OPS=continue STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue mp --foreground > "$T/mp2.out" 2>&1
mv "$T/gh.log" "$T/gh-mp2.log" 2> /dev/null
check "memory PR: a continued run reuses its open memory PR" \
  'p=$(mpr mp) && [[ $(cat "$T/gh-mp.log" "$T/gh-mp2.log" | grep -c "^gh pr create .*--head harness-memory/mp ") == 1 ]] \
  && grep -x "gh pr edit https://example.test/pr/${p##*-} --body-file .*" "$T/gh-mp2.log" > /dev/null \
  && [[ $(hlog mp | grep -c " · memory PR updated · https://example.test/pr/${p##*-}$") == 1 && $(hlog mp | grep -c " · memory: 4 ops · 1 applied · 2 dropped · 1 proposals$") == 1 ]] \
  && [[ $(git -C "$O" log --oneline main..harness-memory/mp | wc -l) == 2 ]] \
  && git -C "$O" show harness-memory/mp:CLAUDE.md | gotchas | grep -F -- "- the stub'"'"'s C work sits in work-C.txt at the root (mp " > /dev/null \
  && [[ $(git -C "$O" show harness-memory/mp:CLAUDE.md | gotchas | wc -l) == 6 ]] \
  && sed -n "/^_An earlier segment of this run:_$/,\$p" "$p.body" | grep -F "## Gotchas: the stub'"'"'s A work sits in work-A.txt" > /dev/null'

# mc: a project at 15 Gotchas lines, a 16th add without an anchor
git -C "$O" update-ref refs/heads/main "$seed15"
run mc STUB_FACTS=A STUB_CURATOR_OPS=cap
check "memory PR: a 16th Gotchas add without an anchor refuses the tier-1 commit; no branch, no PR" \
  'grep -q "^done" "$(st mc)/ended" && [[ $(hlog mc | grep -c " · memory: tier-1 commit refused (## Gotchas: 16 entries, over 15)$") == 1 ]] \
  && hlog mc | grep -F " · memory PR: none (no tier-1 change); the body is in memory.md" > /dev/null && ! hlog mc | grep " · memory: dropped " > /dev/null \
  && [[ -z $(git -C "$O" ls-remote --heads . harness-memory/mc) ]] && ! titles | grep -x "memory: mc" > /dev/null \
  && jq -e ".pr == null and .applied == 0 and .dropped == 1" "$(st mc)/memory.json" > /dev/null && titles | grep -x "mc: run record" > /dev/null'

# me: the same add with an anchor (the eviction), an op on Live system and a replace whose anchor matches no line
git -C "$O" update-ref refs/heads/main "$seed15"
run me STUB_FACTS=A,B STUB_PROPOSE=A STUB_CURATOR_OPS=cap-evict
git -C "$O" show harness-memory/me:CLAUDE.md > "$T/me-claude.md" 2> /dev/null
check "memory PR: an op on Live system is dropped with a note and carried as a proposal; an unmatched anchor is dropped naming it" \
  'p=$(mpr me) && [[ $(hlog me | grep -c " · memory: dropped add ## Live system (protected section: a proposal for Michael)$") == 1 ]] \
  && [[ $(hlog me | grep -c " · memory: dropped replace ## Gotchas (anchor \"a gotcha no line of this CLAUDE.md has ever said\" matches no line)$") == 1 ]] \
  && sed -n "/^## Proposals (protected, tier 3)$/,/^## Dropped$/p" "$p.body" | grep -F "### \`add\` CLAUDE.md · ## Live system" > /dev/null \
  && sed -n "/^## Proposals (protected, tier 3)$/,/^## Dropped$/p" "$p.body" | grep -xF -- "- stub proposal: run the stub suite before each commit" > /dev/null \
  && sed -n "/^## Dropped$/,\$p" "$p.body" | grep -F "a gotcha no line of this CLAUDE.md has ever said" > /dev/null \
  && ! sed -n "/^## Live system$/,/^## /p" "$T/me-claude.md" | grep -F "stub proposal" > /dev/null'
check "memory PR: the same add with an anchor lands as one edit" \
  '[[ $(gotchas < "$T/me-claude.md" | wc -l) == 15 ]] && ! grep -F "seeded gotcha 03" "$T/me-claude.md" > /dev/null \
  && [[ $(hlog me | grep -c " · memory: 3 ops · 1 applied · 2 dropped · 1 proposals$") == 1 ]] \
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

# mz: harness-memory/mz on origin with no PR, and this segment's one op a protected proposal: the PR still opens on it
git -C "$O" update-ref refs/heads/main "$seed3"; mz0=$(hand mz)
run mz STUB_FACTS=A STUB_PROPOSE=A STUB_CURATOR_OPS=proposal
check "memory PR: a memory branch on origin with no PR gets its PR when nothing new reaches tier 1" \
  'p=$(mpr mz) && [[ -n $mz0 && $(git -C "$O" rev-parse harness-memory/mz) == "$mz0" ]] && [[ $(hlog mz | grep -c " · memory: 1 ops · 0 applied · 1 dropped · 1 proposals$") == 1 ]] \
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
run mw STUB_FACTS=A STUB_PROPOSE=A STUB_CURATOR_OPS=proposal
check "memory PR: under MEMORY_POLICY=auto a PR opened with no new tier-1 commit is left open with one note" \
  'p=$(mpr mw) && [[ -n $mw0 && ! -f $p.merged && $(git -C "$O" rev-parse harness-memory/mw) == "$mw0" ]] \
  && [[ $(hlog mw | grep -c " · memory PR opened; left open (MEMORY_POLICY=auto: no new tier-1 commit to merge) · https://example.test/pr/${p##*-}$") == 1 ]] \
  && ! grep "^gh pr merge https://example.test/pr/${p##*-} " "$T/gh-mw.log" > /dev/null'
check "memory PR: no run leaves its scratch worktree registered or a local harness-memory branch" \
  '! git -C "$T/proj" worktree list --porcelain | grep "/memory$" > /dev/null && [[ -z $(git -C "$T/proj" branch --list "harness-memory/*") ]] \
  && [[ $(git -C "$T/proj" worktree list --porcelain | grep -c "^worktree ") == 11 ]]'

suite_end
