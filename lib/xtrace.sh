#!/usr/bin/env bash
# Usage: [[ -z ${HARNESS_XTRACE:-} ]] || source "<lib>/xtrace.sh"   → this process traces every command it runs to $HARNESS_XTRACE/<pid>.xtrace
# The first line of work in every script that runs as a process of its own (bin/harness, lib/driver.sh, lib/lane.sh,
# lib/check.sh, lib/queue.sh, lib/debrief.sh, lib/desk.sh, lib/sync.sh, lib/backlog.sh, lib/eval.sh, lib/merge-sorted.sh,
# lib/prompt.sh as a command): `set -x` does not cross a process, so each asks for itself. Off unless the variable is
# set: nothing is opened and no option changes. Each line is bash's own trace led by `+<source file>:<line>: ` (the +
# once per nesting level; the file as bash names it, a full path), on a descriptor of its own, never stderr; subshells
# write to the same file. A directory that can't be made or written: no trace, and the script goes on.
# tests/tools/coverage.mjs reduces the traces to the lines that ran (decisions/2026-11-03-suite-coverage).
if mkdir -p "$HARNESS_XTRACE" 2> /dev/null && { exec {BASH_XTRACEFD}>> "$HARNESS_XTRACE/$$.xtrace"; } 2> /dev/null; then
  PS4='+${BASH_SOURCE:-}:${LINENO}: '; set -x
fi
