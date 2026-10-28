#!/usr/bin/env bash
# The suite's shared preamble (the single-file tests/run.sh's lines 6-58), sourced by every tests/checks/*.sh.
#   source "$(dirname "$0")/../lib.sh" && suite_setup   … checks …   suite_end   (KEEP=1 keeps the file's $T)
set -uo pipefail
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd); H=$HERE/../bin/harness F="node $HERE/../lib/features.mjs"

# a fresh $T, private tmux server, stub environment, base user config and throwaway project (cwd: $T/proj), so every file starts from the same state
suite_setup() {
T=$(mktemp -d); echo "tmp: $T"
unset TMUX TMUX_PANE   # inside Michael's tmux, plain `tmux` talks to his server: the suite must never
export TMUX_TMPDIR=$T/tmux HARNESS_DESK_SESSION=h-desk-test-$$; mkdir -p "$TMUX_TMPDIR"   # a private tmux server
trap 'for w in "$T"/evaltmp/*/harness; do [[ -d $w ]] && git -C "$HERE/.." worktree remove --force "$w"; done 2> /dev/null   # the harness worktree of a killed eval
  for p in $(cat "$T"/scope/*.pids "$T"/left.pids 2> /dev/null); do kill "$p"; done 2> /dev/null   # sleeps a stub session left
  tmux kill-session -t "=$HARNESS_DESK_SESSION" 2> /dev/null; [[ $TMUX_TMPDIR == "$T/tmux" ]] && tmux kill-server 2> /dev/null; [[ ${KEEP:-} ]] || rm -rf "$T"' EXIT   # the server is ours alone
trap 'exit 143' TERM   # the runner's TEST_FILE_TIMEOUT or stop: the EXIT trap above still runs (rm -rf $T, the tmux server)
export HARNESS_STATE=$T/state HARNESS_WORKTREES=$T/wt HARNESS_SCRATCH_ROOT=$T/scratch HARNESS_PAUSE_POLL=1 HARNESS_LANE_POLL=1 \
  HARNESS_CLAUDE=$HERE/stub-claude.sh HARNESS_GH=$HERE/stub-gh.sh HARNESS_CURL=$HERE/stub-curl.sh STUB_DIR=$T HARNESS_LEDGER=$T/ledger \
  HARNESS_CONFIG=$T/user-config.sh HARNESS_LIMIT_SLEEP=0 HARNESS_NO_RUNNER=1 HARNESS_QUEUE_POLL=0 HARNESS_QUEUE_SETTLE=0
export HARNESS_SYSTEMD_RUN=$HERE/stub-systemd-run.sh HARNESS_SYSTEMCTL=$HERE/stub-systemctl.sh HARNESS_MEMINFO=$HERE/fixtures/meminfo.txt HARNESS_MEM_POLL=1
unset HARNESS_SCOPE_PREFIX HARNESS_CHECK_MEMORY_MAX HARNESS_CHECK_TIMEOUT HARNESS_CHECK_KEY_IGNORE SCOPE_OK   # a session running the suite inherits its own run's
unset REPLAY   # set only around a replayed section (check): from the environment it would silence every check
export XDG_CACHE_HOME=$T/cache   # every run's HARNESS_CACHE ($T/cache/harness/<project>) stays in $T
# tmux windows get the private server's environment from when it started, not the caller's: a supervisor window's bare
# `claude` must be the stub (a wrapper, not a symlink: the stub finds its fixtures through dirname $0)
mkdir -p "$T/bin" && printf '#!/usr/bin/env bash\nexec %q "$@"\n' "$HERE/stub-claude.sh" > "$T/bin/claude" && chmod +x "$T/bin/claude"
export PATH=$T/bin:$PATH
fails=0 total=0

# the base user config opens no record PR (50-lanes-record-pr turns it on: a third PR would change every run's gh.log); it posts through the stub curl (and keeps each run's scratch: checks read it after the run; L3's scrub run doesn't); NOTIFY_CMD is set too, and must not be called (NTFY_URL wins)
printf '%s\n' 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1 MERGE_POLICY=auto RECORD_PR=off NTFY_URL=https://ntfy.example/t NTFY_TOKEN=tok-secret-123' \
  "NOTIFY_CMD='printf \"%s\\n===\\n\" \"\$1\" >> \"$T/notify-cmd.log\"'" > "$T/base-config.sh"
cp "$T/base-config.sh" "$T/user-config.sh"
git init -q --bare -b main "$T/origin.git"
git init -q -b main "$T/proj" && cd "$T/proj"
mkdir .harness && cat > .harness/config.sh <<'EOF'
CHECK_CMD="test ! -f BROKEN"
INIT_CMD='echo init ok; echo "cache: $HARNESS_CACHE"; [[ -z ${STUB_SLOW_INITCMD:-} ]] || { touch "${HARNESS_SCRATCH%%/lanes/*}/init-begin"; sleep "$STUB_SLOW_INITCMD"; }'
BASE_PORT=7950
EOF
# its teardown hook (L2-03): one marker per why, and the call in the stubs' own timeline (systemd.log); the markers go
# to the run's scratch, a lane's teardown included (${HARNESS_SCRATCH%%/lanes/*})
cat > .harness/teardown.sh <<'EOF'
#!/usr/bin/env bash
w=$(printf %s "$HARNESS_TEARDOWN_WHY" | tr -cs 'A-Za-z0-9' -) rs=${HARNESS_SCRATCH%%/lanes/*}
touch "$rs/teardown-$w.marker"
[[ -z ${STUB_SLOW_TEARDOWN:-} ]] || { touch "$rs/teardown-begin"; sleep "$STUB_SLOW_TEARDOWN"; }
printf 'teardown\n%s\n%s\n===\n' "$HARNESS_RUN_ID" "$HARNESS_TEARDOWN_WHY" >> "$STUB_DIR/systemd.log"
EOF
chmod +x .harness/teardown.sh
printf '# proj\nrules\n' > CLAUDE.md; echo spec > SPEC.md
git add -A && git commit -qm init && git config url."$T/origin.git".insteadOf git@github.com:test/proj.git && git remote add origin git@github.com:test/proj.git && git push -q -u origin main
}

# REPLAY=1 (split.sh, around a section a file replays for its state): the check runs, silent and uncounted (its own file counts it)
check() { [[ ${REPLAY:-} ]] && { eval "$2" > /dev/null 2>&1; return 0; }
  total=$((total + 1)); if eval "$2"; then echo "PASS $1"; else echo "FAIL $1"; fails=$((fails + 1)); fi; }
hlog() { cat "$T/wt/${2:-proj}/$1/.harness/runs/$1/harness-log.md" 2>/dev/null || (( $? == 141 )); }   # <run> [<project>]; a reader that quits early (grep -q) must not turn cat's SIGPIPE into a pipefail failure
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
# two helpers the debrief sections define (the same lines, copied): L5 calls settle and the desk calls ran, each in a file
# of its own without the debrief sections since P0-02
HH=$(cd "$HERE/.." && pwd)
settle() {   # the runner's debrief is detached: wait until no debrief process is left
  local i; sleep 0.5
  for i in $(seq 150); do pgrep -f "$HH/lib/debrief\.sh|$HH/bin/harness debrief" > /dev/null || return 0; sleep 0.2; done; return 1
}
ran() { local r; sleep 1; for r; do echo "$(date '+%F %T') run $r on harness/$r in $T/wt/proj/$r · port 7999" >> "$HARNESS_STATE/proj/$r/run.log"; done; }   # runs since

# The read views' stub runs (U1; call once after suite_setup): every time relative to a fixed HARNESS_NOW, TZ=UTC (the
# stamps are local time). proj: done2h, done3d, running (a live sleep as its driver and as lane M1's, one unit each, B
# on its last attempt),
# parked, gcd (worktree removed, its summary.json only in the ledger), crashed (driver.pid naming no process); proj2:
# stopped, givenup (parked and givenup with the needs records the lane opens); and <bulk> more ended 4 days ago (bulk-01's ended a bare reason). The queue: a start with a long
# brief (held: proj's run is going), a requested continue, a parked start. Leaves at, ago and sr defined for status_bulk.
#   status_stubs [<bulk>]
status_stubs() {
  export TZ=UTC HARNESS_NOW=1793145600 STUB_MEM_CURRENT=314572800   # 300 MB
  local now=$HARNESS_NOW port=7950 i r
  at() { date -d "@$(( HARNESS_NOW - $1 ))" '+%F %T'; }
  iso() { date -u -d "@$(( HARNESS_NOW - $1 ))" '+%Y-%m-%dT%H:%M:%S.000Z'; }
  ago() { touch -d "@$(( HARNESS_NOW - $2 ))" "$1"; }
  sr() {   # <project> <run> <started s ago> [<end reason> <ended s ago>]: state dir, worktree, record, run.log
    local st=$HARNESS_STATE/$1/$2 wt=$T/wt/$1/$2; local rec=$wt/.harness/runs/$2
    mkdir -p "$st" "$rec"; port=$(( port + 1 )); echo "$port" > "$st/port"
    printf 'PROJECT_DIR=%q\nWT=%q\nRUN_ID=%q\nSTATE=%q\n' "$T/$1" "$wt" "$2" "$st" > "$st/meta.env"
    { echo "$(at "$3") run $2 on harness/$2 in $wt · port $port · policy build-only · merge auto · harness test"
      echo "$(at $(( $3 - 60 ))) session 1 · A · claude-opus-5-5"; } > "$st/run.log"
    [[ -n ${4:-} ]] && { echo "$(at "$5") $4" >> "$st/run.log"; echo "$4 · $(at "$5")" > "$st/ended"; ago "$st/ended" "$5"; ago "$st/run.log" "$5"; }
    return 0
  }
  fl() {   # <project> <run> <id:passes:milestone>…: the feature list
    local rec=$T/wt/$1/$2/.harness/runs/$2 f i r m; shift 2
    for f; do IFS=: read -r i r m <<< "$f"; printf '{"id":"%s","milestone":"%s","description":"%s","steps":["x"],"passes":%s}\n' "$i" "$m" "$i" "$r"; done \
      | jq -s '{features: .}' > "$rec/feature_list.json"
  }
  mx() {   # <project> <run> [<kind>:]<feature>…: one metrics.jsonl row each, from the real session shape (driver.sh's
    # init, lane.sh's verify and its limit-refused coding row, `refused:`, beside the coding ones), at MX_AT s before now
    local rec=$T/wt/$1/$2/.harness/runs/$2 r=$2 f k e; shift 2
    for f; do k=coding e=false; [[ $f == *:* ]] && { k=${f%%:*}; f=${f#*:}; }; [[ $k == refused ]] && k=coding e=true
      node "$HERE/../lib/metrics.mjs" append "$HERE/fixtures/usage-tokens.jsonl" "$rec/metrics.jsonl" "$r" "$k" "$f" claude-opus-5-5 \
        "$([[ $e == true ]] && echo false || echo true)" 600 0 "$e" "$k" 100; done
    jq -c --arg at "$(iso "${MX_AT:-1900}")" '.at = $at' "$rec/metrics.jsonl" > "$rec/m.tmp" && mv "$rec/m.tmp" "$rec/metrics.jsonl"
  }
  sr proj done2h 14400 done 7200; fl proj done2h A:true:M1 B:true:M1 C:true:M1; mx proj done2h A B C; touch "$HARNESS_STATE/proj/done2h/merged-M1"
  echo 419 > "$HARNESS_STATE/proj/done2h/tests-start"; echo 430 > "$HARNESS_STATE/proj/done2h/tests-end"
  node "$HERE/../lib/summary.mjs" build "$T/wt/proj/done2h" done2h "$HARNESS_STATE/proj/done2h" > "$T/wt/proj/done2h/.harness/runs/done2h/summary.json"   # finish's
  echo '{"features":{"passing":1,"total":3,"verified":0,"merged":0},"cost":{"total":5}}' > "$HARNESS_STATE/proj/done2h/summary.json"   # an earlier harness report's
  sr proj done3d 270000 done 259200; fl proj done3d A:true:M1
  sr proj2 stopped 36000 "stopped by Michael: rebase first" 18000; fl proj2 stopped A:true:M1 B:false:M1 C:false:M2; mx proj2 stopped A
  sr proj running 7200; fl proj running A:true:M1 B:false:M1 C:false:M2; mx proj running init: A refused:B
  { echo "$(at 3000) A · claude-opus-5-5 · passes=true · 69 min · 1/3 passing"; echo "$(at 2900) session 2 · B · claude-opus-5-5"   # lane.sh's lines
    echo "$(at 2800) session for B hit a limit (five-hour); not counted; resuming at 23:30"; echo "$(at 1800) session 2 · B · claude-opus-5-5"; } >> "$HARNESS_STATE/proj/running/run.log"
  echo 1 > "$HARNESS_STATE/proj/running/sessions"; echo '{"A":1,"B":2}' > "$HARNESS_STATE/proj/running/attempts.json"   # this segment's count; B on its last attempt
  sleep 600 & echo $! > "$HARNESS_STATE/proj/running/driver.pid"; echo $! >> "$T/left.pids"
  mkdir -p "$HARNESS_STATE/proj/running/lanes/M1" "$T/scope"; cp "$HARNESS_STATE/proj/running/driver.pid" "$HARNESS_STATE/proj/running/lanes/M1/pid"
  echo "B · session 2" > "$HARNESS_STATE/proj/running/lanes/M1/now"; echo 7960 > "$HARNESS_STATE/proj/running/lanes/M1/port"
  echo "$T/wt/proj/running-slots/slot-1" > "$HARNESS_STATE/proj/running/lanes/M1/slot"
  for r in harness-running-M1-s2 harness-running-svc; do touch "$T/scope/$r.alive" "$T/scope/$r.running"; done
  nopen() {   # <project> <run> <s ago> <reason> <subject> [key=value…]: the needs record lane.sh's needs_open writes, then
    local p=$1 r=$2 s=$3; local wt=$T/wt/$p/$r; local rec=$wt/.harness/runs/$r; shift 3
    HARNESS_NOW=$(( HARNESS_NOW - s )) node "$HERE/../lib/needs.mjs" open "$HARNESS_STATE/$p/$r" "$r" "$p" "$@" list="$rec/feature_list.json" \
      record="$rec" inbox="$rec/INBOX.md" worktree="$wt" branch="harness/$r" record_branch="harness/$r" state="$HARNESS_STATE/$p/$r" > /dev/null
  }
  sr proj parked 10800 "waiting on Michael: B" 3600; fl proj parked A:true:M1 B:false:M1 C:false:M1; mx proj parked A
  printf '{"B":{"answers":"x","why":"set the gatus vars\\nand the token","at":"%s"}}\n' "$(iso 3700)" > "$HARNESS_STATE/proj/parked/parked.json"
  printf 'status: run\n\n### B: set the gatus vars, then answer\n\n## Answers\n' > "$T/wt/proj/parked/.harness/runs/parked/INBOX.md"
  nopen proj parked 3700 parked B feature=B why="$(printf 'set the gatus vars\nand the token')"
  sr proj2 givenup 9000 "blocked on C" 1800; fl proj2 givenup A:true:M1 B:true:M1 C:false:M1
  echo '{"C":2}' > "$HARNESS_STATE/proj2/givenup/attempts.json"; echo 2 > "$HARNESS_STATE/proj2/givenup/max-attempts"; ago "$HARNESS_STATE/proj2/givenup/attempts.json" 2000
  nopen proj2 givenup 2000 given_up C feature=C attempts=2 max_attempts=2 log="$HARNESS_STATE/proj2/givenup/run.log"
  sr proj gcd 30000 done 4200; fl proj gcd $(for i in $(seq 23); do echo "F$i:true:M$(( (i - 1) / 12 + 1 ))"; done); mx proj gcd F1 F2
  { echo "$(at 29000) lane M1 opened (slot 1)"; echo "$(at 28000) lane M2 opened (slot 2)"; echo "$(at 9000) lane M1 closed (merged)"; echo "$(at 5000) lane M2 closed (merged)"; } >> "$HARNESS_STATE/proj/gcd/run.log"
  touch "$HARNESS_STATE/proj/gcd/verified-M1" "$HARNESS_STATE/proj/gcd/verified-M2" "$HARNESS_STATE/proj/gcd/merged-M1" "$HARNESS_STATE/proj/gcd/merged-M2"
  mkdir -p "$HARNESS_LEDGER/proj/gcd"; node "$HERE/../lib/summary.mjs" build "$T/wt/proj/gcd" gcd "$HARNESS_STATE/proj/gcd" > "$HARNESS_LEDGER/proj/gcd/summary.json"
  rm -rf "$T/wt/proj/gcd"
  sr proj crashed 40000; fl proj crashed A:false:M1; echo '{"features":{"passing":9,"total":9}}' > "$T/wt/proj/crashed/.harness/runs/crashed/summary.json"; sh -c 'echo $$' > "$HARNESS_STATE/proj/crashed/driver.pid"; ago "$HARNESS_STATE/proj/crashed/run.log" 36000
  (( ${1:-0} )) && status_bulk "$1"
  local q=$HARNESS_STATE/queue; mkdir -p "$q/held"
  printf '%s\n' start "$T/proj" --spec "SPEC.md docs/b.md" --until 23:52 --brief "$(printf 'brief %.0s' $(seq 200))" > "$q/0001-start-proj.args"; ago "$q/0001-start-proj.args" 600
  printf '%s\n' continue stopped --queued --requested > "$q/0002-continue-stopped.args"; ago "$q/0002-continue-stopped.args" 300
  printf '%s\n' start "$T/proj2" proj2-next --until-epoch $(( now + 3600 )) > "$q/held/0003-start-proj2.args"; echo "waiting on the measure PRs (2026-10-28 23:00)" > "$q/held/0003-start-proj2.why"
  ago "$q/held/0003-start-proj2.args" 900
}
status_bulk() {   # <n>: bulk-01 … bulk-<n> (proj), ended done 4 days and <i> minutes before HARNESS_NOW; bulk-01's a bare reason
  local i port=8000
  for (( i = 1; i <= $1; i++ )); do sr proj "bulk-$(printf %02d "$i")" 400000 done $(( 345600 + i * 60 )); done
  echo done > "$HARNESS_STATE/proj/bulk-01/ended"; ago "$HARNESS_STATE/proj/bulk-01/ended" 345660
}

# <reason> open|resolved [<at epoch>] [<run>]: the run nf-<reason>-<state> (proj) whose needs/1.json is <reason>'s item (needs.mjs
# open), with plan §2.1's markers for that state; its record holds a list (A passes, B doesn't). overlap has no sweep rule
# before U3: resolved is its worktree removed (no harness/<run> branch exists in $T/proj)
needs_fixture() {
  local r=$1 s=$2 run=${4:-nf-$1-$2} sub=M1; local st=$HARNESS_STATE/proj/$run wt=$T/wt/proj/$run
  mkdir -p "$st" "$wt/.harness/runs/$run"
  printf 'PROJECT_DIR=%q\nWT=%q\nRUN_ID=%q\nSTATE=%q\n' "$T/proj" "$wt" "$run" "$st" > "$st/meta.env"
  echo '{"features":[{"id":"A","milestone":"M1","passes":true},{"id":"B","milestone":"M1","passes":false}]}' > "$wt/.harness/runs/$run/feature_list.json"
  case $r in parked|given_up) sub=B ;; feature_list_edits|initializer_failed|driver_crash|usage_limit|weekly_budget) sub=run ;; overlap) sub=nf-other ;; esac
  # the overlap's other run: live (this file's shell), so the sweep keeps an open one (U3-06's rule)
  [[ $r == overlap && ! -e $HARNESS_STATE/proj/nf-other ]] && mkdir -p "$HARNESS_STATE/proj/nf-other" && echo $$ > "$HARNESS_STATE/proj/nf-other/driver.pid" &&
    printf 'PROJECT_DIR=%q\nWT=/x\nRUN_ID=nf-other\nSTATE=%q\n' "$T/proj" "$HARNESS_STATE/proj/nf-other" > "$HARNESS_STATE/proj/nf-other/meta.env"
  HARNESS_NOW=${3:-} node "$HERE/../lib/needs.mjs" open "$st" "$run" proj "$r" "$sub" feature="$([[ $sub == B ]] && echo B)" milestone=M1 > /dev/null
  [[ $s == open ]] || { [[ $r == overlap ]] && rm -rf "$wt"; return 0; }
  case $r in
    parked) echo '{"B":{"why":"set the vars","at":"2026-10-28T00:00:00.000Z"}}' > "$st/parked.json" ;;
    given_up) echo '{"B":2}' > "$st/attempts.json"; echo 2 > "$st/max-attempts" ;;
    verify_*|base_conflict) touch "$st/needs-M1" ;;
    merge_conflict) touch "$st/conflict-M1" "$st/needs-M1" ;;
    merge_refused) touch "$st/refused-M1" ;;
    main_conflict) touch "$st/main-conflict-M1" ;;
    overlap) ;;
    *) echo "x · 2026-10-28 00:00:00" > "$st/ended" ;;
  esac
}

# the widest stdin line in display columns (view.mjs's displayWidth); a URL line a card leaves whole (`  <scheme>://`) is not counted
widest() { node --input-type=module -e "import { displayWidth } from \"$HERE/../lib/view.mjs\"; import { readFileSync } from \"node:fs\";
  console.log(Math.max(0, ...readFileSync(0, \"utf8\").split(\"\n\").filter(l => !/^  [a-z]+:\/\//.test(l)).map(displayWidth)))"; }

# the file's count; exit 1 on a failure
suite_end() {
  (( fails )) && [[ -f $T/run1.out ]] && { echo "--- run1 output"; tail -30 "$T/run1.out"; echo "--- harness-log"; hlog demo; }
  echo "$(( total - fails ))/$total checks passed"
  exit $(( fails > 0 ))
}
