#!/usr/bin/env bash
# .harness/init.sh (optional) — run by the harness before every session, in the run's worktree, with HARNESS_PORT and
# HARNESS_SCRATCH set. The harness runs the suite itself; this only prepares what sessions need, e.g. a dev server.
# Idempotent: stop the server the previous session left (pid in $SCRATCH/server.pid). Output (last 4 KB) goes into the prompt.
# A finished run deletes $SCRATCH: installs that should outlive it (Playwright browsers: PLAYWRIGHT_BROWSERS_PATH=
# $HARNESS_CACHE/ms-playwright) go under $HARNESS_CACHE (~/.cache/harness/<project>, never deleted).
set -euo pipefail
cd "$(dirname "$0")/.."
PORT=${HARNESS_PORT:?} SCRATCH=${HARNESS_SCRATCH:?}
[[ -f $SCRATCH/server.pid ]] && { kill "$(cat "$SCRATCH/server.pid")" 2>/dev/null || true; }
# nohup <start the dev server on $PORT> > "$SCRATCH/server.log" 2>&1 & echo $! > "$SCRATCH/server.pid"
echo "server: (none configured)"
