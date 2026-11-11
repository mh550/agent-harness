#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- the review surface's verbs (docs/specs/2026-11-10-review-surface.md V2): a memory PR's merge and close from the
# card, and the run-level decline a close with a why writes (harness memory decline <run> --why) ----
# No stub run: the ledger is built here as a run's ledger() leaves it, its memory-result.json from curator.mjs apply over
# tests/fixtures/memory's corrected ops and entries (the driver's own call), its memory-answers.jsonl a ledger commit.
status_stubs
L=$HARNESS_LEDGER FM=$HERE/fixtures/memory
cp "$T/base-config.sh" "$T/user-config.sh" && echo 'LEDGER_COMMIT=1' >> "$T/user-config.sh"
mkdir -p "$L/proj/r1" "$T/mw" && printf '# proj\n\n## Code rules\n\n- a seeded rule (seed 2026-11-01)\n\n## Gotchas\n\n- a seeded gotcha (seed 2026-11-01)\n' > "$T/mw/CLAUDE.md"
# two rules beside the corrected facts (rules/1, rules/2: what a close of the rules PR with a why declines): B's entry
# and its op with the text and the section changed
RT=("Every lib file opens with a one-line usage header (r1 2026-11-07)" "Every check name gets one line in check-names.txt (r1 2026-11-07)")
{ cat "$FM/corrected.entries.jsonl"; for i in 0 1; do sed -n 3p "$FM/corrected.entries.jsonl" | jq -c --arg t "${RT[$i]}" --arg f "C$i" '.feature = $f | .discoveries[0].text = $t'; done; } > "$T/mem.entries.jsonl"
jq -c --arg a "${RT[0]}" --arg b "${RT[1]}" '.[1] as $o | . + ([[$a, 4], [$b, 5]] | map(. as [$t, $l] | $o | .section = "## Code rules" | .tier = 2 | .text = $t | .from = "entries.jsonl:\($l)"))' \
  "$FM/corrected.ops.json" > "$T/mem.ops.json"
node "$HERE/../lib/curator.mjs" apply "$T/mem.ops.json" "$T/mw" r1 "$T/mem.entries.jsonl" \
  | jq -c 'del(.ruleTexts)' > "$L/proj/r1/memory-result.json"   # as driver.sh's ledger copy writes it
# ledger/memory.jsonl as the driver's ledger() writes it (summary.mjs memory-line over the run's summary): r1's facts PR
# (pr/1) and rules PR (pr/2) from a stub run's memory.json (fixtures/memory/event-memory.json) with every op held, and
# r2's facts PR (pr/3) whose review did not run; r2 has no memory-result.json in the ledger
jq -c '{run: "r1", project: "proj", memory: (.pr = "https://example.test/pr/1" | .rules_pr = "https://example.test/pr/2" | .rules = 2 | .reviewed_ids += ["rules/2"] | .reviewed = 4 | .failed = 0 | .held = 4 | .failed_ids = [])}' \
  "$FM/event-memory.json" > "$T/sum-r1.json"
jq -c '{run: "r2", project: "proj", memory: (.pr = "https://example.test/pr/3" | .rules_pr = null | .review = "the reviewer wrote no memory-review.json")}' \
  "$FM/event-memory.json" > "$T/sum-r2.json"
node "$HERE/../lib/summary.mjs" memory-line "$T/sum-r1.json" "$L/memory.jsonl" > /dev/null && node "$HERE/../lib/summary.mjs" memory-line "$T/sum-r2.json" "$L/memory.jsonl" > /dev/null
git init -q -b main "$L" && git -C "$L" config user.name t && git -C "$L" config user.email t@t
git -C "$L" add -A && git -C "$L" commit -qm "ledger: r1"
lines() { git -C "$L" log --oneline | wc -l; }

# by hand: the facts PR of r1 closed on GitHub with a reason the next curator should read
n0=$(lines)
"$H" memory decline r1 --why 'these facts are stale' > "$T/d1.out" 2> "$T/d1.err"; d1=$?
check "harness memory decline <run> --why: one run-level row in memory-answers.jsonl and one ledger commit" \
  '(( d1 == 0 )) && [[ $(cat "$T/d1.out") == "memory: r1 declined · the facts PR · these facts are stale" && ! -s $T/d1.err ]] \
  && jq -e -s "length == 1 and (.[0] | keys_unsorted == [\"run\",\"project\",\"n\",\"tier\",\"verdict\",\"why\",\"file\",\"section\",\"text\",\"key\",\"at\"]
       and .run == \"r1\" and .project == \"proj\" and .n == null and .tier == 1 and .verdict == \"declined\" and .why == \"these facts are stale\"
       and .file == null and .section == null and .text == null and .key == null)" "$L/memory-answers.jsonl" > /dev/null \
  && (( $(lines) == n0 + 1 )) && [[ $(git -C "$L" log -1 --format=%s) == "ledger: memory decline r1" && -z $(git -C "$L" status --porcelain) ]]'

cp "$L/memory-answers.jsonl" "$T/answers-before"; n1=$(lines)
"$H" memory decline r1 > "$T/d2.out" 2> "$T/d2.err"; d2=$?
check "harness memory decline <run> without --why: one usage: line on stderr, exit 1, no row written" \
  '(( d2 == 1 )) && [[ ! -s $T/d2.out && $(wc -l < "$T/d2.err") == 1 ]] && grep -x "memory: usage: harness memory decline <run>/<n> --why \"<text>\" | decline <run> --why \"<text>\"" "$T/d2.err" > /dev/null \
  && cmp "$T/answers-before" "$L/memory-answers.jsonl" && (( $(lines) == n1 ))'

# ---- the card's merge and close (V2-02): harness requests runs a v2 request on a memory PR the ledger knows ----
# The PRs are made in the stub gh as memory_pr makes them: the driver's commits on harness-memory/<run> and
# harness-rules/<run>, then pr create (pr/1, pr/2, pr/3). Each part below starts from them open (reset: the stub's PR
# files and origin's main as they were), and from no memory-answers.jsonl.
R=$HARNESS_STATE/requests FX=$HERE/fixtures/requests RQ=$HERE/../lib/requests.sh P=$T/prs
port=7990; sr proj r1 7200 done 3600; sr proj r2 7200 done 3600   # the runs the requests name, real runs of the state
mkpr() { git checkout -q -b "$1" main && echo "$2" > "pr-${1//\//-}.txt" && git add -A && git commit -qm "$2" && git push -q origin "$1" \
  && git checkout -q main && "$HARNESS_GH" pr create --base main --head "$1" --title "$3" > /dev/null; }   # <head> <commit subject> <title>
mkpr harness-memory/r1 "memory: r1: 1 facts" "memory: r1"; mkpr harness-rules/r1 "memory: r1: 2 rules" "memory rules: r1"; mkpr harness-memory/r2 "memory: r2: 1 facts" "memory: r2"
M0=$(git -C "$T/origin.git" rev-parse main)
reset() { rm -f "$P"/pr-[0-9]*.merged "$P"/pr-[0-9]*.closed "$P"/pr-[0-9]*.comment "$L/memory-answers.jsonl"; git -C "$T/origin.git" update-ref refs/heads/main "$M0"; }
req() { local n=$1 fx=$2 f=$3; shift 3; jq -c "$@" "$f" "$FX/$fx.json" > "$R/$n"; }   # <file> <fixture> <jq filter> [jq args…], as request-files.sh's
res() { jq -e "$2" "$R/done/$1.json" > /dev/null 2>&1; }   # <name> <jq test>
logl() { grep -F " id=$1 " "$R/requests.log"; }   # <id>: its requests.log line
KEYS='["v","id","at","verb","run","ok","exit","output","runner_started","refused","pr","state"]'
U1=https://example.test/pr/1 U2=https://example.test/pr/2 U3=https://example.test/pr/3
"$H" requests > /dev/null 2>&1   # requests/ made as the first call makes it (mode 700)
reset

# merges: the facts PR, the rules PR, a merged one again, the first id again
req req-0101-merge.json merge .
req req-0104-mrul.json merge '.id = "req-0104-mrul" | .pr = $u' --arg u "$U2"
"$H" requests > "$T/m1.out" 2>&1; m1=$?
cp "$R/done/req-0101-merge.json" "$T/m1-result.json"
"$H" memory > "$T/m1-memory.out" 2>&1
check "harness requests: a v2 merge of the facts PR merges it in the stub gh, its result ok with state merged and the twelve keys, requests.log's line pr= and no why" \
  '(( m1 == 0 )) && [[ -f $P/pr-1.merged ]] && on_main harness-memory/r1 && res req-0101-merge ".v == 2 and .ok == true and .exit == 0 and .state == \"merged\" and .pr == \"$U1\" and .refused == null and .runner_started == false" \
  && [[ $(jq -c keys_unsorted "$R/done/req-0101-merge.json") == "$KEYS" ]] && [[ -f $R/done/req-0101-merge.request.json && ! -e $R/req-0101-merge.json ]] \
  && logl req-0101-merge | grep -E "^2026-10-28 00:00:00 id=req-0101-merge verb=merge run=r1 pr=$U1 ok exit=0$" > /dev/null && grep -xF "gh pr merge $U1 --merge" "$T/gh.log" > /dev/null'
check "harness requests: a v2 merge of the rules PR merges it the same way, and harness memory reads both rows merged unchanged with no override" \
  '[[ -f $P/pr-2.merged ]] && on_main harness-rules/r1 && res req-0104-mrul ".ok == true and .state == \"merged\" and .pr == \"$U2\"" \
  && grep -E "^r1 · proj · facts · [0-9]+/[0-9]+/[0-9]+ · held 2 · failed 0 · $U1 · merged unchanged$" "$T/m1-memory.out" > /dev/null \
  && grep -xF "r1 · proj · rules · 2 · ## Code rules · held 2 · failed 0 · $U2 · merged unchanged" "$T/m1-memory.out" > /dev/null && ! grep -F "override:" "$T/m1-memory.out" > /dev/null'
req req-0105-again.json merge '.id = "req-0105-again"'
req req-0101-merge.json merge .
"$H" requests > "$T/m2.out" 2>&1; m2=$?
check "harness requests: a merge of a merged PR is refused already merged and moves to rejected/; a second request with the first id stands on the first result" \
  '(( m2 == 0 )) && res req-0105-again ".ok == false and .exit == null and .refused == \"pr $U1 is already merged\" and .state == null and .pr == \"$U1\"" \
  && [[ -f $R/rejected/req-0105-again.json && ! -e $R/done/req-0105-again.request.json ]] && [[ $(grep -c "gh pr merge $U1 --merge" "$T/gh.log") == 1 ]] \
  && logl req-0105-again | grep -E " verb=merge run=r1 pr=$U1 refused exit=- why=pr $U1 is already merged$" > /dev/null \
  && cmp "$T/m1-result.json" "$R/done/req-0101-merge.json" && [[ $(ls "$R/done" | grep -c "^req-0101-merge") == 2 && -f $R/rejected/req-0101-merge.json ]]'

# closes: the rules PR without a why, then the facts PR with the fixture's why and the rules PR with one a shell would expand
reset
req req-0102-close.json close .
"$H" requests > "$T/c1.out" 2>&1; c1=$?
"$H" memory > "$T/c1-memory.out" 2>&1
check "harness requests: a v2 close without a why closes the PR, writes no memory-answers.jsonl row, and harness memory reads closed against a hold" \
  '(( c1 == 0 )) && [[ -f $P/pr-2.closed && ! -e $P/pr-2.comment && ! -e $L/memory-answers.jsonl ]] && grep -xF "gh pr close $U2" "$T/gh.log" > /dev/null \
  && res req-0102-close ".ok == true and .exit == 0 and .state == \"closed\" and .refused == null" \
  && grep -xF "r1 · proj · rules · 2 · ## Code rules · held 2 · failed 0 · $U2 · closed · override: closed against a hold" "$T/c1-memory.out" > /dev/null'
reset
WHY=$'it\'s `x` $(rm -rf /) "q" and a backtick'
req req-0103-cwhy.json close-why .
req req-0106-crwhy.json close '.id = "req-0106-crwhy" | .why = $w' --arg w "$WHY"
"$H" requests > "$T/c2.out" 2>&1; c2=$?
"$H" memory > "$T/c2-memory.out" 2>&1
"$H" memory proposals r1 > "$T/c2-proposals.out" 2>&1
check "harness requests: a v2 close of the facts PR with a why closes it with the why as gh's comment, one run-level declined row, and harness memory reads no override" \
  '(( c2 == 0 )) && [[ -f $P/pr-1.closed && $(cat "$P/pr-1.comment") == "These facts are already in the README." ]] \
  && res req-0103-cwhy ".ok == true and .state == \"closed\" and .refused == null" \
  && jq -se "map(select(.n == null)) | length == 1 and .[0].run == \"r1\" and .[0].verdict == \"declined\" and .[0].why == \"These facts are already in the README.\"" "$L/memory-answers.jsonl" > /dev/null \
  && grep -E "^r1 · proj · facts · .* · $U1 · closed( · [0-9]+ answered)?$" "$T/c2-memory.out" > /dev/null && ! grep -F "override:" "$T/c2-memory.out" > /dev/null \
  && ! grep -F "These facts" "$R/requests.log" > /dev/null'
check "harness requests: a v2 close of the rules PR with a why writes one declined row per rules/<n>, and harness memory proposals shows each verdict" \
  '[[ -f $P/pr-2.closed ]] && res req-0106-crwhy ".ok == true and .state == \"closed\"" \
  && jq -se --arg w "$WHY" "map(select(.n != null)) | map([.run, .n, .tier, .verdict, .why == \$w]) == [[\"r1\", 1, 2, \"declined\", true], [\"r1\", 2, 2, \"declined\", true]]" "$L/memory-answers.jsonl" > /dev/null \
  && grep -xF "r1/1 · rules · CLAUDE.md · ## Code rules · ${RT[0]} · declined: $WHY" "$T/c2-proposals.out" > /dev/null \
  && grep -xF "r1/2 · rules · CLAUDE.md · ## Code rules · ${RT[1]} · declined: $WHY" "$T/c2-proposals.out" > /dev/null \
  && grep -E "^r1 · proj · rules · .* · closed · 3 answered$|^r1 · proj · (facts|rules) · .* · 3 answered$" "$T/c2-memory.out" > /dev/null'
check "harness requests: a why holding a backtick, \$( and a quote reaches gh pr close --comment byte for byte, and lib/requests.sh holds no eval or bash -c" \
  'cmp <(printf %s "$WHY") <(printf %s "$(cat "$P/pr-2.comment")") && [[ $(grep -c "eval\|bash -c" "$RQ") == 0 ]] && ! grep -F "rm -rf" "$R/requests.log" > /dev/null'

# refusals before any call: the review rule, an unknown PR, a PR of another run; then a close whose run has no
# memory-result.json in the ledger (the decline fails, the close stands)
reset; : > "$T/gh.log"
req req-0107-norev.json merge '.id = "req-0107-norev" | .run = "r2" | .pr = $u' --arg u "$U3"
req req-0108-unkn.json merge '.id = "req-0108-unkn" | .pr = "https://example.test/pr/9"'
req req-0109-othr.json merge '.id = "req-0109-othr" | .pr = $u' --arg u "$U3"
"$H" requests > "$T/f1.out" 2>&1; f1=$?
check "harness requests: a merge of a PR whose row's review is not ok is refused, the review did not run, and nothing is merged" \
  '(( f1 == 0 )) && res req-0107-norev ".ok == false and .exit == null and .state == null and .refused == \"the review did not run for $U3 (the reviewer wrote no memory-review.json): merge it on GitHub if you mean to\"" \
  && [[ ! -e $P/pr-3.merged && -f $R/rejected/req-0107-norev.json ]] && ! grep "pr merge" "$T/gh.log" > /dev/null'
check "harness requests: a merge of a PR no ledger row has, or of another run, is refused with V2-01's reasons before any gh call" \
  'res req-0108-unkn ".refused == \"pr https://example.test/pr/9 is not a memory PR the ledger knows (ledger/memory.jsonl)\" and .pr == null and (keys_unsorted | length) == 12" \
  && res req-0109-othr ".refused == \"pr $U3 belongs to run r2, not r1\"" && [[ -f $R/rejected/req-0108-unkn.json && -f $R/rejected/req-0109-othr.json ]] \
  && ! grep -F "/pr/9" "$T/gh.log" > /dev/null && [[ $(grep -c "^gh pr view" "$T/gh.log") == 1 ]]'
req req-0110-nores.json close-why '.id = "req-0110-nores" | .run = "r2" | .pr = $u' --arg u "$U3"
"$H" requests > "$T/f2.out" 2>&1; f2=$?
check "harness requests: a close with a why whose run has no memory-result.json in the ledger closes the PR, its failed decline one line in the output" \
  '(( f2 == 0 )) && [[ -f $P/pr-3.closed ]] && res req-0110-nores ".ok == true and .exit == 0 and .state == \"closed\" and .refused == null" \
  && [[ $(jq -r .output "$R/done/req-0110-nores.json" | grep -c "^memory decline r2 failed, the close stands: ") == 1 ]] && [[ ! -e $L/memory-answers.jsonl ]]'

# gh refusing the merge: it ran, so ok false with gh's text, no refusal
reset
req req-0111-gref.json merge '.id = "req-0111-gref"'
STUB_REFUSE_MERGE=1 "$H" requests > "$T/g1.out" 2>&1; g1=$?
check "harness requests: gh refusing a v2 merge gives ok false with gh's GraphQL line as the output and no refusal, nothing in rejected/" \
  '(( g1 == 0 )) && res req-0111-gref ".ok == false and .exit == 1 and .refused == null and .state == null and (.output | contains(\"GraphQL: Head branch was modified.\"))" \
  && [[ ! -e $R/rejected/req-0111-gref.json && -f $R/done/req-0111-gref.request.json && ! -e $P/pr-1.merged ]] && logl req-0111-gref | grep -E " pr=$U1 failed exit=1$" > /dev/null'

# ---- the n8n-home half (V2-03): the checklist a session there builds from names this repo's fixtures, and each is real ----
CL=$HERE/../docs/2026-11-10-review-surface-n8n-home.md need=() gone=()
for f in n8n-event-v2-memory.json requests/merge.json requests/close.json requests/close-why.json requests/result-v2.json; do
  grep -F "tests/fixtures/$f" "$CL" > /dev/null 2>&1 || need+=("$f"); done
while read -r f; do [[ -e $HERE/fixtures/${f#tests/fixtures/} ]] || gone+=("$f"); done < <(grep -oE 'tests/fixtures/[A-Za-z0-9_./-]+' "$CL" 2>/dev/null)
nf=$(grep -cE 'tests/fixtures/[A-Za-z0-9_./-]+' "$CL" 2>/dev/null)
check "the n8n-home checklist names the v2 event, request and result fixtures by path, and every tests/fixtures path it names exists" \
  '[[ -f $CL && ${#need[@]} == 0 && ${#gone[@]} == 0 ]] && (( ${nf:-0} >= 5 ))'

suite_end
