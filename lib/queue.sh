#!/usr/bin/env bash
# The queue runner (`harness queue start`, tmux session h-queue). Starts queued runs in order: at most
# MAX_PARALLEL_RUNS at a time (user config, re-read each poll; 1 = one after another), never while the box-wide usage-limit window is
# closed, none after the --until time, and one run per project at a time: an entry whose project already has a live
# run is held (it keeps its place) and the next entry for a free project goes first. Exits when the queue is empty and nothing it started is still running,
# when it is past --until with nothing running, on `harness queue stop`, or when the plan's 7-day window is past
# WEEKLY_STOP_AT (as the newest session reported it; what is queued stays queued). Every run it starts is marked with its id
# (<state>/runners, by `harness start`). Whichever way it exits, if it started a run it runs `harness gc <project>
# --all-merged --deps` for each project it started one in (output in runner.log), then starts `harness debrief`
# detached (setsid: a new runner replacing tmux h-queue doesn't kill it). The debrief covers every run since the last
# successful one, so a debrief that fails or is killed is caught up by the next one (or `harness debrief` by hand).
# Before each start with no run alive it runs lib/sync.sh (the live checkout level with origin, ledger pushed). Entries
# in queue/held/ (`harness queue park`) are skipped until unparked; the runner says how many at start-up.
#   queue.sh [<until epoch, 0 = none>]
set -uo pipefail
: "${HARNESS_HOME:?}"
STATE_ROOT=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness} Q=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness}/queue
UNTIL=${1:-0} POLL=${HARNESS_QUEUE_POLL:-30}
# shellcheck source=lib/config.sh
source "$HARNESS_HOME/lib/config.sh"; harness_config /nonexistent   # defaults + the user's config
# shellcheck source=lib/tmux.sh
source "$HARNESS_HOME/lib/tmux.sh"   # tmux_reap, as the runner exits
H=$HARNESS_HOME/bin/harness
mkdir -p "$Q/done"
log() { echo "$(date '+%F %T') $*" | tee -a "$Q/runner.log"; }
alive_count() { local d p n=0; for d in "$STATE_ROOT"/*/*/; do p=$(cat "$d/driver.pid" 2>/dev/null) && kill -0 "$p" 2>/dev/null && n=$(( n + 1 )); done; echo "$n"; }
# a project is busy while a run's driver or one of its lanes lives (a SIGKILLed driver's lane works on), as bin/harness
# project_busy has it: a start queued behind such a run must not start here at once
busy_projects() { local d p f; for d in "$STATE_ROOT"/*/*/; do
  p=$(cat "$d/driver.pid" 2>/dev/null) && kill -0 "$p" 2>/dev/null && { basename "$(dirname "$d")"; continue; }
  for f in "$d"lanes/*/pid; do p=$(cat "$f" 2>/dev/null) && [[ -n $p ]] && kill -0 "$p" 2>/dev/null \
    && tr '\0' ' ' < "/proc/$p/cmdline" 2> /dev/null | grep "lib/lane.sh" > /dev/null && { basename "$(dirname "$d")"; break; }; done; done; }
# An entry's project: start → the repo's directory name (what the state dir is named after); continue → its run's state dir.
entry_project() { local verb arg d; { read -r verb; read -r arg; } < "$1"
  if [[ $verb == start ]]; then basename "$arg"; else d=$(compgen -G "$STATE_ROOT/*/$arg" | head -1) && basename "$(dirname "$d")"; fi; }
# One block, parsed whole before it runs: lib/sync.sh may rewrite this file under the running loop.
{
echo $$ > "$Q/runner.pid"; trap 'rm -f "$Q/runner.pid"' EXIT
RID=$(date +%Y%m%d-%H%M%S)-$$ UP=$(date '+%F %T'); export HARNESS_RUNNER_ID=$RID
echo "$UP runner up · MAX_PARALLEL_RUNS=$MAX_PARALLEL_RUNS$( (( UNTIL )) && echo " · no new runs after $(date -d "@$UNTIL" '+%F %H:%M')") · id $RID" | tee -a "$Q/runner.log"
n=$(ls "$Q"/held/*.args 2> /dev/null | wc -l)
(( n )) && log "$n parked entr$( (( n == 1 )) && echo y || echo ies) skipped until unparked (harness queue list)"

while :; do
  # the config again each poll (it resets every key, then re-sources): a MAX_PARALLEL_RUNS edit applies without a
  # restart; lowering it only gates the next start, never a running run (decisions/2026-10-25-runner-config-reload)
  # One that is no plain whole number (2x, or 08: bash reads octal) keeps the old: `(( a >= 2x ))` fails, the loop
  # would fall through and start a run past the limit
  was=${MAX_PARALLEL_RUNS-}; harness_config /nonexistent
  if [[ ! ${MAX_PARALLEL_RUNS-} =~ ^(0|[1-9][0-9]*)$ ]]; then
    [[ $was =~ ^(0|[1-9][0-9]*)$ ]] || was=1   # bad since start-up too: the default
    [[ ${bad_max+set} && ${MAX_PARALLEL_RUNS-} == "$bad_max" ]] || log "MAX_PARALLEL_RUNS=${MAX_PARALLEL_RUNS-} in the config is not a whole number: keeping $was"
    bad_max=${MAX_PARALLEL_RUNS-} MAX_PARALLEL_RUNS=$was
  else
    unset bad_max; [[ $MAX_PARALLEL_RUNS != "$was" ]] && log "MAX_PARALLEL_RUNS $was → $MAX_PARALLEL_RUNS (config reloaded)"
  fi
  [[ -f $Q/STOP ]] && { rm -f "$Q/STOP"; log "stopped by harness queue stop"; break; }
  next="" held="" a=$(alive_count) now=$(date +%s) busy=$(busy_projects)
  for f in $(ls "$Q"/*.args 2>/dev/null | sort); do   # two runs on one repo would build conflicting PRs from the same base
    p=$(entry_project "$f"); [[ -n $p ]] && grep -qxF -- "$p" <<< "$busy" && { held+="${held:+, }$(basename "$f" .args) ($p)"; continue; }
    next=$f; break
  done
  [[ $held != "${last_held:-}" ]] && { [[ -n $held ]] && log "holding $held: that project has a run going"; last_held=$held; }
  # (an entry held by a lane alone, with no driver alive, is waited for: it starts when that lane ends)
  if [[ -z $next ]]; then (( a == 0 )) && [[ -z $held ]] && { log "queue empty, nothing running: done"; break; }; sleep "$POLL"; continue; fi
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
  (( a == 0 )) && log "$("$HARNESS_HOME/lib/sync.sh")"   # no driver alive: the live checkout may move under none
  mapfile -t args < "$next"; mv "$next" "$Q/done/$(date +%Y%m%d-%H%M%S)-$(basename "$next")"
  extra=(--now); [[ ${HARNESS_QUEUE_FOREGROUND:-} ]] && extra=(--foreground) || extra+=(--no-supervisor)
  (( UNTIL )) && extra+=(--until-epoch "$UNTIL")
  log "starting: harness ${args[*]}"
  "$H" "${args[@]}" "${extra[@]}" >> "$Q/runner.log" 2>&1 || log "failed: harness ${args[*]} (see above)"
  sleep "${HARNESS_QUEUE_SETTLE:-10}"   # let the new driver write its pid before counting again
done
rm -f "$Q/runner.pid"; trap - EXIT
# the sessions its runs (and any other project's) left once ended, before the debrief reads them (decisions/2026-10-25-tmux-reaper)
while IFS= read -r l; do log "$l"; done < <(tmux_reap 0 "$STATE_ROOT"/*/*/)
started=$(grep -lsx -- "$RID" "$STATE_ROOT"/*/*/runners | wc -l)
if (( started )); then
  # collect as it drains: each project it started a run in, before the debrief reads what is left; a gc that fails is
  # said and the debrief starts anyway. Nobody watches it: no git prompt, and a hang ends at HARNESS_GC_TIMEOUT (10m;
  # timeout kills the whole group, git's children too) (decisions/2026-10-25-runner-gc)
  while IFS= read -r pd; do
    nm=$(basename "$pd"); log "gc $nm: harness gc $pd --all-merged --deps"
    GIT_TERMINAL_PROMPT=0 timeout -k 10s "${HARNESS_GC_TIMEOUT:-10m}" "$H" gc "$pd" --all-merged --deps 2>&1 < /dev/null | while IFS= read -r l; do log "gc $nm: $l"; done
    rc=${PIPESTATUS[0]}; (( rc )) && log "gc $nm failed (exit $rc)"
  done < <(for f in $(grep -lsx -- "$RID" "$STATE_ROOT"/*/*/runners); do (unset PROJECT_DIR; source "$(dirname "$f")/meta.env" && echo "$PROJECT_DIR") 2> /dev/null; done | grep . | sort -u)
  log "runner down after starting $started run(s): harness debrief (detached; output in queue/debrief.out)"
  setsid -f "$H" debrief >> "$Q/debrief.out" 2>&1 < /dev/null
fi
exit
}
