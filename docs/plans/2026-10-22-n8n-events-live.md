# n8n events: the live checklist for Michael

Spec `docs/specs/2026-10-22-n8n-events.md` (A1–A4). The harness side is built and inert until you do these steps; the
run never touched n8n, `~/.config` or systemd. Do them in order, after n8n-home's reporter is deployed (its own
checklist). Stop at any stage that fails; each stage undoes by itself.

## Stage 1 · the event hook (`EVENT_URL`)

1. Edit `~/.config/harness/config.sh` (the file `templates/user/config.sh`'s header names) and add:
   ```
   EVENT_URL=http://127.0.0.1:5678/webhook/harness-event
   EVENT_TIMEOUT=5
   ```
2. Build a bundle by hand (read-only, posts nothing): `harness context <a recent run id>`. It prints a directory under
   `~/.local/state/harness/events/` holding `context.md` and `context.json`. Worked: both files exist and are non-empty.
3. Make the next park (or needs-you, blocked, debrief) the test. Worked: that run's `run.log` has
   `event → n8n: <kind> <id>`, `events/<id>/event.json` exists, and n8n's card arrives. Fallback worked (n8n down or
   500): the note `event hook failed (…): <kind>; sent to ntfy` and the ntfy post arrives as before.
4. **Undo:** comment out the `EVENT_URL=` line. Nothing else changes; `events/` bundles are removed after 30 days.

## Stage 2 · the request inbox (answers from the phone card)

1. Create the directory and check the pass runs: `harness requests` prints `requests: none pending (…)`.
2. Link and enable the units (the harness never installs them):
   ```
   systemctl --user link ~/projects/agent-harness/systemd/harness-requests.path ~/projects/agent-harness/systemd/harness-requests.service
   systemctl --user enable --now harness-requests.path
   ```
3. Test with a hand-written request for any existing run (use one you can spare):
   ```
   printf '{"v":1,"id":"live-test-0001","at":"2026-11-08T00:00:00.000Z","verb":"answer","run":"<run id>","text":"test answer","source":"n8n-card","event":null}\n' > ~/.local/state/harness/requests/live-test-0001.json
   ```
   Worked within a few seconds: the text is in `~/.local/state/harness/<project>/<run id>/inbox.md` (the driver moves it into the run's `INBOX.md`),
   `requests/done/live-test-0001.json` exists with `"ok": true`, and `requests/requests.log` has one line. Check the
   exact shape against `tests/fixtures/requests/answer.json` if it lands in `requests/rejected/`.
4. A `continue` request queues the run and starts the runner; try it only on a run you mean to continue.
5. **Backup window:** between 03:15 and 04:30 a `continue` is queued but the runner is not started (the result says
   so); it starts with the next `harness queue start` or the next request outside the window.
6. If the path unit shows `failed` (five restarts in 10 s): `systemctl --user reset-failed harness-requests.path`, then
   `systemctl --user enable --now harness-requests.path`.
7. **Undo:** `systemctl --user disable --now harness-requests.path harness-requests.service`. Request files stay.
   After a unit file changes in git: `systemctl --user daemon-reload`.

Install text also lives in README § Steering ("Answers from the phone card").
