#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- a session's environment carries no TMUX (decisions/2026-11-10-session-env-no-tmux): the driver runs in a tmux pane
# and keeps TMUX/TMUX_PANE (its window's cleanup reads them); a session it or a lane starts gets neither, so a `tmux
# kill-server` in the session's shell can't reach the driver's server. A driver that gets a hangup anyway ends with a
# reason that names it and says what to do; the needs card carries the same words ----
export COLUMNS=200 HARNESS_GLYPHS=unicode
# the driver's environment is a pane's: TMUX names the suite's private server (a bogus path would only make tmux fail)
PANE_TMUX=$TMUX_TMPDIR/tmux-$(id -u)/default,0,0
rm -f "$T/slow-coding"
TMUX=$PANE_TMUX TMUX_PANE=%0 STUB_RECORD_ENV=1 STUB_SLOW_CODING=30 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 \
  "$H" start "$T/proj" hup --spec SPEC.md --foreground > "$T/hup.out" 2>&1 & HP=$!
wait_for 60 test -e "$T/slow-coding"
kill -HUP "$(cat "$HARNESS_STATE/proj/hup/driver.pid")"; wait "$HP"; HRC=$?
HS=$HARNESS_STATE/proj/hup
"$H" needs hup > "$T/hup-needs.out" 2>&1
HREF=$(jq -rs '.[] | select(.key == "driver_crash:run") | .ref' "$HS"/needs/*.json 2> /dev/null)
WHY="the driver got a hangup (its tmux server or terminal went away); state is kept: harness continue hup"
check "a session's environment carries no TMUX or TMUX_PANE while the driver's does (the initializer's and the coding session's recorded)" \
  'grep -q "^== # Initializer session" "$T/sessions.env" && grep -q "^== # Coding session" "$T/sessions.env" \
  && grep -qx "HARNESS_RUN_ID" "$T/sessions.env" && ! grep -qx "TMUX" "$T/sessions.env" && ! grep -qx "TMUX_PANE" "$T/sessions.env"'
check "a driver that gets a hangup ends with the hangup reason through the EXIT trap: ended, harness-log.md, exit 129" \
  '(( HRC == 129 )) && grep -qF "$WHY · $(date +%F)" "$HS/ended" && [[ ! -e $HS/driver.pid ]] && hlog hup | grep -qF "$WHY" \
  && grep -q "^12 lane exited unexpectedly" "$HS"/lanes/*/exit'
check "the hangup opens driver_crash whose card carries the hangup reason: headline, title and harness needs, needs.md committed" \
  '[[ -n $HREF && $HREF != hup/crash ]] && H=$(jq -s ".[] | select(.key == \"driver_crash:run\")" "$HS"/needs/*.json) \
  && [[ $(jq -r .card.headline <<< "$H") == "$WHY" && $(jq -r .title <<< "$H") == "[hup] ended: $WHY" ]] \
  && grep -qF "hup · $WHY" "$T/hup-needs.out" && grep -qF "$HREF" "$T/hup-needs.out" && jq -r .body <<< "$H" | grep -q "harness continue hup" \
  && [[ -z $(git -C "$T/wt/proj/hup" status --porcelain -- .harness/runs/hup/needs.md) ]] && grep -qF "$WHY" "$T/wt/proj/hup/.harness/runs/hup/needs.md"'
suite_end
