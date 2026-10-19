#!/usr/bin/env bash
# `harness desk`: a Remote Control claude session in tmux that briefs Michael on what a run needs and passes his answers on.
# Usage: desk.sh <run> [--why "<one line>"]
# (plan: docs/plans/2026-10-19-P3-desk.md) 1. the prompt <state>/desk/<stamp>.md from prompts/desk.md; 2. window <run>
# in tmux session ${HARNESS_DESK_SESSION:-h-desk} runs `claude --remote-control "desk · <run> · <why>"` in the project
# directory (trusted; the worktree goes in with --add-dir); 3. the session URL from the pane (≤ HARNESS_DESK_WAIT s);
# 4. types "Read <prompt> and follow it."; 5. notes it in the run record, notifies with the URL as the click, prints it.
set -uo pipefail
: "${HARNESS_HOME:?}"
STATE_ROOT=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness}
S=${HARNESS_DESK_SESSION:-h-desk} WAIT=${HARNESS_DESK_WAIT:-60} LEDGER=${HARNESS_LEDGER:-$HARNESS_HOME/ledger}

die() { echo "harness: $*" >&2; exit 1; }
usage() { echo 'usage: harness desk <run> [--why "<one line>"]' >&2; exit 2; }
alive() { local p; p=$(cat "$1/driver.pid" 2>/dev/null) && [[ -n $p ]] && kill -0 "$p" 2>/dev/null; }

run="" why=""
while (( $# )); do case $1 in
  --why) (( $# >= 2 )) || usage; why=$2; shift 2 ;;
  -*) usage ;;
  *) [[ -z $run ]] || usage; run=$1; shift ;;
esac; done
[[ -n $run ]] || usage
# the run id is checked as bin/harness's state_of does (compgen globs)
[[ $run =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]] || die "no run '$run' (run-id: letters, digits, . _ - only)"
[[ $run == debrief ]] && die "no run desk for a run named 'debrief' (that window is the debrief's)"
st=$(compgen -G "$STATE_ROOT/*/$run" | head -1 || true)
[[ -n $st && -f $st/meta.env ]] || die "no run '$run' (see: harness status)"
why=${why//[[:cntrl:]]/ }; why=$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<< "$why")   # one line: it goes into a title and a typed line
(( ${#why} > 200 )) && why="${why:0:199}…"

# shellcheck source=/dev/null
source "$st/meta.env"
# shellcheck source=lib/config.sh
source "$HARNESS_HOME/lib/config.sh"; harness_config "$WT" "$STATE"   # a project may set DESK_MODEL
# shellcheck source=lib/notify.sh
source "$HARNESS_HOME/lib/notify.sh"; NOTIFY_TAG=$RUN_ID
RUN_DIR=$WT/.harness/runs/$RUN_ID D=$STATE/desk
log() { echo "$(date '+%F %T') $*" >> "$STATE/run.log"; }   # no tee: stdout is the URL
note() { log "$*"; [[ -d $RUN_DIR ]] && echo "- $(date '+%F %H:%M') · $*" >> "$RUN_DIR/harness-log.md"; }
fail() { log "desk: $1"; echo "no desk ($1)" >&2; exit 1; }
t() { tmux "$@" 8>&- 9>&-; }   # the first call may start the tmux server: one that inherited a lock fd (ours, the driver's or debrief's 9) would hold it forever

command -v tmux > /dev/null || fail "tmux not found"
claude=$(command -v "${HARNESS_CLAUDE:-claude}") || fail "${HARNESS_CLAUDE:-claude} not found"   # the pane's PATH is the tmux server's
model=$(node "$HARNESS_HOME/lib/features.mjs" model "$DESK_MODEL") && [[ -n $model ]] || fail "no model id for DESK_MODEL=$DESK_MODEL"

exec 8> "$STATE_ROOT/desk.lock"   # two drivers may start desks at once: both would try new-session
flock -w $(( WAIT + 10 )) 8 || fail "another desk start held the lock"

mkdir -p "$D"
stamp=$(date +%Y%m%d-%H%M%S) P="" i=1
P=$D/$stamp.md; while [[ -e $P ]]; do i=$(( i + 1 )); P=$D/$stamp-$i.md; done   # two events in one second keep both
# no secret is a variable here: render fills only HARNESS_* names, and the template names none of the config's
HARNESS_RUN_ID=$RUN_ID HARNESS_WHY=${why:-a new event} HARNESS_EVENT_AT=$(date '+%F %H:%M') HARNESS_INBOX=$RUN_DIR/INBOX.md \
  HARNESS_PROGRESS=$RUN_DIR/progress.md HARNESS_BIN=$HARNESS_HOME/bin/harness HARNESS_NOTE=$LEDGER/debrief.md \
  node "$HARNESS_HOME/lib/render.mjs" "$HARNESS_HOME/prompts/desk.md" \
  | sed '/^<!-- debrief -->$/,/^<!-- \/debrief -->$/d; /^<!-- \/\{0,1\}run -->$/d' > "$P" || fail "could not write $P"
date +%s > "$D/last-event"

# tmux runs the command directly (separate arguments, no shell) in its server's environment, not ours: pass the
# harness overrides on, unset the ones we don't have (a server an earlier call started must not leak them), and
# never the ntfy token (a pane's environment is visible to ps). env reads every -u before the first NAME=value.
unset_=(-u NTFY_TOKEN) set_=()
for v in HARNESS_STATE HARNESS_WORKTREES HARNESS_CONFIG HARNESS_LEDGER HARNESS_CLAUDE HARNESS_GH HARNESS_CURL STUB_DIR STUB_DESK_NO_URL; do
  if [[ -n ${!v+x} ]]; then set_+=("$v=${!v}"); else unset_+=(-u "$v"); fi
done
name="desk · $RUN_ID${why:+ · $why}"
cmd=(env "${unset_[@]}" "${set_[@]}" "$claude" --remote-control "$name" --model "$model")
[[ -d $WT ]] && cmd+=(--add-dir "$WT")   # a gc'd run's desk can still read the state and the ledger

# every target after this is the window id @N: dots, prefixes and look-alike names never matter (= : exact session)
if t has-session -t "=$S" 2> /dev/null; then
  id=$(t new-window -d -t "=$S:" -n "$RUN_ID" -c "$PROJECT_DIR" -P -F '#{window_id}' -- "${cmd[@]}")
  [[ $id == @* ]] && t resize-window -t "$id" -x 250 -y 50 2> /dev/null   # a narrow client's size: the TUI would cut the URL itself, -J can't rejoin that
else
  id=$(t new-session -d -s "$S" -n "$RUN_ID" -c "$PROJECT_DIR" -x 250 -y 50 -P -F '#{window_id}' -- "${cmd[@]}")
fi
[[ $id == @* ]] || fail "tmux could not open window $RUN_ID in $S"

URL=""
for (( i = 0; i < WAIT; i++ )); do
  # -S -: the scrollback too (the line may have scrolled by); -J: wrapped lines joined
  URL=$(t capture-pane -p -J -S - -t "$id" 2> /dev/null | grep -oE 'https://claude\.ai/code/session_[A-Za-z0-9]+' | tail -1)
  [[ -n $URL ]] && break
  t list-windows -t "=$S" -F '#{window_id}' 2> /dev/null | grep -qxF "$id" || break   # claude exited: no point waiting
  sleep 1
done
[[ -n $URL ]] || { t kill-window -t "$id" 2> /dev/null; fail "no session URL within $WAIT s; killed the window"; }
echo "$URL" > "$D/url"
sleep 1   # the TUI takes input once it is drawn
# -l: literal text, no key names; Enter on its own submits it like typed input
t send-keys -t "$id" -l "Read $P and follow it."; sleep 0.5; t send-keys -t "$id" Enter   # apart: a burst reads as a paste, its Enter a newline
exec 8>&-

note "desk started: $URL${why:+ ($why)}"
notify "needs you${why:+: $why}" title="[$RUN_ID] needs you${why:+: $why}" priority=high tags=question click="$URL" \
  body="${why:+$why$'\n'}Open the desk: $URL"$'\n'"Or by hand: harness parked $RUN_ID"
# a run whose driver is gone: commit the line now so the worktree stays clean for gc (a live driver's next commit takes it)
if [[ -d $RUN_DIR ]] && ! alive "$STATE"; then
  f=.harness/runs/$RUN_ID/harness-log.md
  if git -C "$WT" add -- "$f" && git -C "$WT" commit -q -m "HARNESS: desk" -- "$f" > /dev/null; then
    git -C "$WT" symbolic-ref -q HEAD > /dev/null && { git -C "$WT" push -q origin HEAD > /dev/null 2>&1 || log "desk: push failed (the commit stays local)"; }
  else log "desk: could not commit $f"; fi
fi
echo "$URL"
