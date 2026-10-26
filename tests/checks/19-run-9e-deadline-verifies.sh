#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 9e: the deadline verifies a complete milestone once (R5) ----
# MAX_SESSIONS=2 ends the first segment at the cap with M1 complete and unverified; a continue past its deadline verifies it once
dl() {   # <run> <stub env for the deadline segment...>; DL_BEFORE=<command> runs between the segments, DL_UNTIL=<s> sets the deadline that far ahead
  mkdir -p "$HARNESS_STATE/proj/$1" && echo MAX_SESSIONS=2 > "$HARNESS_STATE/proj/$1/run.env"
  STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" "$1" --spec SPEC.md --foreground > "$T/$1-a.out" 2>&1
  { head -1 "$HARNESS_STATE/proj/$1/ended"; $F summary "$(list "$1")"; git -C "$T/origin.git" tag -l "run/$1/*"; } > "$T/$1-a.end"   # cap, 2/3, no tag
  eval "${DL_BEFORE:-}"
  env "${@:2}" "$H" continue "$1" --until-epoch $(( $(date +%s) + ${DL_UNTIL:--1} )) --foreground > "$T/$1-b.out" 2>&1; }
dl_status() {   # <run> <status line>: INBOX.md's first line, committed in the run's worktree as a pull from the phone leaves it
  sed -i "1s/.*/status: $2/" "$T/wt/proj/$1/.harness/runs/$1/INBOX.md" && git -C "$T/wt/proj/$1" commit -qam "phone: status: $2"; }
vcount_dl() { grep -c '^verify M1' "$T/scratch/proj/$1/sessions.log"; }
dl dlok STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1
check "the deadline verifies a complete milestone once and merges it" 'hlog dlok | grep -q "deadline reached: M1 complete but unverified; one verify before the end" \
  && hlog dlok | grep -q "M1 verified and tagged run/dlok/M1" && hlog dlok | grep -q "M1 merged into main" && on_main run/dlok/M1 \
  && grep -q "^deadline" "$HARNESS_STATE/proj/dlok/ended" && [[ $(vcount_dl dlok) == 1 ]] \
  && [[ $(sed 1s/\ ·.*// "$T/dlok-a.end") == "session cap (2)"$'"'"'\n'"'"'"2/3 passing" ]]'
dl dlstrict STUB_STRICT_VERIFIER=1 STUB_NO_TAMPER=1 STUB_NO_RED=1
check "a failed verify at the deadline is not retried: M1 needs Michael" 'hlog dlstrict | grep -q "verify M1: A failed the re-check in round 1 of 1; M1 needs Michael" \
  && grep -q "^deadline" "$HARNESS_STATE/proj/dlstrict/ended" && [[ $(vcount_dl dlstrict) == 1 ]] && ! git -C "$T/origin.git" rev-parse -q --verify refs/tags/run/dlstrict/M1 > /dev/null'
dl dlthin STUB_THIN_VERIFY=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1
check "thin evidence at the deadline is not escalated: one verify, M1 not verified" 'hlog dlthin | grep -q "after one verify at the deadline; not verified" \
  && grep -q "^deadline" "$HARNESS_STATE/proj/dlthin/ended" && [[ $(vcount_dl dlthin) == 1 ]] && ! git -C "$T/origin.git" rev-parse -q --verify refs/tags/run/dlthin/M1 > /dev/null'
DL_BEFORE='dl_status dlstop "stop going home"' dl dlstop STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1
check "a stop at the deadline comes first: no verify, M1 left for a continue" 'hlog dlstop | grep -q "deadline reached: M1 complete but unverified; stopped by Michael, so no verify before the end" \
  && ! hlog dlstop | grep -q "one verify before the end" && [[ $(vcount_dl dlstop) == 0 ]] && grep -q "^deadline" "$HARNESS_STATE/proj/dlstop/ended"'
DL_BEFORE='echo $(( $(date +%s) + 3600 )) > "$HARNESS_STATE/LIMIT_UNTIL"' dl dllimit STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1
rm -f "$HARNESS_STATE/LIMIT_UNTIL"
check "a usage-limit window at the deadline: no verify session to be refused, M1 left for a continue" 'hlog dllimit | grep -q "deadline reached: M1 complete but unverified; the usage limit holds until [0-9:]*, so no verify before the end" \
  && [[ $(vcount_dl dllimit) == 0 ]] && ! hlog dllimit | grep -q "refused" && grep -q "^deadline" "$HARNESS_STATE/proj/dllimit/ended"'
DL_BEFORE='dl_status dlpause pause' DL_UNTIL=20 dl dlpause STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1
check "a deadline while paused verifies a complete milestone once too" 'hlog dlpause | grep -q "deadline reached while paused" \
  && hlog dlpause | grep -q "deadline reached: M1 complete but unverified; one verify before the end" && on_main run/dlpause/M1 \
  && grep -q "^deadline (paused)" "$HARNESS_STATE/proj/dlpause/ended" && [[ $(vcount_dl dlpause) == 1 ]]'
rm -f "$HARNESS_STATE"/queue/*-continue-dl*.args   # the first segments' caps queued automatic continuations

suite_end
