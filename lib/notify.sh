# shellcheck shell=bash
# Usage: source lib/notify.sh; notify "<message>" [title=…] [body=…] [click=…] [actions=…] [priority=…] [tags=…]
#        gh_url <path in the repo> [blob|edit]   (the GitHub URL of that file on $BRANCH or the current one, or nothing)
# Structured notifications (plan: docs/plans/2026-10-19-P1-notifications.md). With NTFY_URL set the harness posts to
# ntfy itself through ${HARNESS_CURL:-curl} and NOTIFY_CMD is not called; otherwise NOTIFY_CMD gets "$1" as it always
# has ("[<NOTIFY_TAG>] <message>") plus the fields as HARNESS_NOTIFY_*. Always returns 0: a notification never stops
# a run. Needs the caller's log (and note, where there is one) and NTFY_URL NTFY_TOKEN NOTIFY_CMD from lib/config.sh.
NOTIFY_MJS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/notify.mjs

notify() {
  local msg=${1-} kv k v title=harness body="" click="" actions="" priority="" tags="" rc a
  shift
  [[ -n ${NOTIFY_TAG:-} ]] && msg="[$NOTIFY_TAG] $msg"
  for kv; do
    [[ $kv == *=* ]] || continue
    k=${kv%%=*} v=${kv#*=}
    [[ $k == body ]] || v=${v//[[:cntrl:]]/ }   # a why must not add a header, nor carry a byte ntfy refuses (400)
    case $k in
      title) [[ -n $v ]] && title=$v ;; body) body=$v ;; click) click=$v ;; actions) actions=$v ;;
      priority) priority=$v ;; tags) tags=$v ;;
    esac
  done
  [[ -n $body ]] && body=$(notify_trim "$body")
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

# The 3500-byte cap (trimBody), without a node per post when the text already fits (text that fits is sent as-is:
# invalid UTF-8, which nothing the harness writes has, would reach ntfy unreplaced).
notify_trim() {
  local n; n=$(LC_ALL=C; echo "${#1}")
  if (( n <= 3500 )); then printf '%s' "$1"; else printf '%s' "$1" | node "$NOTIFY_MJS" trim 9>&-; fi
}

# remote.origin.url, not `git remote get-url`: that one returns the url.<…>.insteadOf rewrite (the suite's local origin).
gh_url() {
  local u; u=$(node "$NOTIFY_MJS" urls "$(git config --get remote.origin.url)" "${BRANCH:-$(git branch --show-current)}" "$1" 2> /dev/null) || return 0
  [[ ${2:-blob} == edit ]] && echo "${u#*$'\t'}" || echo "${u%%$'\t'*}"
}
