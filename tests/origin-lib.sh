# The helpers origin-outage.sh and origin-after-gc.sh share (M1 of docs/specs/2026-11-04-run-resilience.md):
# sourced after suite_setup. A run of theirs starts from the file's first main and goes through stub-git-down.sh when
# its PATH says so; inv_scan collects the invariant over every run that still has a worktree.
export COLUMNS=200 HARNESS_GLYPHS=unicode HARNESS_ORIGIN_WAITS="0 0 0"   # four tries per step, no wait between them
main0=$(git -C "$T/origin.git" rev-parse main)   # each run starts from it (one origin for the file's runs)
nkey() { cat "$HARNESS_STATE/proj/$1"/needs/*.json 2> /dev/null | jq -se --arg k "$2" 'any(.[]; .key == $k)' > /dev/null; }   # <run> <key>: an open item
DOWN=$T/down; mkdir -p "$DOWN" && ln -s "$HERE/stub-git-down.sh" "$DOWN/git"   # first on PATH for a run: the outage stub
ni() { jq -s -r ".[] | select(.key == \"$2\") | ${3:-.}" "$HARNESS_STATE/proj/$1"/needs/*.json 2> /dev/null; }   # <run> <key> <jq>: an open item's field
ndone() { jq -s -r ".[] | select(.key == \"$2\") | ${3:-.}" "$HARNESS_STATE/proj/$1"/needs/done/*.json 2> /dev/null; }   # the same, resolved
# how many stub-curl posts hold every one of the given strings
posts() { awk 'BEGIN { RS = "===\n"; split(ARGV[1], k, "\t"); ARGV[1] = "" } { for (i in k) if (!index($0, k[i])) next; n++ } END { print n + 0 }' "$(IFS=$'\t'; echo "$*")" "$T/curl.log"; }
fresh() { git -C "$T/origin.git" update-ref refs/heads/main "$main0"; rm -f "$T"/gh-down-*; }   # the next run starts from main0, gh's counts at 0
srun() { local r=$1; shift; env STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$@" "$H" start "$T/proj" "$r" --spec SPEC.md --foreground > "$T/$r.out" 2>&1; }   # <run> [VAR=value…]: a stub run
# The invariant (a falsifier of the spec's Predictions): scanned over every run with a worktree, before gc removes any
inv_bad="" inv_n=0
inv_scan() { local d r stamp hm m close
  for d in "$HARNESS_STATE"/proj/*/; do r=$(basename "$d")
    while read -r stamp hm m; do
      close=$(date -d "$stamp $hm" +%s); inv_n=$(( inv_n + 1 ))
      find "$d"needs -name '*.json' -exec cat {} + 2> /dev/null | jq -se --arg m "$m" --argjson t "$close" 'any(.[]; .milestone == $m and (.at | sub("\\.[0-9]+Z$"; "Z") | fromdate) < $t + 60)' > /dev/null || inv_bad+=" $r/$m"
    done < <(hlog "$r" | sed -nE 's/^- ([0-9-]+ [0-9:]+) · lane ([^ ]+) closed \(\2 needs Michael: .*$/\1 \2/p')
  done; }
