#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 20: the review gate's rounds and measures (M6-05, the M6 review's findings) ----
# M1 is A, B, D (build) and R (review); verify is lenient so each run ends done.
# rquiet: R's summary gives no counts. rlimit: R's escalation round is refused by the usage limit, then runs.
# rfail: R's escalation round ends not passing; R's next attempt runs on opus and never escalates again.
STUB_REVIEW_LIST=1 STUB_LENIENT=1 "$H" start "$T/proj" rquiet --spec SPEC.md --foreground > "$T/rquiet.out" 2>&1
git pull -q --ff-only origin main
STUB_REVIEW_LIST=1 STUB_LENIENT=1 STUB_REVIEW_FINDINGS=1,0 STUB_REVIEW_ROUND=limit "$H" start "$T/proj" rlimit --spec SPEC.md --foreground > "$T/rlimit.out" 2>&1
rm -f "$HARNESS_STATE/LIMIT_UNTIL"; git pull -q --ff-only origin main
STUB_REVIEW_LIST=1 STUB_LENIENT=1 STUB_REVIEW_FINDINGS=0,1 STUB_REVIEW_ROUND=fail "$H" start "$T/proj" rfail --spec SPEC.md --foreground > "$T/rfail.out" 2>&1
met() { jq -r --arg f "$2" 'select(.feature == $f and .kind == "coding") | .model' "$T/wt/proj/$1/.harness/runs/$1/metrics.jsonl" 2> /dev/null; }   # <run> <id> → its coding rows' models
plog() { ls "$HARNESS_STATE/proj/$1/logs/"*-"$2".prompt.md 2> /dev/null | head -1; }   # <run> <id> → its first session's prompt copy

check "review gate: a review whose summary gives no counts is noted not escalated, and the run ends done" \
  'hlog rquiet | grep -qF "· review R: no \"<n> Critical, <n> Important\" in its summary or final message; not escalated" \
  && [[ $(met rquiet R | wc -l) == 1 ]] && grep -q "^done" "$HARNESS_STATE/proj/rquiet/ended"'
check "review gate: a review's prompt asks for <n> Critical, <n> Important, <n> Minor in its entry summary; a build session's doesn't" \
  'grep -qF "give your entry'"'"'s summary this review'"'"'s findings as \`<n> Critical, <n> Important, <n> Minor\`" "$(plog rquiet R)" \
  && [[ -s $(plog rquiet A) ]] && ! grep -q "<n> Critical" "$(plog rquiet A)"'
check "review gate: an escalation round refused by a usage limit runs again on opus, still at no attempt" \
  '[[ $(met rlimit R | paste -sd " " -) == *sonnet*" "*opus*" "*opus* ]] && [[ $(hlog rlimit | grep -c "· review R: sonnet found 1 Critical, 0 Important; one round on opus$") == 1 ]] \
  && [[ $(jq -r .R "$HARNESS_STATE/proj/rlimit/attempts.json") == 1 ]] && [[ ! -e $HARNESS_STATE/proj/rlimit/review-escalate ]] && ! compgen -G "$HARNESS_STATE/proj/rlimit/lanes/*/review-escalate" > /dev/null \
  && grep -q "^done" "$HARNESS_STATE/proj/rlimit/ended"'
check "review gate: after an escalation round that doesn't pass, the review's next attempt runs on opus and never escalates again" \
  '[[ $(met rfail R | paste -sd " " -) == *sonnet*" "*opus*" "*opus* && $(met rfail R | wc -l) == 3 ]] \
  && [[ $(hlog rfail | grep -c "one round on") == 1 ]] && hlog rfail | grep -qE "· review R: [0-9]+ changed lines, escalated earlier in this run; opus$" \
  && [[ $(jq -r .R "$HARNESS_STATE/proj/rfail/attempts.json") == 2 ]] && grep -q "^done" "$HARNESS_STATE/proj/rfail/ended"'
check "review gate: the escalation round's Review diff line names the model it runs on" \
  'p2=$(ls "$HARNESS_STATE/proj/rlimit/logs/"*-R.prompt.md | sed -n 2p) && [[ -s $p2 ]] \
  && grep -qE "^Review diff: [0-9]+ files, [0-9]+ changed lines .*; under 400; escalated to opus$" "$p2"'

# review_diff fetches main first: a milestone merged on the server (MERGE_POLICY=auto, gh pr merge) drops out at once
RD=$T/rd; mkdir -p "$RD" && git init -q --bare -b main "$RD/o.git" && git clone -q "$RD/o.git" "$RD/c" 2> /dev/null \
  && (cd "$RD/c" && git commit -q --allow-empty -m base && git push -q origin HEAD:main && git checkout -qb run \
    && seq 300 > m1.txt && git add -A && git commit -qm M1 && git push -q origin run) \
  && git clone -q "$RD/o.git" "$RD/s" 2> /dev/null && (cd "$RD/s" && git merge -q --no-ff --no-edit origin/run && git push -q origin main) \
  && (cd "$RD/c" && seq 50 > m2.txt && mkdir -p .harness/runs && seq 9 > .harness/runs/x && git add -A && git commit -qm M2)
check "review_diff: fetches main first, so a milestone merged meanwhile drops out; the run directory is left out" \
  '[[ $(cd "$RD/c" && source "$HERE/../lib/review.sh" && MAIN_BRANCH=main review_diff) == "1 50" ]]'
check "review_diff: fails with the reason when origin has no such main branch" \
  'out=$(cd "$RD/c" && source "$HERE/../lib/review.sh" && MAIN_BRANCH=nope review_diff); rc=$?; (( rc == 1 )) && [[ $out == "no origin/nope" ]]'

RF='import { reviewFindings as f } from "'$HERE'/../lib/entries.mjs"; const j = x => JSON.stringify(f(x));
  process.exit(j("Critical 0 Important 2") === "{\"critical\":0,\"important\":2}" && j("Critical: 0, Important: 2") === "{\"critical\":0,\"important\":2}"
    && j("**2 Critical**, 3 Important") === "{\"critical\":2,\"important\":3}" && f("M3-06 Critical regression fixed") === null
    && f("Step 1 important: run the suite") === null && f("fixed the 2 critical paths") === null ? 0 : 1);'
check "reviewFindings: reads Critical before Important in either order of word and count, never a step number or lowercase prose" 'node --input-type=module -e "$RF"'
RS='import { reviewSummary as r } from "'$HERE'/../lib/summary.mjs";
  const list = [{ id: "R", kind: "review" }, { id: "S", kind: "review" }, { id: "Q", kind: "review" }];
  const a = r(list, [{ role: "review", cost_usd: 1 }], [{ feature: "R", summary: "R: 1 Critical, 0 Important" }, { feature: "R", summary: "R: 0 Critical, 0 Important" },
    { feature: "S", summary: "S: 0 Critical, 0 Important" }, { feature: "S", summary: "S: not done" }, { feature: "Q", summary: "Q: no counts" }]),
    b = r(list, [], [{ feature: "R", summary: "R: 0 Critical, 0 Important" }, { feature: "R", summary: "R: done" }]);
  process.exit(a.found_nothing === 1 && a.reviews === 3 && b.found_nothing === 1 && b.reviews === 1 ? 0 : 1);'
check "reviewSummary: a review counts as finding nothing only when every entry that gives counts reports 0 Critical, 0 Important" 'node --input-type=module -e "$RS"'

suite_end
