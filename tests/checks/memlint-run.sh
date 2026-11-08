#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- memlint in a run (M4-02): the driver notes each finding before the first session; harness memlint ----
# The module's cases are tests/unit/memlint.test.mjs; the cap at the write is lib/curator.mjs capCheck
# (decisions/2026-11-07-memory-policy, decisions/2026-11-05-suite-shape).
mkdir -p "$T/ml"   # a directory in no git repository (harness memlint's last case)
# ---- the driver (M4-02): each segment's memlint findings become notes before the first session, never a stop ----
# .claude/CLAUDE.md beside CLAUDE.md: Claude Code loads both, so the pair is a third finding (N1-02)
mkdir -p docs .claude && cp "$HERE/fixtures/decisions-rane.md" docs/decisions.md && printf "%s\n" "- the suite: ~1,870 tests" "- no rename tonight" >> CLAUDE.md &&
  echo "# the twin" > .claude/CLAUDE.md &&
  git add -A && git commit -qm "memory to lint" && git push -q origin main
"$H" start "$T/proj" mlrun --spec SPEC.md --foreground > "$T/mlrun.out" 2>&1
check "driver memlint: three findings, the twin among them, are three memlint notes before the initializer's, and the run ends done 3/3" '
  l=$(hlog mlrun) && [[ $(grep -c "· memlint: " <<< "$l") == 3 ]] &&
  grep -q "· memlint: CLAUDE.md:3 derivable-count: \"~1,870 tests\"" <<< "$l" && grep -q "· memlint: CLAUDE.md:4 run-scope: \"tonight\"" <<< "$l" &&
  grep -qF "· memlint: .claude/CLAUDE.md:1 twin: CLAUDE.md exists too; Claude Code loads both as project memory" <<< "$l" &&
  (( $(grep -n "· memlint: " <<< "$l" | tail -1 | cut -d: -f1) < $(grep -n "· feature list written" <<< "$l" | cut -d: -f1) )) &&
  grep -q "^done" "$HARNESS_STATE/proj/mlrun/ended" && [[ $($F summary "$(list mlrun)") == "3/3 passing" ]]'
HARNESS_MEMLINT=/bin/false "$H" start "$T/proj" mlfail --spec SPEC.md --foreground > "$T/mlfail.out" 2>&1
check "driver memlint: a failing memlint is one memlint: failed note and the run goes on to done 3/3" '
  l=$(hlog mlfail) && [[ $(grep -c "· memlint: " <<< "$l") == 1 ]] && grep -q "· memlint: failed (exit 1)" <<< "$l" &&
  grep -q "^done" "$HARNESS_STATE/proj/mlfail/ended" && [[ $($F summary "$(list mlfail)") == "3/3 passing" ]]'
check "harness memlint: a project (or a directory in it) prints the same three findings, exit 0; no argument or no repo is one error line" '
  o=$("$H" memlint "$T/proj") && [[ $(wc -l <<< "$o") == 3 ]] && [[ $(hlog mlrun | grep "· memlint: " | sed "s/.*· memlint: //") == "$o" ]] &&
  [[ $("$H" memlint "$T/proj/docs") == "$o" ]] && ! "$H" memlint > /dev/null 2> "$T/ml-h.err" && [[ $(wc -l < "$T/ml-h.err") == 1 ]] &&
  ! "$H" memlint "$T/ml" > /dev/null 2> "$T/ml-h.err" && [[ $(cat "$T/ml-h.err") == "harness: no project '"'"'$T/ml'"'"': not a git repository" ]] && sed -n "2,/^set -/p" "$H" | grep "harness memlint <project>" > /dev/null'
suite_end
