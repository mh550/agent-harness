#!/usr/bin/env bash
# Stand-in for `curl` in tests: records each call in $STUB_DIR/curl.log (every argument on its own line, then a line
# "===") and posts nothing. STUB_CURL_FAIL=1: still records, then fails the way `curl --fail` does on an HTTP 500.
# STUB_CURL_SPY: a command run with the same arguments at the moment of the call (what did origin have by then?).
printf '%s\n' "$@" === >> "$STUB_DIR/curl.log"
[[ -n ${STUB_CURL_SPY:-} ]] && bash -c "$STUB_CURL_SPY" _ "$@"
[[ ${STUB_CURL_FAIL:-} == 1 ]] && { echo "curl: (22) The requested URL returned error: 500" >&2; exit 22; }
exit 0
