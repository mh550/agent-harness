#!/usr/bin/env bash
# Usage: lib/prompt.sh <state dir> <template> <feature>   → the prompt a session of that kind for <feature> gets, on stdout
# The driver's prompt assembly (sourced by lib/driver.sh): prompt_vars and prompt_env set what every template fills
# from, prompt_render renders one. Run as a command, it renders a run's prompt the way its driver would (the run's
# meta.env, worktree, config and run.env, with the caller's HARNESS_CONFIG and HARNESS_SCRATCH_ROOT), so
# `harness eval probes` judges the exact handoff (plan: docs/plans/2026-10-21-E2-evals.md §5.2).

# Needs PROJECT_DIR RUN_ID STATE HARNESS_HOME, lib/scope.sh sourced (prompt_env), and the worktree as the working directory.
prompt_vars() {
  PROJECT_NAME=$(basename "$PROJECT_DIR") BRANCH=$(git branch --show-current) RUN_DIR=.harness/runs/$RUN_ID
  SCRATCH=${HARNESS_SCRATCH_ROOT:-/tmp/harness}/$PROJECT_NAME/$RUN_ID CHECK=$HARNESS_HOME/lib/check.sh PORT=$(cat "$STATE/port")
}

# <dir>: rm -rf it only when it is this run's scratch directory as prompt_vars builds it, never its parent (live.lock),
# and only when its real path is that too (a symlinked project or run dir is refused). 2 = refused, else rm's status
scratch_rm() {
  local root=${HARNESS_SCRATCH_ROOT:-/tmp/harness}
  [[ $root == /?* && ${PROJECT_NAME:-} =~ ^[A-Za-z0-9._-]+$ && $PROJECT_NAME != . && $PROJECT_NAME != .. \
     && ${RUN_ID:-} =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ && $1 == "$root/$PROJECT_NAME/$RUN_ID" \
     && $(realpath -m -- "$1") == "$(realpath -m -- "$root")/$PROJECT_NAME/$RUN_ID" ]] || return 2
  rm -rf --one-file-system -- "$1"
}

# <tree key>: finish's last word on scratch. init.out, teardown.out and the last suite output (the final tree's
# check-<key>.out, else check.out) as check-last.out into $STATE; then $SCRATCH goes, unless KEEP_SCRATCH=1 or a copy
# failed. Only finish deletes: a crash leaves it to read (and to the tmpfiles rule). Needs SCRATCH STATE KEEP_SCRATCH note
scratch_done() {
  local f src kept=() rc
  for f in init.out teardown.out check-last.out; do
    src=$SCRATCH/$f; [[ $f == check-last.out ]] && { src=$SCRATCH/check-${1:-}.out; [[ -n ${1:-} && -f $src ]] || src=$SCRATCH/check.out; }
    [[ -f $src ]] || continue
    cp -f "$src" "$STATE/$f" 2> /dev/null || { note "scratch kept: copying $f into $STATE failed"; return 0; }
    kept+=("$f")
  done
  if [[ $KEEP_SCRATCH == 1 ]]; then note "scratch kept (KEEP_SCRATCH=1): $SCRATCH"; return 0; fi
  scratch_rm "$SCRATCH" 2> /dev/null; rc=$?   # the note carries rm's exit
  case $rc in
    0) note "scratch removed: $SCRATCH (in the state dir: ${kept[*]:-nothing})" ;;
    2) note "scratch not removed: $SCRATCH is not this run's scratch directory" ;;
    *) note "scratch not fully removed: $SCRATCH (rm exit $rc)" ;;
  esac
}

# After harness_config: what sessions (and their {{NAME}}s) see.
prompt_env() {
  LIVE_LOCK=${LIVE_LOCK:-${HARNESS_SCRATCH_ROOT:-/tmp/harness}/$PROJECT_NAME/live.lock}
  export HARNESS_RUN_ID=$RUN_ID HARNESS_RUN_DIR=$RUN_DIR HARNESS_BRANCH=$BRANCH HARNESS_PORT=$PORT HARNESS_SCRATCH=$SCRATCH \
    HARNESS_CHECK="$CHECK" HARNESS_CHECK_CMD=$CHECK_CMD HARNESS_SMOKE_CMD=$SMOKE_CMD HARNESS_INIT_CMD=$INIT_CMD \
    HARNESS_SPEC_FILES=${SPEC_FILES:-none} HARNESS_MAIN_BRANCH=$MAIN_BRANCH HARNESS_PROJECT=$PROJECT_NAME HARNESS_WT=$WT \
    HARNESS_POLICY=$POLICY HARNESS_LIVE_LOCK=$LIVE_LOCK HARNESS_CHECK_CACHE=$STATE/green \
    HARNESS_CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/harness/$PROJECT_NAME \
    HARNESS_SCOPE_PREFIX="$(scope_unit "$RUN_ID" "")" HARNESS_CHECK_MEMORY_MAX=$CHECK_MEMORY_MAX HARNESS_CHECK_TIMEOUT=$CHECK_TIMEOUT   # check.sh caps the same way for both
}

prompt_render() {   # template name → stdout: the static template, the policy, this run (its lines, the brief, the line naming CLAUDE.md), this session
  local extra=() rules=()
  # Claude Code loads CLAUDE.md in the worktree itself: one line names it, the file isn't pasted (decisions/2026-10-21-no-double-claude-md)
  [[ -f CLAUDE.md ]] && rules=("$HARNESS_HOME/prompts/parts/rules.md")
  if [[ $1 == retro ]]; then extra=("${rules[@]}")
  else   # these go at the template's {{SECTIONS}} line: nothing run-specific before the policy (decisions/2026-10-21-static-first-prompts)
    extra=("Harness policy for this project=$HARNESS_HOME/prompts/policy/$POLICY.md" "$HARNESS_HOME/prompts/parts/run.md")
    # the brief as written: a "{{X}}" in it would put session values into the shared prefix (E3 review F7)
    [[ -s $RUN_DIR/brief.md ]] && extra+=(--raw "Brief for this run, from Michael (it wins over the spec on scope)=$RUN_DIR/brief.md")
    extra+=("${rules[@]}")
    [[ -f .harness/project.md ]] && extra+=("Project rules (.harness/project.md)=.harness/project.md")
  fi
  # the last 40 whole lines and where the rest is (decisions/2026-10-21-clock-and-bounded-init-output)
  HARNESS_INIT_OUTPUT=$([[ -f $SCRATCH/init.out ]] && { tail -n 40 "$SCRATCH/init.out"; echo "full output: $SCRATCH/init.out"; }) HARNESS_CHECK="$CHECK" \
    node "$HARNESS_HOME/lib/render.mjs" "$HARNESS_HOME/prompts/$1.md" "${extra[@]}"
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  set -uo pipefail
  (( $# == 3 )) || { echo "usage: lib/prompt.sh <state dir> <template> <feature>" >&2; exit 2; }
  STATE=$(cd "$1" && pwd) && [[ -f $STATE/meta.env ]] || { echo "prompt.sh: $1 is not a run's state dir (no meta.env)" >&2; exit 1; }
  HARNESS_HOME=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)   # this version's templates, whatever the caller's
  # shellcheck source=lib/config.sh
  source "$HARNESS_HOME/lib/config.sh"
  # shellcheck source=lib/scope.sh
  source "$HARNESS_HOME/lib/scope.sh"   # scope_unit, for prompt_env's HARNESS_SCOPE_PREFIX
  # shellcheck source=/dev/null
  source "$STATE/meta.env"
  cd "$WT" || exit 1
  prompt_vars; harness_config "$WT" "$STATE"; prompt_env
  jq -e --arg id "$3" 'any(.features[]; .id == $id)' "$RUN_DIR/feature_list.json" > /dev/null || { echo "prompt.sh: no feature '$3' in $RUN_DIR/feature_list.json" >&2; exit 1; }
  m=$(jq -r --arg id "$3" '.features[] | select(.id == $id) | .milestone // empty' "$RUN_DIR/feature_list.json")
  # no driver, so no run clock or attempt: the line says so rather than going blank
  HARNESS_CLOCK=${HARNESS_CLOCK:-"Clock: $(date '+%F %H:%M') · outside a run (no deadline, budget or attempt)"} HARNESS_FEATURE=$3 HARNESS_MILESTONE=$m prompt_render "$2"
fi
