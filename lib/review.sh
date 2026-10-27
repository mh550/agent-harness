# shellcheck shell=bash
# Usage: source lib/review.sh; review_diff   (in the worktree, MAIN_BRANCH set) → "<files> <changed lines>", or exit 1 and why
# The review gate (M6) sizes a review's model by what this branch has and main doesn't: three dots, from the merge base,
# with main fetched first, so a milestone merged meanwhile (a self-merge moves origin's main, not ours) drops out at once.
review_diff() {
  local o="origin/$MAIN_BRANCH" out
  git fetch -q origin "$MAIN_BRANCH" 2> /dev/null   # a failed fetch measures from the ref we have
  git rev-parse -q --verify "$o^{commit}" > /dev/null || { echo "no $o"; return 1; }
  out=$(git diff --shortstat "$o...HEAD" -- . ':!.harness/runs' 2> /dev/null) || { echo "git diff $o...HEAD failed"; return 1; }
  awk '{ for (i = 2; i <= NF; i++) { if ($i ~ /^file/) f = $(i-1); if ($i ~ /^insertion/ || $i ~ /^deletion/) l += $(i-1) } }
    END { print f + 0, l + 0 }' <<< "$out"
}
