#!/usr/bin/env bash
# Stand-in for `curl` in tests: records each call in $STUB_DIR/curl.log (every argument on its own line, then a line
# "===") and posts nothing. STUB_CURL_FAIL=1: still records, then fails the way `curl --fail` does on an HTTP 500.
# STUB_CURL_SPY: a command run with the same arguments at the moment of the call (what did origin have by then?).
# The event POST (lib/notify.sh's notify_event; the one call with a "Content-Type: application/json" argument) answers
# per STUB_EVENT instead, with real curl 8.5.0's bytes for `-s -o /dev/null -w '%{http_code}' --max-time` on loopback:
# unset or 200 → tests/fixtures/curl-event-200.out, exit 0; 500 → curl-event-500.out, exit 0 (no --fail);
# timeout → curl-event-timeout.out ("000"), exit 28, no sleep (-s without -S: real curl writes nothing on stderr).
printf '%s\n' "$@" === >> "$STUB_DIR/curl.log"
[[ -n ${STUB_CURL_SPY:-} ]] && bash -c "$STUB_CURL_SPY" _ "$@"
for a; do
  [[ $a == "Content-Type: application/json" ]] || continue
  f=$(dirname "$0")/fixtures/curl-event
  case ${STUB_EVENT:-200} in
    500) cat "$f-500.out"; exit 0 ;;
    timeout) cat "$f-timeout.out"; exit 28 ;;
    *) cat "$f-200.out"; exit 0 ;;
  esac
done
[[ ${STUB_CURL_FAIL:-} == 1 ]] && { echo "curl: (22) The requested URL returned error: 500" >&2; exit 22; }
exit 0
