# shellcheck shell=bash
# Configuration, in layers (later wins):
#   1. harness defaults (below)
#   2. the user's config: ${HARNESS_CONFIG:-~/.config/harness/config.sh} (models, limits, merge policy, queue width, notify)
#   3. the project's .harness/config.sh (optional: POLICY plus real overrides)
#   4. the run's overrides: <state>/run.env (written by `harness start --spec/--until`)
#   5. conventions for anything still unset: the suite, the smoke check and the init script are detected in the repo
# Usage: source lib/config.sh; harness_config <worktree> [<state dir>]

harness_config() {
  local wt=$1 st=${2:-} f
  HOURS=8 MAX_SESSIONS=auto MAX_ATTEMPTS=2 MAX_REPAIRS=3 MAX_VERIFY_ROUNDS=2 MAX_LIMIT_HITS=6
  LIMIT_WAITS="900 1800 3600" SESSION_TIMEOUT=100m MAX_TURNS=250 SESSION_BUDGET_USD=20
  SESSION_MEMORY_HIGH=5G SESSION_MEMORY_MAX=6G SESSION_SWAP_MAX=1G   # each session's scope (lib/scope.sh): throttle, kill, swap
  CHECK_KEY_IGNORE=".harness/runs docs/plans"   # path prefixes left out of the suite cache key (lib/treekey.mjs): a plan alone doesn't rerun the suite
  CHECK_MEMORY_MAX=3G CHECK_TIMEOUT=15m   # each check.sh run's scope (no MemoryHigh: a runaway test dies, not crawls) and its timeout -k 30s
  INIT_TIMEOUT=10m SVC_MEMORY_MAX=3G   # run_init: timeout -k 10s around the init's foreground; its services scope's MemoryMax
  TMUX_KEEP_HOURS=24   # a tmux-started run's session stays this many whole hours after its driver exits (0: closes at once)
  DEPS_DIRS="node_modules .next .next-check .venv"   # `harness gc --deps` deletes these in the worktrees of ended runs
  KEEP_SCRATCH=0   # 1: finish keeps the run's scratch directory (debugging); 0: it goes, check-last.out and init.out kept in the state dir
  TEARDOWN_CMD=""   # services_down runs it before stopping the services scope (empty: .harness/teardown.sh when executable)
  SVC_IDLE_STOP_MIN=10   # limit_wait stops the services before a usage-limit wait of more than this many minutes
  MEM_MIN_AVAILABLE_GB=5 MEM_WAIT_MAX=30m   # mem_gate before each session: under this much MemAvailable, wait up to this long, then start anyway
  INIT_MODEL=fable WORKER_MODEL=opus VERIFY_MODEL=sonnet VERIFY_ESCALATE_MODEL=opus RETRO_MODEL=sonnet SUPERVISOR_MODEL=opus
  REVIEW_OPUS_LINES=400 REVIEW_ESCALATE_MODEL=opus   # a review feature: sonnet under this many changed lines, opus at or over (M6)
  DEBRIEF_MODEL=sonnet   # `harness debrief`: one read-only session after a queue (40 turns, $3 cap, like the retro)
  POLICY=build-only MERGE_POLICY=pr MAIN_BRANCH=main RETRO=1 AUTO_CONTINUE=1   # MERGE_POLICY=pr: a project self-merges only by setting auto
  MAX_PARALLEL_RUNS=1 LEDGER_COMMIT=1 BASE_PORT=7800 DEADLINE_AT=0
  # Lanes (docs/specs/2026-10-26-lanes.md): one process per open milestone, each in its own slot worktree
  MAX_LANES=1   # milestones built at once in one run; 1 = one after another (the box's memory decides any more)
  LANE_RESERVE_GB=4   # a further lane opens only with MEM_MIN_AVAILABLE_GB + this many GB per lane already open
  LANE_OPEN_BELOW_5H=70   # % of the 5-hour window: past it no further lane opens (the open ones would hit the limit sooner)
  LANE_REBASE=suite   # main moved under a verified lane: disjoint files re-tag on a green suite; verify = a verify session every time
  MAX_REBASE_ROUNDS=1   # verify rounds a re-based lane gets before it needs Michael
  RECORD_PR=end   # the run record's own PR, opened at finish (off = none: the record stays on harness/<run>)
  LIVE_SYNC=1   # the queue runner keeps the live checkout level with origin while no run is alive (lib/sync.sh; 0 = off)
  CONTEXT_PACK_BYTES=8192   # context.md's cap (E4): the pack of the journal a coding session reads first
  CONTEXT_PACK_BYTES_VERIFY=16384   # a verify session's pack: its failed rows first (decisions/2026-10-26-pack-current-rules)
  WEEKLY_STOP_AT=85   # % of the plan's 7-day window: past it no run starts and a run ends before its next session (0 = off)
  EVAL_BUDGET_USD=10   # `harness eval run`: no further task starts once its tasks have spent this much (a safety cap)
  PROBE_MODEL=haiku   # `harness eval probes`: the one tool-less session that answers the handoff questions
  DEBRIEF_PAGE_CMD=""   # run with the debrief page's path as $1 after each debrief (e.g. copy it where your phone can open it)
  LIVE_LOCK=""   # live-staged: the one-writer lock (default /tmp/harness/<project>/live.lock); share it with the backup job
  CHECK_CMD="" INIT_CMD="" SMOKE_CMD="" SPEC_FILES="" NOTIFY_CMD="" AGENT_SETTINGS=.claude/settings.json PR_POLICY=""
  NTFY_URL="" NTFY_TOKEN="" DESK_URL=""   # NTFY_URL set: the harness posts to ntfy itself (NOTIFY_CMD is then not called)
  DESK=0 DESK_MODEL=opus   # DESK=1: a Remote Control session briefs you when a run needs you (lib/desk.sh)
  for f in "${HARNESS_CONFIG:-${XDG_CONFIG_HOME:-$HOME/.config}/harness/config.sh}" "$wt/.harness/config.sh" ${st:+"$st/run.env"}; do
    # shellcheck source=/dev/null
    [[ -f $f ]] && source "$f"
  done
  [[ $PR_POLICY == off ]] && MERGE_POLICY=off   # v2 name; "milestone" and "end" are superseded by MERGE_POLICY
  [[ -n $CHECK_CMD ]] || CHECK_CMD=$(detect_check "$wt")
  [[ -n $SMOKE_CMD ]] || SMOKE_CMD=$(detect_smoke "$wt")
  [[ -n $INIT_CMD ]] || { [[ -f $wt/.harness/init.sh ]] && INIT_CMD=.harness/init.sh || INIT_CMD=true; }
  # TEARDOWN_CMD stays empty unless set: services_down looks for .harness/teardown.sh when it runs (a hook merged or
  # written mid-run counts). The form above always succeeds: as the last line it is harness_config's exit (set -e)
}

# The project's suite, by convention. Empty when nothing is found (the driver warns; nothing can be gated on it).
detect_check() {
  local wt=$1
  if [[ -f $wt/.harness/check.sh ]]; then echo ".harness/check.sh"
  elif [[ -f $wt/package.json ]] && node -e 'process.exit(require(process.argv[1]).scripts?.check ? 0 : 1)' "$wt/package.json" 2>/dev/null; then
    echo "npm run check --silent"
  elif [[ -f $wt/package.json ]] && node -e 'const t=require(process.argv[1]).scripts?.test; process.exit(t && !/no test specified/.test(t) ? 0 : 1)' "$wt/package.json" 2>/dev/null; then
    echo "npm test --silent"
  elif [[ -f $wt/pytest.ini || -f $wt/pyproject.toml || -f $wt/setup.cfg || -d $wt/tests ]] && compgen -G "$wt/tests/*.py" > /dev/null; then
    echo "python3 -m pytest -q"
  elif [[ -f $wt/Cargo.toml ]]; then echo "cargo test"
  elif [[ -f $wt/go.mod ]]; then echo "go test ./..."
  elif [[ -f $wt/Makefile ]] && grep -q '^test:' "$wt/Makefile"; then echo "make test"
  fi
}

detect_smoke() {
  local wt=$1
  if [[ -f $wt/.harness/smoke.mjs ]]; then echo "node .harness/smoke.mjs"
  elif [[ -f $wt/.harness/smoke.sh ]]; then echo "bash .harness/smoke.sh"
  else echo true; fi
}

# The plan's 7-day window, as the newest session reported it (<state>/USAGE_7D: "<utilization 0..1> <reset epoch>").
# Exit 0 and print why when it is past WEEKLY_STOP_AT and that window hasn't reset yet; exit 1 otherwise.
weekly_over() {
  local u r pct; read -r u r 2> /dev/null < "$1" || return 1   # 2> first: a missing file is silent
  (( WEEKLY_STOP_AT > 0 )) && [[ $r =~ ^[0-9]+$ ]] && (( r > $(date +%s) )) || return 1
  pct=$(awk -v u="$u" 'BEGIN { printf "%d", u * 100 + 0.5 }')
  (( pct >= WEEKLY_STOP_AT )) || return 1
  echo "7-day window at $pct%, stop at $WEEKLY_STOP_AT%; resets $(date -d "@$r" '+%a %H:%M')"
}
