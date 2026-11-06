#!/usr/bin/env bash
# tier: fast
source "$(dirname "$0")/../lib.sh" && suite_setup
# A section of the queue and debrief file (tests/checks/queue-debrief.sh) until the shape cut it out
# (decisions/2026-11-05-suite-shape): it reads no run of that file, so it needs no replay. What it had there, and has here:
# the plain user config, and has_s (the queue section's one-liner).
echo 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"
has_s() { tmux has-session -t "=$1" 2> /dev/null; }
# ---- tmux (L3-04): harness gc reaps the sessions of its project's ended runs, run → session, never the other way ----
# sessions first, then the markers: a session created after its run ended stands for a resume's (fresh), spared
RS="h-gone1 h-gone2 h-livey h-pausy h-pausx h-fresh h-held-x h-queue h-odone"   # held.x (ended) shares h-held-x with held-x (live, other project); odone: another project's ended run
for s in $RS; do tmux new-session -d -s "$s" sleep 600; done   # sleep-ok: stand-in sessions
has_s "$HARNESS_DESK_SESSION" || tmux new-session -d -s "$HARNESS_DESK_SESSION" sleep 600   # sleep-ok: a stand-in desk session
for r in gone1 gone2 livey pausy pausx fresh held.x; do mkdir -p "$HARNESS_STATE/proj/$r" && : > "$HARNESS_STATE/proj/$r/meta.env"; done
mkdir -p "$HARNESS_STATE/other/held-x" && : > "$HARNESS_STATE/other/held-x/meta.env" && echo $$ > "$HARNESS_STATE/other/held-x/driver.pid"
mkdir -p "$HARNESS_STATE/other/odone" && : > "$HARNESS_STATE/other/odone/meta.env" && echo done > "$HARNESS_STATE/other/odone/ended"
true & tp=$!; wait "$tp"; echo "$tp" > "$HARNESS_STATE/proj/gone2/driver.pid"; echo $$ > "$HARNESS_STATE/proj/livey/driver.pid"
echo done | tee "$HARNESS_STATE/proj/"{gone1,gone2,livey,pausx,held.x}/ended > /dev/null
touch "$HARNESS_STATE/proj/"{pausy,pausx}/PAUSE; echo done > "$HARNESS_STATE/proj/fresh/ended"; touch -d '1 hour ago' "$HARNESS_STATE/proj/fresh/ended"
all_s() { local s; for s in $RS "$HARNESS_DESK_SESSION"; do has_s "$s" || return 1; done; }
"$H" gc "$T/proj" --dry-run > "$T/gcr-dry.out" 2>&1; gcr_dry_all=$(all_s && echo yes)
"$H" gc "$T/proj" > "$T/gcr.out" 2>&1
check "harness gc --dry-run kills no tmux session" '[[ $gcr_dry_all == yes ]] && grep -qxF "would: tmux kill-session -t =h-gone1 (gone1 ended)" "$T/gcr-dry.out" \
  && grep -qxF "would: tmux kill-session -t =h-gone2 (gone2 ended)" "$T/gcr-dry.out" && [[ $(grep -c "tmux kill-session" "$T/gcr-dry.out") == 2 ]]'
check "harness gc reaps only the ended runs' tmux sessions (h-queue, the desk, a live driver, a paused run, a resume's session, a live run sharing the name survive)" '! has_s h-gone1 && ! has_s h-gone2 \
  && grep -qxF "+ reaped tmux session h-gone1 (gone1 ended)" "$T/gcr.out" && grep -qxF "+ reaped tmux session h-gone2 (gone2 ended)" "$T/gcr.out" && [[ $(grep -c "tmux session" "$T/gcr.out") == 2 ]] \
  && RS="h-livey h-pausy h-pausx h-fresh h-held-x h-queue h-odone" all_s \
  && ! "$H" start "$T/proj" queue --spec SPEC.md --foreground 2> "$T/gcr-q.err" && grep -q "run-id .queue. is taken by the queue runner" "$T/gcr-q.err"'
# L3-05 review: a start never kills another live run's session (a-b vs a.b, or one id in two projects); h-queue and attach are exact targets
"$H" start "$T/proj" held-x --foreground > "$T/coll.out" 2>&1; coll_rc=$?
mkdir -p "$T/tmuxlog" && printf '#!/usr/bin/env bash\necho "$*" >> %q\n' "$T/tmux-calls" > "$T/tmuxlog/tmux" && chmod +x "$T/tmuxlog/tmux"
PATH=$T/tmuxlog:$PATH HARNESS_NO_RUNNER= "$H" queue start > /dev/null 2>&1; PATH=$T/tmuxlog:$PATH "$H" attach proj-x > /dev/null 2>&1
check "harness start refuses a run id whose tmux session another live run holds; its session lives" '(( coll_rc )) && has_s h-held-x \
  && grep -qF "run id held-x shares tmux session h-held-x with $HARNESS_STATE/other/held-x, which has not ended" "$T/coll.out" && [[ ! -e $HARNESS_WORKTREES/proj/held-x ]]'
check "the queue runner and attach target their tmux sessions exactly (=h-queue, =h-<run>), never by prefix" 'grep -qxF "has-session -t =h-queue" "$T/tmux-calls" \
  && grep -qxF "kill-session -t =h-queue" "$T/tmux-calls" && grep -qxF "attach -t =h-proj-x" "$T/tmux-calls" && ! grep -qE -- "-t h-" "$T/tmux-calls"'
for s in $RS; do tmux kill-session -t "=$s" 2> /dev/null; done
rm -rf "$HARNESS_STATE/proj/"{gone1,gone2,livey,pausy,pausx,fresh,held.x} "$HARNESS_STATE/other/held-x" "$HARNESS_STATE/other/odone"   # livey and held-x name the suite's own pid: alive_count would count it

suite_end
