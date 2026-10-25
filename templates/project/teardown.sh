#!/usr/bin/env bash
# .harness/teardown.sh (optional; make it executable) — run by the harness when it stops the run's services: at the
# run's end, and when its driver is killed (TERM) or dies on an error. It runs in
# the run's worktree under `timeout -k 10s 2m`, with HARNESS_PORT, HARNESS_SCRATCH, HARNESS_RUN_ID and HARNESS_TEARDOWN_WHY
# set, before the harness stops the services scope (harness-<run>-svc). That stop already takes everything the init
# started itself; this is for what lives outside it: containers run by dockerd, which no cgroup of the run reaches.
# Output goes to $HARNESS_SCRATCH/teardown.out; its exit is noted and never stops the run. Idempotent: it may run twice.
# By hand, after a SIGKILL (`harness gc` stops the units, not containers): HARNESS_RUN_ID=<run> .harness/teardown.sh
set -uo pipefail
cd "$(dirname "$0")/.."
run=${HARNESS_RUN_ID:?run as HARNESS_RUN_ID=<run> .harness/teardown.sh} why=${HARNESS_TEARDOWN_WHY:-by hand}
compose=harness-$(printf %s "$run" | tr 'A-Z' 'a-z' | tr -c 'a-z0-9_-' -)   # compose project names: lowercase [a-z0-9_-]
# npx supabase stop                      # a local Supabase the init started (`npx supabase start`)
# docker compose -p "$compose" down      # the containers the init brought up with that project name
echo "teardown: (nothing configured; $why; compose project $compose)"
