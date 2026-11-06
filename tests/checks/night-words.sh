#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- runs go regardless of the time of day: the night words stay out of what the sessions and the docs say ----
# decisions/2026-11-04-no-default-end-time. Beside no-deadline (its stub runs make it slow) so a stray word is red in
# the fast tier, not first at a verify. It reads CLAUDE.md, so it is in CHECK_KEY_MAP (key-map-lint).
# Allowed by file and word: memlint's list of the patterns it looks for, and the catch-up's lines about deleting such words
NW="\\btonight\\b|\\bovernight\\b|\\bnights?\\b|night's|morning after|morning session"
nw_left=$(cd "$HERE/.." && grep -rnIioE "$NW" README.md docs/architecture.md CLAUDE.md prompts templates lib bin | awk -F: '
  { w = tolower($3); f = $1 }
  f == "lib/memlint.mjs" && w == "tonight" { next }
  f == "prompts/project-catchup.md" && (w == "night" || w == "overnight" || w == "tonight") { next }
  { print }')
check "night words: out of the docs, prompts, templates and code, but for memlint's patterns and the catch-up's lines" \
  '[[ -z $nw_left ]] || { echo "$nw_left"; false; }'
ML=$T/ml; mkdir -p "$ML"; printf '%s\n' '# x' '- no rename tonight' > "$ML/CLAUDE.md"
check "night words: memlint says run-scope and that it goes in the run's brief" \
  '[[ $(node "$HERE/../lib/memlint.mjs" "$ML" | grep -F "CLAUDE.md:2 ") == "CLAUDE.md:2 run-scope: \"tonight\" (run scope goes in the run'"'"'s brief)" ]]'

suite_end
