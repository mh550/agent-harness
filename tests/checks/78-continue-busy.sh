#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- a parked run's continue while another run of its project is alive (decisions/2026-10-29-continue-advice-busy-project):
# ---- the per-project hold queues a plain continue behind that run, so the card offers the queue add and --now ----
export TZ=UTC COLUMNS=200 HARNESS_GLYPHS=unicode
sleep 600 & LIVE=$!; echo "$LIVE" >> "$T/left.pids"
live_run() { mkdir -p "$HARNESS_STATE/$1/$2" && echo "$LIVE" > "$HARNESS_STATE/$1/$2/driver.pid" \
  && printf 'PROJECT_DIR=%q\nWT=/x\nRUN_ID=%q\nSTATE=%q\n' "$T/$1" "$2" "$HARNESS_STATE/$1/$2" > "$HARNESS_STATE/$1/$2/meta.env"; }
needs_fixture parked open "" park1
live_run other elsewhere   # another project's live run holds nothing here
cmds() { "$H" needs park1 --json | jq -c 'map(select(.reason == "parked")) | .[0].card.commands'; }
check "busy continue: another project's live run changes nothing: answer, then continue" \
  '[[ $(cmds) == "[\"harness answer park1 \\\"…\\\"\",\"harness continue park1\"]" ]]'
live_run proj live1
Q="harness queue add --continue park1 # waits for live1 to end; live1 merges first"
N="harness continue park1 --now # runs beside live1; this run merges first if it finishes first"
check "busy continue: harness needs --json gives the queue add and --now, each naming the live run" \
  '"$H" needs park1 --json | jq -e --arg q "$Q" --arg n "$N" "map(select(.reason == \"parked\")) | .[0].card | .commands == [\"harness answer park1 \\\"…\\\"\", \$q, \$n]
    and .run_state == \"no; live1 is running on this project: pick one continue\"" > /dev/null'
check "busy continue: the card's do and run lines name the hold" \
  '"$H" needs park1 > "$T/n.out" && grep -F "$Q" "$T/n.out" > /dev/null && grep -F "$N" "$T/n.out" > /dev/null \
  && grep -F "  run        no; live1 is running on this project: pick one continue" "$T/n.out" > /dev/null'
check "busy continue: harness parked --json carries the same commands" \
  '"$H" parked park1 --json | jq -e --arg q "$Q" --arg n "$N" ".[0].commands == [\"harness answer park1 \\\"…\\\"\", \$q, \$n] and .[0].card.commands == .[0].commands" > /dev/null'
kill "$LIVE" 2> /dev/null; wait "$LIVE" 2> /dev/null
check "busy continue: once that run has ended, the plain continue is back" \
  '[[ $(cmds) == "[\"harness answer park1 \\\"…\\\"\",\"harness continue park1\"]" ]]'
S=$HH/skills/harness-answer/SKILL.md
check "the answer skill: another live run of the project: ask, with the queue add and --now and their merge order" \
  'ok=1; for k in "harness queue add --continue <run>" "harness continue <run> --now" "merges first" "harness status <run>" "same project"; do grep -F -- "$k" "$S" > /dev/null || ok=0; done; (( ok )) \
  && sed -n "/^## Never/,\$p" "$S" | grep -F "suggest" > /dev/null'
check "the answer skill's facts cite file:line" \
  'ok=1; for k in "lib/driver.sh:" "bin/harness:" "lib/sync.sh:"; do sed -n "/^## Facts that matter/,/^## /p" "$S" | grep -F -- "$k" > /dev/null || ok=0; done; (( ok ))'
check "the desk prompt: two continues on a card: ask Michael which, run one" \
  'P=$HH/prompts/desk.md; grep -F -- "--now" "$P" > /dev/null && grep -F "merges first" "$P" > /dev/null'
suite_end
