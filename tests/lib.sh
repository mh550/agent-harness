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

# the file's count; exit 1 on a failure
suite_end() {
  (( fails )) && [[ -f $T/run1.out ]] && { echo "--- run1 output"; tail -30 "$T/run1.out"; echo "--- harness-log"; hlog demo; }
  echo "$(( total - fails ))/$total checks passed"
  exit $(( fails > 0 ))
}
