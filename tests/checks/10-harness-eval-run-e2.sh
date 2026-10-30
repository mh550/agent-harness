#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- harness eval run (E2-03): two stub tasks replayed by the committed driver (--harness HEAD), in isolation ----
# The task repo's own config would merge through gh and post to ntfy: the eval's run.env must beat it.
ER=$T/evrepo; git init -q --bare -b main "$T/evorigin.git" && git init -q -b main "$ER" && mkdir "$ER/.harness" \
  && printf '%s\n' 'CHECK_CMD="test ! -f BROKEN"' 'MERGE_POLICY=auto NTFY_URL=https://ntfy.example/evproj BASE_PORT=7831' > "$ER/.harness/config.sh" \
  && printf '# evproj\nrules\n' > "$ER/CLAUDE.md" && echo spec > "$ER/SPEC.md" && git -C "$ER" add -A && git -C "$ER" commit -qm init \
  && git -C "$ER" remote add origin "$T/evorigin.git" && git -C "$ER" push -q -u origin main
EB=$(git -C "$ER" rev-parse HEAD); mkdir -p "$T/tasks"
# the source's later work (a branch, and a run tag on it, as real milestones leave): no replay may see it (E2 review)
git -C "$ER" checkout -qb later && echo answer > "$ER/later.txt" && git -C "$ER" add later.txt && git -C "$ER" commit -qm "later: the answer" \
  && git -C "$ER" tag run/src/M1 && git -C "$ER" checkout -q main && git -C "$ER" repack -qad \
  && for p in "$ER"/.git/objects/pack/*.pack; do touch "${p%.pack}.keep"; done; EF=$(git -C "$ER" rev-parse later)   # a kept pack gc won't touch
for t in t1 t2; do mkdir -p "$T/tasks/$t" && jq --arg r "$ER" --arg b "$EB" '.repo = $r | .base = $b' "$HERE/fixtures/eval-tasks/$t/task.json" > "$T/tasks/$t/task.json"
  echo "$T/tasks/$t/task.json"; done > "$T/set.txt"
src_refs() { git -C "$ER" for-each-ref; git -C "$ER" status --porcelain; git -C "$T/evorigin.git" for-each-ref; }   # the source repo and its origin
lines() { cat "$1" 2> /dev/null | wc -l; }; GH0=$(lines "$T/gh.log") CU0=$(lines "$T/curl.log") SR0=$(src_refs)
HARNESS_EVAL_TMP=$T/evaltmp HARNESS_EVAL_RESULTS=$T/results HARNESS_EVAL_GH=$HERE/stub-gh.sh HARNESS_EVAL_CURL=$HERE/stub-curl.sh \
  "$H" eval run --set "$T/set.txt" --harness HEAD --label test > "$T/eval1.out" 2>&1
# the short sha of HEAD, as harness_version names it (a ledger-only commit on top of main isn't a new version)
ED=$(compgen -G "$T/results/*-test" | head -1); EJ=$ED/eval.json HS=$(git -C "$HERE/.." log -1 --format=%h -- . ":(exclude)ledger")
ev_files() { local t; for t in t1 t2; do for f in summary.json metrics.jsonl harness-log.md feature_list.json; do [[ -s $ED/$t/$f ]] || return 1; done; done; }
ev_local() { local c; [[ $(jq '.tasks | length' "$EJ") == 2 ]] || return 1   # each task clone's origin is a path in the eval dir
  for c in $(jq -r '.tasks[].clone' "$EJ"); do [[ $(git -C "$c" remote get-url origin) == "$(jq -r .eval_dir "$EJ")"/* ]] || return 1; done; }
ev_driver() { local s; jq -e --arg v "$HS" '.harness.version == $v' "$ED/t1/summary.json" > /dev/null && jq -e --arg v "$HS" '.harness.version == $v' "$ED/t2/summary.json" > /dev/null \
  && for s in $(jq -r '.tasks[].state' "$EJ"); do grep -qF "$1/lib/check.sh" "$s/prompt-coding.md" || return 1; done; }   # the {{CHECK}} of the ref's driver
check "eval run: two stub tasks end to end, results in place" '[[ -n $ED && $ED == *-$HS-test ]] && ev_files \
  && jq -e "(.features_detail | length) == 1 and all(.features_detail[]; .passes)" "$ED/t1/summary.json" > /dev/null \
  && jq -e "(.features_detail | length) == 2 and all(.features_detail[]; .passes)" "$ED/t2/summary.json" > /dev/null \
  && jq -e ".stamp and .ref == \"HEAD\" and .sha == \"$HS\" and .label == \"test\" and ([.tasks[].id] == [\"t1\", \"t2\"]) and all(.tasks[]; .clone and .worktree)" "$EJ" > /dev/null \
  && ! git -C "$HERE/.." worktree list | grep -q "$T/evaltmp" && [[ $(src_refs) == "$SR0" ]]'
check "eval run: --harness <ref> runs that ref's driver" '[[ -f $EJ && $(jq -r .sha "$EJ") == "$HS" ]] && HD=$(jq -r .harness_dir "$EJ") && [[ $HD == "$T/evaltmp/"* ]] \
  && grep -qF "$HD" "$ED/eval.log" && ev_driver "$HD"'
check "eval run: nothing reaches a remote" '[[ -f $EJ ]] && ev_local && [[ $(lines "$T/gh.log") == "$GH0" && $(lines "$T/curl.log") == "$CU0" ]] \
  && [[ $(compgen -G "$T/evaltmp/*/state/*/*/run.log" | wc -l) == 2 ]] && ! cat "$T"/evaltmp/*/state/*/*/run.log | grep -q "notified:\|notification failed" \
  && (( $(cat "$T"/evaltmp/*/state/*/*/port | sort -u | wc -l) == 2 && $(cat "$T"/evaltmp/*/state/*/*/port | sort -n | head -1) >= 7900 ))'
ev_sealed() { local c r; for c in $(jq -r '.tasks[].clone' "$EJ"); do r=$(jq -r --arg c "$c" '.tasks[] | select(.clone == $c) | .run' "$EJ")
  [[ $(git -C "$c" rev-parse main) == "$EB" ]] && ! git -C "$c" rev-parse -q --verify refs/tags/run/src/M1 > /dev/null && ! git -C "$c" cat-file -e "$EF" 2> /dev/null \
  && ! git -C "$c" show "harness/$r:.harness/runs/$r/progress.md" | grep -qF "$ER" || return 1; done; }   # nor the source's path
check "eval run: a clone holds nothing of its source past base (E2 review)" '[[ -f $EJ && -n $EF ]] && ev_sealed && git -C "$ER" cat-file -e "$EF"'

# ---- eval money and time (E2-04): the budget cap, the 7-day window, --repeat ----
evrun() { HARNESS_EVAL_TMP=$T/evaltmp HARNESS_EVAL_RESULTS=$T/results HARNESS_EVAL_GH=$HERE/stub-gh.sh HARNESS_EVAL_CURL=$HERE/stub-curl.sh \
  "$H" eval run --set "$T/set.txt" --harness HEAD "$@"; }
# a stub task spends $0.35 (coding $0.25, verify $0.10): a $0.30 cap lets t1 run and starts nothing after it
EVAL_BUDGET_USD=0.3 evrun --label budget > "$T/eval-budget.out" 2>&1; EBR=$?   # not starting a task exits 1
EBD=$(compgen -G "$T/results/*-budget" | head -1)
check "eval: the budget cap stops starting tasks" '(( EBR == 1 )) && [[ -n $EBD ]] && grep -q "^budget: \$0.35 of \$0.3; 1 tasks not started$" "$T/eval-budget.out" \
  && grep -q "starting no further task: \$0.35 spent, the cap is \$0.3" "$T/eval-budget.out" \
  && jq -e "[.tasks[].id] == [\"t1\"] and .budget.cap == 0.3 and .budget.spent == 0.35 and .budget.not_started == [\"t2\"] and .weekly == null
    and .budget.text == \"budget: \$0.35 of \$0.3; 1 tasks not started\"" "$EBD/eval.json" > /dev/null && [[ -s $EBD/t1/summary.json && ! -e $EBD/t2 ]] \
  && grep -qx "WEEKLY_STOP_AT=85" "$(jq -r ".tasks[0].state" "$EBD/eval.json")/run.env"'   # the runs stop where the eval does
# the real state root's USAGE_7D (here $HARNESS_STATE) past WEEKLY_STOP_AT (85): nothing is created, not even the tmp dir
mkdir -p "$T/evstate" && echo "0.9 $(( $(date +%s) + 3600 ))" > "$T/evstate/USAGE_7D"
HARNESS_STATE=$T/evstate HARNESS_EVAL_TMP=$T/evaltmp-w HARNESS_EVAL_RESULTS=$T/results-w "$H" eval run --set "$T/set.txt" --label weekly > "$T/eval-weekly.out" 2>&1; EWR=$?
check "eval: refuses past WEEKLY_STOP_AT" '(( EWR == 1 )) && grep -q "7-day window at 90%" "$T/eval-weekly.out" && [[ ! -e $T/results-w && ! -e $T/evaltmp-w ]]'
# a real run holds port 7900 (its port file in the real state root): the eval's runs keep off it (E2 review)
mkdir -p "$T/evstate-p/proj/run" && echo 7900 > "$T/evstate-p/proj/run/port"
HARNESS_STATE=$T/evstate-p evrun --label rep --repeat 2 > "$T/eval-rep.out" 2>&1; ERR=$?
ERD=$(compgen -G "$T/results/*-rep" | head -1)
ev_reps() { local t r; for t in t1 t2; do for r in r1 r2; do jq -e "all(.features_detail[]; .passes)" "$ERD/$t/$r/summary.json" > /dev/null || return 1; done; done; }
check "eval: --repeat 2 runs each task twice" '(( ERR == 0 )) && [[ -n $ERD ]] && ev_reps && jq -e ".repeat == 2 and ([.tasks[].result] == [\"t1/r1\", \"t2/r1\", \"t1/r2\", \"t2/r2\"])
    and ([.tasks[].repeat] == [1, 1, 2, 2]) and ([.tasks[].clone] | unique | length) == 4 and ([.tasks[].run] | unique | length) == 4" "$ERD/eval.json" > /dev/null \
  && ! cat $(jq -r ".tasks[].state + \"/port\"" "$ERD/eval.json") | grep -qx 7900'
# refused before anything is created (E2 review): a task whose repo isn't there; a set named as a file in the cwd
mkdir -p "$T/evnorepo/t1" && jq '.repo = "/nonexistent/ev repo"' "$T/tasks/t1/task.json" > "$T/evnorepo/t1/task.json" && echo "$T/evnorepo/t1/task.json" > "$T/set-norepo.txt"
HARNESS_EVAL_TMP=$T/evaltmp-n HARNESS_EVAL_RESULTS=$T/results-n "$H" eval run --set "$T/set-norepo.txt" > "$T/eval-norepo.out" 2>&1; ENR=$?
(cd "$T" && HARNESS_EVAL_TMP=$T/evaltmp-n HARNESS_EVAL_RESULTS=$T/results-n "$H" eval run --set set-norepo.txt > "$T/eval-norepo2.out" 2>&1); ENR2=$?
check "eval: a missing repo is refused before any spend, a set file in the cwd is read (E2 review)" '(( ENR == 1 && ENR2 == 1 )) \
  && grep -q "t1: no repo /nonexistent/ev repo; nothing started" "$T/eval-norepo.out" && cmp -s "$T/eval-norepo.out" "$T/eval-norepo2.out" && [[ ! -e $T/evaltmp-n && ! -e $T/results-n ]]'
# an eval killed mid-task (its process group TERMed) removes its harness worktree. The session itself runs on: the
# driver's `timeout` has a process group of its own (a known limit, docs/plans/2026-10-21-E2-review.md R2)
STUB_SLOW_CODING=8 HARNESS_EVAL_TMP=$T/evaltmp-i HARNESS_EVAL_RESULTS=$T/results-i HARNESS_EVAL_GH=$HERE/stub-gh.sh HARNESS_EVAL_CURL=$HERE/stub-curl.sh \
  setsid bash -c 'echo $$ > "$1"; shift; exec "$@"' _ "$T/eval-int.pid" "$H" eval run --set "$T/set.txt" --harness HEAD --label int > "$T/eval-int.out" 2>&1 & EIJ=$!
wait_for 60 test -e "$T/slow-coding"
EIH=$(compgen -G "$T/evaltmp-i/*/harness" | head -1) EIP=$(cat "$T/eval-int.pid"); kill -TERM -- "-$EIP" 2> /dev/null
wait "$EIJ"; EIR=$?   # setsid didn't fork (EIJ == EIP), so this is the eval's own exit
check "eval: an interrupted eval removes its harness worktree (E2 review)" '[[ -n $EIH && $EIJ == "$EIP" ]] && (( EIR == 130 )) && [[ ! -e $EIH ]] \
  && ! git -C "$HERE/.." worktree list | grep -qF "$T/evaltmp-i" && [[ -f $(compgen -G "$T/results-i/*-int" | head -1)/eval.json ]]'
# compare (E2-05): the one-repeat eval against the two-repeat one (one sample), and the two-repeat one against itself
"$H" eval compare "$ED" "$ERD" > "$T/evcmp.out" 2>&1; ECR=$?
"$H" eval compare "$ERD" "$ERD" > "$T/evcmp2.out" 2>&1; ECR2=$?
HARNESS_EVAL_RESULTS=$T/results "$H" eval compare "${ED##*/}" "${ERD##*/}" > "$T/evcmp3.out" 2>&1   # a bare name is a dir under the results root
cp -r "$ERD" "$T/evcrash" && rm "$T/evcrash/t2/r2/summary.json"   # a repeat that started and wrote no summary failed
"$H" eval compare "$ERD" "$T/evcrash" > "$T/evcmp4.out" 2>&1
ev_cmp() { local m; (( ECR == 0 && ECR2 == 0 )) || return 1
  for m in 'pass rate' '\$ per verified feature' 'tokens per verified feature' 'cache hit rate' 'orientation tokens' 'context peak' 'wall time (h)' 'rework'; do
    grep -q "^$m: one sample (A " "$T/evcmp.out" && grep -q "^$m: within noise (A " "$T/evcmp2.out" || return 1; done; }
check "eval compare prints the table" 'ev_cmp && grep -q "^| t1 | pass rate | pass^1 1 (1/1) | pass^2 1 (2/2) | one sample |$" "$T/evcmp.out" \
  && [[ $(grep -c "^| t[12] | " "$T/evcmp.out") == 16 ]] && grep -q "^## Totals" "$T/evcmp.out" && [[ $(grep -c "^| total | " "$T/evcmp.out") == 8 ]] \
  && cmp -s "$T/evcmp.out" "$T/evcmp3.out" && ! "$H" eval compare "$T/results" "$ED" > /dev/null 2>&1 && grep -q "^A: 1 repeat, B: 2 repeats: pass^N" "$T/evcmp.out" \
  && grep -q "^| t2 | pass rate | pass^2 1 (2/2) | pass^2 0 (1/2) | " "$T/evcmp4.out" && grep -q "^B: t2 r2: no summary" "$T/evcmp4.out"'
# probes (E2-06): questions from the record, one tool-less session on the next session's prompt, scored by match
EVPQ='import { questions as q, score as s, target as tg } from "'$HERE'/../lib/eval.mjs";
  const list = { features: [ { id: "X1", milestone: "M", passes: true }, { id: "X2", milestone: "M", passes: false, after: ["X1"] }, { id: "X3", milestone: "M", passes: false } ] };
  const rows = [ { kind: "coding", feature: "X2", passes: false, env: false, final: "The suite was red: test foo failed. Then I stopped." },
    { kind: "coding", feature: "X2", passes: false, env: true, final: "usage limit" }, { kind: "verify", feature: null, passes: false, env: false, final: "M not verified." } ];
  const commits = [ { subject: "X1: work", files: ["a.txt", ".harness/runs/r/feature_list.json"] }, { subject: "X1: more", files: ["b.txt"] },
    { subject: "X10: other", files: ["c.txt"] }, { subject: "HARNESS: x", files: ["d.txt"] } ];
  const p = q(list, rows, commits), k = p.questions.map(x => x.kind).join();
  const r = s(p, "Q1: `b.txt`, a.txt.\nQ2: it depends on X1 only\nQ3: no idea"), m = r.questions.map(x => x.match).join();
  const all = { features: [ { id: "Y1", passes: true }, { id: "Y2", passes: true } ] };
  // a markdown final, an abbreviation; the last real attempt passed (X2: no question); a park is not a failure (X3)
  const f2 = q({ features: [ { id: "X1", passes: false }, { id: "X2", passes: true }, { id: "X3", passes: false } ] }, [
    { kind: "coding", feature: "X1", passes: false, env: false, final: "## Summary\n\n**X1 is not done: the suite fails on e.g. foo.** More text." },
    { kind: "coding", feature: "X2", passes: false, env: false, final: "Red suite." }, { kind: "coding", feature: "X2", passes: true, env: false, final: "Done." },
    { kind: "coding", feature: "X3", passes: false, env: false, final: "Needs a token.\nPARKED: set the token" } ], []);
  process.exit(p.target === "X2" && tg(all) === "Y2" && k === "files,depends,fails" && JSON.stringify(p.questions[0].key) === "[\"a.txt\",\"b.txt\"]"
    && p.questions[0].q === "Which files did X1 change?" && p.questions[2].key === "The suite was red: test foo failed" && p.questions[2].feature === "X2"
    && m === "exact,contains,miss" && r.points === 2 && r.score === "2/3" && q(all, [], []).questions.map(x => x.key.join()).join() === "Y1"
    && s(p, "Q2: X1").questions[0].match === "miss" && s(p, "Q01: a.txt b.txt\nQ2: X10").questions.map(x => x.match).join() === "exact,miss,miss"
    && s(p, "Q1: Which files did X1 change?\nQ1: data.txt, b.txt").questions[0].match === "miss" && s(p, "Q1: the files a.txt and b.txt").questions[0].match === "contains"
    && f2.questions.filter(x => x.kind === "fails").map(x => x.feature + "=" + x.key).join("|") === "X1=X1 is not done: the suite fails on e.g. foo"
    && !f2.questions.some(x => x.kind === "fails" && x.feature === "X2") ? 0 : 1);'
"$H" eval probes "$ED/t2" > "$T/evprobe.out" 2>&1; EPR=$?
cp "$STUB_DIR/probe-args" "$T/probe-args1" 2> /dev/null; cp "$STUB_DIR/probe-prompt" "$T/probe-prompt1" 2> /dev/null
# a session that fails (an API error) is no score: exit 1, and the last scored probes.json is kept
cp "$ED/t2/probes.json" "$T/probes-kept.json" 2> /dev/null; STUB_PROBE_ERROR=1 "$H" eval probes "$ED/t2" > "$T/evperr.out" 2>&1; EPE=$?
ev_probe() { local wt; wt=$(jq -r '.tasks[1].worktree' "$EJ")
  (( EPR == 0 )) && grep -qx "score 1/2" "$T/evprobe.out" && grep -q "^Q1 exact · Which files did T2a change? · work-T2a.txt" "$T/evprobe.out" \
  && jq -e '(.questions | length) >= 2 and .target == "T2b" and .score == "1/2" and .points == 1 and .model == "haiku" and .cost == 0.01
    and .questions[0].kind == "files" and .questions[0].key == ["work-T2a.txt"] and .questions[0].match == "exact" and .questions[0].score == 1
    and .questions[1].kind == "depends" and .questions[1].key == ["T2a"] and .questions[1].match == "miss" and .questions[1].score == 0' "$ED/t2/probes.json" > /dev/null \
  && grep -qx -- "--max-turns 1" <(paste -d" " - - < <(sed -n '/^--max-turns$/,+1p' "$T/probe-args1")) \
  && sed -n '/^--permission-mode$/{n;p}' "$T/probe-args1" | grep -qx dontAsk && sed -n '/^--tools$/{n;p}' "$T/probe-args1" | grep -qx "" \
  && sed -n '/^--allowedTools$/{n;p}' "$T/probe-args1" | grep -qx "" && sed -n '/^--model$/{n;p}' "$T/probe-args1" | grep -qx haiku \
  && grep -qx -- "--strict-mcp-config" "$T/probe-args1" && sed -n '/^--max-budget-usd$/{n;p}' "$T/probe-args1" | grep -qx 0.5 \
  && (( EPE == 1 )) && grep -q "probes: the probe session failed.*session limit" "$T/evperr.out" && cmp -s "$ED/t2/probes.json" "$T/probes-kept.json" \
  && grep -qx "PWD=$wt" "$T/probe-args1" && grep -qx "HARNESS_EVAL=1" "$T/probe-args1" && [[ $(head -1 "$T/probe-prompt1") == "# Probe session" ]] && grep -qx "Q1: Which files did T2a change?" "$T/probe-prompt1"; }
check "eval probes: questions derived, answers scored" 'node --input-type=module -e "$EVPQ" && ev_probe'
# the prompt the probe sees is the one T2b's coding session got (the init output differs: verify re-ran init after it; the clock too);
# a result without its run worktree runs the probe elsewhere and says so; one without a probe prompt is refused
cp -r "$ED" "$T/evgone" && jq '.tasks[].worktree = "/nonexistent"' "$ED/eval.json" > "$T/evgone/eval.json"
mkdir -p "$T/ptmp"; TMPDIR=$T/ptmp "$H" eval probes "$T/evgone/t2" > "$T/evgone.out" 2>&1; EPG=$?
cp -r "$ED" "$T/evnop" && rm "$T/evnop/t2/probe-prompt.md"; "$H" eval probes "$T/evnop/t2" > "$T/evnop.out" 2>&1; EPN=$?
noinit() { sed '/^Clock: /d; /^Suite: last full run /d; /^## Init output/,/^---$/d' "$1"; }   # the clock, the last wall and init output are the session's own
check "eval probes: the probe prompt is the driver's coding prompt" '[[ -s $ED/t2/probe-prompt.md ]] && [[ $(head -1 "$ED/t2/probe-prompt.md") == "# Coding session" ]] && grep -qx "Feature: \`T2b\`" "$ED/t2/probe-prompt.md" && grep -q "^full output: .*/init.out$" "$ED/t2/probe-prompt.md" \
  && cmp -s <(noinit "$ED/t2/probe-prompt.md") <(noinit "$(jq -r ".tasks[1].state" "$EJ")/prompt-coding.md") && cmp -s <(sed -n "3,$(( $(awk 1 "$ED/t2/probe-prompt.md" | wc -l) + 2 ))p" "$T/probe-prompt1") <(awk 1 "$ED/t2/probe-prompt.md") \
  && (( EPG == 0 )) && grep -q "probes: run worktree gone; CLAUDE.md not auto-loaded" "$T/evgone.out" && jq -e ".note | test(\"worktree gone\")" "$T/evgone/t2/probes.json" > /dev/null && [[ -z $(ls -A "$T/ptmp") ]] \
  && ! grep -qx "PWD=$(jq -r ".tasks[1].worktree" "$EJ")" "$STUB_DIR/probe-args" && (( EPN == 1 )) && grep -q "no probe-prompt.md" "$T/evnop.out"'
# the probe reads the run's context pack as the next session would (E4-05 / plan §9), pasted after the prompt
check "eval probes: the probe reads the run's context pack" '[[ $(head -1 "$ED/t2/context.md" 2> /dev/null) == "# Context pack for \`T2b\`" ]] \
  && grep -q " → entries.jsonl:[0-9]*$" "$ED/t2/context.md" && at() { grep -nx -- "$1" "$T/probe-prompt1" | head -1 | cut -d: -f1; } \
  && (( $(at "Feature: \`T2b\`") < $(at "# context.md (the run directory'"'"'s context pack, as the next session reads it)") \
     && $(at "# context.md (the run directory'"'"'s context pack, as the next session reads it)") < $(at "# Context pack for \`T2b\`") \
     && $(at "# Context pack for \`T2b\`") < $(grep -n "^Answer from what is above only" "$T/probe-prompt1" | cut -d: -f1) ))'

suite_end
