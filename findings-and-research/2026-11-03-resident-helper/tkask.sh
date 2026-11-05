#!/usr/bin/env bash
# Usage: tkask.sh <tree> <n> — median wall (ms) of n `ask treekey.mjs` in <tree>, the helper's per-call cost (a pipeline's side would spawn)
tree=$1 n=$2; cd "$tree" || exit 1; export HARNESS_HOME=$tree HARNESS_SCRATCH=${HARNESS_SCRATCH}/proof/tkask; mkdir -p "$HARNESS_SCRATCH"
source lib/record.sh; helper_start 2> /dev/null
ask treekey.mjs > /dev/null   # the import's cost is the first call's
r=(); for ((i=0;i<n;i++)); do t0=${EPOCHREALTIME/./}; ask treekey.mjs > /dev/null; t1=${EPOCHREALTIME/./}; r+=($(( t1 - t0 ))); done
printf '%s\n' "${r[@]}" | sort -n | awk '{a[NR]=$1/1000} END {printf "ask treekey median %.1f ms of %d, load ", (a[int((NR+1)/2)]+a[int(NR/2)+1])/2, NR}'; cut -d' ' -f1 /proc/loadavg
helper_stop 2> /dev/null; exit 0
