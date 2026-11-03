#!/usr/bin/env bash
# Usage: starthand.sh <kept $T> <run name> — check file 13's first `harness start` by hand, under strace and time -v,
# in the kept $T with suite_setup's exports (tests/lib.sh), as findings-and-research/2026-10-30-suite-load-curve §4 did
S=/tmp/harness/agent-harness/agent-harness-2026-11-03/lanes/C1 WT=/home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-11-03/slot-1
source "$WT/tests/lib.sh"; T=$1; cd "$T/proj" || exit 1
unset TMUX TMUX_PANE $(compgen -e | grep -E "^(HARNESS_|STUB_)")   # this session's own run's exports: never inherited
export TMUX_TMPDIR=$T/tmux HARNESS_DESK_SESSION=h-desk-test-$$; mkdir -p "$TMUX_TMPDIR"
export HARNESS_STATE=$T/state HARNESS_WORKTREES=$T/wt HARNESS_SCRATCH_ROOT=$T/scratch HARNESS_PAUSE_POLL=1 HARNESS_LANE_POLL=1 \
  HARNESS_CLAUDE=$HERE/stub-claude.sh HARNESS_GH=$HERE/stub-gh.sh HARNESS_CURL=$HERE/stub-curl.sh STUB_DIR=$T HARNESS_LEDGER=$T/ledger \
  HARNESS_CONFIG=$T/user-config.sh HARNESS_LIMIT_SLEEP=0 HARNESS_NO_RUNNER=1 HARNESS_QUEUE_POLL=0 HARNESS_QUEUE_SETTLE=0
export HARNESS_SYSTEMD_RUN=$HERE/stub-systemd-run.sh HARNESS_SYSTEMCTL=$HERE/stub-systemctl.sh HARNESS_MEMINFO=$HERE/fixtures/meminfo.txt HARNESS_MEM_POLL=1
unset HARNESS_SCOPE_PREFIX HARNESS_CHECK_MEMORY_MAX HARNESS_CHECK_TIMEOUT HARNESS_CHECK_KEY_IGNORE HARNESS_CHECK_RERUN HARNESS_LANE SCOPE_OK REPLAY
export XDG_CACHE_HOME=$T/cache PATH=$T/bin:$PATH
cp "$T/base-config.sh" "$T/user-config.sh"
/usr/bin/time -v -o "$S/stubstart.time" strace -f -s 512 -e trace=execve,clone,clone3,fork,vfork -o "$S/execs.strace" \
  "$H" start "$T/proj" "$2" --spec SPEC.md --brief "only A–C" --foreground > "$S/stubstart.out" 2>&1
echo "rc $?"
tmux kill-server 2> /dev/null; true
