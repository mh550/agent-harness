# fixture of 82-key-map-lint: the escapes the plan closes, one per line; this comment and the next are no hits
# grep x "$HERE/../CLAUDE.md"
git -C "$HERE/.." show HEAD:CLAUDE.md
git -C "$HERE/.." grep -n x
ROOT=$(readlink -f "$HERE/..") && grep x "$ROOT/CLAUDE.md"
grep x "$HH/CLAUDE.md"
(cd "$HERE" && grep x ../CLAUDE.md)
mytool "$(cd "$HERE/.." && pwd)"
r=${HERE%/*}; cat "$r"
cat "$HERE/../lib/a.sh" "$HERE/../templates/x"
