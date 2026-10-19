#!/usr/bin/env bash
# End-to-end test of the driver and CLI with stub claude/gh, a throwaway project and a local bare "origin".
#   tests/run.sh        → prints PASS/FAIL per check, exit 1 on any failure (KEEP=1 keeps the temp dir)
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd); H=$HERE/../bin/harness F="node $HERE/../lib/features.mjs"
T=$(mktemp -d); echo "tmp: $T"
unset TMUX TMUX_PANE   # inside Michael's tmux, plain `tmux` talks to his server: the suite must never
export TMUX_TMPDIR=$T/tmux HARNESS_DESK_SESSION=h-desk-test-$$; mkdir -p "$TMUX_TMPDIR"   # a private tmux server
trap 'tmux kill-session -t "=$HARNESS_DESK_SESSION" 2> /dev/null; [[ $TMUX_TMPDIR == "$T/tmux" ]] && tmux kill-server 2> /dev/null; [[ ${KEEP:-} ]] || rm -rf "$T"' EXIT   # the server is ours alone
export HARNESS_STATE=$T/state HARNESS_WORKTREES=$T/wt HARNESS_SCRATCH_ROOT=$T/scratch HARNESS_PAUSE_POLL=1 \
  HARNESS_CLAUDE=$HERE/stub-claude.sh HARNESS_GH=$HERE/stub-gh.sh HARNESS_CURL=$HERE/stub-curl.sh STUB_DIR=$T HARNESS_LEDGER=$T/ledger \
  HARNESS_CONFIG=$T/user-config.sh HARNESS_LIMIT_SLEEP=0 HARNESS_NO_RUNNER=1 HARNESS_QUEUE_POLL=0 HARNESS_QUEUE_SETTLE=0
fails=0 total=0
check() { total=$((total + 1)); if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fails=$((fails + 1)); fi; }
hlog() { cat "$T/wt/proj/$1/.harness/runs/$1/harness-log.md" 2>/dev/null; }
list() { echo "$T/wt/proj/$1/.harness/runs/$1/feature_list.json"; }
on_main() { git -C "$T/origin.git" merge-base --is-ancestor "$(git -C "$T/origin.git" rev-parse "$1^{commit}")" main; }
curl_with() { awk -v k="$1" 'BEGIN { RS = "===\n" } index($0, k) { printf "%s", $0; exit }' "$T/curl.log" 2>/dev/null; }   # the first stub-curl call containing $1
curl_body() { curl_with "$1" | sed '1,/^--data-binary$/d' | sed '$d'; }   # its data: the lines between --data-binary and the URL
curl_last() { awk -v k="$1" 'BEGIN { RS = "===\n" } index($0, k) { b = $0 } END { printf "%s", b }' "$T/curl.log" 2>/dev/null; }   # the last call containing $1
curl_count() { awk -v k="$1" 'BEGIN { RS = "===\n" } index($0, k) { n++ } END { print n + 0 }' "$T/curl.log" 2>/dev/null; }   # how many calls contain $1
win() { tmux list-windows -t "=$HARNESS_DESK_SESSION" -F '#{window_id} #{window_name}' 2> /dev/null | awk -v w="$1" '$2 == w { print $1 }'; }
wins() { tmux list-windows -t "=$HARNESS_DESK_SESSION" -F '#W' 2> /dev/null; }
in_has() { local i; for i in $(seq 20); do grep -q "$2" "$1" 2> /dev/null && return 0; sleep 0.1; done; return 1; }   # send-keys is asynchronous: wait ≤ 2 s for the typed line
desk_of() { grep -lx "desk · $1\( · .*\)\?" "$T"/desk/*.args 2> /dev/null | sort -V | tail -1; }   # the newest desk of run $1 (.args; .in beside it)
GHP=https://github.com/test/proj

# the base user config posts through the stub curl; NOTIFY_CMD is set too, and must not be called (NTFY_URL wins)
printf '%s\n' 'LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1 NTFY_URL=https://ntfy.example/t NTFY_TOKEN=tok-secret-123' \
  "NOTIFY_CMD='printf \"%s\\n===\\n\" \"\$1\" >> \"$T/notify-cmd.log\"'" > "$T/base-config.sh"
cp "$T/base-config.sh" "$T/user-config.sh"
git init -q --bare -b main "$T/origin.git"
git init -q -b main "$T/proj" && cd "$T/proj"
mkdir .harness && cat > .harness/config.sh <<'EOF'
CHECK_CMD="test ! -f BROKEN"
INIT_CMD="echo init ok"
BASE_PORT=7950
EOF
printf '# proj\nrules\n' > CLAUDE.md; echo spec > SPEC.md
git add -A && git commit -qm init && git config url."$T/origin.git".insteadOf git@github.com:test/proj.git && git remote add origin git@github.com:test/proj.git && git push -q -u origin main

# ---- the scheduler, pure: "after" may name a milestone (all of its features) ----
DEPS='import { deps } from "'$HERE'/../lib/features.mjs"; const l = [{ id: "A", milestone: "M1" }, { id: "B", milestone: "M1" },
  { id: "C", milestone: "M2", after: ["M1"] }, { id: "D", milestone: "M3", after: ["C", "M9"] }];
  process.exit(deps(l, l[2]).join() === "A,B" && deps(l, l[3]).join() === "C,M9" ? 0 : 1);'
check "after may name a milestone"        'node --input-type=module -e "$DEPS"'

# ---- notifications, pure: the body cap and ntfy's actions header ----
TRIM='import { trimBody } from "'$HERE'/../lib/notify.mjs"; const t = trimBody("x".repeat(4000)), e = trimBody("é".repeat(2000)), s = "y".repeat(100);
  process.exit(Buffer.byteLength(t) <= 3500 && t.endsWith("…") && Buffer.byteLength(e) <= 3500 && e.endsWith("é…") && trimBody(s) === s ? 0 : 1);'
check "notify.mjs: trimBody caps at 3500 bytes with …" 'node --input-type=module -e "$TRIM"'
ACT='import { actionsHeader as a } from "'$HERE'/../lib/notify.mjs";
  const two = a([{ label: "Edit INBOX", url: "https://e/1" }, { label: "Skip", url: "" }, { label: "Progress", url: "https://e/2" }]);
  process.exit(two === "view, Edit INBOX, https://e/1; view, Progress, https://e/2" && a([1, 2, 3, 4].map(i => ({ label: "L" + i, url: "u" + i }))).split("; ").length === 3
    && a([]) === "" && a([{ label: "x", url: "" }]) === "" ? 0 : 1);'
check "notify.mjs: actionsHeader joins view actions, skips empty urls, at most 3" 'node --input-type=module -e "$ACT"'
URLS='import { githubUrls as g } from "'$HERE'/../lib/notify.mjs"; const a = g("git@github.com:o/r.git", "harness/x", ".harness/runs/x/INBOX.md");
  const same = ["git@github.com:o/r", "https://github.com/o/r.git", "https://github.com/o/r", "https://github.com/o/r/", "ssh://git@github.com/o/r.git"].every(u => g(u, "b", "p")?.blob === "https://github.com/o/r/blob/b/p");
  process.exit(a?.blob === "https://github.com/o/r/blob/harness/x/.harness/runs/x/INBOX.md" && a.edit === "https://github.com/o/r/edit/harness/x/.harness/runs/x/INBOX.md"
    && same && g("git@github.com:o/r.git", "", "p") === null && g("/tmp/origin.git", "b", "p") === null && g("git@gitlab.com:o/r.git", "b", "p") === null && g("", "b", "p") === null ? 0 : 1);'
check "notify.mjs: githubUrls for ssh, https and non-GitHub origins" 'node --input-type=module -e "$URLS"'
QUES='import { inboxQuestion as q } from "'$HERE'/../lib/notify.mjs"; const b = "status: run\n\n## Answers\nold\n", a = "status: run\n### B: set the gatus vars, then answer\n\n## Answers\nold\nmine\n";
  process.exit(q(b, a) === "### B: set the gatus vars, then answer" && q(b, b) === "" && q("", a) === "status: run\n### B: set the gatus vars, then answer"
    && q("status: run\n", a) === "### B: set the gatus vars, then answer" && q(b, "status: run\n### B: q\nold\n") === "### B: q" ? 0 : 1);'
check "notify.mjs: inboxQuestion is the lines added above ## Answers (never Michael's old answers)" 'node --input-type=module -e "$QUES"'

# ---- harness parked, pure: the report and the INBOX question it quotes ----
PREP='import { parkedReport as r } from "'$HERE'/../lib/parked.mjs"; const e = { run: "r", project: "p", feature: "B", since: "2026-10-19T01:00:00Z", why: "w", question: "q", running: false, runner: false };
  const a = r([e]), b = r([{ ...e, runner: true }]), c = r([{ ...e, running: true }]), j = JSON.parse(r([e, { ...e, run: "s", since: "2026-10-18T01:00:00Z" }], { json: true }));
  process.exit(a.includes("harness answer r \"…\"") && a.includes("harness continue r") && b.includes("harness queue add --continue r") && !b.includes("harness continue r")
    && c.includes("running:  yes") && c.includes("harness answer r \"…\"") && !c.includes("continue r") && r([], {}) === "nothing parked\n" && r([], { run: "x" }) === "nothing parked in x\n"
    && JSON.parse(r([], { json: true })).length === 0 && j.map(x => x.run).join() === "s,r" && Object.keys(j[0]).join() === "run,project,feature,since,why,question,running,ending,queued,commands" ? 0 : 1);'
check "parked.mjs: the report names the answer and continue commands" 'node --input-type=module -e "$PREP"'
QFOR='import { questionFor as q, parkedReport as r } from "'$HERE'/../lib/parked.mjs";
  const i = "status: run\n<!-- Steer this run\n     from the app -->\n\n### A: db url\nwhich db?\n### B: set the gatus vars, then answer\n\n## Answers\n### B: an old answer\n";
  const t = r([{ run: "parky", project: "proj", feature: "B", since: "2026-10-19T01:00:00Z", why: "set the gatus vars", question: q(i, "A"), running: false, runner: false }], { now: Date.parse("2026-10-19T03:00:00Z") });
  process.exit(q(i, "B") === "### B: set the gatus vars, then answer" && q(i, "C") === "### A: db url\nwhich db?\n### B: set the gatus vars, then answer"
    && q("status: run\n\n## Answers\n", "B") === "" && q("### Bx: q\n## Answers\n", "B") === "### Bx: q" && q("", "B") === "" && q("### A: needs B first\n### B: the vars\n", "B") === "### B: the vars"
    && t === "parky · proj · B\n  since:    2026-10-19 01:00 (2 h ago)\n  why:      set the gatus vars\n  question: ### A: db url\n            which db?\n  running:  no\n  next:     harness answer parky \"…\"\n            harness continue parky\n" ? 0 : 1);'
check "parked.mjs: the question is the feature's INBOX section" 'TZ=UTC node --input-type=module -e "$QFOR"'
QNEW='import { questionFor as q, commandsFor as c } from "'$HERE'/../lib/parked.mjs";
  process.exit(q("status: run\n\n### B: set the gatus vars\nold, answered\n\n### B: now the token too\nnew one\n\n## Answers\n", "B") === "### B: now the token too\nnew one"
    && q("### 1.2: y\n### 1.2.3: x\n## Answers\n", "1.2") === "### 1.2: y" && q("### B: q\nthe text\n## Notes\nnot it\n## Answers\n", "B") === "### B: q\nthe text"
    && q("status: run\n### B: q\n### 2026-10-19 10:00 (local)\nmy answer\n", "C") === "### B: q"
    && q("status: run\n### B: q1\n### 2026-10-19 10:00 (local)\nans\n### B: q2 new\n", "B") === "### B: q2 new"
    && q("### B: set vars\n```bash\n# put these in .env\nFOO=1\n```\nthen answer\n## Answers\n", "B") === "### B: set vars\n```bash\n# put these in .env\nFOO=1\n```\nthen answer"
    && JSON.stringify(c("r", { queued: true })) === JSON.stringify(["harness answer r \"…\""]) ? 0 : 1);'
check "parked.mjs: the newest question wins, ids with dots, code fences, never Michael's answers" 'node --input-type=module -e "$QNEW"'
( NTFY_URL=https://ntfy.example/t NTFY_TOKEN="" NOTIFY_CMD=""; log() { :; }; source "$HERE/../lib/notify.sh"; notify "long one" title="long one" body="$(head -c 4000 /dev/zero | tr '\0' x)" )
check "a body over the cap is trimmed"    'Bd=$(curl_body "Title: long one"); (( $(printf %s "$Bd" | wc -c) <= 3500 && $(printf %s "$Bd" | wc -c) > 3000 )) && [[ $Bd == *… ]]'

# ---- run 1: misbehaving sessions, two milestones; verified milestones merge themselves ----
"$H" start "$T/proj" demo --spec SPEC.md --brief "only A–C" --foreground > "$T/run1.out" 2>&1
WT=$T/wt/proj/demo RD=$T/wt/proj/demo/.harness/runs/demo
check "all features pass"                 '[[ $($F summary "$(list demo)") == "3/3 passing" ]]'
check "tampered list restored"            'hlog demo | grep -q "restored the feature list after B"'
check "tampered text reverted"            '[[ $(jq -r ".features[2].description" "$(list demo)") == c ]]'
check "red suite un-passes C"             'hlog demo | grep -q "C un-passed: suite red"'
check "C retried and passed"              'grep -q "C attempt 2" "$T/scratch/proj/demo/sessions.log"'
check "verifier caught A, re-queued"      'hlog demo | grep -q "verify M1: A failed the re-check" && grep -q "A attempt 2" "$T/scratch/proj/demo/sessions.log"'
check "M1 and M2 tagged"                  'git -C "$T/origin.git" tag | grep -qx run/demo/M1 && git -C "$T/origin.git" tag | grep -qx run/demo/M2'
check "M1 and M2 merged into main by PRs" '[[ $(grep -c "pr merge" "$T/gh.log") == 2 ]] && on_main run/demo/M2 && hlog demo | grep -q "M2 merged into main"'
check "no final tag, no false 'verified'" '! git -C "$T/origin.git" tag | grep -q final && ! hlog demo | grep -q "final verified"'
check "brief committed with the run"      'grep -q "only A–C" "$RD/brief.md"'
check "brief, rules and policy in the prompt" 'P=$HARNESS_STATE/proj/demo/prompt-coding.md; grep -q "only A–C" "$P" && grep -q "Project rules (CLAUDE.md)" "$P" && grep -q "Policy: build-only" "$P"'
check "metrics: wall time and roles"      'jq -e "select(.kind==\"coding\") | .wall_s != null and .role == \"build\"" "$RD/metrics.jsonl" > /dev/null'
check "ended: done; status says so"       'grep -q "^done" "$HARNESS_STATE/proj/demo/ended" && grep -q "ended: done" <<< "$("$H" status demo)"'
check "summary, report and retro written" '[[ $(jq .features.merged "$RD/summary.json") == 3 ]] && grep -q "per passing feature" "$RD/report.md" && grep -q "Stub retro" "$RD/retro.md"'
check "ledger has the run"                'grep -q "\"run\":\"demo\"" "$T/ledger/runs.jsonl" && [[ -f $T/ledger/proj/demo/summary.json ]]'
check "harness report prints the writeup" 'grep -q "Spend by role" <<< "$("$H" report demo)"'
check "init model resolved to fable"      'grep -q "initializer · claude-fable-5-1" "$HARNESS_STATE/proj/demo/run.log"'
check "summary end reason is how the run ended" '[[ $(jq -r .end_reason "$RD/summary.json") == done ]]'
check "a milestone without an after list is noted" 'hlog demo | grep -q "dependencies: M2 has no after list"'
check "NTFY_URL: curl posts the fields as headers, NOTIFY_CMD not called" 'B=$(curl_with "[demo] started:"); [[ $(tail -1 <<< "$B") == https://ntfy.example/t ]] && grep -A1 -x -- -H <<< "$B" | grep -qx "Title: harness" && grep -A1 -x -- --data-binary <<< "$B" | grep -qx "\[demo\] started: 0/3 passing" && [[ ! -e $T/notify-cmd.log ]]'
check "NTFY_TOKEN: bearer header sent, never logged" 'grep -qx "Authorization: Bearer tok-secret-123" "$T/curl.log" && [[ -d $HARNESS_STATE/proj/demo && -d $RD ]] && ! grep -rq tok-secret-123 "$HARNESS_STATE/proj/demo" "$RD"'
check "a successful post: a line in run.log only" 'grep -q "notified: harness" "$HARNESS_STATE/proj/demo/run.log" && ! hlog demo | grep -q "notified\|notification failed"'
check "routine notifications keep the default priority" 'Bs=$(curl_with "[demo] started:") Bm=$(curl_with "[demo] M1 merged") && [[ -n $Bs && -n $Bm ]] && ! grep -q "^Priority:" <<< "$Bs$Bm" \
  && grep -qx "Click: $GHP/blob/harness/demo/.harness/runs/demo/progress.md" <<< "$Bs" && U=$(grep -o "https://example.test/pr/[0-9]*" <<< "$Bm" | head -1) && [[ -n $U ]] && grep -qx "Click: $U" <<< "$Bm"'

# ---- gc: main has every milestone; only run-record commits are left on the branch ----
"$H" gc "$T/proj" > "$T/gc.out" 2>&1
check "gc removed the finished worktree"  '[[ ! -d $WT ]]'
check "gc deleted the run branch"         '! git -C "$T/origin.git" rev-parse -q --verify harness/demo >/dev/null'
check "gc kept the tags"                  'git -C "$T/origin.git" tag | grep -qx run/demo/M2'

# ---- run 2: Michael sets "status: stop" in INBOX.md from the phone (and only NOTIFY_CMD is configured) ----
printf '%s\n' 'LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' "NOTIFY_CMD='{ printf \"%s\\n\" \"\$1\"; env | grep ^HARNESS_NOTIFY_; echo ===; } >> \"$T/notify-env.log\"'" > "$T/user-config.sh"
STUB_PHONE_STOP=1 "$H" start "$T/proj" stoppy --spec SPEC.md --foreground > "$T/run2.out" 2>&1
cp "$T/base-config.sh" "$T/user-config.sh"
check "NOTIFY_CMD-only: \$1 unchanged, fields as env" 'grep -q "^\[stoppy\] started: 0/3 passing$" "$T/notify-env.log" && grep -qx "HARNESS_NOTIFY_TITLE=harness" "$T/notify-env.log" && grep -qx "HARNESS_NOTIFY_PRIORITY=" "$T/notify-env.log" && [[ -s $T/curl.log ]] && ! grep -q "\[stoppy\]" "$T/curl.log"'
check "phone stop honoured before any coding session" 'hlog stoppy | grep -q "stopped by Michael" && ! grep -q attempt "$T/scratch/proj/stoppy/sessions.log"'
check "second run got its own port"       '[[ $(cat "$HARNESS_STATE/proj/stoppy/port") != $(cat "$HARNESS_STATE/proj/demo/port") ]]'

# ---- run 3: a verifier that always rejects; C is independent of M1 ----
SPY3='printf "%s · %s\n" "$(printf "%s\n" "$@" | sed -n "s/^Title: //p")" "$(git -C "$STUB_DIR/origin.git" log -1 --format=%s harness/strict)" >> "$STUB_DIR/spy-strict.log"'
STUB_CURL_SPY=$SPY3 STUB_STRICT_VERIFIER=1 STUB_INDEPENDENT_M2=1 "$H" start "$T/proj" strict --spec SPEC.md --foreground > "$T/run3.out" 2>&1
check "verify ping-pong capped, needs Michael" 'hlog strict | grep -q "M1 needs Michael" && (( $(grep -c "^A attempt" "$T/scratch/proj/strict/sessions.log") <= 2 ))'
check "verify needs Michael: priority high, click = progress.md (GitHub-shaped origin)" 'Bv=$(curl_with "[strict] M1 needs Michael: A fails verification"); grep -qx "Title: \[strict\] M1 needs you" <<< "$Bv" \
  && grep -qx "Priority: high" <<< "$Bv" && grep -qx "Click: $GHP/blob/harness/strict/.harness/runs/strict/progress.md" <<< "$Bv"'
check "verify needs Michael goes out after the verify entry is pushed" 'grep -qxF "[strict] M1 needs you · HARNESS: verify M1" "$T/spy-strict.log"'
check "independent M2 verified, not merged (M1 isn't)" 'git -C "$T/origin.git" tag | grep -qx run/strict/M2 && ! on_main run/strict/M2'
check "no dependency note when every milestone has after" '! hlog strict | grep -q "dependencies:"'

# ---- run 4: the same, but C depends on M1 (default): gated ----
STUB_CURL_FAIL=1 STUB_STRICT_VERIFIER=1 "$H" start "$T/proj" gated --spec SPEC.md --foreground > "$T/run4.out" 2>&1
check "a failed post is noted and the run goes on" 'hlog gated | grep -q "notification failed (curl exit 22): harness"'
check "a failed run-end post is committed: the worktree stays clean for gc" '[[ -d $T/wt/proj/gated && -z $(git -C "$T/wt/proj/gated" status --porcelain) ]]'
check "a given-up feature blocks what depends on it" 'grep -q "^blocked on A" "$HARNESS_STATE/proj/gated/ended" && ! grep -q "^C attempt" "$T/scratch/proj/gated/sessions.log"'

# ---- run 5: the real usage-limit message (2026-10-17) for 3 sessions, then a $0 no-work session ----
STUB_LIMIT_HITS=3 STUB_NOWORK=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 "$H" start "$T/proj" limited --spec SPEC.md --foreground > "$T/run5.out" 2>&1
check "real limit message: not counted, run completes" '[[ $(hlog limited | grep -c "hit a limit (You.ve hit your session limit") == 3 ]] && [[ $($F summary "$(list limited)") == "3/3 passing" ]]'
check "a \$0 one-turn session is not counted" 'hlog limited | grep -q "hit a limit (no work done"'
check "the limit window is shared"        '[[ -f $HARNESS_STATE/LIMIT_UNTIL ]]'
check "refused sessions recorded as env"  '(( $(jq -s "map(select(.env)) | length" "$T/wt/proj/limited/.harness/runs/limited/metrics.jsonl") == 4 ))'

# ---- run 6: a limit cuts a session off midway: work kept, attempt given back ----
STUB_LIMIT_MIDWAY=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" midway --spec SPEC.md --foreground > "$T/run6.out" 2>&1
check "mid-session limit: attempt given back, work kept" 'hlog midway | grep -q "hit a limit" && [[ $(jq -r .A "$HARNESS_STATE/proj/midway/attempts.json") == 1 ]] && [[ -f $T/wt/proj/midway/half-A.txt ]]'

# ---- run 7: a future window set by another run makes this one wait first ----
echo $(( $(date +%s) + 3600 )) > "$HARNESS_STATE/LIMIT_UNTIL"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" waiter --spec SPEC.md --foreground > "$T/run7.out" 2>&1
check "waits for another run's limit window" 'hlog waiter | grep -q "usage-limit window (shared by all runs): waiting"'
rm -f "$HARNESS_STATE/LIMIT_UNTIL"

# ---- run 8: thin verify evidence → one more verify on the stronger model ----
STUB_THIN_VERIFY=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" thin --spec SPEC.md --foreground > "$T/run8.out" 2>&1
check "thin evidence escalates the verify" 'hlog thin | grep -q "evidence short of the steps" && grep -q "verify M1 · claude-opus-5-5" "$HARNESS_STATE/proj/thin/run.log"'

# ---- run 9: endless limit pauses; then `harness continue` finishes it ----
STUB_LIMIT_HITS=99 timeout 60 "$H" start "$T/proj" walled --spec SPEC.md --foreground > "$T/run9.out" 2>&1
check "endless limit ends the run (frees the queue)" 'hlog walled | grep -q "sessions in a row refused" && grep -q "^usage limit (6 sessions refused" "$HARNESS_STATE/proj/walled/ended"'
rm -f "$HARNESS_STATE/LIMIT_UNTIL"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue walled --foreground > "$T/run9b.out" 2>&1
check "continue finishes a paused run"    '[[ $($F summary "$(list walled)") == "3/3 passing" ]] && on_main run/walled/M2'
check "one ledger row per run"            '[[ $(grep -c "\"run\":\"walled\"" "$T/ledger/runs.jsonl") == 1 ]]'

# ---- run 9c: refused sessions in an earlier segment aren't the cause of a later ending ----
STUB_LIMIT_HITS=6 "$H" start "$T/proj" stale --spec SPEC.md --foreground > "$T/run9c.out" 2>&1; rm -f "$HARNESS_STATE/LIMIT_UNTIL"
S9=$T/wt/proj/stale/.harness/runs/stale/summary.json
check "a limit ending: the cause is the usage limit" '[[ $(jq -r ".features_detail[0].cause" "$S9") == "usage limit" ]]'
"$H" continue stale --until-epoch $(( $(date +%s) - 60 )) --foreground > "$T/run9d.out" 2>&1
check "a later deadline: the earlier refusals aren't the cause" '[[ $(jq -r .end_reason "$S9") == deadline && $(jq -r ".features_detail[0].cause" "$S9") == "not reached" ]]'

# ---- run 10: merges refused (MERGE_POLICY=auto but GitHub says no) → `harness merge` later ----
STUB_REFUSE_MERGE=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" later --spec SPEC.md --foreground > "$T/run10.out" 2>&1
check "refused merge leaves the PR, needs Michael" 'hlog later | grep -q "merge was refused" && ! on_main run/later/M1'
check "a refused merge: priority high, click = the PR" 'Br=$(curl_with "[later] M1 needs Michael: merge refused"); U=$(grep -o "https://example.test/pr/[0-9]*" <<< "$Br" | head -1) \
  && [[ -n $U ]] && grep -qx "Title: \[later\] M1 needs you" <<< "$Br" && grep -qx "Priority: high" <<< "$Br" && grep -qx "Click: $U" <<< "$Br"'
"$H" merge later > "$T/run10b.out" 2>&1
check "harness merge merges verified milestones afterwards" 'on_main run/later/M2 && grep -q "^done" "$HARNESS_STATE/proj/later/ended"'

# ---- queue: start queues behind a running run; the runner runs entries in order ----
mkdir -p "$HARNESS_STATE/proj/busy" && echo $$ > "$HARNESS_STATE/proj/busy/driver.pid" && printf 'WT=/x\nRUN_ID=busy\nSTATE=%s\nPROJECT_DIR=/x\n' "$HARNESS_STATE/proj/busy" > "$HARNESS_STATE/proj/busy/meta.env"
check "start queues when MAX_PARALLEL_RUNS are going" 'grep -q "is queued" <<< "$("$H" start "$T/proj" --spec SPEC.md)"'
check "continue refuses a running run"     '! "$H" continue busy 2> "$T/busy.err" && grep -q "is running" "$T/busy.err"'
rm -rf "$HARNESS_STATE/proj/busy"
"$H" queue add "$T/proj" --spec SPEC.md > /dev/null
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$T/queue.out" 2>&1
D=$(date +%F)
check "queue ran both entries, distinct run ids" '[[ $($F summary "$(list proj-$D)") == "3/3 passing" && $($F summary "$(list proj-$D-2)") == "3/3 passing" ]] && grep -q "queue empty" "$HARNESS_STATE/queue/runner.log"'
check "trends lists every run"            'grep -q "| proj-$D-2 | proj |" <<< "$("$H" trends)"'
DB=$T/debriefs.log Q=$HARNESS_STATE/queue NOTE=$T/ledger/debrief.md
ndb() { cat "$DB" 2>/dev/null | grep -c .; }
settle() {   # the runner's debrief is detached: wait until no debrief process is left
  local i; sleep 0.5
  for i in $(seq 150); do pgrep -f "$HH/lib/debrief\.sh|$HH/bin/harness debrief" > /dev/null || return 0; sleep 0.2; done; return 1
}
HH=$(cd "$HERE/.." && pwd); settle
check "queue end triggers one debrief, detached" '[[ $(ndb) == 1 && -s $NOTE && -s $Q/last-debrief ]] && grep -q "debrief written" "$Q/runner.log" && grep -q "harness debrief (detached" "$Q/runner.log"'
check "the debrief saw the queue's runs"  'grep -q "### proj-$D-2 (proj)" "$T/debrief-prompt" && grep -q "### proj-$D (proj)" "$T/debrief-prompt"'
PAGE=$T/ledger/debrief.html
check "a debrief page beside the note: a card per run, the note escaped" '[[ -s $PAGE ]] && grep -q "proj-$D-2" "$PAGE" && grep -q "3/3 passing" "$PAGE" && grep -q "Landed: proj M1, M2 on main" "$PAGE" && grep -q "&lt;i&gt;raw" "$PAGE" && ! grep -q "<i>raw" "$PAGE"'
"$H" debrief > "$T/again.out" 2>&1
check "by hand right after: nothing new, no session" '[[ $(ndb) == 1 ]] && grep -q "no runs started since the last debrief" "$T/again.out"'
"$H" queue add --continue stoppy > /dev/null   # Michael stopped stoppy: the runner skips it, so it starts nothing
HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$T/queue2.out" 2>&1; settle
check "a runner that started nothing (a skipped continuation): no debrief" '[[ $(ndb) == 1 ]] && grep -q "skipping queued continuation of stoppy" "$Q/runner.log" && ! grep -q "harness debrief (detached" "$T/queue2.out"'

# ---- run 11: a verify refused by the usage limit is deferred, never a "holds" ----
STUB_VERIFY_LIMIT=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" vlimit --spec SPEC.md --foreground > "$T/run11.out" 2>&1
check "refused verify: deferred, then verified, then merged" 'hlog vlimit | grep -q "verify M1 refused" && [[ $(hlog vlimit | grep -n "verify M1 refused" | cut -d: -f1) -lt $(hlog vlimit | grep -n "M1 verified and tagged" | cut -d: -f1) ]] && on_main run/vlimit/M1'

# ---- run 12: a session claims its feature, then the limit cuts it off: the claim is reverted ----
{ cat "$T/base-config.sh"; echo 'MERGE_POLICY=pr'; } > "$T/user-config.sh"   # its milestones are proposed, not merged
STUB_PASS_THEN_LIMIT=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" claim --spec SPEC.md --foreground > "$T/run12.out" 2>&1
cp "$T/base-config.sh" "$T/user-config.sh"
check "a limit-cut session's passes is reverted, A retried" 'grep -q "A attempt 2" "$T/scratch/proj/claim/sessions.log" && grep -qx "HARNESS: usage limit" <<< "$(git -C "$T/wt/proj/claim" log --format=%s -- .harness/runs/claim/feature_list.json)"'
check "a proposed merge: ready to merge, click = the PR, default priority" 'Bp=$(curl_with "[claim] M1 verified · review:"); U=$(grep -o "https://example.test/pr/[0-9]*" <<< "$Bp" | head -1) \
  && [[ -n $U ]] && grep -qx "Title: \[claim\] M1 ready to merge" <<< "$Bp" && grep -qx "Click: $U" <<< "$Bp" && ! grep -q "^Priority:" <<< "$Bp"'

# ---- run 13: verify and retro may not change code ----
STUB_VERIFY_EDITS=1 STUB_RETRO_EDITS=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" meddle --spec SPEC.md --foreground > "$T/run13.out" 2>&1
check "verifier code edits reverted, never merged" 'hlog meddle | grep -q "reverted code edits the verifier may not make" && ! git -C "$T/origin.git" show main:hack-M1.txt > /dev/null 2>&1 && ! git -C "$T/origin.git" show main:CLAUDE.md | grep -q edited'
check "retro edits reverted"              'hlog meddle | grep -q "retro: reverted" && [[ ! -f $T/wt/proj/meddle/retro-hack.txt ]]'

# ---- run 14: v2-style tags don't merge on a resume; `harness merge` merges them ----
echo 'LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1 MERGE_POLICY=off' > "$T/user-config.sh"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" legacy --spec SPEC.md --foreground > "$T/run14.out" 2>&1
echo 'LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"
for m in M1 M2; do git -C "$T/wt/proj/legacy" tag -f -a "run/legacy/$m" "run/legacy/$m^{commit}" -m "harness run legacy: $m verified" > /dev/null
  git -C "$T/wt/proj/legacy" push -q -f origin "run/legacy/$m"; done
mkdir -p "$T/prs" && touch "$T/prs/branch-harness_legacy"   # its v2 whole-run PR
"$H" continue legacy --foreground > "$T/run14b.out" 2>&1
check "v2 tags don't merge on resume"     'hlog legacy | grep -q "verified by harness v2" && ! on_main run/legacy/M1 && [[ -f $T/prs/branch-harness_legacy ]]'
"$H" merge legacy > "$T/run14c.out" 2>&1
check "harness merge merges v2 tags, closes the v2 PR" 'on_main run/legacy/M2 && [[ ! -f $T/prs/branch-harness_legacy ]]'

# ---- run 15: a resumed run reloads its configuration after merging main (here: a new POLICY) ----
STUB_PHONE_STOP=1 "$H" start "$T/proj" flip --spec SPEC.md --foreground > "$T/run15.out" 2>&1
(cd "$T/proj" && git pull -q origin main && echo "POLICY=live-staged" >> .harness/config.sh && git commit -qam "policy: live-staged" && git push -q origin main)
"$H" continue flip --foreground > "$T/run15b.out" 2>&1
check "resume reloads config merged from main" 'hlog flip | grep -q "configuration reloaded after merging main: policy live-staged"'

# ---- debrief: the runner's other exits ----
rm -f "$HARNESS_STATE/LIMIT_UNTIL"
"$H" queue add "$T/proj" --spec SPEC.md > /dev/null; "$H" queue add "$T/proj" --spec SPEC.md > /dev/null
B=$(ndb); STUB_QUEUE_STOP=1 STUB_PHONE_STOP=1 HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$T/queue3.out" 2>&1; settle
check "queue stop after a run: one debrief" '[[ $(ndb) == $((B + 1)) ]] && grep -q "stopped by harness queue stop" "$T/queue3.out" && [[ $(ls "$Q"/*.args | wc -l) == 1 ]]'
"$H" queue add "$T/proj" --spec SPEC.md > /dev/null
B=$(ndb); STUB_SLOW_INIT=3 STUB_PHONE_STOP=1 HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" $(( $(date +%s) + 2 )) > "$T/queue4.out" 2>&1; settle
check "past --until after a run: one debrief" '[[ $(ndb) == $((B + 1)) ]] && grep -q "past the --until time" "$T/queue4.out"'
rm -f "$Q"/*.args

# ---- debrief: since the last success; failed and killed debriefs; continuations; notification ----
printf '%s\n' 'LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' "NOTIFY_CMD='printf \"%s\\n===\\n\" \"\$1\" >> \"$T/notify.log\"'" \
  "DEBRIEF_PAGE_CMD='cp \"\$1\" \"$T/page-copy.html\"'" > "$T/user-config.sh"
ran() { local r; sleep 1; for r; do echo "$(date '+%F %T') run $r on harness/$r in $T/wt/proj/$r · port 7999" >> "$HARNESS_STATE/proj/$r/run.log"; done; }   # runs since
ran stoppy demo walled limited gated
for r in stoppy limited gated; do echo "deadline · $(date '+%F %T')" > "$HARNESS_STATE/proj/$r/ended"; done
echo "usage limit (6 sessions refused in a row) · $(date '+%F %T')" > "$HARNESS_STATE/proj/walled/ended"
LD=$(cat "$Q/last-debrief") B=$(ndb)
STUB_DEBRIEF_LIMIT=1 "$H" debrief > "$T/refused.out" 2>&1
check "a refused debrief: no note, nothing marked done, LIMIT_UNTIL set, one line to NOTIFY_CMD" '[[ $(cat "$Q/last-debrief") == "$LD" && -f $HARNESS_STATE/LIMIT_UNTIL ]] && ! grep -q "stoppy" "$NOTE" && grep -q "refused" "$T/refused.out" && grep -q "^\[debrief\] refused" "$T/notify.log"'
rm -f "$HARNESS_STATE/LIMIT_UNTIL"
STUB_DEBRIEF_DEAD=1 "$H" debrief > "$T/dead.out" 2>&1
check "a session that dies at startup: failed, and no usage-limit window for the box" '[[ ! -f $HARNESS_STATE/LIMIT_UNTIL && $(cat "$Q/last-debrief") == "$LD" ]] && grep -q "the session failed" "$T/dead.out" && grep -q "^\[debrief\] failed" "$T/notify.log"'
STUB_DEBRIEF_ERROR=1 "$H" debrief > "$T/error.out" 2>&1
check "a failed session: its error text is never the note" '[[ $(cat "$Q/last-debrief") == "$LD" ]] && ! grep -q "max turns" "$NOTE" && ! grep -qs "max turns" "$T/notify.log"'
echo $(( $(date +%s) + 3600 )) > "$HARNESS_STATE/LIMIT_UNTIL"
HARNESS_LIMIT_SLEEP=60 setsid "$H" debrief > "$T/killed.out" 2>&1 & P=$!
for i in $(seq 50); do grep -q "waiting" "$T/killed.out" && break; sleep 0.2; done; kill -- -"$P"; wait "$P" 2> /dev/null
rm -f "$HARNESS_STATE/LIMIT_UNTIL"
check "a killed debrief changes nothing" '[[ $(cat "$Q/last-debrief") == "$LD" && $(ndb) == $B ]] && grep -q "waiting" "$T/killed.out"'
touch "$Q/0099-continue-walled.args"; echo $$ > "$HARNESS_STATE/proj/gated/driver.pid"
"$H" debrief --dry-run > "$T/dry.out" 2>&1
check "--dry-run prints the context, launches nothing" '[[ $(ndb) == $B && -f $(head -1 "$T/dry.out") && $(cat "$Q/last-debrief") == "$LD" ]] && grep -q "^## harness status" "$T/dry.out" && grep -q "^### stoppy (proj)" "$T/dry.out" && grep -q "ended: deadline" "$T/dry.out"'
cp "$NOTE" "$T/note-before.md"; echo "{{LEDGER}} stays literal" >> "$T/wt/proj/stoppy/.harness/runs/stoppy/INBOX.md"
STUB_DEBRIEF_TOUCH=$T/wt/proj/gated/still-working.txt STUB_DEBRIEF_CONTINUE="stoppy demo walled limited gated" "$H" debrief > "$T/next.out" 2>&1
check "placeholders inside the context are not filled" 'grep -q "{{LEDGER}} stays literal" "$T/debrief-prompt"'
check "a still-running run changing its worktree is not flagged" '! grep -q "changed during the debrief session" "$NOTE"'
check "the allowlist runs nothing that writes or executes" 'A=$T/debrief-args; sed -n "/^--allowedTools$/,/^--disallowedTools$/p" "$A" > "$T/allow"; ! grep -qE "^Bash\((rg|git grep|git branch:|harness report|.*/bin/harness report)" "$T/allow" && grep -qxF "Bash(harness report:*)" "$A" && grep -qxF "Bash(git branch --list:*)" "$A" && grep -qxF "Bash(git diff --output:*)" "$A" && grep -qxF "Bash(git log --output:*)" "$A" && grep -qxF "Bash(git show --output:*)" "$A"'
check "the session may read each run's state dir and the queue" 'A=$T/debrief-args; grep -qxF "$HARNESS_STATE/proj/stoppy" "$A" && grep -qxF "$Q" "$A"'
check "the next debrief covers what the failed and killed ones missed" '[[ $(ndb) == $((B + 1)) && $(cat "$Q/last-debrief") != "$LD" ]] && ! for r in stoppy demo walled limited gated; do grep -q "^### $r (proj)" "$T/debrief-prompt" || echo missing; done | grep -q missing'
check "one note, overwritten: ledger/debrief.md" '! cmp -s "$NOTE" "$T/note-before.md" && [[ $(grep -c "^# Debrief" "$NOTE") == 1 && ! -e $T/ledger/debriefs ]] && grep -q "stub runs" "$NOTE"'
check "the session: an allowlist (dontAsk) and the never-list" 'A=$T/debrief-args; grep -qx dontAsk "$A" && ! grep -qx auto "$A" && grep -qx -- --allowedTools "$A" && grep -qx Read "$A" && grep -qxF "Bash(git log:*)" "$A" && grep -qx -- --disallowedTools "$A" && grep -qx Edit "$A" && grep -qx Write "$A" && grep -qxF "Bash(git push:*)" "$A" && grep -qxF "Bash(gh pr merge:*)" "$A" && grep -qxF "Bash(harness queue start:*)" "$A" && grep -qxF "Bash(harness merge:*)" "$A" && grep -qxF "Bash(harness continue:*)" "$A" && grep -qx "$($F model sonnet)" "$A"'
check "the prompt goes in on stdin, not as an argument" 'grep -q "^# Debrief" "$T/debrief-prompt" && ! grep -q "# Debrief" "$T/debrief-args"'
check "continuation queued: keeps attempts, brief marked as the debrief's" 'f=$(compgen -G "$Q/*-continue-stoppy.args") && grep -qx -- --keep-attempts "$f" && grep -q "do C next" "$f" && grep -qi "suggested by the debrief" "$f" && grep -q "Queued: .*stoppy" "$NOTE" && ! grep -q "debrief: queued" "$NOTE"'
check "not queued: ended done / already queued / no work left / still running" 'grep -q "Not queued: demo (it ended .done." "$NOTE" && grep -q "Not queued: walled (a continuation is already queued)" "$NOTE" && grep -q "Not queued: limited (no work left)" "$NOTE" && grep -q "Not queued: gated (still running)" "$NOTE" && ! compgen -G "$Q/*-continue-demo.args" > /dev/null && ! compgen -G "$Q/*-continue-limited.args" > /dev/null && ! compgen -G "$Q/*-continue-gated.args" > /dev/null && ! grep -q "CONTINUE:" "$NOTE"'
msg_with() { awk -v k="$1" 'BEGIN { RS = "===\n" } index($0, k) { printf "%s", $0; exit }' "$T/notify.log"; }
check "NOTIFY_CMD gets 3 headline lines and the note path" 'M=$(msg_with Landed); (( $(wc -l <<< "$M") <= 4 )) && grep -q "Landed: proj M1" <<< "$M" && grep -qF "$NOTE" <<< "$M" && ! grep -q FOURTH <<< "$M"'
check "DEBRIEF_PAGE_CMD gets the page"     'cmp -s "$PAGE" "$T/page-copy.html"'
check "a run still going is covered again next time" 'S=$(cut -f2 "$Q/last-debrief"); "$H" debrief --dry-run | grep -q "^### gated (proj)" && [[ $S < $(date "+%F %T") ]]'
rm -f "$HARNESS_STATE/proj/gated/driver.pid" "$Q"/*.args "$T/wt/proj/gated/still-working.txt"
echo 'NTFY_URL=https://ntfy.example/t' >> "$T/user-config.sh"   # from here on the debrief posts to ntfy (NOTIFY_CMD not called)
N=$(grep -c . "$T/notify.log"); STUB_DEBRIEF_DEAD=1 "$H" debrief > "$T/dead2.out" 2>&1
check "debrief notifications go to NTFY_URL when set" 'Bd=$(curl_with "[debrief] failed"); grep -qx "Title: harness debrief" <<< "$Bd" && ! grep -q "^Click:" <<< "$Bd" \
  && [[ $(grep -c . "$T/notify.log") == "$N" ]]'

# ---- debrief: a big record, a session that writes, the limit window, no node, git history as the archive ----
ran stoppy; head -c 300000 /dev/zero | tr '\0' x | fold -w 100 > "$T/wt/proj/stoppy/.harness/runs/stoppy/report.md"
B=$(ndb); STUB_DEBRIEF_CONTINUE=demo STUB_DEBRIEF_TOUCH=$T/wt/proj/stoppy/debrief-tamper.txt "$H" debrief > "$T/tamper.out" 2>&1
C=$(ls -td "$HARNESS_STATE"/debrief/*/ | head -1)context.md
check "a 300 KB report: the context stays small, the session runs" '(( $(wc -c < "$C") < 200000 )) && [[ $(ndb) == $((B + 1)) ]]'
check "files changed during the session are flagged in the note" 'grep -q "changed during the debrief session" "$NOTE" && grep -q "debrief-tamper.txt" "$NOTE"'
check "a debrief headline over ntfy: no Click (the note is a path), default priority when nothing needs Michael (a Not queued line isn't)" 'Bh=$(curl_last "[debrief] Landed: proj M1"); grep -qx "Title: harness debrief" <<< "$Bh" \
  && grep -qxF "$NOTE" <<< "$Bh" && ! grep -q "^Click:\|^Priority:" <<< "$Bh" && grep -q "^- Not queued: demo" "$NOTE"'
rm -f "$T/wt/proj/stoppy/debrief-tamper.txt"
ran stoppy; echo $(( $(date +%s) + 3600 )) > "$HARNESS_STATE/LIMIT_UNTIL"
B=$(ndb); t0=$(date +%s); STUB_DEBRIEF_NEEDS=1 HARNESS_LIMIT_SLEEP=3 "$H" debrief > "$T/limit1.out" 2>&1 & P=$!
for i in $(seq 50); do grep -q "waiting" "$T/limit1.out" && break; sleep 0.2; done; ran demo; wait "$P"; t1=$(date +%s)   # demo starts meanwhile
check "debrief waits for the usage-limit window, then runs" 'grep -q "usage-limit window" "$T/limit1.out" && (( t1 - t0 >= 3 )) && [[ $(ndb) == $((B + 1)) ]] && (( $(stat -c %Y "$T/debrief-prompt") >= t0 + 3 ))'
check "a run that starts during the wait is covered by the next debrief" '! grep -q "^### demo (proj)" "$T/debrief-prompt" && "$H" debrief --dry-run | grep -q "^### demo (proj)"'
check "a debrief whose note needs Michael: priority high" 'Bn=$(curl_with "Blocked: parky B waits on Michael"); grep -qx "Title: harness debrief" <<< "$Bn" && grep -qx "Priority: high" <<< "$Bn"'
ran stoppy; echo $(( $(date +%s) + 6 * 3600 )) > "$HARNESS_STATE/LIMIT_UNTIL"
B=$(ndb); "$H" debrief > "$T/limit2.out" 2>&1
check "a window past the 5 h cap: no session (the next debrief covers it)" 'grep -q "5 h cap" "$T/limit2.out" && [[ $(ndb) == $B ]]'
rm -f "$HARNESS_STATE/LIMIT_UNTIL"
NP=$(tr : '\n' <<< "$PATH" | while read -r d; do [[ -x $d/node ]] || printf '%s:' "$d"; done)
B=$(ndb); PATH=${NP%:} NVM_DIR=$T/no-nvm HOME=$T/nohome "$H" debrief > "$T/nonode.out" 2>&1; rc=$?
check "preflight: no node anywhere, a clear failure and no session" '(( rc != 0 )) && grep -q "missing: node" "$T/nonode.out" && [[ $(ndb) == $B ]]'
( flock "$HARNESS_STATE/debrief.lock" sleep 2 ) & HOLD=$!; sleep 0.3
"$H" debrief > "$T/locked.out" 2>&1; wait "$HOLD"
check "by hand while another debrief runs: it says it is waiting" 'grep -q "waiting for the debrief already running" "$T/locked.out"'
ran stoppy; HARNESS_DEBRIEF_CONTEXT_MAX=8000 "$H" debrief --dry-run > "$T/capped.out" 2>&1
check "the whole context is capped too" 'C=$(head -1 "$T/capped.out"); (( $(wc -c < "$C") <= 8000 )) && grep -q "context cut" "$C"'
git -C "$T/ledger" init -q -b main && git -C "$T/ledger" add -A && git -C "$T/ledger" -c user.name=t -c user.email=t@t commit -qm ledger
printf '%s\n' 'LEDGER_COMMIT=1 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"
for i in 1 2; do ran stoppy; GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t "$H" debrief > "$T/commit$i.out" 2>&1; done
check "each debrief is a commit of ledger/debrief.md" '[[ $(git -C "$T/ledger" log --oneline -- debrief.md | grep -c "ledger: debrief") == 2 && -z $(git -C "$T/ledger" status --porcelain) ]]'
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
staged() { git -C "$T/ledger" diff --cached --name-only; }
git -C "$T/ledger" checkout -qb side; ran stoppy; "$H" debrief > "$T/side.out" 2>&1; git -C "$T/ledger" checkout -q main
check "a ledger checkout on another branch: the note is written, not committed" 'grep -q "not committed" "$T/side.out" && [[ $(git -C "$T/ledger" log --oneline side -- debrief.md | grep -c "ledger: debrief") == 2 && -z $(staged) ]] && grep -q "^# Debrief" "$NOTE"'
touch "$T/ledger/.git/index.lock"; ran stoppy; "$H" debrief > "$T/ilock.out" 2>&1; rm -f "$T/ledger/.git/index.lock"
check "a held index.lock: written, not committed, nothing left staged" 'grep -q "not committed" "$T/ilock.out" && [[ -z $(staged) ]]'
printf '#!/bin/sh\nexit 1\n' > "$T/ledger/.git/hooks/pre-commit"; chmod +x "$T/ledger/.git/hooks/pre-commit"
ran stoppy; "$H" debrief > "$T/hook.out" 2>&1; rm -f "$T/ledger/.git/hooks/pre-commit"
check "a refused commit: the note is unstaged again" 'grep -q "not committed" "$T/hook.out" && [[ -z $(staged) ]]'
unset GIT_AUTHOR_NAME GIT_AUTHOR_EMAIL GIT_COMMITTER_NAME GIT_COMMITTER_EMAIL
echo 'LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"

# ---- run 16: a feature waiting on Michael parks (no attempt); independent work goes on; an answer unparks it ----
{ cat "$T/base-config.sh"; echo 'DESK_URL=https://claude.ai/code/env-test'; } > "$T/user-config.sh"
STUB_PARK=B STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" parky --spec SPEC.md --foreground > "$T/run16.out" 2>&1
S16=$T/wt/proj/parky/.harness/runs/parky/summary.json
check "parked: not an attempt, not retried" 'hlog parky | grep -q "B parked (waiting on Michael): set the gatus vars" && [[ $(jq -r ".B // 0" "$HARNESS_STATE/proj/parky/attempts.json") == 0 && $(grep -c "^B attempt" "$T/scratch/proj/parky/sessions.log") == 1 ]]'
check "independent work goes on past a parked feature" 'grep -q "^C attempt" "$T/scratch/proj/parky/sessions.log"'
check "ends waiting on Michael; the summary says so" 'grep -q "^waiting on Michael: B" "$HARNESS_STATE/proj/parky/ended" && [[ $(jq -r .end_reason "$S16") == "waiting on Michael: B" && $(jq -r ".features_detail[1].cause" "$S16") == "waiting on Michael" ]]'
# two short parks without DESK_URL (A parks; B and C wait on it): one with the GitHub origin, one with a local origin
# whose posts fail (both runs stay behind, ended waiting on Michael)
cp "$T/base-config.sh" "$T/user-config.sh"
SPY='printf "%s · %s\n" "$(printf "%s\n" "$@" | sed -n "s/^Title: //p")" "$(git -C "$STUB_DIR/origin.git" log -1 --format=%s harness/parkn)" >> "$STUB_DIR/spy.log"'
STUB_CURL_SPY=$SPY STUB_PARK=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" parkn --spec SPEC.md --foreground > "$T/run16n.out" 2>&1
git -C "$T/proj" config remote.origin.url "$T/origin.git"
STUB_CURL_FAIL=1 STUB_PARK=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" parkl --spec SPEC.md --foreground > "$T/run16l.out" 2>&1
git -C "$T/proj" config remote.origin.url git@github.com:test/proj.git
{ cat "$T/base-config.sh"; echo 'DESK_URL=https://claude.ai/code/env-test'; } > "$T/user-config.sh"
B16=$(curl_with "Title: [parky] B needs you"); BB16=$(curl_body "Title: [parky] B needs you")
check "a park notification: title, question, answer command, click and Edit INBOX action" 'grep -qx "Priority: high" <<< "$B16" && grep -qx "Tags: question" <<< "$B16" \
  && grep -qx "Click: $GHP/blob/harness/parky/.harness/runs/parky/INBOX.md" <<< "$B16" && grep "^Actions: " <<< "$B16" | grep -qF "view, Edit INBOX, $GHP/edit/harness/parky/.harness/runs/parky/INBOX.md" \
  && grep "^Actions: " <<< "$B16" | grep -qF "view, Progress, $GHP/blob/harness/parky/.harness/runs/parky/progress.md" \
  && grep -qx "PARKED: set the gatus vars" <<< "$BB16" && grep -qx "### B: set the gatus vars, then answer" <<< "$BB16" && grep -q "^Answer: harness answer parky \"" <<< "$BB16" \
  && grep -q "notified: \[parky\] B needs you" "$HARNESS_STATE/proj/parky/run.log"'
check "Answer with Claude only when DESK_URL is set" 'grep "^Actions: " <<< "$B16" | grep -qF "view, Answer with Claude, https://claude.ai/code/env-test" \
  && grep -q "^Actions: .*Edit INBOX" <<< "$(curl_with "Title: [parkn] A needs you")" && ! grep -q "Answer with Claude" <<< "$(curl_with "Title: [parkn] A needs you")"'
check "the park goes out after the run branch is pushed (the link shows the question)" 'grep -qx "\[parkn\] A needs you · HARNESS: after A (passes=false)" "$T/spy.log"'
check "the run end goes out before the retro, once report.md is pushed" 'grep -qxF "[parkn] ended: waiting on Michael: A · HARNESS: run ended (waiting on Michael: A)" "$T/spy.log" \
  && git -C "$T/origin.git" cat-file -e "$(git -C "$T/origin.git" log -1 --format=%H --grep="^HARNESS: run ended" harness/parkn):.harness/runs/parkn/report.md" \
  && awk "/notified: \[parky\] ended:/ { n = NR } /retro · / && !r { r = NR } END { exit !(n && r && n < r) }" "$HARNESS_STATE/proj/parky/run.log"'
check "a failed park post is noted and committed at once" 'hlog parkl | grep -q "notification failed (curl exit 22): \[parkl\] A needs you" && git -C "$T/origin.git" log --format=%s harness/parkl | grep -x "HARNESS: park notification failed" > /dev/null'
check "no URLs for a non-GitHub origin" 'Bl=$(curl_with "Title: [parkl] A needs you"); grep -qx "Priority: high" <<< "$Bl" && grep -q "^Answer: harness answer parkl \"" <<< "$(curl_body "Title: [parkl] A needs you")" \
  && ! grep -q "^Click: " <<< "$Bl" && ! grep -q "^Actions: " <<< "$Bl" && ! grep -q "https://github.com" <<< "$Bl"'
check "a waiting-on-Michael run end: priority high, click = report.md" 'Be=$(curl_with "[parky] ended (waiting on Michael: B)"); grep -qx "Title: \[parky\] ended: waiting on Michael: B" <<< "$Be" \
  && grep -qx "Priority: high" <<< "$Be" && grep -qx "Click: $GHP/blob/harness/parky/.harness/runs/parky/report.md" <<< "$Be" \
  && grep "^Actions: " <<< "$Be" | grep -qF "view, Edit INBOX, $GHP/edit/harness/parky/.harness/runs/parky/INBOX.md"'
check "one notification per run end" '[[ $(curl_count "[parky] ended (") == 1 && $(curl_count "needs Michael: waiting on Michael") == 0 && $(curl_count "needs Michael: blocked on") == 0 ]] \
  && ! grep -q "Priority:" <<< "$(curl_with "[demo] ended (done)")" && grep -q "^Click: .*/demo/report.md" <<< "$(curl_with "[demo] ended (done)")"'
# harness parked: parky, parkn and parkl are all parked and ended; no queue runner
touch "$T/parked.stamp"; "$H" parked > "$T/parked.out" 2>&1; "$H" parked parky --json > "$T/parked.json" 2>&1
check "harness parked: id, why, question, both commands" 'P=$(cat "$T/parked.out"); [[ $P == *"parky · proj · B"* && $P == *"why:      set the gatus vars"* && $P == *"question: ### B: set the gatus vars, then answer"* \
  && $P == *"harness answer parky \"…\""* && $P == *"harness continue parky"* && $P == *"parkn · proj · A"* && $P == *"parkl · proj · A"* ]]'
check "harness parked is read-only" '[[ -z $(find "$HARNESS_STATE" "$T/wt/proj/parky" -newer "$T/parked.stamp") && -z $(git -C "$T/wt/proj/parky" status --porcelain) ]]'
check "harness parked --json parses" 'jq -e ".[0].feature == \"B\" and .[0].running == false and (.[0].commands | length) == 2" "$T/parked.json" > /dev/null'
RP=$HARNESS_STATE/queue/runner.pid; mkdir -p "$HARNESS_STATE/queue"; [[ -f $RP ]] && mv "$RP" "$RP.keep"; echo $$ > "$RP"
check "with a queue runner going, the continue command is a queue add" 'P=$("$H" parked parky); [[ $P == *"harness queue add --continue parky"* && $P != *"harness continue parky"* ]]'
rm -f "$RP"; [[ -f $RP.keep ]] && mv "$RP.keep" "$RP"
# parky's driver still alive (our pid): wrapping up after "ended" (finish: merge, suite, retro), then mid-run
DP=$HARNESS_STATE/proj/parky/driver.pid; echo $$ > "$DP"
check "a run still ending: answer now, continue once it has ended" 'P=$("$H" parked parky); [[ $P == *"running:  ending"* && $P == *"harness continue parky"* ]] \
  && "$H" parked parky --json | jq -e ".[0].running == false and .[0].ending == true and (.[0].commands | length) == 2" > /dev/null'
mv "$HARNESS_STATE/proj/parky/ended" "$T/parky.ended"
check "a run still going: only the answer command" 'P=$("$H" parked parky); [[ $P == *"running:  yes"* && $P == *"harness answer parky"* && $P != *"continue parky"* ]]'
mv "$T/parky.ended" "$HARNESS_STATE/proj/parky/ended"; rm -f "$DP"
check "harness parked: an unknown or glob run id is an error" '! "$H" parked nosuch 2> /dev/null && ! "$H" parked "parky*" > /dev/null 2>&1 \
  && ! "$H" answer "park*" "a glob answers no run" > /dev/null 2>&1 && ! grep -rqs "a glob answers" "$HARNESS_STATE"/proj/park*/inbox.md'
# a session-cap end queues its own continuation (finish): a second one would restart the run twice
touch "$HARNESS_STATE/queue/9999-continue-parky.args"
check "a queued continuation: only the answer command" 'P=$("$H" parked parky); [[ $P == *"continuation queued"* && $P == *"harness answer parky"* && $P != *"continue parky"* ]] \
  && "$H" parked parky --json | jq -e ".[0].queued == true and (.[0].commands | length) == 1" > /dev/null'
rm -f "$HARNESS_STATE/queue/9999-continue-parky.args"
# demo's worktree is gc'd: a parked.json left in its state dir names nothing that can be answered or continued
echo '{"Z":{"answers":"x","why":"stale","at":"2026-10-19T01:00:00.000Z"}}' > "$HARNESS_STATE/proj/demo/parked.json"
check "nothing parked"                    '[[ $("$H" parked demo) == "nothing parked in demo" ]] && ! "$H" parked | grep -q "^demo "'
check "the answer skill exists and names the commands and the never-list" 'S=$HH/skills/harness-answer/SKILL.md; [[ $(head -1 "$S") == --- ]] && grep -q "^name: harness-answer$" "$S" && grep -q "harness parked" "$S" && grep -q "harness answer" "$S" && grep -qi "never edit INBOX.md" "$S" && grep -q sudo "$S"'
check "the answer skill passes Michael's words through a quoted heredoc" 'S=$HH/skills/harness-answer/SKILL.md; grep -qF "\"\$(cat <<'"'"'HARNESS_ANSWER_END'"'"'" "$S" && grep -qi "never let his words reach the shell" "$S"'
check "the user config template sets nothing" 'bash -n "$HH/templates/user/config.sh" && ( unset NTFY_URL NTFY_TOKEN DESK_URL NOTIFY_CMD; source "$HH/templates/user/config.sh"; [[ -z ${NTFY_URL:-}${NTFY_TOKEN:-}${DESK_URL:-}${NOTIFY_CMD:-} ]] )'
rm -f "$HARNESS_STATE/proj/demo/parked.json"
"$H" answer parky "gatus vars set" > /dev/null
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" continue parky --keep-attempts --foreground > "$T/run16b.out" 2>&1
check "an INBOX answer unparks it; the run finishes" 'hlog parky | grep -q "B unparked" && [[ $($F summary "$(list parky)") == "3/3 passing" ]]'

# ---- the desk: a Remote Control claude in a tmux window briefs Michael (stub claude's interactive mode, private server) ----
cp "$T/base-config.sh" "$T/user-config.sh"   # NTFY_URL: the checks read curl.log
# every run so far (parky parked and ended, strict and later needed Michael) had the default DESK=0
check "DESK=0: no desk" '[[ -z $(compgen -G "$HARNESS_STATE/*/*/desk") && -z $(wins) && ! -e $T/desk/count ]] && ! grep -rqs "desk started\|desk: " "$T"/wt/proj/*/.harness/runs/*/harness-log.md'
SU=$T/stubunit; mkdir -p "$SU"   # its own counter: the suite's first desk stays session_TEST1
BIG=$(printf '# Retro\n%0122880d' 0)   # > the 64 KB pipe buffer, < the 128 KB argument limit
check "the stub claude's interactive mode prints the pane line and records input" 'O=$(printf "hello\n" | STUB_DIR=$SU "$HERE/stub-claude.sh" --remote-control "desk · u · x" --model m) \
  && [[ $O == "/remote-control is active · Continue here, on your phone, or at https://claude.ai/code/session_TEST1" && $(cat "$SU/desk/1-desk_u_x.in") == hello ]] \
  && grep -qx -- --remote-control "$SU/desk/1-desk_u_x.args" && [[ $(tail -1 "$SU/desk/1-desk_u_x.args") == "PWD=$PWD" ]] \
  && [[ -z $(STUB_DESK_NO_URL=1 STUB_DIR=$SU "$HERE/stub-claude.sh" --remote-control "desk · v" < /dev/null) && $(cat "$SU/desk/count") == 2 ]] \
  && STUB_DIR=$SU HARNESS_SCRATCH=$SU "$HERE/stub-claude.sh" -p "$BIG" --model m < /dev/null | grep -q "Stub retro" && [[ $(cat "$SU/desk/count") == 2 ]]'
check "DESK=0 by default, DESK_MODEL=opus" '( source "$HH/lib/config.sh"; harness_config /nonexistent; [[ $DESK == 0 && $DESK_MODEL == opus ]] )'
"$H" desk parky --why "B parked: set the gatus vars" > "$T/desk1.out" 2> "$T/desk1.err"; D1=$?
DS=$HARNESS_STATE/proj/parky/desk; DP1=$(ls "$DS"/*.md 2> /dev/null | head -1)
check "harness desk: one window, the Read line, the prompt, the notification click" '[[ $D1 == 0 && $(cat "$T/desk1.out") == https://claude.ai/code/session_TEST1 && $(wins) == parky && -n $DP1 ]] \
  && in_has "$(desk_of parky | sed "s/\.args$/.in/")" "Read" && [[ $(cat "$(desk_of parky | sed "s/\.args$/.in/")") == "Read $DP1 and follow it." ]] \
  && grep -q parky "$DP1" && grep -qF "$T/wt/proj/parky/.harness/runs/parky/INBOX.md" "$DP1" && grep -q "harness answer parky" "$DP1" \
  && [[ $(cat "$DS/url") == https://claude.ai/code/session_TEST1 && $DP1 == "$DS"/[0-9]*-[0-9]*.md ]]'
check "the desk notification" 'Bd=$(curl_last "Title: [parky] needs you"); grep -qx "Title: \[parky\] needs you: B parked: set the gatus vars" <<< "$Bd" \
  && grep -qx "Priority: high" <<< "$Bd" && grep -qx "Click: https://claude.ai/code/session_TEST1" <<< "$Bd" && ! grep -q tok-secret "$DP1"'
check "the desk's claude: --remote-control, the model id, --add-dir the worktree, in the project directory" 'A=$(desk_of parky); [[ -n $A ]] && grep -qx -- --remote-control "$A" \
  && grep -qx "desk · parky · B parked: set the gatus vars" "$A" && grep -qx -- --model "$A" && grep -qx "$($F model opus)" "$A" && grep -qx -- --add-dir "$A" \
  && grep -qx "$T/wt/proj/parky" "$A" && [[ $(tail -1 "$A") == "PWD=$T/proj" ]]'
check "the desk prompt names the run, its commands and the never-list" '( for k in "harness parked parky" "harness status parky" progress.md "by name only" .env sudo "1 yes" "harness answer parky" \
  "harness queue add --continue parky" CLAUDE.md; do grep -qF -- "$k" "$DP1" || exit 1; done ) && grep -qi "never edit INBOX.md" "$DP1" && ! grep -qF "{{" "$DP1" && ! grep -qF "<!--" "$DP1" && ! grep -q "Needs Michael" "$DP1"'
check "harness desk notes 'desk started:' in the run record" 'hlog parky | grep -qF "desk started: https://claude.ai/code/session_TEST1 (B parked: set the gatus vars)" && [[ -z $(git -C "$T/wt/proj/parky" status --porcelain) ]]'
"$H" desk parky --why "C parked: db url" > "$T/desk2.out" 2> "$T/desk2.err"; D2=$?
DP2=$(ls -t "$DS"/*.md 2> /dev/null | head -1)
check "a second event reuses the desk window" 'I=$(desk_of parky | sed "s/\.args$/.in/"); [[ $D2 == 0 && $(cat "$T/desk2.out") == https://claude.ai/code/session_TEST1 && $(wins) == parky && $DP2 != "$DP1" ]] \
  && in_has "$I" "New since" && [[ $(tail -1 "$I") == "New since your last brief: C parked: db url. Re-read $DP2." && $(head -1 "$I") == "Read $DP1 and follow it." ]] \
  && Bd=$(curl_last "Title: [parky] needs you") && grep -qx "Title: \[parky\] needs you: C parked: db url" <<< "$Bd" && grep -qx "Click: https://claude.ai/code/session_TEST1" <<< "$Bd" \
  && hlog parky | grep -qF "desk: sent to the open desk: https://claude.ai/code/session_TEST1 (C parked: db url)" && [[ $(hlog parky | grep -c "desk started:") == 1 && -z $(git -C "$T/wt/proj/parky" status --porcelain) ]]'
STUB_DESK_NO_URL=1 HARNESS_DESK_WAIT=2 "$H" desk stoppy --why "x" > "$T/desk3.out" 2> "$T/desk3.err"; D3=$?
check "no URL in time: no window, the plain notification" '[[ $D3 == 0 && ! -s $T/desk3.out && -z $(win stoppy) ]] && grep -q "no session URL" "$T/desk3.err" \
  && hlog stoppy | grep -qF "desk: no session URL within 2 s; killed the window; plain notification" && [[ ! -s $HARNESS_STATE/proj/stoppy/desk/url ]] \
  && Bn=$(curl_last "Title: [stoppy] needs you") && grep -qx "Title: \[stoppy\] needs you: x" <<< "$Bn" && grep -qx "Priority: high" <<< "$Bn" && ! grep -q "Click: https://claude.ai" <<< "$Bn" \
  && ! grep -q "Open the desk" <<< "$Bn" && grep -qx "Or by hand: harness parked stoppy" <<< "$Bn" && grep -q "; notified)$" "$T/desk3.err" \
  && [[ -z $(git -C "$T/wt/proj/stoppy" status --porcelain -- .harness/runs/stoppy/harness-log.md) ]]'   # committed (the debrief checks planted the INBOX and report edits)
tmux kill-window -t "$(win parky)" 2> /dev/null   # the session goes with its last window
"$H" desk parky --why "again" > "$T/desk4.out" 2> "$T/desk4.err"; D4=$?
check "a dead desk is replaced" 'I=$(desk_of parky | sed "s/\.args$/.in/"); [[ $D4 == 0 && $(cat "$T/desk4.out") == https://claude.ai/code/session_TEST3 && $(wins | grep -cx parky) == 1 && $I == */3-desk_parky_again.in ]] \
  && in_has "$I" "Read" && [[ $(head -1 "$I") == "Read "*" and follow it." ]] && ! grep -q "New since" "$I" && [[ $(cat "$DS/url") == https://claude.ai/code/session_TEST3 ]]'
"$H" desk --debrief > "$T/desk5.out" 2> "$T/desk5.err"; D5=$?
QP=$(ls -t "$HARNESS_STATE"/queue/desk/*.md 2> /dev/null | head -1)
check "harness desk --debrief" 'A=$(desk_of debrief); [[ $D5 == 0 && $(cat "$T/desk5.out") == https://claude.ai/code/session_TEST4 && -n $(win debrief) && -n $QP && -n $A ]] \
  && grep -qF "ledger/debrief.md" "$QP" && grep -q "Needs Michael" "$QP" && ! grep -qF "{{" "$QP" && ! grep -qF "<!--" "$QP" && ! grep -q "harness parked parky" "$QP" \
  && in_has "${A%.args}.in" "Read" && [[ $(cat "${A%.args}.in") == "Read $QP and follow it." && $(tail -1 "$A") == "PWD=$HH" ]] && grep -qx "$T/wt" "$A" && grep -qx "$T/ledger" "$A" \
  && grep -qx "Title: \[debrief\] needs you" <<< "$(curl_last "Title: [debrief]")" && grep -qx "Click: https://claude.ai/code/session_TEST4" <<< "$(curl_last "Title: [debrief]")" \
  && grep -qF "desk started: https://claude.ai/code/session_TEST4" "$HARNESS_STATE/queue/runner.log"'
W0=$(wins | sort)
rc() { "$@" > /dev/null 2>&1; echo $?; }
check "harness desk: an unknown run or a bad option is an error, nothing started" '[[ $(rc "$H" desk nosuch) == 1 && $(rc "$H" desk "park*") == 1 && $(rc "$H" desk debrief) == 1 && $(rc "$H" desk desk) == 1 ]] \
  && [[ $(rc "$H" desk parky --nope) == 2 && $(rc "$H" desk --debrief parky) == 2 && $(rc "$H" start "$T/proj" desk --spec SPEC.md) == 1 ]] \
  && [[ ! -d $HARNESS_STATE/proj/nosuch && ! -d $HARNESS_STATE/proj/desk && ! -d $T/wt/proj/desk && $(wins | sort) == "$W0" ]]'
tmux kill-window -t "$(win parky)"; tmux new-window -d -t "=$HARNESS_DESK_SESSION:" -n parky sleep 600; rm -f "$DS/url"   # a window of that name that is no desk
"$H" desk parky --why "stale" > "$T/desk6.out" 2> /dev/null; D6=$?
check "a window of the run's name that never showed a URL is replaced" '[[ $D6 == 0 && $(cat "$T/desk6.out") == https://claude.ai/code/session_TEST5 && $(wins | grep -cx parky) == 1 ]] \
  && in_has "$(desk_of parky | sed "s/\.args$/.in/")" "Read" && ! tmux list-panes -a -F "#{pane_start_command}" | grep -q "sleep 600"'
# DESK=1: the driver and the debrief start desks themselves (a park, a run end needing Michael, verify, the debrief)
{ cat "$T/base-config.sh"; echo 'DESK=1'; } > "$T/user-config.sh"
STUB_PARK=B STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" desky --spec SPEC.md --foreground > "$T/run18.out" 2>&1
check "DESK=1: a park starts one desk, the run end reuses it" 'I=$(desk_of desky | sed "s/\.args$/.in/"); grep -q "^waiting on Michael: B" "$HARNESS_STATE/proj/desky/ended" && [[ $(wins | grep -cx desky) == 1 ]] \
  && in_has "$I" "New since" && [[ $(sed -n 1p "$I") == "Read $HARNESS_STATE/proj/desky/desk/"*".md and follow it." ]] \
  && [[ $(sed -n 2p "$I") == "New since your last brief: ended: waiting on Michael: B. Re-read $HARNESS_STATE/proj/desky/desk/"*.md. && $(wc -l < "$I") == 2 ]] \
  && [[ $(hlog desky | grep -c "desk started:") == 1 ]] && hlog desky | grep -qF "(B parked: set the gatus vars)" && hlog desky | grep -q "desk: sent to the open desk: .* (ended: waiting on Michael: B)" \
  && [[ -n $(curl_with "Title: [desky] B needs you") && -n $(curl_with "Title: [desky] needs you: B parked: set the gatus vars") && -z $(git -C "$T/wt/proj/desky" status --porcelain) ]]'
STUB_DESK_NO_URL=1 HARNESS_DESK_WAIT=2 STUB_PARK=B STUB_INDEPENDENT_M2=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" deskno --spec SPEC.md --foreground > "$T/run19.out" 2>&1
check "a desk that cannot start never changes the run" 'grep -q "^waiting on Michael: B" "$HARNESS_STATE/proj/deskno/ended" && [[ -n $(curl_with "Title: [deskno] B needs you") && -z $(win deskno) ]] \
  && [[ $(hlog deskno | grep -c "desk: no session URL within 2 s; killed the window; plain notification") == 2 ]] && ! hlog deskno | grep -q "desk: could not start" \
  && [[ $($F summary "$(list deskno)") == "2/3 passing" && -z $(git -C "$T/wt/proj/deskno" status --porcelain) ]]'
STUB_STRICT_VERIFIER=1 STUB_INDEPENDENT_M2=1 "$H" continue strict --foreground > "$T/run3b.out" 2>&1   # clears needs-M1: M1 fails its re-checks again
check "verify needs Michael starts a desk" 'I=$(desk_of strict | sed "s/\.args$/.in/"); [[ -n $(win strict) ]] && in_has "$I" "Read" && P=$(sed -n "1s/^Read \(.*\) and follow it\.$/\1/p" "$I") \
  && [[ $P == "$HARNESS_STATE/proj/strict/desk/"*.md ]] && grep -q "M1 needs Michael: A fails verification" "$P" && hlog strict | grep -q "desk started: .* (M1 needs Michael: A fails verification)"'
W=$(win debrief); [[ -n $W ]] && tmux kill-window -t "$W"   # the by-hand one above (an empty -t would hit the current window)
ran stoppy; "$H" debrief > "$T/ddesk1.out" 2>&1; DW1=$(win debrief)
ran stoppy; STUB_DEBRIEF_NEEDS=1 "$H" debrief > "$T/ddesk2.out" 2>&1
check "the debrief starts a desk when Needs Michael is non-empty" '[[ -z $DW1 && -n $(win debrief) ]] && grep -q "debrief written" "$T/ddesk1.out" && grep -q "debrief written" "$T/ddesk2.out" \
  && [[ $(grep -c "desk started: .*session_TEST" "$HARNESS_STATE/queue/runner.log") == 2 ]]'
echo 'LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"

# ---- run 17: the 7-day window past WEEKLY_STOP_AT: the run stops before its next session; the queue starts nothing ----
STUB_WEEKLY=0.9 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" weekly --spec SPEC.md --foreground > "$T/run17.out" 2>&1
check "the weekly budget ends a run after the session that crossed it" 'grep -q "^weekly budget (7-day window at 90%" "$HARNESS_STATE/proj/weekly/ended" && [[ $(grep -c attempt "$T/scratch/proj/weekly/sessions.log") == 1 ]]'
"$H" queue add "$T/proj" --spec SPEC.md > /dev/null
HARNESS_QUEUE_FOREGROUND=1 HARNESS_HOME=$HERE/.. "$HERE/../lib/queue.sh" > "$T/queue5.out" 2>&1
check "the queue starts no run past the weekly budget" 'grep -q "7-day window at 90%" "$T/queue5.out" && [[ $(ls "$Q"/*.args | wc -l) == 1 ]]'
echo 'LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1 WEEKLY_STOP_AT=95' > "$T/user-config.sh"
check "WEEKLY_STOP_AT raises the bar"     '( source "$HERE/../lib/config.sh" && harness_config /nonexistent && [[ $WEEKLY_STOP_AT == 95 ]] && ! weekly_over "$HARNESS_STATE/USAGE_7D" > /dev/null )'
rm -f "$Q"/*.args "$HARNESS_STATE/USAGE_7D"; echo 'LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"

(( fails )) && { echo "--- run1 output"; tail -30 "$T/run1.out"; echo "--- harness-log"; hlog demo; }
echo "$(( total - fails ))/$total checks passed"
exit $(( fails > 0 ))
