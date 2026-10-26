#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh" && suite_setup
# ---- run 14: v2-style tags don't merge on a resume; `harness merge` merges them ----
echo 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1 MERGE_POLICY=off' > "$T/user-config.sh"
STUB_NO_TAMPER=1 STUB_NO_RED=1 STUB_LENIENT=1 "$H" start "$T/proj" legacy --spec SPEC.md --foreground > "$T/run14.out" 2>&1
echo 'KEEP_SCRATCH=1 LEDGER_COMMIT=0 MAX_PARALLEL_RUNS=1' > "$T/user-config.sh"
# its record made pre-E4 (E4-04): no journal, a progress.md the sessions wrote; `harness continue` keeps it as the archive
LW=$T/wt/proj/legacy LR=$T/wt/proj/legacy/.harness/runs/legacy
git -C "$LW" rm -q --ignore-unmatch "$LR/entries.jsonl" "$LR/progress-archive.md"
printf '# progress\n\n### 2026-10-20 10:00 · verify M1\n\n| Feature | Step | Ran | Saw | Holds |\n|---|---|---|---|---|\n| A | 1 | check | ok | yes |\n\n### 2026-10-20 09:00 · A · passes\n\nhand-written  \n' > "$LR/progress.md"
git -C "$LW" add -A && git -C "$LW" commit -qm "a pre-E4 record" && git -C "$LW" push -q origin harness/legacy
cp "$LR/progress.md" "$T/legacy-progress.md"
LJ0=$(git -C "$T/origin.git" cat-file -e harness/legacy:.harness/runs/legacy/entries.jsonl 2> /dev/null && echo yes || echo no)
for m in M1 M2; do git -C "$T/wt/proj/legacy" tag -f -a "run/legacy/$m" "run/legacy/$m^{commit}" -m "harness run legacy: $m verified" > /dev/null
  git -C "$T/wt/proj/legacy" push -q -f origin "run/legacy/$m"; done
mkdir -p "$T/prs" && touch "$T/prs/branch-harness_legacy"   # its v2 whole-run PR
"$H" continue legacy --foreground > "$T/run14b.out" 2>&1
check "a legacy run is untouched, then continued into a journal" '[[ $LJ0 == no ]] && cmp -s "$LR/progress-archive.md" "$T/legacy-progress.md" \
  && cmp -s "$LR/progress.md" "$T/legacy-progress.md" && [[ -f $LR/entries.jsonl ]] && hlog legacy | grep -q "journal started; progress.md kept as progress-archive.md$" \
  && git -C "$T/origin.git" cat-file -e harness/legacy:.harness/runs/legacy/entries.jsonl \
  && cp -r "$LR" "$T/lr2" && echo "{\"feature\":\"A\",\"kind\":\"coding\",\"outcome\":\"passes\",\"summary\":\"s\",\"at\":\"2026-10-22 03:00\"}" >> "$T/lr2/entries.jsonl" \
  && node "$HERE/../lib/entries.mjs" render "$T/lr2" && [[ $(sed -n 2p "$T/lr2/progress.md") == "# progress" ]] && ! grep -q hand-written "$T/lr2/progress.md" \
  && grep -qx "### 2026-10-22 03:00 · A · passes" "$T/lr2/progress-archive.md" && grep -qx "<!-- harness: progress.md before the journal, kept as it was -->" "$T/lr2/progress-archive.md" \
  && tail -c "$(wc -c < "$T/legacy-progress.md")" "$T/lr2/progress-archive.md" | cmp -s - "$T/legacy-progress.md"'
check "v2 tags don't merge on resume"     'hlog legacy | grep -q "verified by harness v2" && ! on_main run/legacy/M1 && [[ -f $T/prs/branch-harness_legacy ]]'
"$H" merge legacy > "$T/run14c.out" 2>&1
check "harness merge merges v2 tags, closes the v2 PR" 'on_main run/legacy/M2 && [[ ! -f $T/prs/branch-harness_legacy ]]'

suite_end
