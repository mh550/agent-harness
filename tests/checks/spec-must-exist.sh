#!/usr/bin/env bash
# tier: fast
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

# ---- the runner re-checks at dequeue (Q1-02): a spec gone from origin/main parks its entry in queue/held/, never starts ----
Q=$HARNESS_STATE/queue; rm -f "$Q"/*.args
echo gone > docs/gone.md && git add docs/gone.md && git commit -qm "a spec" && git push -q origin main
"$H" queue add "$T/proj" qgone --spec docs/gone.md > "$T/qgone.out" 2>&1
git rm -q docs/gone.md && git commit -qm "the spec moved away" && git push -q origin main   # a pushed delete, no rewrite
printf '%s\n' start "$T/proj" qplant --spec docs/missing.md > "$Q/0002-start-proj.args"   # planted by hand: never checked at add
"$H" queue add "$T/proj" qbrief --brief x --until-epoch "$(past)" > /dev/null
HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. timeout 120 "$HERE/../lib/queue.sh" > "$T/qrun.out" 2>&1; settle
check "the runner parks a queued start whose spec left origin/main: .args and .why in held/, a parked line, no run" \
  'grep -q "^queued: 0001-start-proj.args" "$T/qgone.out" && [[ -e $Q/held/0001-start-proj.args && ! -e $Q/0001-start-proj.args ]] \
  && grep -qE "^spec docs/gone.md: not in origin/main .* \([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}\)$" "$Q/held/0001-start-proj.why" \
  && grep -qF "parked 0001-start-proj.args: spec docs/gone.md: not in origin/main" "$Q/runner.log" \
  && [[ ! -e $HARNESS_STATE/proj/qgone && ! -e $T/wt/proj/qgone ]] && ! grep -q "starting: harness start $T/proj qgone" "$Q/runner.log"'
check "the same runner goes on to the next entry and starts it (a --brief start of the same project)" \
  'grep -q "starting: harness start $T/proj qbrief" "$Q/runner.log" && [[ -d $HARNESS_STATE/proj/qbrief ]] && grep -q "run qbrief on harness/qbrief" "$Q/runner.log" && grep -q "queue empty" "$Q/runner.log"'
check "an .args planted by hand naming a missing spec is parked at dequeue the same way" \
  '[[ -e $Q/held/0002-start-proj.args && ! -e $HARNESS_STATE/proj/qplant && ! -e $T/wt/proj/qplant ]] && grep -qF "spec docs/missing.md: not in origin/main" "$Q/held/0002-start-proj.why" \
  && grep -qF "parked 0002-start-proj.args: spec docs/missing.md: not in origin/main" "$Q/runner.log"'
check "harness queue list shows the parked entry with not in origin/main in its reason" \
  'COLUMNS=200 "$H" queue list > "$T/qlist.out" 2>&1; grep -E "why: spec docs/gone.md: not in origin/main" "$T/qlist.out" > /dev/null'

# the review's minors (Q1-02): a taken name in held/ parks under another, a project that is no repository is not parked
# (its start says why), a check that fails without a line parks with a reason
echo "planted" > "$Q/held/0005-start-proj.args"
printf '%s\n' start "$T/proj" qtaken --spec docs/missing.md > "$Q/0005-start-proj.args"
mkdir -p "$T/norepo"; printf '%s\n' start "$T/norepo" qnorepo --spec docs/x.md > "$Q/0006-start-norepo.args"
git clone -q "$T/origin.git" "$T/brk" && mkdir -p "$T/brk/.harness" && echo 'exit 3' > "$T/brk/.harness/config.sh"
printf '%s\n' start "$T/brk" qbrk --spec SPEC.md > "$Q/0007-start-brk.args"
HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. timeout 120 "$HERE/../lib/queue.sh" > "$T/qrun2.out" 2>&1; settle
check "a name taken in held/ parks under another; the one there is untouched; the queue drains" \
  'tk=$(compgen -G "$Q/held/0005-start-proj-*.args") && grep -qx qtaken "$tk" && [[ $(cat "$Q/held/0005-start-proj.args") == planted ]] \
  && grep -qF "spec docs/missing.md: not in origin/main" "${tk%.args}.why" && ! compgen -G "$Q/*.args" > /dev/null && grep -q "queue empty" "$T/qrun2.out"'
check "an entry whose project is no repository is not parked: its start fails and says why" \
  '! compgen -G "$Q/held/0006-*" > /dev/null && grep -q "starting: harness start $T/norepo qnorepo" "$Q/runner.log" && grep -q "failed: harness start $T/norepo" "$Q/runner.log"'
check "a spec check that fails without a line parks with a reason, never an empty one" \
  'grep -qE "^spec check failed in [^ ]*brk \(exit 3\) \([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}\)$" "$Q/held/0007-start-brk.why" && grep -qF "parked 0007-start-brk.args: spec check failed" "$Q/runner.log"'

# an absolute --spec inside the project (a shell's ~ expanded) is checked as its path in the repo (the Q1-02 review)
"$H" start "$T/proj" absok --spec "$T/proj/SPEC.md" --until-epoch "$(past)" --foreground > "$T/absok.out" 2>&1
"$H" start "$T/proj" absmiss --spec "$T/proj/docs/missing.md" > "$T/absmiss.out" 2>&1; absmiss_rc=$?
check "an absolute --spec inside the project is checked as its repo path: present proceeds, missing is refused by that path" \
  '[[ -d $HARNESS_STATE/proj/absok && $absmiss_rc == 1 && ! -e $HARNESS_STATE/proj/absmiss ]] && ! grep -q "not in origin" "$T/absok.out" \
  && grep -qF "spec docs/missing.md: not in origin/main" "$T/absmiss.out"'

suite_end
