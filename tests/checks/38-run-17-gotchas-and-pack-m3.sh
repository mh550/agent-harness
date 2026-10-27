#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- Gotchas in place (M3): the coding prompt's Finish step edits one `## Gotchas` line; the driver notes the diff ----
MM=$HERE/../lib/memlint.mjs
gd() { node --input-type=module -e 'import { gotchasDiff } from "'"$MM"'"; const [b, a] = process.argv.slice(1).map(s => s === "-" ? null : s);
  const d = gotchasDiff(b, a); console.log(`+${d.added} ~${d.edited} -${d.deleted}`)' "$1" "$2"; }
G=$'# p\nrules\n\n## Gotchas\n\n- one (r 2026-10-26)\n- two (r 2026-10-26)\n\n## Later\nx\n'
check "gotchasDiff: added, edited, deleted and no section" '
  [[ $(gd "$G" "${G/- two (r 2026-10-26)/- two (r 2026-10-26)$'"'"'\n'"'"'- three (r 2026-10-26)}") == "+1 ~0 -0" ]] &&
  [[ $(gd "$G" "${G/- two/- 2}") == "+0 ~1 -0" ]] && [[ $(gd "$G" "${G/- two (r 2026-10-26)$'"'"'\n'"'"'/}") == "+0 ~0 -1" ]] &&
  [[ $(gd $'"'"'# p\nrules\n'"'"' $'"'"'# p\nother\n'"'"') == "+0 ~0 -0" ]] && [[ $(gd - -) == "+0 ~0 -0" ]] && [[ $(gd - $'"'"'# p\n'"'"') == "+0 ~0 -0" ]] &&
  [[ $(gd "$G" "${G/rules/changed}") == "+0 ~0 -0" ]] && [[ $(gd "$G" "${G/x/y}") == "+0 ~0 -0" ]] &&
  printf "%s" "$G" > "$T/g1.md" && printf "%s" "${G/- two/- 2}" > "$T/g2.md" &&
  [[ $(node "$MM" gotchas "$T/g1.md" "$T/g2.md") == "+0 ~1 -0" ]] && o=$(node "$MM" gotchas "$T/g1.md" "$T/g1.md") && [[ -z $o ]] &&
  [[ $(node "$MM" gotchas "$T/none.md" "$T/g1.md") == "+2 ~0 -0" ]]'
# the same run asks and resolves a question of C's (M3-03) and records A's project fact, which B's Gotchas line carries
STUB_GOTCHA=B STUB_PROJECT_FACT=A STUB_ASK=C STUB_RESOLVE=C "$H" start "$T/proj" gotcha --spec SPEC.md --foreground > "$T/gotcha.out" 2>&1
check "coding prompt: the Finish step adds one Gotchas line" '
  p=$(sed -n "/^## 3\. Finish/,/^Final message/p" "$HARNESS_STATE/proj/gotcha/prompt-coding.md" | tr -s " \n" "  ") &&
  [[ $p == *"## Gotchas"* && $p == *"160 characters"* && $p == *"(<run> <date>)"* && $p == *"15 lines"* && $p == *"never rewrite the section"* ]]'
check "a stub session that adds a Gotchas line is noted" '
  hlog gotcha | grep -q "· B: gotchas +1 ~0 -0$" && git -C "$T/wt/proj/gotcha" show HEAD:CLAUDE.md | sed -n "/^## Gotchas/,\$p" | grep -q "(gotcha "'
check "a session that leaves CLAUDE.md alone gets no gotchas note" '
  [[ $(hlog gotcha | grep -c ": gotchas ") == 1 ]] && (( $(grep -c " attempt " "$T/scratch/proj/gotcha/sessions.log") >= 3 ))'
GL=$HARNESS_STATE/proj/gotcha/logs
check "coding and verify prompts name resolved, project facts and Promote to Gotchas" '
  c=$(tr -s " \n" "  " < "$HARNESS_STATE/proj/gotcha/prompt-coding.md") && v=$(tr -s " \n" "  " < "$HARNESS_STATE/proj/gotcha/prompt-verify.md") &&
  [[ $c == *"\"resolved\": [\"Should X default to off?\"]"* && $c == *"\"affects\": [\"project\"]"* && $c == *"\"project\"\` for a fact that outlives the run"* ]] &&
  [[ $c == *"Write each \`Promote to Gotchas\` item of context.md"* && $v == *"durable fact"*"with \`affects: [\"project\"]\`"* ]]'
check "a resolved question is gone from the next context.md" '
  grep -qx -- "- Question (C): Should C default to off? → entries.jsonl:[0-9]*" "$GL/05-C.context.md" &&
  v=$(ls "$GL"/*-verify-M2.context.md | head -1) && grep -q "^# Context pack for \`M2\`" "$v" && ! grep -q "Question (" "$v"'
check "a project discovery is listed under Promote to Gotchas until CLAUDE.md carries it" '
  sed -n "/^## Promote to Gotchas/,/^## /p" "$GL/02-B.context.md" | grep -qx -- "- the stub.s work files sit at the repo root, one per feature → entries.jsonl:[0-9]*" &&
  ! grep -q "Promote to Gotchas" "$GL/01-A.context.md" && ! grep -q "Promote to Gotchas" "$GL/03-A.context.md" && grep -q "^## " "$GL/03-A.context.md"'
suite_end
