#!/usr/bin/env bash
# `harness desk`: a Remote Control claude session in tmux that briefs Michael on what a run needs and passes his answers on.
# Usage: desk.sh <run> [--why "<one line>"] | --debrief [--why "<one line>"]
# (plan: docs/plans/2026-10-19-P3-desk.md) 1. the prompt <state>/desk/<stamp>.md from prompts/desk.md; 2. one window per
# run (window <run> in tmux session ${HARNESS_DESK_SESSION:-h-desk}): an open desk gets "New since your last brief: …"
# typed in; otherwise a new window runs `claude --remote-control "desk · <run> · <why>"` in the project directory
# (trusted; the worktree goes in with --add-dir); 3. the session URL from the pane (≤ HARNESS_DESK_WAIT s); 4. types
# "Read <prompt> and follow it."; 5. notes it in the run record, notifies with the URL as the click, prints it.
# A desk that can't start (no URL in time, no tmux, the lock) is a note and the plain notification: exit 0 whenever
# Michael was told, so a caller never has to care. --debrief: window 'debrief' for the newest ledger/debrief.md.
set -uo pipefail
: "${HARNESS_HOME:?}"
STATE_ROOT=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness}
S=${HARNESS_DESK_SESSION:-h-desk} WAIT=${HARNESS_DESK_WAIT:-60} LEDGER=${HARNESS_LEDGER:-$HARNESS_HOME/ledger}

die() { echo "harness: $*" >&2; exit 1; }
usage() { echo 'usage: harness desk <run> [--why "<one line>"] | --debrief [--why "<one line>"]' >&2; exit 2; }
alive() { local p; p=$(cat "$1/driver.pid" 2>/dev/null) && [[ -n $p ]] && kill -0 "$p" 2>/dev/null; }

run="" why="" debrief=0
while (( $# )); do case $1 in
  --why) (( $# >= 2 )) || usage; why=$2; shift 2 ;;
  --debrief) debrief=1; shift ;;
  -*) usage ;;
  *) [[ -z $run ]] || usage; run=$1; shift ;;
esac; done
(( debrief )) && [[ -n $run ]] && usage
(( debrief )) || [[ -n $run ]] || usage
why=${why//[[:cntrl:]]/ }; why=$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<< "$why")   # one line: it goes into a title and a typed line
(( ${#why} > 200 )) && why="${why:0:199}…"

# shellcheck source=lib/config.sh
source "$HARNESS_HOME/lib/config.sh"
if (( debrief )); then   # no run record: the queue's dir and runner.log, the user config only, the harness checkout (trusted)
  RUN_ID=debrief WT="" RUN_DIR="" PROJECT_DIR=$HARNESS_HOME D=$STATE_ROOT/queue/desk mode=debrief other=run event="the debrief names what needs you"
  harness_config /nonexistent
  mkdir -p "$STATE_ROOT/queue"
  log() { echo "$(date '+%F %T') $*" >> "$STATE_ROOT/queue/runner.log"; }
  note() { log "$*"; }
else
  # the run id is checked as bin/harness's state_of does (compgen globs)
  [[ $run =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die "no run '$run' (run-id: letters, digits, . _ - only)"
  [[ $run == debrief || $run == desk ]] && die "no run desk for a run named '$run' (the debrief's window and state: harness desk --debrief)"
  st=$(compgen -G "$STATE_ROOT/*/$run" | head -1 || true)
  [[ -n $st && -f $st/meta.env ]] || die "no run '$run' (see: harness status)"
  # shellcheck source=/dev/null
  source "$st/meta.env"
  harness_config "$WT" "$STATE"   # a project may set DESK_MODEL
  RUN_DIR=$WT/.harness/runs/$RUN_ID D=$STATE/desk mode=run other=debrief event="a new event"
  log() { echo "$(date '+%F %T') $*" >> "$STATE/run.log"; }   # no tee: stdout is the URL
  note() { log "$*"; [[ -d $RUN_DIR ]] && echo "- $(date '+%F %H:%M') · $*" >> "$RUN_DIR/harness-log.md"; }
fi
# shellcheck source=lib/notify.sh
source "$HARNESS_HOME/lib/notify.sh"; NOTIFY_TAG=$RUN_ID
# the first call may start the tmux server: one that inherited a lock fd (ours, the driver's or debrief's 9) would hold
# it forever, and one that inherited NTFY_TOKEN would hand it to every later window
t() { env -u NTFY_TOKEN tmux "$@" 8>&- 9>&-; }
type_in() { t send-keys -t "$1" -l "$2" && sleep 0.5 && t send-keys -t "$1" Enter; }   # -l: literal text; Enter apart: a burst reads as a paste, its Enter a newline

# The notification, with the desk's URL as the click, or (no URL) the plain one: the INBOX on GitHub, if there is one.
tell() {
  local url=$1 click=$1 hand="harness parked" b=()
  [[ -z $url && -d $RUN_DIR ]] && click=$(cd "$WT" && gh_url ".harness/runs/$RUN_ID/INBOX.md")
  (( debrief )) || hand+=" $RUN_ID"
  [[ -n $why ]] && b+=("$why")
  (( debrief )) && b+=("Needs Michael: $LEDGER/debrief.md")
  [[ -n $url ]] && b+=("Open the desk: $url")
  b+=("Or by hand: $hand")
  notify "needs you${why:+: $why}" title="[$RUN_ID] needs you${why:+: $why}" priority=high tags=question click="$click" \
    body="$(printf '%s\n' "${b[@]}")"
}
# A run whose driver is gone: commit the note now so the worktree stays clean for gc (a live driver's next commit takes it).
commit_record() {
  [[ -d $RUN_DIR ]] && ! alive "$STATE" || return 0
  local f=.harness/runs/$RUN_ID/harness-log.md n ok=0
  for n in 1 2 3; do   # a desk start that missed the lock may meet the holder's commit (index.lock)
    git -C "$WT" add -- "$f" 2> /dev/null && git -C "$WT" commit -q -m "HARNESS: desk" -- "$f" > /dev/null 2>&1 && { ok=1; break; }; sleep 1
  done
  if (( ok )); then
    git -C "$WT" symbolic-ref -q HEAD > /dev/null && { git -C "$WT" push -q origin HEAD > /dev/null 2>&1 || log "desk: push failed (the commit stays local)"; }
  else log "desk: could not commit $f"; fi
}
plain() {   # <why there is no desk>
  exec 8>&-
  note "desk: $1; plain notification"; tell ""; commit_record
  [[ -n $NTFY_URL$NOTIFY_CMD ]] && set -- "$1; notified" || set -- "$1; no NTFY_URL or NOTIFY_CMD: nobody was told"
  echo "no desk ($1)" >&2; exit 0
}
finish() {   # <url> <note>
  exec 8>&-
  note "$2"; tell "$1"; commit_record; echo "$1"; exit 0
}

command -v tmux > /dev/null || plain "tmux not found"
claude=$(command -v "${HARNESS_CLAUDE:-claude}") || plain "${HARNESS_CLAUDE:-claude} not found"   # the pane's PATH is the tmux server's
model=$(node "$HARNESS_HOME/lib/features.mjs" model "$DESK_MODEL") && [[ -n $model ]] || plain "no model id for DESK_MODEL=$DESK_MODEL"

exec 8> "$STATE_ROOT/desk.lock"   # two drivers may start desks at once: both would try new-session
flock -w $(( WAIT + 10 )) 8 || plain "another desk start held the lock"

mkdir -p "$D"
stamp=$(date +%Y%m%d-%H%M%S) P="" i=1
P=$D/$stamp.md; while [[ -e $P ]]; do i=$(( i + 1 )); P=$D/$stamp-$i.md; done   # two events in one second keep both
# no secret is a variable here: render fills only HARNESS_* names, and the template names none of the config's
HARNESS_RUN_ID=$RUN_ID HARNESS_WHY=${why:-$event} HARNESS_EVENT_AT=$(date '+%F %H:%M') HARNESS_INBOX=${RUN_DIR:+$RUN_DIR/INBOX.md} \
  HARNESS_PROGRESS=${RUN_DIR:+$RUN_DIR/progress.md} HARNESS_BIN=$HARNESS_HOME/bin/harness HARNESS_NOTE=$LEDGER/debrief.md \
  node "$HARNESS_HOME/lib/render.mjs" "$HARNESS_HOME/prompts/desk.md" \
  | sed "/^<!-- $other -->\$/,/^<!-- \/$other -->\$/d; /^<!-- \/\{0,1\}$mode -->\$/d" > "$P" || plain "could not write $P"
date +%s > "$D/last-event"

# One desk per run: an open one (named $RUN_ID, its claude alive, a URL kept) gets the new event typed in. Any other
# window of that name (dead, or never showed a URL) goes. Every target is the window id @N (= : exact session).
url=$(cat "$D/url" 2> /dev/null) id=""
while IFS=$'\t' read -r w dead; do
  if [[ -z $id && $dead == 0 && -n $url ]]; then id=$w; else t kill-window -t "$w" 2> /dev/null; fi
done < <(t list-windows -t "=$S" -F '#{window_id}'$'\t''#{window_name}'$'\t''#{pane_dead}' 2> /dev/null | awk -F '\t' -v w="$RUN_ID" '$2 == w { print $1 "\t" $3 }')
if [[ -n $id ]]; then
  type_in "$id" "New since your last brief: ${why:-$event}. Re-read $P." \
    && finish "$url" "desk: sent to the open desk: $url${why:+ ($why)}"
  t kill-window -t "$id" 2> /dev/null; log "desk: could not type into the open desk; starting a new one"   # it went meanwhile
fi
rm -f "$D/url"

# tmux runs the command directly (separate arguments, no shell) in its server's environment, not ours: pass the
# harness overrides on, unset the ones we don't have (a server an earlier call started must not leak them), and
# never the ntfy token (a pane's environment is visible to ps). env reads every -u before the first NAME=value.
unset_=(-u NTFY_TOKEN) set_=()
for v in HARNESS_STATE HARNESS_WORKTREES HARNESS_CONFIG HARNESS_LEDGER HARNESS_CLAUDE HARNESS_GH HARNESS_CURL STUB_DIR STUB_DESK_NO_URL; do
  if [[ -n ${!v+x} ]]; then set_+=("$v=${!v}"); else unset_+=(-u "$v"); fi
done
name="desk · $RUN_ID${why:+ · $why}"; (( debrief )) && name="desk · debrief"
cmd=(env "${unset_[@]}" "${set_[@]}" "$claude" --remote-control "$name" --model "$model")
if (( debrief )); then   # the runs the note names, and the ledger when it lives outside the harness checkout
  [[ -d ${HARNESS_WORKTREES:-$HOME/worktrees} ]] && cmd+=(--add-dir "${HARNESS_WORKTREES:-$HOME/worktrees}")
  [[ $LEDGER != "$HARNESS_HOME"/* && -d $LEDGER ]] && cmd+=(--add-dir "$LEDGER")
elif [[ -d $WT ]]; then cmd+=(--add-dir "$WT")   # a gc'd run's desk can still read the state and the ledger
fi

if t has-session -t "=$S" 2> /dev/null; then
  id=$(t new-window -d -t "=$S:" -n "$RUN_ID" -c "$PROJECT_DIR" -P -F '#{window_id}' -- "${cmd[@]}")
  [[ $id == @* ]] && t resize-window -t "$id" -x 250 -y 50 2> /dev/null   # a narrow client's size: the TUI would cut the URL itself, -J can't rejoin that
else
  id=$(t new-session -d -s "$S" -n "$RUN_ID" -c "$PROJECT_DIR" -x 250 -y 50 -P -F '#{window_id}' -- "${cmd[@]}")
fi
[[ $id == @* ]] || plain "tmux could not open window $RUN_ID in $S"

URL=""
for (( i = 0; i < WAIT; i++ )); do
  # -S -: the scrollback too (the line may have scrolled by); -J: wrapped lines joined
  URL=$(t capture-pane -p -J -S - -t "$id" 2> /dev/null | grep -oE 'https://claude\.ai/code/session_[A-Za-z0-9]+' | tail -1)
  [[ -n $URL ]] && break
  [[ $(t display-message -p -t "$id" '#{pane_dead}' 2> /dev/null) == 0 ]] || break   # claude exited (window gone, or dead under remain-on-exit)
  sleep 1
done
if [[ -z $URL ]]; then
  gone="no session URL within $WAIT s"; [[ $(t display-message -p -t "$id" '#{pane_dead}' 2> /dev/null) == 0 ]] || gone="claude exited before it showed a session URL"
  t kill-window -t "$id" 2> /dev/null; plain "$gone; killed the window"
fi
echo "$URL" > "$D/url"
sleep 1   # the TUI takes input once it is drawn
type_in "$id" "Read $P and follow it."
finish "$URL" "desk started: $URL${why:+ ($why)}"
