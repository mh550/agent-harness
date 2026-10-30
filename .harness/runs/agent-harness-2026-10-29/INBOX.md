status: run
<!-- Steer this run from the GitHub app: edit this file on branch harness/agent-harness-2026-10-29.
     Change the first line to "status: pause" or "status: stop"; write answers to questions under the Answers heading at the end
     of this file. The harness pulls before every session; every session reads this file at startup. -->

### N2-02: step 2's "A untouched" can't hold beside "git reports the conflict as usual" (2026-10-29 08:55)

Blocked: N2-02 (last attempt), so N2's merge. Verify N2 failed step 2 on the words "a side that fails `LC_ALL=C sort -c` makes it exit 1 with A untouched". In git 2.43, when a merge driver exits 1, git keeps A as the file as it is. An untouched A is a conflict with no markers: ours' lines only, theirs' lines gone. Tried in /tmp/harness/agent-harness/agent-harness-2026-10-29/lanes/N2/kept-a, where the base is `a b`, ours is `b a` and theirs is `b a c`. A driver that exits 1 without writing leaves `f` as `b a` with 0 `<<<<<<<` lines, so `c` is lost and a resolve session has no marker to find. N2-06's Opus review found this, so `lib/merge-sorted.sh` now hands an unsorted side to `git merge-file`. A clean text merge exits 0. A conflict exits 1 with its markers in A, which is "git reports the conflict as usual", what the spec (§ Layer 1) means. `75-merge-sorted` checks it (7/7 green). I can't edit a step, so the feature can't pass as worded.

Files: /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29/slot-1/lib/merge-sorted.sh:11, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29/slot-1/.harness/runs/agent-harness-2026-10-29/feature_list.json, /home/mh550/worktrees/agent-harness/lanes/agent-harness-2026-10-29/slot-1/journal/decisions/2026-10-29-conflict-resolution.md:15

Options:
1. (recommended) Reword step 2's last clause to: "a side that fails `LC_ALL=C sort -c` gets git's text merge (`git merge-file`): clean exits 0, a conflict exits 1 with its `<<<<<<<` markers in A". Then answer "N2-02: step 2 reworded" below, and the retry verifies it as the code stands. In the run directory:

   ```
   jq '(.features[] | select(.id=="N2-02") | .steps[1]) |= sub("makes it exit 1 with A untouched \\(git reports the conflict as usual\\)"; "gets git'"'"'s text merge (`git merge-file`): clean exits 0, a conflict exits 1 with its `<<<<<<<` markers in A")' feature_list.json > f.tmp && mv f.tmp feature_list.json
   ```
2. Keep the step and go back to A untouched. Not advised: that conflict leaves no markers and loses theirs' lines.

## Answers

### 2026-10-29 10:21 (local)
N2-02: step 2 reworded
