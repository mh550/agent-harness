#!/usr/bin/env bash
# Usage: tk.sh <tree> <n> <label> — median wall (ms) of n spawned treekey calls in <tree>, of node -e 0, and the load
tree=$1 n=$2; cd "$tree" || exit 1
med() { sort -n | awk '{a[NR]=$1} END {printf "%.1f", (a[int((NR+1)/2)]+a[int(NR/2)+1])/2}'; }
ms() { local i t0 t1; for ((i=0;i<n;i++)); do t0=${EPOCHREALTIME/./}; "$@" > /dev/null 2>&1; t1=${EPOCHREALTIME/./}; echo $(( t1 - t0 )) | awk '{print $1/1000}'; (( ${TK_GAP:-0} )) && sleep "$TK_GAP"; done; }
l0=$(cut -d' ' -f1 /proc/loadavg); idle=$(ms node -e 0 | med); key=$(ms node lib/treekey.mjs | med)
echo "tk $3 tree=$tree n=$n load=$l0 node-e0=$idle treekey=$key above=$(awk "BEGIN{printf \"%.1f\", $key-$idle}")"
