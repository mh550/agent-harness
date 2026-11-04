#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- a notification body over the cap (lib/notify.sh): the report's and the INBOX question's evals are tests/unit/parked.test.mjs ----
( NTFY_URL=https://ntfy.example/t NTFY_TOKEN="" NOTIFY_CMD=""; log() { :; }; source "$HERE/../lib/notify.sh"; notify "long one" title="long one" body="$(head -c 4000 /dev/zero | tr '\0' x)" )
check "a body over the cap is trimmed"    'Bd=$(curl_body "Title: long one"); (( $(printf %s "$Bd" | wc -c) <= 3500 && $(printf %s "$Bd" | wc -c) > 3000 )) && [[ $Bd == *… ]]'

suite_end
