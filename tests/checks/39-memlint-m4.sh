#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- memlint (M4): four deterministic checks on a worktree's memory files, one finding per line, on fixtures trimmed ----
# ---- from the projects' files as they were before chunk 3 Part 2 tidied them ----
M="node $HERE/../lib/memlint.mjs" MM=$HERE/../lib/memlint.mjs FX=$HERE/fixtures/memlint
wt() { rm -rf "$T/ml/$1" && mkdir -p "$T/ml/$1/docs" "$T/ml/$1/.harness" && echo "$T/ml/$1"; }   # <name> → a fresh worktree
DJ=$(wt dj) && cp "$FX/dj-claude.md" "$DJ/CLAUDE.md"
PW=$(wt pw) && cp "$FX/pathways-project.md" "$PW/.harness/project.md"
OLD=$(wt old) && cp "$FX/rane-decisions-old.md" "$OLD/docs/decisions.md"
TIDY=$(wt tidy) && cp "$FX/rane-decisions-tidy.md" "$TIDY/docs/decisions.md" && cp "$FX/rane-claude-tidy.md" "$TIDY/CLAUDE.md"
check "memlint: node --check passes, the usage header lists the five checks, a missing worktree exits 2" '
  node --check "$MM" && h=$(sed -n "/^\/\/   <worktree>/,/^import/p" "$MM") &&
  ok=1; for c in size gotchas derivable-count night-scope decisions; do [[ $h == *"$c"* ]] || ok=0; done; (( ok )) &&
  { $M "$T/ml/nope" > /dev/null 2>&1; (( $? == 2 )); }'
check "memlint: the dj CLAUDE.md (ed75a2d^) yields one derivable-count finding naming its line, exit 0" '
  o=$($M "$DJ") && [[ $(grep -c " derivable-count: " <<< "$o") == 1 ]] && grep -q "^CLAUDE.md:17 derivable-count: .*1,870 tests" <<< "$o"'
check "memlint: the pathways project.md (4cafb65^) yields a night-scope finding for tonight" '
  o=$($M "$PW") && grep -q "^.harness/project.md:22 night-scope: .*tonight" <<< "$o" && [[ $(grep -c " night-scope: " <<< "$o") == 1 ]]'
check "memlint: the old rane store (aa88421^) yields a decisions finding for its Superseded line, none for the header or D9" '
  o=$($M "$OLD") && [[ $(grep -c " decisions: " <<< "$o") == 1 ]] && grep -q "^docs/decisions.md:33 decisions: D15 .*Updated in place" <<< "$o"'
check "memlint: the old rane store without its current-rule-set header yields a header finding" '
  sed -i 4,6d "$OLD/docs/decisions.md" && o=$($M "$OLD") && grep -q "^docs/decisions.md:1 decisions: no current-rule-set header" <<< "$o" &&
  [[ $(grep -c " decisions: " <<< "$o") == 2 ]]'
check "memlint: the tidy rane store (aa88421) beside its tidy CLAUDE.md (3d7abc9, Where things go) yields no finding" '
  o=$($M "$TIDY") && [[ -z $o ]] && grep -q "^## Where things go" "$TIDY/CLAUDE.md"'
check "memlint: the voice-concierge store (99091b5) yields no finding (the rows they superseded is prose, not a marker)" '
  V=$(wt voice) && cp "$FX/voice-decisions.md" "$V/docs/decisions.md" && grep -q "rows they superseded" "$V/docs/decisions.md" &&
  o=$($M "$V") && [[ -z $o ]]'
check "memlint: a worktree with neither DECISIONS= nor docs/decisions.md yields decisions: no store" '
  o=$($M "$DJ") && grep -q "^.harness/config.sh:1 decisions: no store" <<< "$o" &&
  echo DECISIONS=docs/gone.md > "$DJ/.harness/config.sh" && $M "$DJ" | grep -q "^.harness/config.sh:1 decisions: store docs/gone.md not found"'
check "memlint: a CLAUDE.md of 121 lines yields a size finding at line 121, MEMLINT_LINES moves the cap" '
  S=$(wt size) && cp "$TIDY/docs/decisions.md" "$S/docs/" && { cat "$FX/rane-claude-tidy.md"; seq 28 | sed "s/^/pad /"; } > "$S/CLAUDE.md" &&
  [[ $(wc -l < "$S/CLAUDE.md") == 121 ]] && [[ $($M "$S") == "CLAUDE.md:121 size: 121 lines, over 120 (MEMLINT_LINES)" ]] &&
  sed -i \$d "$S/CLAUDE.md" && [[ -z $($M "$S") ]] && [[ $(MEMLINT_LINES=100 $M "$S") == "CLAUDE.md:101 size: 120 lines, over 100 (MEMLINT_LINES)" ]]'
check "memlint: 16 Gotchas lines yield a gotchas finding at the 16th, 15 none (a wrapped bullet is one line)" '
  G=$(wt gotchas) && cp "$TIDY/docs/decisions.md" "$G/docs/" &&
  awk "{ print } /^## Gotchas/ { for (i = 1; i <= 9; i++) print \"- added fact \" i }" "$FX/rane-claude-tidy.md" > "$G/CLAUDE.md" &&
  o=$($M "$G") && [[ $o == "CLAUDE.md:94 gotchas: 16 lines, over 15" ]] &&
  sed -i "/^- added fact 9$/d" "$G/CLAUDE.md" && [[ -z $($M "$G") ]]'
check "memlint: a directory store file marked superseded with no Updated in place line yields a finding, with one none" '
  D=$(wt dir) && mkdir -p "$D/journal/decisions" && echo DECISIONS=journal/decisions > "$D/.harness/config.sh" &&
  printf "# Old rule\n\n- **Choice:** x\n- Superseded by decisions/2026-10-26-new.\n" > "$D/journal/decisions/2026-10-25-old.md" &&
  printf "# New rule\n\n- **Choice:** y; its origin replaced by a clone (prose, not a marker)\n" > "$D/journal/decisions/2026-10-26-new.md" &&
  [[ $($M "$D") == "journal/decisions/2026-10-25-old.md:4 decisions: superseded with no \"Updated in place\" line" ]] &&
  echo "Updated in place 2026-10-26: now y." >> "$D/journal/decisions/2026-10-25-old.md" && [[ -z $($M "$D") ]]'
check "memlint: a stated rule is no count or night scope (1 test, as of decision 12), a month alone is a date (as of October)" '
  X=$(wt text) && echo "DECISIONS=docs/d.md" > "$X/.harness/config.sh" && printf "%s\n" "# d" "The current rule set." > "$X/docs/d.md" &&
  printf "%s\n" "# x" "- Write 1 test first, watch it fail." "- Rules hold as of decision 12." "- Prices as of October." > "$X/CLAUDE.md" &&
  [[ $($M "$X") == "CLAUDE.md:4 night-scope: \"as of October\" (night scope goes in the run'"'"'s brief)" ]]'
check "memlint: a ### under a decision is part of it, a ## heading is named by itself, a .md directory in a dir store is skipped" '
  X=$(wt store) && printf "%s\n" "# d" "The current rule set, rewritten in place." "" "## D15 old" "Superseded in part by D17." "### History" \
    "Updated in place 2026-10-20: narrowed." "## Notes on D17 and hardware" "The jog rule was superseded by the D20 rule." > "$X/docs/decisions.md" &&
  [[ $($M "$X") == "docs/decisions.md:9 decisions: Notes on D17 and hardware superseded with no \"Updated in place\" line" ]] &&
  D=$(wt dirmd) && mkdir -p "$D/journal/decisions/old.md" && echo DECISIONS=journal/decisions > "$D/.harness/config.sh" && o=$($M "$D") && [[ -z $o ]]'
check "memlint: the store lookup is decisionsStore (one function), and this worktree prints nothing" '
  [[ $(grep -c "\"\.harness/config\.sh\"" "$MM") == 1 && $(grep -c "\"docs/decisions\.md\"" "$MM") == 1 ]] &&
  o=$($M "$HERE/..") && [[ -z $o ]]'
# the M4 review (M4-02): an unreadable file is one stderr line naming it; a header under a non-decision `## ` section is
# a header; a symlinked decision file is linted as readRules reads it
check "memlint: an unreadable CLAUDE.md is exit 1 and one stderr line naming the file and the error" '
  U=$(wt unread) && mkdir "$U/CLAUDE.md" && { $M "$U" > "$T/ml-u.out" 2> "$T/ml-u.err"; (( $? == 1 )); } && [[ ! -s $T/ml-u.out ]] &&
  [[ $(wc -l < "$T/ml-u.err") == 1 ]] && grep -q "^memlint: cannot read CLAUDE.md: EISDIR" "$T/ml-u.err"'
check "memlint: a current-rule-set header under a ## section before the first decision is a header; a symlinked file is linted" '
  X=$(wt hdr) && printf "%s\n" "# Decisions" "## How this file works" "This is the current rule set, rewritten in place." "## D1 one" "Rule." > "$X/docs/decisions.md" &&
  o=$($M "$X") && [[ -z $o ]] && D=$(wt dirln) && mkdir -p "$D/journal/decisions" "$D/elsewhere" && echo DECISIONS=journal/decisions > "$D/.harness/config.sh" &&
  printf "# Old\n- Superseded by decisions/x.\n" > "$D/elsewhere/old.md" && ln -s ../../elsewhere/old.md "$D/journal/decisions/2026-10-25-old.md" &&
  [[ $($M "$D") == "journal/decisions/2026-10-25-old.md:2 decisions: superseded with no \"Updated in place\" line" ]]'
# ---- the driver (M4-02): each segment's memlint findings become notes before the first session, never a stop ----
mkdir -p docs && cp "$HERE/fixtures/decisions-rane.md" docs/decisions.md && printf "%s\n" "- the suite: ~1,870 tests" "- no rename tonight" >> CLAUDE.md &&
  git add -A && git commit -qm "memory to lint" && git push -q origin main
"$H" start "$T/proj" mlrun --spec SPEC.md --foreground > "$T/mlrun.out" 2>&1
check "driver memlint: two findings are two memlint notes before the initializer's, and the run ends done 3/3" '
  l=$(hlog mlrun) && [[ $(grep -c "· memlint: " <<< "$l") == 2 ]] &&
  grep -q "· memlint: CLAUDE.md:3 derivable-count: \"~1,870 tests\"" <<< "$l" && grep -q "· memlint: CLAUDE.md:4 night-scope: \"tonight\"" <<< "$l" &&
  (( $(grep -n "· memlint: " <<< "$l" | tail -1 | cut -d: -f1) < $(grep -n "· feature list written" <<< "$l" | cut -d: -f1) )) &&
  grep -q "^done" "$HARNESS_STATE/proj/mlrun/ended" && [[ $($F summary "$(list mlrun)") == "3/3 passing" ]]'
HARNESS_MEMLINT=/bin/false "$H" start "$T/proj" mlfail --spec SPEC.md --foreground > "$T/mlfail.out" 2>&1
check "driver memlint: a failing memlint is one memlint: failed note and the run goes on to done 3/3" '
  l=$(hlog mlfail) && [[ $(grep -c "· memlint: " <<< "$l") == 1 ]] && grep -q "· memlint: failed (exit 1)" <<< "$l" &&
  grep -q "^done" "$HARNESS_STATE/proj/mlfail/ended" && [[ $($F summary "$(list mlfail)") == "3/3 passing" ]]'
check "harness memlint: a project (or a directory in it) prints the same two findings, exit 0; no argument or no repo is one error line" '
  o=$("$H" memlint "$T/proj") && [[ $(wc -l <<< "$o") == 2 ]] && [[ $(hlog mlrun | grep "· memlint: " | sed "s/.*· memlint: //") == "$o" ]] &&
  [[ $("$H" memlint "$T/proj/docs") == "$o" ]] && ! "$H" memlint > /dev/null 2> "$T/ml-h.err" && [[ $(wc -l < "$T/ml-h.err") == 1 ]] &&
  ! "$H" memlint "$T/ml" > /dev/null 2> "$T/ml-h.err" && [[ $(cat "$T/ml-h.err") == "harness: $T/ml is not a git repository" ]] && sed -n "2,/^set -/p" "$H" | grep "harness memlint <project>" > /dev/null'
suite_end
