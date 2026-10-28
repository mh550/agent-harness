#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- overlaps (U3-05, the pure half): lib/overlap.mjs named finds the tracked paths a spec or brief names, overlap ----
# ---- their intersection. tests/fixtures/overlap-spec.md is a byte copy of docs/specs/2026-10-26-suite-split.md ----
O=$HERE/../lib/overlap.mjs
git -C "$HERE/.." ls-files > "$T/tracked.txt"
node "$O" named "$T/tracked.txt" < "$HERE/fixtures/overlap-spec.md" > "$T/named.txt"
check "overlap: named on the suite-split spec with this repo's git ls-files finds tests/run.sh, lib/treekey.mjs and lib/check.sh" '
  grep -qx tests/run.sh "$T/named.txt" && grep -qx lib/treekey.mjs "$T/named.txt" && grep -qx lib/check.sh "$T/named.txt"'
check "overlap: every name is a tracked file or a tracked dir/ of two or more segments; no tests/, lib/ or .harness/runs/" '
  ok=1; while IFS= read -r l; do
    if [[ $l == */ ]]; then [[ $l == */*/ ]] && grep -q "^$l" "$T/tracked.txt" || ok=0; else grep -qxF -- "$l" "$T/tracked.txt" || ok=0; fi
    [[ $l == .harness/runs/* ]] && ok=0; done < "$T/named.txt"
  (( ok )) && [[ -s $T/named.txt ]] && ! grep -qxE "tests/|lib/" "$T/named.txt" && grep -qx tests/checks/ "$T/named.txt" && [[ $(LC_ALL=C sort -u "$T/named.txt") == "$(cat "$T/named.txt")" ]]'
printf '%s\n' CLAUDE.md README.md lib/a.sh lib/b/c.mjs lib/b/d.mjs tests/checks/01-x.sh tests/run.sh .harness/runs/r/x.md > "$T/t.txt"
nm() { printf '%s' "$1" | node "$O" named "$T/t.txt" | paste -sd" "; }
check "overlap: named takes backticked and bare path words, strips .,:;) and :<line>, and a word without / only in backticks" '
  [[ $(nm "see lib/a.sh:12, (tests/run.sh). And \`CLAUDE.md\` but not README.md") == "CLAUDE.md lib/a.sh tests/run.sh" ]] &&
  [[ $(nm "\`./lib/a.sh\` and lib/nope.sh") == "lib/a.sh" ]]'
check "overlap: a dir/ or glob names its directory of two or more segments; .harness/runs/ never" '
  [[ $(nm "lib/b/ and lib/ and tests/checks/NN-<slug>.sh and tests/*.sh") == "lib/b/ tests/checks/" ]] &&
  [[ $(nm "lib/x/ .harness/runs/r/x.md .harness/runs/") == "" ]]'
check "overlap: Markdown emphasis and HTML tags stuck to a path neither hide it nor turn it into its directory" '
  [[ $(nm "**lib/a.sh** and *tests/run.sh*") == "lib/a.sh tests/run.sh" ]] && [[ $(nm "lib/b/c.mjs<br> <code>tests/checks/01-x.sh</code>") == "lib/b/c.mjs tests/checks/01-x.sh" ]] &&
  [[ $(nm "**tests/checks/*.sh**") == "tests/checks/" && $(nm "tests/checks/0*") == "tests/checks/" ]]'
printf '%s\n' lib/a.sh tests/checks/ docs/x.md > "$T/a.txt"; printf '%s\n' tests/checks/02-y.sh lib/a.sh README.md > "$T/b.txt"
printf '%s\n' docs/y.md > "$T/c.txt"; printf '%s\n' tests/checks/ > "$T/d.txt"
check "overlap: overlap is the sorted intersection: file and file, a dir/ and a file under it (the file), dir/ and dir/; none" '
  [[ $(node "$O" overlap "$T/a.txt" "$T/b.txt" | paste -sd" ") == "lib/a.sh tests/checks/02-y.sh" ]] &&
  [[ $(node "$O" overlap "$T/b.txt" "$T/a.txt" | paste -sd" ") == "lib/a.sh tests/checks/02-y.sh" ]] &&
  [[ $(node "$O" overlap "$T/a.txt" "$T/d.txt") == tests/checks/ ]] && [[ -z $(node "$O" overlap "$T/a.txt" "$T/c.txt") ]]'
check "overlap: named and overlap are exported and pure (no I/O at import); node --check lib/overlap.mjs" '
  node --check "$O" && node --input-type=module -e "
    import { named, overlap } from \"$O\";
    const n = named(\"\`lib/a.sh\` lib/b/\", [\"lib/a.sh\", \"lib/b/c.mjs\"]);
    if (n.join() !== \"lib/a.sh,lib/b/\") process.exit(1);
    if (overlap(n, [\"lib/b/c.mjs\"]).join() !== \"lib/b/c.mjs\") process.exit(2);"'
suite_end
