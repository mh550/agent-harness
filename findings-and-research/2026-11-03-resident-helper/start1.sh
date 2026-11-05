#!/usr/bin/env bash
# Usage: start1.sh <tree> <out dir> [VAR=value…] — file 13's first stub start in <tree>, node counted by 92's shim; logs kept
tree=$1 d=$2; shift 2; mkdir -p "$d"
source "$tree/tests/lib.sh" && suite_setup > /dev/null
mkdir -p "$d/shim"; : > "$d/count"
printf '#!/usr/bin/env bash\na=$*; echo "${a//[[:cntrl:]]/ }" >> "$NODE_COUNT"\nexec %q "$@"\n' "$(command -v node)" > "$d/shim/node"; chmod +x "$d/shim/node"
env PATH="$d/shim:$PATH" NODE_COUNT="$d/count" "$@" "$H" start "$T/proj" demo --spec SPEC.md --brief "only A–C" --foreground > "$d/out" 2>&1
echo $? > "$d/rc"
cp "$T/wt/proj/demo/.harness/runs/demo/harness-log.md" "$d/harness-log.md"; cp "$HARNESS_STATE/proj/demo/run.log" "$d/run.log"; cp "$(list demo)" "$d/feature_list.json"
cat "$HARNESS_STATE/proj/demo/ended" > "$d/ended" 2> /dev/null
exit 0
