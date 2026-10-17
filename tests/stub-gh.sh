#!/usr/bin/env bash
# Stand-in for `gh` in tests: records calls; one PR per branch.
echo "gh $*" >> "$STUB_DIR/gh.log"
case "$1 $2" in
  "pr view") [[ -f $STUB_DIR/pr-open ]] && echo "https://example.test/pr/1" || exit 1 ;;
  "pr create") touch "$STUB_DIR/pr-open"; echo "https://example.test/pr/1" ;;
  "pr edit") ;;
esac
