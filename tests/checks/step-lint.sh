#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- step lint (R3, R2): the prompt and the CLI; the rules' evals are tests/unit/features.test.mjs ----
check "prompt: the initializer states counts as the command that prints them (N/M checks passed)" 'grep -F "N/M checks passed" "$HERE/../prompts/initializer.md" > /dev/null'
printf '%s\n' '{"features":[{"id":"A","milestone":"M1","steps":["works correctly","`lib/x.mjs` exists"]},{"id":"B","milestone":"M2","steps":["the suite is green"]}]}' > "$T/lint-list.json"
printf '%s\n' '{"features":[{"id":"A","milestone":"M1","steps":["`lib/x.mjs` exists"]},{"id":"B","milestone":"M2","after":[],"steps":["the suite is green"]}]}' > "$T/lint-clean.json"
check "lint: the CLI prints <id> step <n> <rule> <text> lines, exit 1 with findings and 0 clean" '
  out=$($F lint "$T/lint-list.json"); rc=$?; clean=$($F lint "$T/lint-clean.json"); crc=$?
  [[ $rc == 1 && $out == "$(printf "A\tstep 1\tno-anchor\tworks correctly\nB\tstep -\tundeclared\tM2%s" "'\''s first feature has no \"after\": it waits on every earlier feature")" && $crc == 0 && -z $clean ]] \
    && [[ $($F lint "$T/lint-list.json" --note; echo "rc=$?") == "lint: 2 findings (no-anchor: 1, undeclared: 1); the list is not edited — first: A step 1 no-anchor"$'\''\n'\''"rc=0" ]] \
    && h=$(sed -n "1,/^import/p" "$HERE/../lib/features.mjs") && [[ $h == *"lint <list>"* && $h == *no-anchor* && $h == *outside-repo* && $h == *self-match* && $h == *undeclared* && $h == *review-small* && $h == *review-missing* ]]'

suite_end
