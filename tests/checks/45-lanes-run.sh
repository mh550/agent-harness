#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- lanes run (P1-04): lib/lane.sh runs each milestone as its own process; lib/driver.sh is the coordinator ----
# MAX_LANES=1 (the default): today's three-feature list, M1 (A, B) then M2 (C, no after: it waits on M1), one lane at a time
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" ln --spec SPEC.md --foreground > "$T/ln.out" 2>&1
S=$HARNESS_STATE/proj/ln R=$T/wt/proj/ln/.harness/runs/ln
at() { hlog ln | grep -n -m1 -F -- "$1" | cut -d: -f1; }   # the line of the first note containing $1
check "lanes run: MAX_LANES=1 ends done with M1 and M2 merged by two PRs" 'grep -q "^done" "$S/ended" && [[ $(grep -c "pr merge" "$T/gh.log") == 2 ]] \
  && on_main run/ln/M1 && on_main run/ln/M2 && [[ $($F summary "$R/feature_list.json") == "3/3 passing" ]]'
check "lanes run: each lane is noted opened in slot 0 and then closed, M1's before M2's" 'o1=$(at "· lane M1 opened (slot 0, port 7950, from ") c1=$(at "· lane M1 closed (M1 merged)")
  o2=$(at "· lane M2 opened (slot 0, port 7950, from ") c2=$(at "· lane M2 closed (M2 merged)"); [[ -n $o1 && -n $c1 && -n $o2 && -n $c2 ]] && (( o1 < c1 && c1 < o2 && o2 < c2 ))'
check "lanes run: every coding and verify row in metrics.jsonl carries its lane; the initializer and the retro none" \
  'jq -se "(map(select(.kind == \"coding\")) | length >= 3 and all(.lane == (if .feature == \"C\" then \"M2\" else \"M1\" end)))
    and (map(select(.kind == \"verify\")) | length >= 2 and all(.lane == .feature)) and (map(select(.kind == \"init\" or .kind == \"retro\")) | all(.lane == null))" "$R/metrics.jsonl" > /dev/null'
check "lanes run: harness/ln holds every entry; each lane wrote its exit line, closed by the coordinator" \
  '[[ $(git -C "$T/origin.git" show harness/ln:.harness/runs/ln/entries.jsonl | jq -s length) == $(grep -cE " (init|coding|verify) exit " "$S/run.log") ]] \
  && [[ $(cat "$S/lanes/M1/closed") == "0 M1 merged" && $(cat "$S/lanes/M2/closed") == "0 M2 merged" ]] && ! compgen -G "$S/lanes/*/pid" > /dev/null && ! compgen -G "$S/lanes/*/exit" > /dev/null'
check "lanes run: a lane's sessions, suites and services run in its own units (harness-<run>-<m>-s<n>, -check-<pid>, -svc)" \
  '( for m in M1 M2; do grep -qx -- "--unit=harness-ln-$m-s[0-9]*" "$T/systemd.log" && grep -qx -- "--unit=harness-ln-$m-check-[0-9]*" "$T/systemd.log" \
     && grep -qx -- "--unit=harness-ln-$m-svc" "$T/systemd.log" || exit 1; done ) && [[ $(grep -cx -- "--unit=harness-ln-s[0-9]*" "$T/systemd.log") == 2 ]]'   # the run's own: the initializer and the retro
check "lanes run: a lane's verify judges the copy against its own snapshot (no list repair, no failed repair note)" \
  '[[ -s $S/lanes/M2/before.json ]] && ! hlog ln | grep -q "reverted list edits beyond un-passing" && ! grep -q "ENOENT" "$T/ln.out"'
check "lanes run: finish leaves the run one worktree (the record's), no slot, and deletes the merged lanes' branches" \
  '[[ $(git -C "$T/proj" worktree list | grep -c "$T/wt/proj/") == 1 ]] && git -C "$T/proj" worktree list | grep -q "^$T/wt/proj/ln " && [[ ! -e $T/wt/proj/lanes ]] \
  && ! git -C "$T/origin.git" rev-parse -q --verify refs/heads/harness-lane/ln/M1 > /dev/null && ! git -C "$T/origin.git" rev-parse -q --verify refs/heads/harness-lane/ln/M2 > /dev/null \
  && ! git -C "$T/proj" rev-parse -q --verify refs/heads/harness-lane/ln/M1 > /dev/null'

# A feature in no milestone (the default lane, D7) builds first; M1 waits on it and opens on its code, as before lanes
# (review of P1, finding 4): M1's verified tag holds Z's work
STUB_DEFAULT_FEATURE=1 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" ld --spec SPEC.md --foreground > "$T/ld.out" 2>&1
check "lanes: a lane opened after the default lane's features pass starts on the default lane's code (M1's tag holds work-Z.txt)" \
  'hlog ld | grep -F "· lane default closed (default: every feature passes)" > /dev/null && git -C "$T/origin.git" cat-file -e run/ld/M1:work-Z.txt \
  && grep -q "^done" "$HARNESS_STATE/proj/ld/ended"'

# harness pause during A's first session (STUB_PAUSE=A touches PAUSE): the lane finishes that session and waits; the
# coordinator logs the pause once; nothing new starts until harness resume
STUB_PAUSE=A STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" lp --spec SPEC.md --foreground > "$T/lp.out" 2>&1 & LPP=$!
wait_for 120 eval 'hlog lp | grep "· services stopped (paused)$" > /dev/null'
sleep 3; lp_sessions=$(grep -c . "$T/scratch/proj/lp/sessions.log"); lp_lane=$(cat "$HARNESS_STATE/proj/lp/lanes/M1/pid" 2> /dev/null)   # sleep-ok: a negative (no session after the pause) over three polls
"$H" resume lp > /dev/null; wait "$LPP"
check "lanes pause: the lane finishes its session and waits (no new session), and the coordinator logs paused once" \
  '[[ $lp_sessions == 1 && -n $lp_lane ]] && [[ $(grep -c "^[0-9-]* [0-9:]* paused (INBOX.md status or harness pause)$" "$HARNESS_STATE/proj/lp/run.log") == 1 ]] \
  && grep -q "^done" "$HARNESS_STATE/proj/lp/ended" && [[ $($F summary "$(list lp)") == "3/3 passing" ]]'

# harness stop during a session: the lane stops after it, the run ends with every lane process gone and no slot left
rm -f "$T/slow-coding"
STUB_SLOW_CODING=3 STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" lst --spec SPEC.md --foreground > "$T/lst.out" 2>&1 & LSP=$!
wait_for 120 eval '[[ -e $T/slow-coding && -s $HARNESS_STATE/proj/lst/lanes/M1/pid ]]'   # up to 2 min: a loaded box
lst_lane=$(cat "$HARNESS_STATE/proj/lst/lanes/M1/pid" 2> /dev/null); "$H" stop lst > /dev/null; wait "$LSP"
check "lanes stop: harness stop ends the run with every lane process dead and no lanes/ directory left" \
  '[[ -n $lst_lane ]] && ! kill -0 "$lst_lane" 2> /dev/null && grep -q "^stopped by Michael" "$HARNESS_STATE/proj/lst/ended" \
  && ( for f in "$HARNESS_STATE"/proj/lst/lanes/*/pid; do [[ -f $f ]] || continue; ! kill -0 "$(cat "$f")" 2> /dev/null || exit 1; done ) && [[ ! -e $HARNESS_WORKTREES/proj/lanes ]] \
  && grep -q "· lane M1 closed (stopped)$" <(hlog lst) && git -C "$T/origin.git" rev-parse -q --verify refs/heads/harness-lane/lst/M1 > /dev/null'

suite_end
