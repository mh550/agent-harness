#!/usr/bin/env bash
# tier: slow
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- Gotchas in place (M3): the coding prompt's Finish step edits one `## Gotchas` line; the driver notes the diff ----
MM=$HERE/../lib/memlint.mjs
G=$'# p\nrules\n\n## Gotchas\n\n- one (r 2026-10-26)\n- two (r 2026-10-26)\n\n## Later\nx\n'
# gotchasDiff and gotchasLines are tests/unit/memlint.test.mjs; here the gotchas CLI on two files
check "memlint.mjs gotchas: the CLI prints +added ~edited -deleted of two files, nothing for none, a missing file as no section" '
  printf "%s" "$G" > "$T/g1.md" && printf "%s" "${G/- two/- 2}" > "$T/g2.md" &&
  [[ $(node "$MM" gotchas "$T/g1.md" "$T/g2.md") == "+0 ~1 -0" ]] && o=$(node "$MM" gotchas "$T/g1.md" "$T/g1.md") && [[ -z $o ]] &&
  [[ $(node "$MM" gotchas "$T/none.md" "$T/g1.md") == "+2 ~0 -0" ]]'
# the stub project has a decisions store (rane-one-mixxx's first three, copied): every pack ends with its rules (M3-04)
mkdir -p docs && cp "$HERE/fixtures/decisions-rane.md" docs/decisions.md && git add docs && git commit -qm "decisions store" && git push -q origin main
# the same run asks and resolves a question of C's (M3-03)
STUB_GOTCHA=B STUB_ASK=C STUB_RESOLVE=C "$H" start "$T/proj" gotcha --spec SPEC.md --foreground > "$T/gotcha.out" 2>&1
check "a stub session that adds a Gotchas line is noted" '
  hlog gotcha | grep -q "· B: gotchas +1 ~0 -0$" && git -C "$T/wt/proj/gotcha" show run/gotcha/M1:CLAUDE.md | sed -n "/^## Gotchas/,\$p" | grep "(gotcha " > /dev/null'
check "a session that leaves CLAUDE.md alone gets no gotchas note" '
  [[ $(hlog gotcha | grep -c ": gotchas ") == 1 ]] && (( $(grep -c " attempt " "$T/scratch/proj/gotcha/sessions.log") >= 3 ))'
GL=$HARNESS_STATE/proj/gotcha/logs
# M1-02: a fact goes in the entry, never in CLAUDE.md (decisions/2026-11-07-memory-one-writer)
check "coding and verify prompts: a fact to discoveries affecting project, a workflow line to proposed_changes, a stale one to resolved; no Gotchas write" '
  c=$(tr -s " \n" "  " < "$HARNESS_STATE/proj/gotcha/prompt-coding.md") && v=$(tr -s " \n" "  " < "$HARNESS_STATE/proj/gotcha/prompt-verify.md") &&
  p=$(sed -n "/^## 3\. Finish/,/^Final message/p" "$HARNESS_STATE/proj/gotcha/prompt-coding.md" | tr -s " \n" "  ") &&
  [[ $p == *"leave the project'"'"'s \`CLAUDE.md\` and \`.harness/project.md\` alone"* && $p == *"\`discoveries\` with \`affects: [\"project\"]\`: at most 160 characters, ending \`(<run> <date>)\`"* ]] &&
  [[ $p == *"workflow line (how to work here) goes in \`proposed_changes\`"* && $p == *"\`Promote to Gotchas\` part first"*"no longer holds in your entry'"'"'s \`resolved\`"* ]] &&
  [[ $c != *"under \`## Gotchas\`"* && $c != *"15 lines at most"* && $c == *"\"resolved\": [\"Should X default to off?\"]"* && $c == *"\"affects\": [\"project\"]"* ]] &&
  [[ $c == *"\"project\"\` for a fact that outlives the run"* && $v == *"durable fact"*"with \`affects: [\"project\"]\`"* ]]'
check "a resolved question is gone from the next context.md" '
  grep -Eqx -- "- Question \(C\): Should C default to off\? Files \(harness, from the session\): /.*/work-C.txt(, /[^ ]+)* → entries.jsonl:[0-9]+" "$GL/05-C.context.md" &&
  v=$(ls "$GL"/*-verify-M2.context.md | head -1) && grep -q "^# Context pack for \`M2\`" "$v" && ! grep -q "Question (" "$v"'
check "context.md lists the decisions store's rules newest first" '
  [[ $(grep "^## " "$GL/01-A.context.md" | tail -1) == "## Current rules" ]] &&
  [[ $(sed -n "/^## Current rules/,\$p" "$GL/01-A.context.md" | grep -o "^- D[0-9]* .*→ docs/decisions.md:[0-9]*$" | sed "s/^- \(D[0-9]*\) .*:\([0-9]*\)$/\1@\2/" | tr "\n" " ") == "D3@15 D2@13 D1@7 " ]] &&
  grep -q -- "^- D1 default · Playback model: hybrid. Mixxx.s clock plays the track while the platter is within tolerance of the expected .*… → docs/decisions.md:7$" "$GL/01-A.context.md"'
# M1-02: A and B state one project fact, C resolves it, A proposes a workflow line; main's CLAUDE.md (B's Gotchas line
# from the gotcha run carries the fact) is read by no pack, and the run changes it nowhere
m0=$(git -C "$T/origin.git" rev-parse main)
STUB_PROJECT_FACT=A,B STUB_RESOLVE_FACT=C STUB_PROPOSE=A "$H" start "$T/proj" facts --spec SPEC.md --foreground > "$T/facts.out" 2>&1
FL=$HARNESS_STATE/proj/facts/logs FR=$T/wt/proj/facts/.harness/runs/facts
pg() { sed -n "/^## Promote to Gotchas/,/^## /p" "$FL/$1.context.md" | grep -c -- "^- the stub.s work files sit at the repo root, one per feature → entries.jsonl:2$"; }
check "a project discovery is listed under Promote to Gotchas once, at its first entry, until a later entry resolves it" '
  [[ $(pg 02-B) == 1 && $(pg 03-A) == 1 && $(pg 04-C) == 1 ]] && [[ $(grep -c "stub.s work files sit" "$FL/03-A.context.md") == 1 ]] &&
  ! grep -q "Promote to Gotchas" "$FL/01-A.context.md" && ! grep -q "Promote to Gotchas" "$FL/05-C.context.md" && grep -q "^## " "$FL/05-C.context.md" &&
  [[ $(jq -rs "[.[] | select(.feature == \"C\" and .kind == \"coding\")][0].resolved[0]" "$FR/entries.jsonl") == "the stub'"'"'s work files sit"* ]]'
check "a coding entry's project fact and proposed change reach entries.jsonl and progress.md; CLAUDE.md stays main's" '
  grep -q "^done" "$HARNESS_STATE/proj/facts/ended" &&
  [[ $(jq -rs "[.[] | select(.feature == \"A\" and .kind == \"coding\")][0] | [(.discoveries[0].affects | join(\",\")), .proposed_changes[0]] | join(\"|\")" "$FR/entries.jsonl") == "project|stub proposal: run the stub suite before each commit" ]] &&
  grep -qF -- "- **Discovery** (affects project): the stub'"'"'s work files sit at the repo root, one per feature" "$FR/progress.md" &&
  grep -qF -- "- **Proposed change:** stub proposal: run the stub suite before each commit" "$FR/progress.md" &&
  git -C "$T/origin.git" diff --quiet "$m0" main -- CLAUDE.md && git -C "$T/origin.git" diff --quiet "$m0" run/facts/M1 -- CLAUDE.md'
# a 1024-byte coding cap from the project's config, and a verify that finds A's step 1 failing after A recorded a dead end
git pull -q --ff-only origin main && printf 'CONTEXT_PACK_BYTES=1024\n' >> .harness/config.sh && git commit -qam "a tight pack" && git push -q origin main
# HARNESS_COUNT_HOLD: M1's lane exits between the coordinator's lane count and its end check, the window that ended
# this run "no feature left to try" before M2's packs now and then (R1-06; decisions/2026-10-29-lane-count-end-check)
HARNESS_COUNT_HOLD=1 STUB_VERIFY_FAIL_ROW=1 "$H" start "$T/proj" tight --spec SPEC.md --foreground > "$T/tight.out" 2>&1
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
