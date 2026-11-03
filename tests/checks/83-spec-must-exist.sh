#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- a run never starts on a spec that isn't there (Q1, decisions/2026-10-31-spec-must-exist) ----
# harness start and harness queue add refuse a --spec (or SPEC_FILES) path absent from the project's origin/main (or
# --base), before anything is queued or started: the run's worktree is made from that ref, not the working tree.
# A resume and a --brief-only start are not checked. A proceeding start here is a --foreground one past its deadline
# (init, initializer, deadline): cheap, and its worktree is the proof.
past() { echo $(( $(date +%s) - 1 )); }
made() { ls -d "$T"/wt/proj/* "$T"/state/proj/* "$T"/state/queue/*.args 2> /dev/null; }   # what a start or a queue add leaves

before=$(made); "$H" start "$T/proj" --spec docs/missing.md > "$T/miss.out" 2>&1; miss_rc=$?
check "start --spec of a path not in origin/main: exit 1, the line, no worktree, state dir or queue entry" \
  '[[ $miss_rc == 1 && -z $before && -z $(made) ]] && grep -qF "spec docs/missing.md: not in origin/main (fetched now); commit and push it, or name its ref with --base" "$T/miss.out"'

mkdir -p docs && echo local > docs/local.md && git add docs/local.md && git commit -qm "a spec, not pushed"
"$H" start "$T/proj" --spec docs/local.md > "$T/local.out" 2>&1; local_rc=$?
check "start --spec of a file committed but not pushed is refused the same way (the working tree is not the reference)" \
  '[[ $local_rc == 1 && -z $(made) ]] && grep -qF "spec docs/local.md: not in origin/main" "$T/local.out"'

git push -q origin main
"$H" start "$T/proj" pushed --spec docs/local.md --until-epoch "$(past)" --foreground > "$T/pushed.out" 2>&1
check "start --spec of a pushed file proceeds: the run's worktree exists" \
  '[[ -d $T/wt/proj/pushed ]] && ! grep -q "not in origin" "$T/pushed.out"'

"$H" start "$T/proj" two --spec "SPEC.md docs/b.md" > "$T/two.out" 2>&1; two_rc=$?
check "start --spec \"a b\" with only the second missing names it, not the first" \
  '[[ $two_rc == 1 && ! -e $T/wt/proj/two ]] && grep -qF "spec docs/b.md: not in origin/main" "$T/two.out" && ! grep -q "spec SPEC.md" "$T/two.out"'

git checkout -qb specbase && echo base > docs/onbase.md && git add docs/onbase.md && git commit -qm "a spec on a branch" \
  && git push -q origin specbase && git checkout -q main
"$H" start "$T/proj" nobase --spec docs/onbase.md > "$T/nobase.out" 2>&1; nobase_rc=$?
"$H" start "$T/proj" based --spec docs/onbase.md --base origin/specbase --until-epoch "$(past)" --foreground > "$T/based.out" 2>&1
check "--base <branch> with the spec on that branch only proceeds; without --base it is refused naming origin/main" \
  '[[ $nobase_rc == 1 && ! -e $T/wt/proj/nobase && -d $T/wt/proj/based ]] && grep -qF "spec docs/onbase.md: not in origin/main" "$T/nobase.out" \
  && ! grep -q "not in origin" "$T/based.out"'

echo "SPEC_FILES=docs/missing.md" >> .harness/config.sh
"$H" start "$T/proj" fromconf > "$T/conf.out" 2>&1; conf_rc=$?
git checkout -q .harness/config.sh
check "SPEC_FILES in the project's .harness/config.sh and no --spec: a missing path is refused" \
  '[[ $conf_rc == 1 && ! -e $T/wt/proj/fromconf ]] && grep -qF "spec docs/missing.md: not in origin/main" "$T/conf.out"'

"$H" start "$T/proj" briefonly --brief "x" --until-epoch "$(past)" --foreground > "$T/brief.out" 2>&1
check "--brief alone with no SPEC_FILES is not checked and starts" '[[ -d $T/wt/proj/briefonly ]] && ! grep -q "not in origin" "$T/brief.out"'

echo "SPEC_FILES=docs/missing.md" >> "$HARNESS_STATE/proj/pushed/run.env"
"$H" start "$T/proj" pushed --spec docs/missing.md --until-epoch "$(past)" --foreground > "$T/resume.out" 2>&1
check "a resume (the run's worktree exists) is not checked: a missing spec in its run.env and --spec does not refuse it" \
  'grep -q "resuming pushed" "$T/resume.out" && ! grep -q "not in origin" "$T/resume.out"'

"$H" queue add "$T/proj" --spec docs/missing.md > "$T/qmiss.out" 2>&1; qmiss_rc=$?
check "queue add --spec of a missing path: the line, exit 1, no .args file" \
  '[[ $qmiss_rc == 1 ]] && ! compgen -G "$HARNESS_STATE/queue/*.args" > /dev/null && grep -qF "spec docs/missing.md: not in origin/main" "$T/qmiss.out"'
"$H" queue add "$T/proj" --spec SPEC.md > "$T/qok.out" 2>&1
check "queue add --spec of a present path is queued" 'grep -q "^queued: " "$T/qok.out" && compgen -G "$HARNESS_STATE/queue/*.args" > /dev/null'

suite_end
