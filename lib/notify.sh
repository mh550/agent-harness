# shellcheck shell=bash
# Usage: source lib/notify.sh; notify "<message>" [title=…] [body=…] [click=…] [actions=…] [priority=…] [tags=…] [kind=…] [feature=…] [since=…]
#        gh_url <path in the repo> [blob|edit]   (the GitHub URL of that file on $BRANCH or the current one, or nothing)
# Structured notifications (plan: docs/plans/2026-10-19-P1-notifications.md). With NTFY_URL set the harness posts to
# ntfy itself through ${HARNESS_CURL:-curl} and NOTIFY_CMD is not called; otherwise NOTIFY_CMD gets "$1" as it always
# has ("[<NOTIFY_TAG>] <message>") plus the fields as HARNESS_NOTIFY_*. Always returns 0: a notification never stops
# a run. Needs the caller's log (and note, where there is one) and NTFY_URL NTFY_TOKEN NOTIFY_CMD from lib/config.sh.
# The event hook (docs/plans/2026-11-07-A1-event-hook.md): kind= park|needs_michael|blocked|debrief with EVENT_URL set
# go to EVENT_URL as v1 event JSON first (lib/notify.mjs event); ntfy/NOTIFY_CMD only when that isn't a 2xx. No kind is
# other; feature= is the event's feature. Before the POST the event's context bundle is written to events/<id>/ by
# ${HARNESS_CONTEXT:-lib/context.sh} (RUN_ID's run, or every run since= for the debrief) and `context` names its
# context.json; a bundle that fails is a note and a null context (docs/plans/2026-11-07-A2-context-bundle.md §3.4).
NOTIFY_MJS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/notify.mjs
declare -F ask > /dev/null || ask() { local s=$1; shift; node "${NOTIFY_MJS%/*}/$s" "$@"; }   # a plain spawn; lib/record.sh's, sourced after this in a driver or lane, answers from its helper

notify() {
  local msg=${1-} kv k v title=harness body="" click="" actions="" priority="" tags="" kind=other feature="" since="" rc a
  shift
  [[ -n ${NOTIFY_TAG:-} ]] && msg="[$NOTIFY_TAG] $msg"
  for kv; do
    [[ $kv == *=* ]] || continue
    k=${kv%%=*} v=${kv#*=}
    [[ $k == body ]] || v=${v//[[:cntrl:]]/ }   # a why must not add a header, nor carry a byte ntfy refuses (400)
    case $k in
      title) [[ -n $v ]] && title=$v ;; body) body=$v ;; click) click=$v ;; actions) actions=$v ;;
      priority) priority=$v ;; tags) tags=$v ;; kind) [[ -n $v ]] && kind=$v ;; feature) feature=$v ;; since) since=$v ;;
    esac
  done
  [[ -n $body ]] && body=$(notify_trim "$body")
  case $kind in park|needs_michael|blocked|debrief) [[ -n ${EVENT_URL:-} ]] && notify_event && return 0 ;; esac   # 2xx: n8n tells Michael
  if [[ -n ${NTFY_URL:-} ]]; then
    # retries a 429/5xx; --retry-max-time keeps a hung ntfy from holding the run for minutes
    a=(-sS --fail --max-time 15 --retry 2 --retry-delay 3 --retry-max-time 20 -o /dev/null -H "Title: $title")
    [[ -n $priority ]] && a+=(-H "Priority: $priority")
    [[ -n $tags ]] && a+=(-H "Tags: $tags")
    [[ -n $click ]] && a+=(-H "Click: $click")
    [[ -n $actions ]] && a+=(-H "Actions: $actions")
    [[ -n ${NTFY_TOKEN:-} ]] && a+=(-H "Authorization: Bearer $NTFY_TOKEN")
    v=${body:-$(notify_trim "$msg")}; [[ $v == @* ]] && v=" $v"   # curl reads "@<file>" as a file to send
    "${HARNESS_CURL:-curl}" "${a[@]}" --data-binary "$v" "$NTFY_URL" < /dev/null > /dev/null 2>&1 8>&- 9>&-; rc=$?
    # neither line may carry the token, the URL or the body
    if (( rc == 0 )); then log "notified: $title"
    elif declare -F note > /dev/null; then note "notification failed (curl exit $rc): $title"
    else log "notification failed (curl exit $rc): $title"; fi
  elif [[ -n ${NOTIFY_CMD:-} ]]; then
    HARNESS_NOTIFY_TITLE=$title HARNESS_NOTIFY_BODY=$body HARNESS_NOTIFY_CLICK=$click HARNESS_NOTIFY_ACTIONS=$actions \
      HARNESS_NOTIFY_PRIORITY=$priority bash -c "$NOTIFY_CMD" _ "$msg" > /dev/null 2>&1 9>&-
  fi
  return 0
}

# notify's routed post, reading its locals: the event built in node, kept at <STATE_ROOT>/events/<id>/event.json and
# POSTed once (no --retry, no token: NTFY_TOKEN is ntfy's). 0: a 2xx took it; 1: noted, and notify's ntfy branch runs.
# Neither line carries EVENT_URL (it may hold a webhook secret) nor the body.
notify_event() {
  local ev id d code rc why E ctx="" out l sc=()
  # the bundle first, synchronous and capped (*default*, decisions/2026-10-22-context-bundle-glossary), so the path the
  # event names exists when n8n reads it; the event takes its id, so event.json lands beside it
  E=${HARNESS_STATE:-${XDG_STATE_HOME:-$HOME/.local/state}/harness}/events
  id=$(cat /proc/sys/kernel/random/uuid 2> /dev/null)
  if [[ -n $since ]]; then sc=(--since "$since"); elif [[ -n ${RUN_ID:-} ]]; then sc=("$RUN_ID"); fi
  if [[ -n $id ]] && (( ${#sc[@]} )) && out=$(timeout 60 "${HARNESS_CONTEXT:-${NOTIFY_MJS%/*}/context.sh}" "${sc[@]}" \
       --out "$E/$id" --id "$id" < /dev/null 2> /dev/null 8>&- 9>&-) && [[ ${out%%$'\n'*} == /* && -s ${out%%$'\n'*}/context.json ]]; then
    E=${out%%$'\n'*}; E=${E%/*} ctx=${out%%$'\n'*}/context.json   # the directory it printed: absolute, no // (n8n's path guard)
    while IFS= read -r l; do [[ $l == "events: removed "* ]] && notify_say "$l"; done <<< "$out"
  else notify_say "context bundle failed for $kind; event sent without it"; fi
  ev=$(ask notify.mjs event kind="$kind" run="${RUN_ID:-}" project="${PROJECT_NAME:-}" feature="$feature" title="$title" \
    body="${body:-$(notify_trim "$msg")}" priority="$priority" click="$click" actions="$actions" id="$id" context="$ctx" 2> /dev/null)
  id=$(jq -r '.id // empty' <<< "$ev" 2> /dev/null)
  if [[ -z $id ]]; then why="no event"   # ask and its spawn can both fail
  else
    d=$E/$id
    { mkdir -p "$d" && printf '%s\n' "$ev" > "$d/event.json"; } 2> /dev/null   # a record, not the delivery: best effort
    code=$("${HARNESS_CURL:-curl}" -s -o /dev/null -w '%{http_code}' --max-time "${EVENT_TIMEOUT:-5}" \
      -H "Content-Type: application/json" --data-binary "$ev" "$EVENT_URL" < /dev/null 2> /dev/null 8>&- 9>&-); rc=$?
    if (( rc == 0 )) && [[ $code =~ ^2[0-9][0-9]$ ]]; then log "event → n8n: $kind $id"; return 0; fi
    (( rc != 0 )) && why="curl exit $rc" || why=$code
  fi
  notify_say "event hook failed ($why): $kind; sent to ntfy"
  return 1
}
notify_say() { if declare -F note > /dev/null; then note "$1"; else log "$1"; fi; }   # the run's note, else the caller's log

# The 3500-byte cap (trimBody), without a node per post when the text already fits (text that fits is sent as-is:
# invalid UTF-8, which nothing the harness writes has, would reach ntfy unreplaced).
notify_trim() {
  local n; n=$(LC_ALL=C; echo "${#1}")
  if (( n <= 3500 )); then printf '%s' "$1"; else printf '%s' "$1" | node "$NOTIFY_MJS" trim 9>&-; fi
}

# remote.origin.url, not `git remote get-url`: that one returns the url.<…>.insteadOf rewrite (the suite's local origin).
gh_url() {
  local u; u=$(ask notify.mjs urls "$(git config --get remote.origin.url)" "${BRANCH:-$(git branch --show-current)}" "$1" 2> /dev/null) || return 0
  [[ ${2:-blob} == edit ]] && echo "${u#*$'\t'}" || echo "${u%%$'\t'*}"
}
