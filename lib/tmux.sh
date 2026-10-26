# shellcheck shell=bash
# Run → tmux session, and the reaper of finished runs' sessions (decisions/2026-10-25-tmux-reaper). Sourced by
# bin/harness (start, attach, gc) and lib/queue.sh (as the runner exits).
#   tmux_name <run>                    → h-<run>, dots as dashes; always run → session, never session → run
#   tmux_reap <dry 0|1> <state dir>…   → kills h-<run> of each run that ended, has no live driver and no PAUSE; a line each
tmux_name() { echo "h-${1//./-}"; }
tmux_live() { local p; p=$(cat "$1/driver.pid" 2> /dev/null) && [[ -n $p ]] && kill -0 "$p" 2> /dev/null; }
tmux_done() { [[ -f $1/meta.env && -f $1/ended && ! -f $1/PAUSE ]] && ! tmux_live "$1"; }   # ended, no live driver, not paused
# a.b and a-b (or one id in two projects) share h-a-b: another run of the same session name that isn't done keeps it
# (TMUX_OTHER names it: cmd_start refuses such an id rather than kill that run's session)
tmux_shared() { local o r; for o in "$2"/*/*/; do o=${o%/} r=${o##*/}; [[ $o != "$1" && h-${r//./-} == "$3" ]] && ! tmux_done "$o" && [[ -f $o/meta.env ]] && { TMUX_OTHER=$o; return 0; }; done; return 1; }
tmux_reap() {
  local dry=$1 d r s c id; shift
  command -v tmux > /dev/null || return 0
  for d in "$@"; do
    d=${d%/} r=${d##*/}; s=$(tmux_name "$r")
    tmux_done "$d" || continue   # meta.env: a run's, not queue/done
    read -r id c < <(tmux display-message -p -t "=$s:" '#{session_id} #{session_created}' 2> /dev/null) && [[ $c =~ ^[0-9]+$ ]] || continue   # no such session
    tmux_shared "$d" "${d%/*/*}" "$s" && continue
    (( c > $(stat -c %Y "$d/ended" 2> /dev/null || echo 0) )) && continue   # created after the run ended: a resume's, its driver not up yet
    if (( dry )); then echo "would: tmux kill-session -t =$s ($r ended)"; continue; fi
    tmux_live "$d" || tmux_shared "$d" "${d%/*/*}" "$s" && continue   # re-checked just before the kill: a resume between the scan and here wins
    if tmux kill-session -t "$id" 2> /dev/null; then echo "+ reaped tmux session $s ($r ended)"   # by id: a resume's new h-<run> is another session
    else echo "! could not kill tmux session $s ($r ended)"; fi   # never fatal: the next run is still reaped
  done
  return 0
}
