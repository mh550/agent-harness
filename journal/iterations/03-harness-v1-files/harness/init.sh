#!/usr/bin/env bash
# Start-of-session setup for a coding session (the article's init.sh):
# deps, the suite, a headless browser, and a scratch server with the sample graph and the 11 Oct set replayed.
# Idempotent: stops the server an earlier session left running, rebuilds the scratch DB from scratch.
set -euo pipefail
cd "$(dirname "$0")/.."

PORT=${PORT:-7791}
SCRATCH=/tmp/pathways-harness
DB=$SCRATCH/dev.db
PW=$SCRATCH/pw
mkdir -p "$SCRATCH"

[[ -d node_modules ]] || npm install --no-audit --no-fund
npm run check --silent > "$SCRATCH/check.log" 2>&1 \
  && echo "check: green ($(grep -E '^ℹ pass' "$SCRATCH/check.log" | awk '{print $3}') tests)" \
  || { echo "check: RED — see $SCRATCH/check.log"; tail -30 "$SCRATCH/check.log"; }

# Playwright stays outside the repo (zero runtime deps); Chromium is already in ~/.cache/ms-playwright.
[[ -d $PW/node_modules/playwright ]] || npm i --prefix "$PW" --no-audit --no-fund playwright@1 > /dev/null
ls ~/.cache/ms-playwright 2>/dev/null | grep -q '^chromium' || npx --prefix "$PW" playwright install chromium

if [[ -f $SCRATCH/server.pid ]]; then kill "$(cat "$SCRATCH/server.pid")" 2>/dev/null || true; sleep 0.5; fi
rm -f "$DB" "$DB-wal" "$DB-shm"
PATHWAYS_DB=$DB bin/pathways import samples/notes-sample.md > /dev/null
PATHWAYS_DB=$DB nohup bin/pathways serve --port "$PORT" --replay tests/fixtures/serato/399.session --speed 0 \
  > "$SCRATCH/server.log" 2>&1 &
echo $! > "$SCRATCH/server.pid"

for _ in $(seq 1 50); do curl -sf "http://localhost:$PORT/api/stats" > /dev/null && break; sleep 0.2; done
curl -sf "http://localhost:$PORT/api/stats" > /dev/null || { echo "server did not start — see $SCRATCH/server.log"; exit 1; }
echo "server: http://localhost:$PORT (editor) · http://localhost:$PORT/live · db $DB · log $SCRATCH/server.log"
echo "next: node harness/smoke.mjs"
