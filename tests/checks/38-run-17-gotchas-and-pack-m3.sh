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
# a wrapped bullet is one line (its indented continuation joins it), and a `# ` heading ends the section too (M3-05)
check "gotchasLines: a wrapped bullet is one line and any # or ## heading ends the section" '
  [[ $(gd "$G" "${G/- two (r 2026-10-26)/- two (r 2026-10-26)$'"'"'\n'"'"'- three wraps$'"'"'\n'"'"'  onto a second line (r 2026-10-26)}") == "+1 ~0 -0" ]] &&
  [[ $(gd "${G/## Later/# Later}" "${G/$'"'"'## Later\nx'"'"'/$'"'"'# Later\ny'"'"'}") == "+0 ~0 -0" ]] &&
  [[ $(node --input-type=module -e "import { gotchasLines as g } from \"$MM\"; console.log(JSON.stringify(g(\"## Gotchas\n- a\n  b\n\n- c\n\")))") == "[\"- a b\",\"- c\"]" ]]'
# the CLI builds the pack without the Gotchas when CLAUDE.md can't be read (here a directory), as readRules skips its store
check "entries.mjs pack: an unreadable CLAUDE.md leaves the Gotchas out, never the pack" '
  mkdir -p "$T/cw/.harness/runs/r" "$T/cw/CLAUDE.md" && : > "$T/cw/.harness/runs/r/entries.jsonl" && echo "{\"features\":[{\"id\":\"X\",\"milestone\":\"M1\"}]}" > "$T/cw/.harness/runs/r/feature_list.json" &&
  node "$HERE/../lib/entries.mjs" pack "$T/cw/.harness/runs/r" X 8192 > "$T/cw.out" 2> "$T/cw.err" && grep -q "^# Context pack for \`X\`" "$T/cw.out"'
# the stub project has a decisions store (rane-one-mixxx's first three, copied): every pack ends with its rules (M3-04)
mkdir -p docs && cp "$HERE/fixtures/decisions-rane.md" docs/decisions.md && git add docs && git commit -qm "decisions store" && git push -q origin main
# the same run asks and resolves a question of C's (M3-03) and records A's project fact, which B's Gotchas line carries
STUB_GOTCHA=B STUB_PROJECT_FACT=A STUB_ASK=C STUB_RESOLVE=C "$H" start "$T/proj" gotcha --spec SPEC.md --foreground > "$T/gotcha.out" 2>&1
check "coding prompt: the Finish step adds one Gotchas line" '
  p=$(sed -n "/^## 3\. Finish/,/^Final message/p" "$HARNESS_STATE/proj/gotcha/prompt-coding.md" | tr -s " \n" "  ") &&
  [[ $p == *"## Gotchas"* && $p == *"160 characters"* && $p == *"(<run> <date>)"* && $p == *"15 lines"* && $p == *"never rewrite the section"* ]]'
check "a stub session that adds a Gotchas line is noted" '
  hlog gotcha | grep -q "· B: gotchas +1 ~0 -0$" && git -C "$T/wt/proj/gotcha" show HEAD:CLAUDE.md | sed -n "/^## Gotchas/,\$p" | grep "(gotcha " > /dev/null'
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
  sed -n "/^## Promote to Gotchas/,/^## /p" "$GL/02-B.context.md" | grep -x -- "- the stub.s work files sit at the repo root, one per feature → entries.jsonl:[0-9]*" > /dev/null &&
  ! grep -q "Promote to Gotchas" "$GL/01-A.context.md" && ! grep -q "Promote to Gotchas" "$GL/03-A.context.md" && grep -q "^## " "$GL/03-A.context.md"'
check "context.md lists the decisions store's rules newest first" '
  [[ $(grep "^## " "$GL/01-A.context.md" | tail -1) == "## Current rules" ]] &&
  [[ $(sed -n "/^## Current rules/,\$p" "$GL/01-A.context.md" | grep -o "^- D[0-9]* .*→ docs/decisions.md:[0-9]*$" | sed "s/^- \(D[0-9]*\) .*:\([0-9]*\)$/\1@\2/" | tr "\n" " ") == "D3@15 D2@13 D1@7 " ]] &&
  grep -q -- "^- D1 default · Playback model: hybrid. Mixxx.s clock plays the track while the platter is within tolerance of the expected .*… → docs/decisions.md:7$" "$GL/01-A.context.md"'
# a 1024-byte coding cap from the project's config, and a verify that finds A's step 1 failing after A recorded a dead end
git pull -q --ff-only origin main && printf 'CONTEXT_PACK_BYTES=1024\n' >> .harness/config.sh && git commit -qam "a tight pack" && git push -q origin main
STUB_VERIFY_FAIL_ROW=1 "$H" start "$T/proj" tight --spec SPEC.md --foreground > "$T/tight.out" 2>&1
TL=$HARNESS_STATE/proj/tight/logs
check "CONTEXT_PACK_BYTES=1024 holds for coding packs and verify packs get their own cap" '
  ls "$TL"/[0-9][0-9]-*.context.md > "$T/tight.ls" && (( $(wc -l < "$T/tight.ls") >= 4 )) &&
  [[ -z $(find "$TL" -name "[0-9][0-9]-*.context.md" -size +1024c) ]] && grep -l "^_[0-9]* items left out at 1024 bytes" $(cat "$T/tight.ls") > /dev/null &&
  v=$(ls "$TL"/*-verify-M1.context.md | head -1) && (( $(wc -c < "$v") > 1024 && $(wc -c < "$v") <= 16384 )) &&
  hlog tight | grep -q "· context.md for M1: [0-9]* bytes" && (( $(hlog tight | sed -n "s/.*· context.md for M1: \([0-9]*\) bytes.*/\1/p" | sort -n | tail -1) > 1024 ))'
check "a verify pack lists failed rows before dead ends" '
  v=$(grep -l "^- Verify M1 found" "$TL"/*-verify-M1.context.md | head -1) && r=$(grep -n "^- Verify M1 found (A step 1): ran check; saw A fails" "$v" | head -1 | cut -d: -f1) &&
  d=$(grep -n "^- Dead end (A," "$v" | head -1 | cut -d: -f1) && [[ -n $r && -n $d ]] && (( r < d ))'
suite_end
