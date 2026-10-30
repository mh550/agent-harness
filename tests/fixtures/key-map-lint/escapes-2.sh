# fixture of 82-key-map-lint: reads through a known root the S2 review found (S2-06), one per line from line 3
# ls "$HERE/../" is a hit; so is each line below
ls "$HERE/../"
grep -r x "$HERE/../."
grep -r x "$HERE/../tests/.."
cat "$HERE"/../*.md
cat "$HERE"/../{CLAUDE,README}.md
for f in CLAUDE.md README.md; do grep -c x "$HERE/../$f"; done
git -C "$HERE/.." ls-files | while read -r f; do grep -c x "$HERE/../$f"; done
cat "${HH:-}/CLAUDE.md"
mytool == "$HERE/.."
cat "$HERE/../evals/tasks/$t/task.json" "$HERE/../lib/$f"
