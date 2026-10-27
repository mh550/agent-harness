#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- one routing rule (M2): decisionsStore() names the project's decisions store; every session's prompt carries the ----
# ---- `## Where things go` block once, unless the project's CLAUDE.md already has it ----
M="node $HERE/../lib/memlint.mjs" MM=$HERE/../lib/memlint.mjs
ds() { node --input-type=module -e 'import { decisionsStore } from "'"$MM"'"; console.log(JSON.stringify(decisionsStore(process.argv[1])))' "$1"; }
mkdir -p "$T/ds/dir/.harness" "$T/ds/dir/journal/decisions" "$T/ds/file/docs" "$T/ds/none/.harness"
printf '%s\n' 'CHECK_CMD="true"' '# DECISIONS=docs/old.md' 'DECISIONS=journal/decisions' > "$T/ds/dir/.harness/config.sh"
echo "# decisions" > "$T/ds/file/docs/decisions.md"; echo 'CHECK_CMD="true"' > "$T/ds/none/.harness/config.sh"
check "memlint.mjs: node --check passes, a usage header, decisionsStore exported" '
  node --check "$MM" && head -1 "$MM" | grep -q "^// " && grep -q "store <worktree>" "$MM" &&
  node --input-type=module -e "import { decisionsStore } from \"$MM\"; process.exit(typeof decisionsStore === \"function\" ? 0 : 1)"'
check "decisionsStore: DECISIONS=journal/decisions in .harness/config.sh is a directory store" '
  [[ $(ds "$T/ds/dir") == "{\"path\":\"journal/decisions\",\"kind\":\"dir\",\"exists\":true}" ]] && [[ $($M store "$T/ds/dir") == journal/decisions ]]'
check "decisionsStore: no DECISIONS and docs/decisions.md present is a file store" '
  [[ $(ds "$T/ds/file") == "{\"path\":\"docs/decisions.md\",\"kind\":\"file\",\"exists\":true}" ]] && [[ $($M store "$T/ds/file") == docs/decisions.md ]]'
check "decisionsStore: neither is null, and store prints nothing" '
  [[ $(ds "$T/ds/none") == null ]] && o=$($M store "$T/ds/none") && [[ -z $o ]]'
check "decisionsStore: a quoted DECISIONS wins over docs/decisions.md, an unknown command exits 2" '
  mkdir -p "$T/ds/file/.harness" && echo "export DECISIONS=\"docs/d.md\"   # one file" > "$T/ds/file/.harness/config.sh" &&
  [[ $($M store "$T/ds/file") == docs/d.md ]] && [[ $(ds "$T/ds/file" | jq -r "[.kind, .exists] | join(\" \")") == "file false" ]] &&
  { $M frob > /dev/null 2>&1; (( $? == 2 )); }'
# ---- the block in the rendered prompts of a stub run: default CLAUDE.md (no heading), with the heading, no CLAUDE.md ----
P() { echo "$HARNESS_STATE/proj/$1/prompt-$2.md"; }
n() { grep -c "## Where things go" "$(P "$1" "$2")"; }
"$H" start "$T/proj" wt1 --spec SPEC.md --foreground > "$T/wt1.out" 2>&1
check "where things go: the coding, initializer and verify prompts carry the block once when CLAUDE.md lacks the heading" '
  [[ $(n wt1 coding) == 1 && $(n wt1 initializer) == 1 && $(n wt1 verify) == 1 ]] &&
  grep -q "Gotchas" "$(P wt1 coding)" && grep -q "Updated in place" "$(P wt1 initializer)" && ! grep -q "{{DECISIONS}}" "$(P wt1 coding)" &&
  grep -q "where the project rules say decisions live" "$(P wt1 coding)"'
check "where things go: the verify prompt has the read-only variant (discoveries, no Gotchas edit)" '
  sed -n "/^## Where things go/,/^#/p" "$(P wt1 verify)" | grep "discoveries" > /dev/null &&
  ! sed -n "/^## Where things go/,/^#/p" "$(P wt1 verify)" | grep -q "Updated in place" && grep -q "^## Where things go" "$(P wt1 retro)"'
git pull -q --ff-only origin main && printf '# proj\nrules\n\n## Where things go\n\nours\n' > CLAUDE.md && git commit -qam "where things go" && git push -q origin main
"$H" start "$T/proj" wt2 --spec SPEC.md --foreground > "$T/wt2.out" 2>&1
check "where things go: with the heading in CLAUDE.md the three prompts carry the block 0 times" '
  [[ $(n wt2 coding) == 0 && $(n wt2 initializer) == 0 && $(n wt2 verify) == 0 ]] && grep -qx "# Project rules" "$(P wt2 coding)"'
git pull -q --ff-only origin main && git rm -q CLAUDE.md && echo DECISIONS=journal/decisions >> .harness/config.sh && git commit -qam "no CLAUDE.md" && git push -q origin main
"$H" start "$T/proj" wt3 --spec SPEC.md --foreground > "$T/wt3.out" 2>&1
check "where things go: with no CLAUDE.md the three prompts carry the block once each, the store from DECISIONS=" '
  [[ $(n wt3 coding) == 1 && $(n wt3 initializer) == 1 && $(n wt3 verify) == 1 ]] && ! grep -q "CLAUDE.md. at the root of this worktree" "$(P wt3 coding)" &&
  grep -q "one file per decision in .journal/decisions/., never numbered" "$(P wt3 coding)"'
check "where things go: verify and retro keep the read-only rule without the heading when CLAUDE.md has its own block" '
  ok=1; for k in verify retro; do [[ $(n wt2 $k) == 0 ]] && grep -q "^\*\*Read-only session\.\*\*.*discoveries" "$(P wt2 $k)" || ok=0; done; (( ok )) &&
  ! grep -q "Read-only session" "$(P wt2 coding)" && ! grep -q "Read-only session" "$(P wt1 verify)"'
check "where things go: the retro prompt carries the read-only variant once, with or without a CLAUDE.md" '
  ok=1; for r in wt1 wt3; do [[ $(n $r retro) == 1 ]] && sed -n "/^## Where things go/,/^#/p" "$(P $r retro)" | grep "discoveries" > /dev/null &&
    ! sed -n "/^## Where things go/,/^#/p" "$(P $r retro)" | grep -q "Updated in place" || ok=0; done; (( ok ))'
# ---- the prompts and templates stop contradicting the block (M2-02) ----
check "routing: the rendered initializer prompt sends gotchas to ## Gotchas, run-only facts to discoveries, no decision number" '
  i=$(tr -s " \n" "  " < "$(P wt1 initializer)") && [[ $i != *"where things live, gotchas"* && $i != *"D<n>"* ]] &&
  [[ $i == *"a durable gotcha (still true after this run) → one line under \`## Gotchas\`"* ]] &&
  [[ $i == *"a run-only fact → \`discoveries\` affecting \`\"run\"\`"* && $i == *"says \`record as a new decision\`"* ]]'
check "routing: coding.md points at the block, draft-claude-md.md asks for the block and Gotchas and no test count" '
  c=$HERE/../prompts/coding.md d=$HERE/../prompts/draft-claude-md.md &&
  sed -n "/^- \*\*Decisions\.\*\*/,/^- \*\*W/p" "$c" | grep "Where things go" > /dev/null && ! grep -q "D<n> \*default\*" "$c" &&
  grep -q "## Where things go" "$d" && grep -q "## Gotchas" "$d" && ! grep -q "test count, duration" "$d"'
check "routing: the project template has the block and an empty Gotchas after Decisions and plans, a commented DECISIONS=" '
  t=$HERE/../templates/project/CLAUDE.md && ! grep -q "<count> tests" "$t" &&
  [[ $(grep -n "^## " "$t" | sed -n "/Decisions and plans/{n;N;p}" | cut -d: -f2 | tr "\n" "|") == "## Where things go|## Gotchas|" ]] &&
  [[ -z $(sed -n "/^## Gotchas/,/^## /p" "$t" | sed "1d;\$d" | grep -v "^ *$" | grep -v "^<!--.*-->$") ]] &&
  grep -q "^# DECISIONS=" "$HERE/../templates/project/config.sh" && bash -n "$HERE/../templates/project/config.sh"'
check "routing: this repo has the block (journal/decisions/, never numbered), an empty Gotchas and DECISIONS=journal/decisions" '
  r=$HERE/.. && sed -n "/^## Where things go/,/^## /p" "$r/CLAUDE.md" | grep "journal/decisions/.*never numbered" > /dev/null &&
  grep -qx "## Gotchas" "$r/CLAUDE.md" && grep -qx "DECISIONS=journal/decisions" "$r/.harness/config.sh" &&
  [[ $(node "$MM" store "$r") == journal/decisions ]]'
suite_end
