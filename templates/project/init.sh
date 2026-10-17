#!/usr/bin/env bash
# .harness/init.sh — run by the harness before every session, in the run's worktree.
# Gets HARNESS_PORT and HARNESS_SCRATCH. Make it idempotent: install deps, run the suite, (re)start a dev server.
# Its output (last 4 KB) is pasted into the session's prompt, so keep it short and say what failed.
set -euo pipefail
cd "$(dirname "$0")/.."
PORT=${HARNESS_PORT:?} SCRATCH=${HARNESS_SCRATCH:?}

[[ -d node_modules ]] || npm install --no-audit --no-fund
npm run check --silent > "$SCRATCH/check.log" 2>&1 && echo "check: green" || { echo "check: RED"; tail -30 "$SCRATCH/check.log"; }

# start a dev server on $PORT here, stopping the one from the previous session first (pid in $SCRATCH/server.pid)
echo "server: (none configured)"
