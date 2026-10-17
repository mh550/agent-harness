# .harness/config.sh — per-project harness settings (sourced by the driver; plain bash assignments).
# Committed on the branch runs start from (usually main), so every run's worktree has it.

SPEC_FILES="SPEC.md"                 # what the initializer turns into features (space-separated paths)
CHECK_CMD="npm run check --silent"   # the suite; green = exit 0. Gate for "passes" and for proposing a milestone
INIT_CMD=".harness/init.sh"          # run by the harness before every session (gets HARNESS_PORT, HARNESS_SCRATCH)
SMOKE_CMD="true"                     # a quick end-to-end check every session runs first
BASE_PORT=7800                       # each run gets the first free port from here

INIT_MODEL=fable                     # one session; writes the feature list (fable | opus | sonnet | claude-… id)
WORKER_MODEL=opus                    # features that name no model
VERIFY_MODEL=sonnet                  # independent re-check of each finished milestone
SUPERVISOR_MODEL=opus                # the interactive session in the tmux window "supervisor"

HOURS=8                              # wall-clock budget of a run
MAX_SESSIONS=40
MAX_ATTEMPTS=2                       # sessions per feature before it is skipped
MAX_REPAIRS=3                        # consecutive sessions that edit the feature list before the run stops
SESSION_TIMEOUT=100m
MAX_TURNS=250
SESSION_BUDGET_USD=20                # claude --max-budget-usd per session

PR_POLICY=milestone                  # milestone: tag + open/refresh the run's PR after each verified milestone
                                     # end: only at the end · off: never
MAIN_BRANCH=main
AGENT_SETTINGS=.claude/settings.json # permissions for headless sessions (passed with --settings; works in untrusted worktrees)
NOTIFY_CMD=""                        # optional, gets the message as $1, e.g. 'curl -s -d "$1" ntfy.sh/<private-topic>'
