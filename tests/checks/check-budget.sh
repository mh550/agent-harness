#!/usr/bin/env bash
# tier: slow
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the check count and the check budget (docs/specs/2026-11-03-slim-suite.md S3, decisions/2026-11-03-check-budget) ----
# A project with the check-name fixture (tests/fixtures/check-names.txt, one name per line, C-sorted): at a verified
# verdict the lane diffs the fixture from the milestone's base (main as merged, or the tag it opened from) to its tree
# and notes `<m>: checks +a ~b −c`, with the milestone's check_budget when the list has one; summary.json's `checks`
# sums the milestones, harness report has a Checks row after Suite runs, the retro prompt carries the line.
# The fixture: four names, the removed one (zeta) not beside the added ones (beta, gamma), so nothing pairs as replaced.
mkdir -p tests/fixtures && printf '%s\n' "alpha: holds" "delta: holds" "mid: holds" "zeta: holds" > tests/fixtures/check-names.txt
git add -A && git commit -qm "the check-name fixture" && git push -q origin main

# cb1: A adds two names and removes one (M1, no budget); M2 has a budget of 3 and C adds nothing (under budget)
STUB_CHECK_NAMES="A:+beta: new,+gamma: new,-zeta: holds" STUB_CHECK_BUDGET=M2:3 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 \
  "$H" start "$T/proj" cb1 --spec SPEC.md --foreground > "$T/cb1.out" 2>&1
S1=$HARNESS_STATE/proj/cb1 R1=$T/wt/proj/cb1/.harness/runs/cb1
check "check budget: a verified milestone whose session added two names and removed one is noted M1: checks +2 ~0 −1 (no budget: no budget words)" \
  'hlog cb1 | grep -F "· M1: checks +2 ~0 −1" > /dev/null && ! hlog cb1 | grep -F "M1: checks +2 ~0 −1 against" > /dev/null \
  && [[ $(ats cb1 "M1: checks") -lt $(ats cb1 "M1 verified") ]]'
check "check budget: a milestone with check_budget 3 whose sessions added nothing is noted M2: checks +0 ~0 −0 against a budget of 3, no parenthesis" \
  'hlog cb1 | grep "· M2: checks +0 ~0 −0 against a budget of 3$" > /dev/null && [[ $(hlog cb1 | grep -c "M2: checks") == 1 ]]'
check "check budget: summary.json has checks {added: 2, replaced: 0, removed: 1} from the fixture, by milestone, M2 with its budget 3" \
  '[[ $(jq -c ".checks | {added, replaced, removed, source}" "$R1/summary.json") == "{\"added\":2,\"replaced\":0,\"removed\":1,\"source\":\"fixture\"}" ]] \
  && [[ $(jq -c ".checks.by_milestone.M1" "$R1/summary.json") == "{\"added\":2,\"replaced\":0,\"removed\":1,\"budget\":null}" ]] \
  && [[ $(jq -c ".checks.by_milestone.M2" "$R1/summary.json") == "{\"added\":0,\"replaced\":0,\"removed\":0,\"budget\":3}" ]] \
  && [[ -f $S1/checks-M1 && -f $S1/checks-M2 ]]'
check "check budget: harness report --md has the Checks row after Suite runs, the counts then each milestone's, a budget named; the TTY card carries the same value" \
  '"$H" report --md cb1 > "$T/rep1.md" 2>&1 && COLUMNS=200 HARNESS_TTY=1 NO_COLOR=1 "$H" report cb1 > "$T/rep1.tty" 2>&1 \
  && grep -A1 "^| Suite runs |" "$T/rep1.md" | grep -xF "| Checks | +2 ~0 −1 (M1 +2 ~0 −1; M2 +0 ~0 −0, budget 3) |" > /dev/null \
  && grep "checks" "$T/rep1.tty" | grep -F "+2 ~0 −1 (M1 +2 ~0 −1; M2 +0 ~0 −0, budget 3)" > /dev/null'
# the line is the record's summary.json checks as checksLine prints it (lib/driver.sh): the retro reports it in Outcome
check "check budget: the rendered retro prompt carries the run's checks line" \
  'grep -F "checks: +2 ~0 −1 (M1 +2 ~0 −1; M2 +0 ~0 −0, budget 3)" "$S1/prompt-retro.md" > /dev/null'
# the suite's own hygiene (a leak found 2026-11-06: 88,652 clones of the gh stub's `pr merge` left under /tmp since
# 2026-10-25, 161 GB): every mktemp of a stub or of the harness under test lands under this file's state (tests/lib.sh
# exports TMPDIR=$T/tmp), gone with it, and the gh stub removes its clone when the merge is done
check "check budget: TMPDIR is the file's own \$T/tmp (tests/lib.sh), the gh stub merged twice, and no clone (.git) is left under it" \
  '[[ ${TMPDIR:-} == "$T/tmp" && -d $T/tmp && $(grep -c "pr merge" "$T/gh.log") == 2 ]] && ! compgen -G "$T/tmp/*/.git" > /dev/null'

# cb2: M1 has a budget of 3; A adds four names (new ones: main holds cb1's beta and gamma now) and replaces one
# (mid: holds → mid: holds now, adjacent in the sorted file), and A's entry gives the reason in its `checks` field: the
# note says over budget with it
git pull -q --ff-only origin main
STUB_CHECK_NAMES="A:+eta: new,+eta2: new,+theta: new,+theta2: new,-mid: holds,+mid: holds now" STUB_CHECK_BUDGET=M1:3 \
  STUB_CHECKS_REASON="A:one row per table of the new view" STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 \
  "$H" start "$T/proj" cb2 --spec SPEC.md --foreground > "$T/cb2.out" 2>&1
R2=$T/wt/proj/cb2/.harness/runs/cb2
check "check budget: four names added against a budget of 3 is noted over budget with the reason from the last coding entry's checks field; a name changed in place counts as replaced" \
  'hlog cb2 | grep -F "· M1: checks +4 ~1 −0 against a budget of 3 (over budget: one row per table of the new view)" > /dev/null \
  && [[ $(jq -rs "[.[] | select(.kind == \"coding\" and .feature == \"A\")] | last | .checks" "$R2/entries.jsonl") == "one row per table of the new view" ]]'
check "check budget: the fixture's tip is main's plus the run's edits: cb2's main held cb1's merged names (beta, gamma, no zeta) before A's session; the report marks M1 over its budget" \
  'git -C "$T/origin.git" show "run/cb2/M1:tests/fixtures/check-names.txt" > "$T/cb2-names.txt" && grep -x "beta: new" "$T/cb2-names.txt" > /dev/null \
  && grep -x "gamma: new" "$T/cb2-names.txt" > /dev/null && ! grep -x "zeta: holds" "$T/cb2-names.txt" > /dev/null && grep -x "theta2: new" "$T/cb2-names.txt" > /dev/null \
  && [[ $(jq -c ".checks | {added, replaced, removed}" "$R2/summary.json") == "{\"added\":4,\"replaced\":1,\"removed\":0}" ]] \
  && [[ $("$H" report --md cb2 | grep "^| Checks |") == "| Checks | +4 ~1 −0 (M1 +4 ~1 −0, budget 3, over; M2 +0 ~0 −0) |" ]]'

# cb3: a project without the fixture that has opted out (CHECK_NAMES empty: `git show <commit>:` would list the tree, and the
# S3 review found the listing counted as names), whose suite prints its count: +<n> from tests-start and tests-end, no note
git pull -q --ff-only origin main && git rm -q tests/fixtures/check-names.txt && echo 3 > tests.n && git add -A && git commit -qm "no fixture; tests.n 3" && git push -q origin main
mkdir -p "$HARNESS_STATE/proj/cb3" && printf '%s\n' "CHECK_CMD='echo HARNESS_TESTS=\$(cat tests.n); test ! -f BROKEN'" 'CHECK_NAMES=""' > "$HARNESS_STATE/proj/cb3/run.env"
STUB_TESTS_N=A:5 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" cb3 --spec SPEC.md --foreground > "$T/cb3.out" 2>&1
S3=$HARNESS_STATE/proj/cb3 R3=$T/wt/proj/cb3/.harness/runs/cb3
check "check budget: a project without the fixture and CHECK_NAMES empty: checks is +<n> from the suite's count (3 → 5), source counts, no checks note (no tree listing counted), the row says where it came from" \
  '[[ $(jq -c ".checks" "$R3/summary.json") == "{\"added\":2,\"source\":\"counts\",\"from\":3,\"to\":5}" ]] && ! hlog cb3 | grep -F ": checks +" > /dev/null \
  && [[ $("$H" report --md cb3 | grep "^| Checks |") == "| Checks | +2 (the suite'"'"'s count, 3 → 5) |" ]] && ! compgen -G "$S3/checks-*" > /dev/null \
  && grep -F "checks: +2 (the suite'"'"'s count, 3 → 5)" "$S3/prompt-retro.md" > /dev/null'

suite_end
