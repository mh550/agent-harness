#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 13c: a stale green marker (R4): verify runs the suite in full ----
# B leaves BROKEN with a green marker for that tree: the post-session check trusts it; verify clears it and runs in full.
# MAX_FIX_ROUNDS=0: the red is the card at once, as before fix rounds (90-fix-rounds has the rounds)
mkdir -p "$HARNESS_STATE/proj/stalegreen" && echo MAX_FIX_ROUNDS=0 > "$HARNESS_STATE/proj/stalegreen/run.env"
STUB_STALE_GREEN=B STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" stalegreen --spec SPEC.md --foreground > "$T/run13c.out" 2>&1
check "a stale green marker is caught at verify: M1 red, not tagged" 'hlog stalegreen | grep -q " · verify M1: suite cache cleared; the suite runs in full on the verified tree$" \
  && hlog stalegreen | grep -q " · verify M1: the suite is red on the verified tree (main had nothing new: a slow-tier red the fast gate let through); not verified (needs Michael)$" && [[ -z $(git -C "$T/origin.git" tag -l "run/stalegreen/M1") ]]'

suite_end
