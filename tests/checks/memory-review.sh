#!/usr/bin/env bash
# tier: slow
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the memory reviewer (R1): one read-only session after the curator's dry apply, before the landing ----
# Every run here curates against a main whose CLAUDE.md has the two sections stub-three-ops writes to (curator-run.sh's
# cd shape), under MEMORY_POLICY=pr. Each run gets its own gh.log.
st() { echo "$HARNESS_STATE/proj/$1"; }
rec() { echo "$T/wt/proj/$1/.harness/runs/$1"; }
rline() { grep -n -m1 -E -- "$2" "$(st "$1")/run.log" | cut -d: -f1; }   # <run> <ERE>: run.log's first line matching
titles() { cat "$T"/prs/pr-*.title 2> /dev/null; }
args() { grep -lx "HARNESS_RUN_ID=$1" "$T"/argv/*-"$2".args 2> /dev/null; }   # <run> <kind> → its sessions' argv files
denied() { sed -n '/^--disallowedTools$/,/^PWD=/p' "$1" | sed '1d;$d'; }   # <args file> → what follows --disallowedTools
kept() { git -C "$T/origin.git" show "harness/$1:.harness/runs/$1/$2"; }   # <run> <file>: the run record's copy on origin
mpr() { local f; f=$(grep -lx "memory: $1" "$T"/prs/pr-*.title 2> /dev/null | head -1); [[ -n $f ]] && echo "${f%.title}"; }   # <run> → prs/pr-N of its memory PR
rpr() { local f; f=$(grep -lx "memory rules: $1" "$T"/prs/pr-*.title 2> /dev/null | head -1); [[ -n $f ]] && echo "${f%.title}"; }   # <run> → prs/pr-N of its rules PR
url() { echo "https://example.test/pr/${1##*-}"; }   # prs/pr-N → its URL
merged() { grep "^gh pr merge $(url "$2") " "$T/gh-$1.log" > /dev/null 2>&1; }   # <run> <prs/pr-N>: the driver merged it
review() { sed -n '/^## Review$/,/^## [^R]/p' "$1"; }   # <body or memory.md> → its ## Review section
gotchas() { sed -n '/^## Gotchas$/,/^## /{/^- /p}'; }   # a CLAUDE.md on stdin → its Gotchas lines
pol() { cp "$T/base-config.sh" "$T/user-config.sh" && echo "MEMORY_POLICY=$1 RECORD_PR=end" >> "$T/user-config.sh"; }   # the memory policy of the runs that follow
w=$T/seed; git clone -q "$T/origin.git" "$w" && printf '# proj\nrules\n\n## Code rules\n\n- bash, set -uo pipefail\n\n## Gotchas\n\n- seeded gotcha 1 (seed 2026-11-01)\n' > "$w/CLAUDE.md" \
  && git -C "$w" -c user.name=m -c user.email=m@test commit -qam "CLAUDE.md with two sections" && git -C "$w" push -q origin HEAD:main
main0=$(git -C "$T/origin.git" rev-parse main)
# seed15: the same two sections with 15 Gotchas, for the eviction runs (memory-branch.sh's seed)
{ printf '# proj\nrules\n\n## Code rules\n\n- bash, set -uo pipefail\n\n## Gotchas\n\n'; for i in $(seq -w 1 15); do echo "- seeded gotcha $i: the seeded project keeps its fact number $((10#$i)) (seed 2026-11-01)"; done; } > "$w/CLAUDE.md" \
  && git -C "$w" -c user.name=m -c user.email=m@test commit -qam "CLAUDE.md with 15 gotchas" && git -C "$w" push -q origin HEAD:refs/heads/seed15
seed15=$(git -C "$T/origin.git" rev-parse seed15); base=$main0
pol pr
run() {   # <run> [VAR=value…]: a stub run from $base (main0 unless set) with the facts three-ops states
  local r=$1; shift; git -C "$T/origin.git" update-ref refs/heads/main "$base"
  env "$@" STUB_FACTS=A,B STUB_PROPOSE=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" "$r" --spec SPEC.md --foreground > "$T/$r.out" 2>&1
  mv "$T/gh.log" "$T/gh-$r.log" 2> /dev/null
}

# mr: three ops (two facts, one rule), a reviewer that holds them all and also edits CLAUDE.md and lib/
run mr STUB_CURATOR_OPS=three-ops STUB_MEMORY_REVIEW=hold STUB_MEMORY_REVIEW_EDITS=1
check "memory review: a run under MEMORY_POLICY=pr ends done with one zz-memory-review transcript and a memory-review metrics row after the curator's" \
  'grep -q "^done" "$(st mr)/ended" && [[ $(ls "$(st mr)"/logs/zz-memory-review-*.jsonl 2> /dev/null | wc -l) == 1 ]] \
  && jq -se "(map(.role) | index(\"curator\")) as \$c | (map(.role) | index(\"memory-review\")) as \$m | \$c != null and \$m != null and \$m > \$c and (map(select(.role == \"memory-review\")) | length) == 1" "$(rec mr)/metrics.jsonl" > /dev/null'
check "memory review: its run.log line follows the curator's; its denied note follows the curator's notes and precedes the first memory PR note" \
  'c=$(rline mr "[0-9] curator · ") v=$(rline mr "[0-9] memory review · [^ ]+ · deny Bash\(git push:\*\) Bash\(gh:\*\)$") \
  n=$(hlog mr | grep -n " · curator: " | tail -1 | cut -d: -f1) d=$(ats mr " · memory review: session denied Bash\(git push:\*\), Bash\(gh:\*\)$") p=$(ats mr " · memory PR"); \
  [[ -n $c && -n $v && -n $n && -n $d && -n $p ]] && (( c < v && n < d && d < p )) && [[ $(hlog mr | grep -c " · memory review: session denied ") == 1 ]]'
check "memory review: the review session runs under --disallowedTools with exactly Bash(git push:*) and Bash(gh:*); no role but the curator's carries it" \
  'm=$(args mr memory-review) && [[ $(wc -l <<< "$m") == 1 && $(grep -cx -- --disallowedTools "$m") == 1 ]] \
  && [[ $(denied "$m") == "Bash(git push:*)"$'"'"'\n'"'"'"Bash(gh:*)" ]] && c=$(args mr curator) && [[ -n $c ]] \
  && others=$(grep -lx "HARNESS_RUN_ID=mr" "$T"/argv/*.args | grep -vxF -e "$m" -e "$c") && [[ -n $others ]] && ! grep -lx -- --disallowedTools $others > /dev/null'
kept mr memory-review-input.json > "$T/mr-input.json" 2> /dev/null; kept mr memory-result.json > "$T/mr-result.json" 2> /dev/null
check "memory review: memory-review-input.json lists facts/1, facts/2 and rules/<n> (memory-result.json's number), each op with its base (the rules base for rules/*) and after paths and the cap read on that base" \
  'n=$(jq -r ".rules[0].n" "$T/mr-result.json") && [[ $n =~ ^[0-9]+$ ]] && s=$T/scratch/proj/mr \
  && jq -e --arg n "rules/$n" --arg s "$s" "map(.id) == [\"facts/1\", \"facts/2\", \$n]
     and all(.[]; has(\"op\") and has(\"file\") and has(\"section\") and has(\"anchor\") and has(\"text\") and has(\"why\") and has(\"from\"))
     and all(.[]; .cap == {gotchas: 1, lines: 10}) and .[2].base == \$s + \"/memory-rules-base/CLAUDE.md\" and .[2].after == \$s + \"/memory-after-rules/CLAUDE.md\"
     and (.[0:2] | all(.[]; .base == \$s + \"/memory-base/CLAUDE.md\" and .after == \$s + \"/memory-after-facts/CLAUDE.md\"))
     and .[0].text == \$r[0].applied[0].text" --slurpfile r "$T/mr-result.json" "$T/mr-input.json" > /dev/null'
check "memory review: memory-review.json is kept in the run record and memory.json reads reviewed 3, held 3, failed 0, review ok, merged_by null" \
  'kept mr memory-review.json > "$T/mr-review.json" 2> /dev/null && [[ $(jq "[.rows[] | select(.holds)] | length" "$T/mr-review.json") == 12 ]] \
  && jq -e ".reviewed == 3 and .held == 3 and .failed == 0 and .review == \"ok\" and .merged_by == null" "$(st mr)/memory.json" > /dev/null'
check "memory review: what lands on harness-memory/<run> and harness-rules/<run> is the dry apply's after texts the reviewer read" \
  's=$T/scratch/proj/mr; git -C "$T/origin.git" show harness-memory/mr:CLAUDE.md > "$T/mr-facts.md" 2> /dev/null && git -C "$T/origin.git" show harness-rules/mr:CLAUDE.md > "$T/mr-rules.md" 2> /dev/null \
  && cmp -s "$T/mr-facts.md" "$s/memory-after-facts/CLAUDE.md" && cmp -s "$T/mr-rules.md" "$s/memory-after-rules/CLAUDE.md" && ! cmp -s "$T/mr-facts.md" "$T/mr-rules.md"'
check "memory review: a reviewer's edits to CLAUDE.md and lib/ are reverted with one note, its memory-review.json kept and the record PR opened" \
  '[[ $(hlog mr | grep -c " · memory review: reverted edits (it is read-only): ") == 1 ]] && hlog mr | grep -x -- "- .* · memory review: reverted edits (it is read-only): CLAUDE.md lib/review-hack.sh" > /dev/null \
  && ! git -C "$T/origin.git" show harness/mr:lib/review-hack.sh > /dev/null 2>&1 && ! git -C "$T/origin.git" show harness/mr:CLAUDE.md 2> /dev/null | grep -F "reviewer was here" > /dev/null \
  && [[ ! -e $T/wt/proj/mr/lib/review-hack.sh && -s $(rec mr)/memory-review.json ]] && titles | grep -x "mr: run record" > /dev/null'
check "memory review: prompts/memory-review.md renders through lib/prompt.sh as a command: the files, the four questions, the thin rule, read-only, no {{ left" \
  'P=$T/mr-prompt.md; "$HH/lib/prompt.sh" "$(st mr)" memory-review A > "$P" 2> "$T/mr-prompt.err" && [[ $(head -1 "$P") == "# Memory review session" ]] \
  && grep -F ".harness/runs/mr/memory-review-input.json" "$P" > /dev/null && grep -F ".harness/runs/mr/memory-review.json" "$P" > /dev/null \
  && grep -F "**Q1, stated and recorded.**" "$P" > /dev/null && grep -F "**Q2, no live referents.**" "$P" > /dev/null \
  && grep -F "**Q3, the cap and the anchor.**" "$P" > /dev/null && grep -F "**Q4, no duplicate.**" "$P" > /dev/null \
  && grep -F "git grep -nF -e" "$P" | grep -F "'"'"':!.harness/runs'"'"' '"'"':!journal'"'"' '"'"':!ledger'"'"' '"'"':!docs/plans'"'"'" > /dev/null \
  && grep -F "~/.claude/CLAUDE.md" "$P" > /dev/null && grep -F "$T/ledger/memory-answers.jsonl" "$P" > /dev/null && grep -F "declined" "$P" | grep -F "## Gotchas" > /dev/null \
  && grep -F "fewer than four" "$P" > /dev/null && grep -F "nothing but" "$P" | grep -F "memory-review.json" > /dev/null \
  && grep -F "denies" "$P" | grep -F "gh" > /dev/null && [[ $(grep -c "{{" "$P") == 0 ]]'
check "memory review: under pr both PR bodies and memory.md carry ## Review, one holds line per op and the five-column table; one note counts 3 reviewed · 3 held · 0 failed" \
  'p=$(mpr mr) && q=$(rpr mr) && ok=1 && for b in "$p.body" "$q.body" "$(rec mr)/memory.md"; do review "$b" > "$T/mr-rv.md"; \
    for l in "- facts/1 holds" "- facts/2 holds" "- rules/1 holds" "| Op | Q | What you ran or read | What you saw | Holds |"; do grep -xF -- "$l" "$T/mr-rv.md" > /dev/null || ok=0; done; \
    [[ $(grep -c "^| [fr][a-z]*/" "$T/mr-rv.md") == 12 ]] || ok=0; done && (( ok )) \
  && (( $(grep -n "^## Review$" "$p.body" | cut -d: -f1) < $(grep -n "^## Applied (tier 1)$" "$p.body" | cut -d: -f1) )) \
  && [[ $(hlog mr | grep -c " · memory review: 3 reviewed · 3 held · 0 failed$") == 1 ]] && ! hlog mr | grep -F " fails: " > /dev/null'
check "memory review: the rules PR carries the verdict and is never merged by the driver" \
  'q=$(rpr mr) && review "$q.body" | grep -xF -- "- rules/1 holds" > /dev/null && ! merged mr "$q"'

# mp: every op proposed: nothing would land, so no reviewer
run mp STUB_CURATOR_OPS=proposal STUB_MEMORY_REVIEW=hold
check "memory review: with every op proposed no reviewer runs, one note says nothing to review, memory.json reviewed 0, and no facts PR opens" \
  'grep -q "^done" "$(st mp)/ended" && grep -x curator "$T/scratch/proj/mp/sessions.log" > /dev/null && ! grep -x memory-review "$T/scratch/proj/mp/sessions.log" > /dev/null \
  && [[ $(hlog mp | grep -c " · memory review: ") == 1 ]] && hlog mp | grep -E " · memory review: nothing to review$" > /dev/null \
  && jq -e ".reviewed == 0 and .review == \"nothing to review\"" "$(st mp)/memory.json" > /dev/null && ! kept mp memory-review-input.json > /dev/null 2>&1 \
  && ! titles | grep -x "memory: mp" > /dev/null && [[ -z $(args mp memory-review) ]]'

# mo: a reviewer that rewrites the curator's ops in scratch, outside the tree its revert covers: nothing lands
run mo STUB_CURATOR_OPS=three-ops STUB_MEMORY_REVIEW=hold STUB_MEMORY_REVIEW_EDITS=ops
check "memory review: a reviewer that changes the ops in scratch lands nothing: the landing differs from what it read, one note, no memory branch or PR" \
  'grep -q "^done" "$(st mo)/ended" && grep -x memory-review "$T/scratch/proj/mo/sessions.log" > /dev/null \
  && [[ $(hlog mo | grep -c " · memory: the landing differs from the dry apply the reviewer read; no memory PR (see run.log)$") == 1 ]] \
  && [[ -z $(git -C "$T/origin.git" ls-remote --heads . "harness-memory/mo" "harness-rules/mo") ]] && ! titles | grep -E "^memory( rules)?: mo$" > /dev/null \
  && jq -e ".review == \"the landing differs from the dry apply\" and .held == 0" "$(st mo)/memory.json" > /dev/null \
  && titles | grep -x "mo: run record" > /dev/null'

# mk: a reviewer that plants a pre-commit hook in the shared git dir, which rewrites the landing's commit: nothing is pushed
run mk STUB_CURATOR_OPS=three-ops STUB_MEMORY_REVIEW=hold STUB_MEMORY_REVIEW_EDITS=hook
rm -f "$(git -C "$T/proj" rev-parse --path-format=absolute --git-common-dir)/hooks/pre-commit"
check "memory review: a commit a git hook changed after the landing wrote its text is never pushed: one note per tier, no memory branch or PR" \
  'grep -q "^done" "$(st mk)/ended" && grep -x memory-review "$T/scratch/proj/mk/sessions.log" > /dev/null \
  && ok=1 && for l in "memory PR" "memory rules PR"; do [[ $(hlog mk | grep -c " · $l: the commit differs from the text the landing wrote (a git hook or filter?); not pushed (see run.log)$") == 1 ]] || ok=0; done && (( ok )) \
  && [[ -z $(git -C "$T/origin.git" ls-remote --heads . "harness-memory/mk" "harness-rules/mk") ]] && ! titles | grep -E "^memory( rules)?: mk$" > /dev/null \
  && ! git -C "$T/origin.git" log --all -p | grep -F "planted by a hook" > /dev/null && titles | grep -x "mk: run record" > /dev/null'

# mt: a thin review (three rows for the first op)
run mt STUB_CURATOR_OPS=three-ops STUB_MEMORY_REVIEW=thin
check "memory review: a review with three rows for an op fails it as review too thin (3 of 4 rows); the rest hold" \
  'p=$(mpr mt) && review "$p.body" | grep -xF -- "- facts/1 **fails**: review too thin (3 of 4 rows)" > /dev/null && review "$p.body" | grep -xF -- "- facts/2 holds" > /dev/null \
  && [[ $(hlog mt | grep -c " · memory review: facts/1 fails: review too thin (3 of 4 rows)$") == 1 ]] && hlog mt | grep -E " · memory review: 3 reviewed · 2 held · 1 failed$" > /dev/null \
  && jq -e ".held == 2 and .failed == 1" "$(st mt)/memory.json" > /dev/null'

# ep / ea: at 15 Gotchas a replace (facts/1), an eviction (facts/2) and a rule; the reviewer fails the eviction's q2
base=$seed15
run ep STUB_CURATOR_OPS=evict-two STUB_MEMORY_REVIEW=evict-fails
git -C "$T/origin.git" show harness-memory/ep:CLAUDE.md > "$T/ep-claude.md" 2> /dev/null
check "memory review: under pr a failed eviction reads **fails** with its grep in the table, stays in the facts commit, is named in one note, and its PR is left open" \
  'p=$(mpr ep) && review "$p.body" | grep -E "^- facts/2 \*\*fails\*\*: 7 files: tests/checks/needs-cards\.sh, .* \(q2\)$" > /dev/null && review "$p.body" | grep -xF -- "- facts/1 holds" > /dev/null \
  && review "$p.body" | grep -F "| facts/2 | 2 | git grep -nF -e '"'"'- seeded gotcha 03: the seeded project k'"'"' -- . '"'"':!.harness/runs'"'"' | 7 files: " | grep -F "| no |" > /dev/null \
  && ! grep -F "seeded gotcha 03" "$T/ep-claude.md" > /dev/null && grep -F "work-B.txt" "$T/ep-claude.md" > /dev/null \
  && [[ $(hlog ep | grep -c " · memory review: facts/2 fails: 7 files: ") == 1 ]] && [[ ! -f $p.merged ]] && ! merged ep "$p" \
  && jq -e ".failed == 1 and .held == 2 and .merged_by == null" "$(st ep)/memory.json" > /dev/null'
pol auto
run ea STUB_CURATOR_OPS=evict-two STUB_MEMORY_REVIEW=evict-fails
git -C "$T/origin.git" show harness-memory/ea:CLAUDE.md > "$T/ea-claude.md" 2> /dev/null
check "memory review: under auto the failed eviction is dropped from the facts commit by verdict, the held replace lands, the PR merges; memory.json failed 1, merged_by driver, dropped as under pr" \
  'p=$(mpr ea) && grep -F "seeded gotcha 03" "$T/ea-claude.md" > /dev/null && ! grep -F "work-B.txt" "$T/ea-claude.md" > /dev/null \
  && grep -F "work-A.txt" "$T/ea-claude.md" > /dev/null && ! grep -F "seeded gotcha 02" "$T/ea-claude.md" > /dev/null && [[ $(gotchas < "$T/ea-claude.md" | wc -l) == 15 ]] \
  && merged ea "$p" && hlog ea | grep -F " · memory PR merged into main · $(url "$p")" > /dev/null \
  && hlog ea | grep -E " · memory: dropped add ## Gotchas \(review: 7 files: .* \(q2\) \(facts/2\)\)$" > /dev/null \
  && review "$p.body" | grep -E "^- facts/2 \*\*fails\*\*: 7 files: " > /dev/null \
  && jq -e --slurpfile e "$(st ep)/memory.json" ".failed == 1 and .held == 2 and .merged_by == \"driver\" and .dropped == \$e[0].dropped" "$(st ea)/memory.json" > /dev/null'
check "memory review: under auto the rules PR carries every op with its verdict and is never merged" \
  'q=$(rpr ea) && review "$q.body" | grep -xF -- "- rules/1 holds" > /dev/null && ! merged ea "$q" \
  && git -C "$T/origin.git" show harness-rules/ea:CLAUDE.md | grep -F "stub proposal: run the stub suite" > /dev/null'

# mn, mb, ml, mx under auto: no review (no file, an invalid file, a limit, a valid file and then a timeout) leaves the PR open with every op in it
base=$main0
run mn STUB_CURATOR_OPS=fact-a STUB_MEMORY_REVIEW=none
mnmain=$(git -C "$T/origin.git" rev-parse main)   # its continue curates against the main it ended on
run mb STUB_CURATOR_OPS=three-ops STUB_MEMORY_REVIEW=bad
run ml STUB_CURATOR_OPS=three-ops STUB_MEMORY_REVIEW=limit
run mx STUB_CURATOR_OPS=three-ops STUB_MEMORY_REVIEW=hold-exit
check "memory review: with no review (no file, an invalid file, a limit, a timeout after a valid file) under auto the PR opens with none: <why>, one note, every op committed and no merge" \
  'ok=1; for x in "mn:the reviewer wrote no memory-review.json" "mb:memory-review.json invalid: not JSON" "ml:the reviewer hit a limit" "mx:the reviewer failed"; do r=${x%%:*} why=${x#*:}; p=$(mpr "$r") \
    && review "$p.body" | grep -E "^none: ${why}" > /dev/null && [[ $(hlog "$r" | grep -c " · memory review: none (${why}") == 1 ]] \
    && hlog "$r" | grep -E " · memory PR: no review \(${why}.*\); not merged \(MEMORY_POLICY=auto\), left open · $(url "$p")$" > /dev/null \
    && ! merged "$r" "$p" && git -C "$T/origin.git" show "harness-memory/$r:CLAUDE.md" | grep -F "work-A.txt" > /dev/null \
    && jq -e ".merged_by == null and (.review | startswith(\"${why}\"))" "$(st "$r")/memory.json" > /dev/null || { echo "$r" >&2; ok=0; }; done; (( ok )) && jq -e ".review == \"the reviewer failed (exit 124)\"" "$(st mx)/memory.json" > /dev/null && [[ -s $(rec mx)/memory-review.json ]]'
# mn's continue: a new fact, a reviewer that holds it; the reused PR still carries mn's unreviewed commit, so no merge
git -C "$T/origin.git" update-ref refs/heads/main "$mnmain"
STUB_CURATOR_OPS=fact-b STUB_MEMORY_REVIEW=hold STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue mn --foreground > "$T/mn2.out" 2>&1
mv "$T/gh.log" "$T/gh-mn2.log" 2> /dev/null
check "memory review: a continue after no review reviews its new fact and leaves the reused PR open under auto, its earlier commit unreviewed" \
  'p=$(mpr mn) && grep -x memory-review "$T/scratch/proj/mn/sessions.log" > /dev/null && [[ $(grep -cx memory-review "$T/scratch/proj/mn/sessions.log") == 2 ]] \
  && hlog mn | grep -E " · memory review: 1 reviewed · 1 held · 0 failed$" > /dev/null && ! merged mn2 "$p" && [[ ! -f $p.merged ]] \
  && c=$(git -C "$T/origin.git" rev-list --reverse "$mnmain..harness-memory/mn" | head -1) && [[ -n $c ]] \
  && hlog mn | grep -xF -- "$(hlog mn | grep -F " · memory PR: ${c:0:12} on harness-memory/mn is not this segment'"'"'s commit; not merged (MEMORY_POLICY=auto), left open · $(url "$p")" | head -1)" > /dev/null \
  && [[ $(hlog mn | grep -c " is not this segment'"'"'s commit; ") == 1 ]] && review "$p.body" | grep -xF -- "- facts/1 holds" > /dev/null && jq -e ".merged_by == null" "$(st mn)/memory.json" > /dev/null'

# md under pr: a fact restating a rule Michael declined (a memory-answers.jsonl row): the reviewer fails its q4
pol pr
mkdir -p "$T/ledger" && jq -nc '{run: "old", project: "proj", n: 1, tier: 2, verdict: "declined", why: "not a rule", file: "CLAUDE.md", section: "## Code rules",
  text: "the stub'"'"'s A work sits in work-A.txt at the root", key: "the stub'"'"'s a work sits in work-a.txt at", at: "2026-11-08 10:00"}' > "$T/ledger/memory-answers.jsonl"
run md STUB_CURATOR_OPS=three-ops STUB_MEMORY_REVIEW=declined
rm -f "$T/ledger/memory-answers.jsonl"
# mq: a reviewer that writes the ledger's answers file (outside the tree, read by the landing): nothing lands
run mq STUB_CURATOR_OPS=three-ops STUB_MEMORY_REVIEW=hold STUB_MEMORY_REVIEW_EDITS=answers
rm -f "$T/ledger/memory-answers.jsonl"
check "memory review: a fact restating a rule Michael declined fails q4 naming declined by Michael (<run>/<n>), marked **fails** in the PR body under pr" \
  'p=$(mpr md) && review "$p.body" | grep -xF -- "- facts/1 **fails**: declined by Michael (old/1) (q4)" > /dev/null && review "$p.body" | grep -xF -- "- facts/2 holds" > /dev/null \
  && kept md memory-review.json | jq -e "[.rows[] | select(.holds | not)] | length == 1 and .[0].q == 4" > /dev/null \
  && git -C "$T/origin.git" show harness-memory/md:CLAUDE.md | grep -F "work-A.txt" > /dev/null && ! merged md "$p"'
check "memory review: a file the landing reads that changes during the review (the answers file) lands nothing: one note, no memory branch or PR" \
  'grep -x memory-review "$T/scratch/proj/mq/sessions.log" > /dev/null && grep -F "memory: a file the landing reads changed during the memory review" "$(st mq)/run.log" > /dev/null \
  && [[ $(hlog mq | grep -c " · memory: the landing differs from the dry apply the reviewer read; no memory PR (see run.log)$") == 1 ]] \
  && [[ -z $(git -C "$T/origin.git" ls-remote --heads . "harness-memory/mq" "harness-rules/mq") ]] && titles | grep -x "mq: run record" > /dev/null'

suite_end
