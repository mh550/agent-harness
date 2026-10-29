#!/usr/bin/env bash
# The sleep lint: a check waits on a condition (wait_for) or a barrier (stub_wait/stub_go), never on the clock.
#   tests/lint-sleeps.sh [<file>…]   (default tests/checks/*.sh and tests/lib.sh; the stubs are exempt: their sleeps are
#                                     the work they stand in for) → one <file>:<line> per line holding the word sleep
#                                     that is no full-line comment and lacks `# sleep-ok: <why>`; exit 1 when it listed any
# The lint doesn't parse comments out of a code line (a # in a string, $#, #{pane…} would fool it): a code line that
# only names sleep in its trailing comment is reworded or says `# sleep-ok: text`.
set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
(( $# )) || set -- "$HERE"/checks/*.sh "$HERE/lib.sh"
listed=0
for f; do
  while IFS=: read -r n _; do echo "$f:$n"; listed=1
  done < <(grep -nE '(^|[^[:alnum:]_])sleep([^[:alnum:]_]|$)' "$f" | grep -vE '^[0-9]+:[[:space:]]*#' | grep -vF '# sleep-ok:')
done
exit "$listed"
