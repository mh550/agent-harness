# Project rules — <project>

_Appended to every harness prompt. Keep it to what every session must know; link to the rest._

## Ground rules
- <what this repo is, what must never be touched, secrets, sudo, read-only inputs>

## Where things are
- Spec: <files>. Decisions already made: <where>. New decisions go: <where>.
- Plans: `docs/plans/<date>-<milestone>-<topic>.md`.

## How to verify
- Suite: `npm run check`. Dev server: `http://localhost:$HARNESS_PORT` (started by `.harness/init.sh`).
- UI checks: <widths, pages, what must be visible>.
