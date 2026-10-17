#!/usr/bin/env bash
# Long-running agent harness, after https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
#   1. no feature list yet → one initializer session (INIT_MODEL) writes harness/feature_list.json + progress.md
#   2. then one fresh coding session per feature, back to back, until every feature passes,
#      the deadline passes, or MAX_SESSIONS is reached. A feature gets MAX_ATTEMPTS sessions, then is skipped.
# Start it detached:  tmux new -d -s pathways-harness harness/run.sh   (watch: tmux attach -t pathways-harness)
set -uo pipefail
cd "$(dirname "$0")/.."

HOURS=${HOURS:-8}; MAX_SESSIONS=${MAX_SESSIONS:-40}; MAX_ATTEMPTS=${MAX_ATTEMPTS:-2}
MAX_TURNS=${MAX_TURNS:-250}; SESSION_TIMEOUT=${SESSION_TIMEOUT:-100m}
INIT_MODEL=${INIT_MODEL:-claude-fable-5-1}
LOGS=harness/logs; mkdir -p "$LOGS"
DEADLINE=$(( $(date +%s) + HOURS * 3600 ))
BRANCH=$(git branch --show-current)

log() { echo "$(date '+%F %T') $*" | tee -a "$LOGS/run.log"; }

[[ -z "$BRANCH" || "$BRANCH" == main ]] && { log "refusing to run on '${BRANCH:-detached HEAD}'"; exit 1; }
[[ -n "$(git status --porcelain)" ]] && { log "working tree not clean; commit or clean it first"; exit 1; }

# one headless session: model, prompt file, log file, extra prompt text
session() {
  timeout "$SESSION_TIMEOUT" claude -p "$(cat "$2")$4" --model "$1" --permission-mode auto \
    --max-turns "$MAX_TURNS" --output-format stream-json --verbose > "$3" 2>&1
  local rc=$?
  log "  exit $rc · $(git log --oneline -1)"
}

if [[ ! -f harness/feature_list.json ]]; then
  log "initializer ($INIT_MODEL) on $BRANCH"
  session "$INIT_MODEL" harness/prompts/initializer.md "$LOGS/session-00-init.jsonl" ""
  node -e 'JSON.parse(require("fs").readFileSync("harness/feature_list.json","utf8")).features.length || process.exit(1)' 2>/dev/null \
    || { log "initializer did not produce a valid harness/feature_list.json; stopping"; exit 1; }
  log "feature list: $(node harness/features.mjs summary)"
fi

for (( n = 1; n <= MAX_SESSIONS; n++ )); do
  (( $(date +%s) >= DEADLINE )) && { log "deadline (${HOURS} h) reached"; break; }
  next=$(node harness/features.mjs next "$MAX_ATTEMPTS")
  [[ -z "$next" ]] && { log "no feature left to try"; break; }
  id=${next%%$'\t'*}; model=${next#*$'\t'}
  node harness/features.mjs bump "$id"
  node harness/features.mjs snapshot > "$LOGS/before.json"
  log "session $n · $id · $model"
  session "$model" harness/prompts/coding.md "$(printf '%s/session-%02d-%s.jsonl' "$LOGS" "$n" "$id")" \
    $'\n\n'"## Your feature this session: \`$id\`"$'\n'
  if ! node harness/features.mjs check "$LOGS/before.json" "$id" 2>>"$LOGS/run.log"; then
    log "feature list was edited beyond '$id' passes; stopping for Michael (see run.log)"; break
  fi
  log "  $(node harness/features.mjs summary) · check: $(npm run check --silent >/dev/null 2>&1 && echo green || echo RED)"
done
log "harness done: $(node harness/features.mjs summary)"
