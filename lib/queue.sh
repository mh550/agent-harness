#!/usr/bin/env bash
# The queue runner (`harness queue start`, tmux session h-queue). Starts queued runs in order: at most
# MAX_PARALLEL_RUNS at a time (user config; 1 = one after another), never while the box-wide usage-limit window is
# closed, none after the --until time, and one run per project at a time: an entry whose project already has a live
# run is held (it keeps its place) and the next entry for a free project goes first. Exits when the queue is empty and nothing it started is still running,
# when it is past --until with nothing running, on `harness queue stop`, or when the plan's 7-day window is past
# WEEKLY_STOP_AT (as the newest session reported it; what is queued stays queued). Every run it starts is marked with its id
# (<state>/runners, by `harness start`). Whichever way it exits, if it started a run it starts `harness debrief`
# detached (setsid: a new runner replacing tmux h-queue doesn't kill it). The debrief covers every run since the last
# successful one, so a debrief that fails or is killed is caught up by the next one (or `harness debrief` by hand).
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
busy_projects() { local d p; for d in "$STATE_ROOT"/*/*/; do p=$(cat "$d/driver.pid" 2>/dev/null) && kill -0 "$p" 2>/dev/null && basename "$(dirname "$d")"; done; }
# An entry's project: start → the repo's directory name (what the state dir is named after); continue → its run's state dir.
entry_project() { local verb arg d; { read -r verb; read -r arg; } < "$1"
  if [[ $verb == start ]]; then basename "$arg"; else d=$(compgen -G "$STATE_ROOT/*/$arg" | head -1) && basename "$(dirname "$d")"; fi; }
echo $$ > "$Q/runner.pid"; trap 'rm -f "$Q/runner.pid"' EXIT
RID=$(date +%Y%m%d-%H%M%S)-$$ UP=$(date '+%F %T'); export HARNESS_RUNNER_ID=$RID
echo "$UP runner up · MAX_PARALLEL_RUNS=$MAX_PARALLEL_RUNS$( (( UNTIL )) && echo " · no new runs after $(date -d "@$UNTIL" '+%F %H:%M')") · id $RID" | tee -a "$Q/runner.log"

while :; do
  [[ -f $Q/STOP ]] && { rm -f "$Q/STOP"; log "stopped by harness queue stop"; break; }
  next="" held="" a=$(alive_count) now=$(date +%s) busy=$(busy_projects)
  for f in $(ls "$Q"/*.args 2>/dev/null | sort); do   # two runs on one repo would build conflicting PRs from the same base
    p=$(entry_project "$f"); [[ -n $p ]] && grep -qxF -- "$p" <<< "$busy" && { held+="${held:+, }$(basename "$f" .args) ($p)"; continue; }
    next=$f; break
  done
  [[ $held != "${last_held:-}" ]] && { [[ -n $held ]] && log "holding $held: that project has a run going"; last_held=$held; }
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
  if why=$(weekly_over "$STATE_ROOT/USAGE_7D"); then   # days, not minutes: stop, leaving the queue for another night
    log "not starting runs: $why; $(ls "$Q"/*.args | wc -l) left queued"; break
  fi
  mapfile -t args < "$next"; mv "$next" "$Q/done/$(date +%Y%m%d-%H%M%S)-$(basename "$next")"
  extra=(--now); [[ ${HARNESS_QUEUE_FOREGROUND:-} ]] && extra=(--foreground) || extra+=(--no-supervisor)
  (( UNTIL )) && extra+=(--until-epoch "$UNTIL")
  log "starting: harness ${args[*]}"
  "$H" "${args[@]}" "${extra[@]}" >> "$Q/runner.log" 2>&1 || log "failed: harness ${args[*]} (see above)"
  sleep "${HARNESS_QUEUE_SETTLE:-10}"   # let the new driver write its pid before counting again
done
rm -f "$Q/runner.pid"; trap - EXIT
started=$(grep -lsx -- "$RID" "$STATE_ROOT"/*/*/runners | wc -l)
if (( started )); then
  log "runner down after starting $started run(s): harness debrief (detached; output in queue/debrief.out)"
  setsid -f "$H" debrief >> "$Q/debrief.out" 2>&1 < /dev/null
fi
