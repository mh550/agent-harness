#!/usr/bin/env bash
# The queue runner (`harness queue start`, tmux session h-queue). Starts queued runs in order: at most
# MAX_PARALLEL_RUNS at a time (user config; 1 = one after another), never while the box-wide usage-limit window is
# closed, and none after the --until time. Exits when the queue is empty and nothing it started is still running.
#   queue.sh [<until epoch, 0 = none>]
set -uo pipefail
: "${HARNESS_HOME:?}"
STATE_ROOT=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness} Q=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness}/queue
UNTIL=${1:-0} POLL=${HARNESS_QUEUE_POLL:-30}
# shellcheck source=lib/config.sh
source "$HARNESS_HOME/lib/config.sh"; harness_config /nonexistent   # defaults + the user's config
H=$HARNESS_HOME/bin/harness
mkdir -p "$Q/done"
log() { echo "$(date '+%F %T') $*" | tee -a "$Q/runner.log"; }
alive_count() { local d p n=0; for d in "$STATE_ROOT"/*/*/; do p=$(cat "$d/driver.pid" 2>/dev/null) && kill -0 "$p" 2>/dev/null && n=$(( n + 1 )); done; echo "$n"; }
echo $$ > "$Q/runner.pid"; trap 'rm -f "$Q/runner.pid"' EXIT
log "runner up · MAX_PARALLEL_RUNS=$MAX_PARALLEL_RUNS$( (( UNTIL )) && echo " · no new runs after $(date -d "@$UNTIL" '+%F %H:%M')")"

while :; do
  [[ -f $Q/STOP ]] && { rm -f "$Q/STOP"; log "stopped by harness queue stop"; break; }
  next=$(ls "$Q"/*.args 2>/dev/null | sort | head -1) a=$(alive_count) now=$(date +%s)
  if [[ -z $next ]]; then (( a == 0 )) && { log "queue empty, nothing running: done"; break; }; sleep "$POLL"; continue; fi
  if (( UNTIL > 0 && now >= UNTIL )); then
    (( a == 0 )) && { log "past the --until time; $(ls "$Q"/*.args | wc -l) left queued"; break; }; sleep "$POLL"; continue
  fi
  (( a >= MAX_PARALLEL_RUNS )) && { sleep "$POLL"; continue; }
  upto=$(cat "$STATE_ROOT/LIMIT_UNTIL" 2>/dev/null || echo 0)
  if (( upto > now )); then
    log "usage-limit window closed until $(date -d "@$upto" '+%H:%M'); waiting"
    w=$(( upto - now )); (( w > 600 )) && w=600; sleep "${HARNESS_LIMIT_SLEEP:-$w}"; continue
  fi
  mapfile -t args < "$next"; mv "$next" "$Q/done/$(date +%Y%m%d-%H%M%S)-$(basename "$next")"
  extra=(--now); [[ ${HARNESS_QUEUE_FOREGROUND:-} ]] && extra=(--foreground) || extra+=(--no-supervisor)
  (( UNTIL )) && extra+=(--until-epoch "$UNTIL")
  log "starting: harness ${args[*]}"
  "$H" "${args[@]}" "${extra[@]}" >> "$Q/runner.log" 2>&1 || log "failed: harness ${args[*]} (see above)"
  sleep "${HARNESS_QUEUE_SETTLE:-10}"   # let the new driver write its pid before counting again
done
