#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- one writer for project memory (M1-03): a coding session's CLAUDE.md and .harness/project.md edits are reverted ----
# (decisions/2026-11-07-memory-one-writer). A edits CLAUDE.md and a file under lib/, tests/ and journal/decisions/;
# A also writes .claude/CLAUDE.md and .claude/rules/r.md (the twins Claude Code loads, N1-02); B edits .harness/project.md;
# C leaves them all alone; the initializer writes a Gotchas line too.
RN="(project memory is the curator's; say it in the entry)"
m0=$(git -C "$T/origin.git" rev-parse main)
STUB_GOTCHA=A STUB_TOUCH_CODE=A STUB_DOT_CLAUDE=A STUB_PROJECT_MD=B STUB_INIT_GOTCHA=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 \
  "$H" start "$T/proj" mem --spec SPEC.md --foreground > "$T/mem.out" 2>&1
check "memory: a coding session's CLAUDE.md edit is reverted with one note in the coding prompt's words, and the run ends done" '
  grep -q "^done" "$HARNESS_STATE/proj/mem/ended" && [[ $(tr -s " \n" "  " < "$HARNESS_STATE/proj/mem/prompt-coding.md") == *"notes \`<feature>: reverted its CLAUDE.md edit $RN\`"* ]] &&
  git -C "$T/origin.git" diff --quiet "$m0" run/mem/M1 -- CLAUDE.md && git -C "$T/origin.git" diff --quiet "$m0" main -- CLAUDE.md &&
  [[ $(hlog mem | grep -cF "· A: reverted its CLAUDE.md edit $RN") == 1 ]]'
check "memory: the same session's lib, tests and journal/decisions edits stay on the branch and merge" '
  miss=0; for r in run/mem/M1 main; do for p in lib/stub-A.sh tests/stub-A.txt journal/decisions/stub-A.md; do
    git -C "$T/origin.git" cat-file -e "$r:$p" 2> /dev/null || { echo "missing $r:$p"; miss=1; }; done; done; (( ! miss ))'
check "memory: a coding session's .harness/project.md edit is reverted the same way" '
  ! git -C "$T/origin.git" cat-file -e run/mem/M1:.harness/project.md 2> /dev/null && ! git -C "$T/origin.git" cat-file -e main:.harness/project.md 2> /dev/null &&
  [[ $(hlog mem | grep -cF "· B: reverted its .harness/project.md edit $RN") == 1 && $(hlog mem | grep -cF "· B: reverted its CLAUDE.md") == 0 ]]'
check "memory: a coding session's .claude/CLAUDE.md and .claude/rules/ files are reverted the same way, one note each" '
  miss=0; for r in run/mem/M1 main; do for p in .claude/CLAUDE.md .claude/rules/r.md; do
    ! git -C "$T/origin.git" cat-file -e "$r:$p" 2> /dev/null || { echo "still there: $r:$p"; miss=1; }; done; done; (( ! miss )) &&
  [[ $(hlog mem | grep -cF "· A: reverted its .claude/CLAUDE.md edit $RN") == 1 && $(hlog mem | grep -cF "· A: reverted its .claude/rules/r.md edit $RN") == 1 ]]'
check "memory: a session that leaves CLAUDE.md and .harness/project.md alone gets no revert note" '
  grep -q "^C attempt 1$" "$T/scratch/proj/mem/sessions.log" && [[ $(hlog mem | grep -c ": reverted its ") == 4 ]] && ! hlog mem | grep -q "· C: reverted its "'
check "memory: the initializer's Gotchas write stays reverted with its outside-the-record note" '
  hlog mem | grep -qF "· initializer: reverted edits outside the run record (the record branch holds the record only): CLAUDE.md" &&
  git -C "$T/origin.git" diff --quiet "$m0" harness/mem -- CLAUDE.md'

# sourced, on a throwaway repo: restrict's memory spec reverts the root files and the twins, added, edited or deleted, and only them
R=$T/rm; git init -q -b main "$R"; rg_() { git -C "$R" -c user.name=t -c user.email=t@t "$@"; }
mkdir -p "$R/.harness" "$R/lib" "$R/docs" "$R/.claude"; echo rules > "$R/CLAUDE.md"; echo c1 > "$R/.harness/config.sh"; echo s1 > "$R/.claude/settings.json"
rg_ add -A; rg_ commit -qm base
rm_out=$( cd "$R" && HARNESS_HOME=$HH source "$HERE/../lib/record.sh"
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  b=$(git rev-parse HEAD); echo more >> CLAUDE.md; echo p > .harness/project.md; echo d > docs/CLAUDE.md; echo x > lib/x.sh; echo c2 > .harness/config.sh
  echo twin > .claude/CLAUDE.md; mkdir -p .claude/rules/a; echo rule > .claude/rules/a/b.md; echo r > .claude/rules/café.md; echo s2 > .claude/settings.json
  echo "first=$(restrict "$b" memory A | paste -sd,)"
  [[ $(cat CLAUDE.md) == rules && ! -e .harness/project.md && ! -e .claude/CLAUDE.md && ! -e .claude/rules/a/b.md && ! -e .claude/rules/café.md ]] && echo back
  [[ -f docs/CLAUDE.md && -f lib/x.sh && $(cat .harness/config.sh) == c2 && $(cat .claude/settings.json) == s2 && -z $(git status --porcelain) ]] && echo kept
  b=$(git rev-parse HEAD); git rm -q CLAUDE.md; git commit -qm gone
  echo "second=$(restrict "$b" memory A | paste -sd,)"; [[ $(cat CLAUDE.md) == rules ]] && echo restored )
check "restrict memory: CLAUDE.md, .harness/project.md, .claude/CLAUDE.md and .claude/rules/ go back, added, edited or deleted; .claude/settings.json, docs/CLAUDE.md, lib/ and .harness/config.sh stay" \
  '[[ $(paste -sd" " <<< "$rm_out") == "first=.claude/CLAUDE.md,.claude/rules/a/b.md,.claude/rules/café.md,.harness/project.md,CLAUDE.md back kept second=CLAUDE.md restored" ]]'

# memory_guard after a session merged main itself: main's CLAUDE.md lines are main's (merge-base base), the session's go
G=$T/mg; git init -q --bare -b main "$G/o.git"; git clone -q "$G/o.git" "$G/main" 2> /dev/null
gg() { git -C "$G/$1" -c user.name=t -c user.email=t@t "${@:2}"; }
echo rules > "$G/main/CLAUDE.md"; gg main add -A; gg main commit -qm base; gg main push -q origin main
git clone -q "$G/o.git" "$G/lane" 2> /dev/null; gg lane checkout -q -b harness-lane/u/M1
echo "main's line" >> "$G/main/CLAUDE.md"; gg main commit -qam "main moves"; gg main push -q origin main
mg_out=$( cd "$G/lane" && HARNESS_HOME=$HH source "$HERE/../lib/record.sh"; MAIN_BRANCH=main; note() { echo "$*" >> "$G/notes"; }
  export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
  sstart=$(git rev-parse HEAD); echo c > c; git add c; git commit -qm code; git fetch -q origin; git merge -q --no-edit origin/main
  echo "the session's line" >> CLAUDE.md; git commit -qam "a Gotchas line"
  memory_guard "$sstart" A
  [[ $(git rev-parse HEAD:CLAUDE.md) == $(git rev-parse origin/main:CLAUDE.md) ]] && echo main; git cat-file -e HEAD:c && echo code )
check "memory_guard: after a session's own merge of main, main's CLAUDE.md lines stay; only the session's own edit goes" \
  '[[ $(paste -sd" " <<< "$mg_out") == "main code" && $(cat "$G/notes") == "A: reverted its CLAUDE.md edit $RN" ]]'
suite_end
