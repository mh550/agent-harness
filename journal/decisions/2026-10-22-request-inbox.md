# The request inbox: n8n writes request files, a systemd path unit runs harness requests, two verbs

*(2026-11-07, A3-02 to A3-05 of run agent-harness-2026-11-07-3, with the A3 review `docs/plans/2026-11-07-A3-review.md`; spec `docs/specs/2026-10-22-n8n-events.md` §A3 and its
Contracts (v1, fixed: n8n-home's `docs/specs/2026-10-22-harness-reporter.md` §4.3); plan
`docs/plans/2026-11-07-A3-request-inbox.md`. The file keeps the spec's name, which n8n-home cites)*

- **Finding:** Michael's answers reached a run only through `harness answer` (appends to `<state>/inbox.md`; the
  driver moves it into `INBOX.md` while a driver runs) or an `INBOX.md` edit on the run branch, and a re-queue
  (`harness queue add --continue`) never starts the runner by itself. n8n's phone card can hold a park until Michael
  answers it, but n8n can't run host commands, and must not. n8n-home writes each request as the final file in one
  write, not a temp file renamed (its D25: its Read/Write Files node has no rename), so a pass can meet one half-written.
- **Choice:**
  - **The directory:** `<STATE_ROOT>/requests/`, made mode 700 with `done/` and `rejected/` by the first
    `harness requests`; one that exists keeps its mode (*default*). n8n (the same uid) writes `<id>.json` there.
  - **Two verbs, each one argv call:** `answer` → `"$H" answer "$run" "$text"`; `continue` → `"$H" queue add
    --continue "$run"` plus `--brief "$brief"` when given, then `"$H" queue start`. Text and brief are quoted argv
    elements, never through `eval`, `bash -c` or a shell; `lib/requests.mjs` parses the file and hands them over as
    files, so no bash parses request JSON. No third verb (*default*); no batching of answers (*default*), one call per
    request; a `continue` for a run whose driver is alive is accepted as `queue add` accepts it today: it waits until
    the run ends (*default*).
  - **The validation** (`validateRequest`, in this order, each with a reason a check greps): JSON; `v == 1`; `id`
    `^[A-Za-z0-9-]{8,64}$`; not already in `done/`; `verb` answer or continue; `run` `^[A-Za-z0-9._-]+$` and then a
    real run (`state_of`'s rule); `text` 1–4000 characters for `answer`; `brief` at most 2000 and not one option word
    (`^--[a-z][a-z-]*$`: `queue add` and `continue` read `--now`, `--automatic`, … wherever they stand); no NUL byte. The
    patterns hold before `id` or `run` names any path. Unknown keys are ignored (*default*); an empty brief is none
    (*default*). Lengths count JavaScript `.length`, as n8n's own checks do.
  - **The result and the log:** every request gets `requests/done/<id>.json` (the contract's ten keys: `v id at verb
    run ok exit output runner_started refused`, `output` cut at 2000 bytes), written to a temp name and renamed; the
    request moves to `done/<id>.request.json` or `rejected/`; `requests.log` gets one line (time, id, verb, run, ok or
    refused, exit, why) and never the text. A rejection's `exit` is `null` (*default*). A file whose id isn't usable
    gets its result under its file name when that passes the id rule (n8n reads `done/<id>.json` by its own id).
  - **At most once:** `flock` on `requests/.lock` for the whole call, the `done/` check inside it, and the request
    claimed into `done/` before its call runs. A duplicate id goes to `rejected/` and the first result stands
    (*default*): n8n's card reads that file. A claim a killed call left with no result gets one at the next call
    (`ok: false`, `refused: "interrupted after its claim: it may have run (see requests.log)"`), so the card never
    waits for ever. A symlink is rejected unread (*default*): its target may be anywhere; node opens the file with
    `O_NOFOLLOW`, so one swapped in after bash's test isn't read either. Anything else not a regular file, and a file
    that can't be read, is rejected too: one left behind matches the path unit's glob again at once.
  - **A queued entry the request replaces is written in the queue's format** (`queue.mjs write`, a newline as 0x1f):
    `queue add --continue` rewrote it with raw lines, so a brief's lines became `continue` options (the review's C1).
  - **The order:** oldest first by mtime, then by name, so n8n's `1-<h>` answer runs before its `2-<h>` continue.
  - **The grace:** an unparsable file younger than 10 s is left for later; at 10 s it is rejected. On the real clock
    one call waits out a young file's grace itself rather than leaving it to "the next pass", which under the path
    unit would be an instant restart.
  - **The backup window:** between 03:15 and 04:30 local (`HARNESS_NOW` in the suite) a `continue` is queued and the
    runner is not started: `ok: true`, `runner_started: false`, `refused: "backup window 03:15–04:30: queued, runner
    not started"`, which the card shows as refused with the why.
  - **The consumer is a systemd user path unit:** `systemd/harness-requests.path` (`PathExistsGlob=` on
    `requests/*.json`, `WantedBy=default.target`) starts `systemd/harness-requests.service` (`Type=oneshot`,
    `ExecStart=` the live checkout's `bin/harness requests`). The unit's PATH holds no nvm directory (*default*):
    `lib/requests.sh` finds node through `nvm.sh`, as the debrief does, so a new node version needs no unit edit.
    Under the unit (`INVOCATION_ID` set) `queue start` runs through `systemd-run --user --scope`: a tmux server it forks
    in the oneshot's cgroup would die with the oneshot, the runner and its runs too. The path unit watches the default
    state root; a `HARNESS_STATE` elsewhere needs its own unit (*default*).
  - **Shipped, never installed:** the harness writes nothing under `~/.config`; README's Steering gives Michael
    `systemctl --user link …` and `systemctl --user enable --now harness-requests.path`. The suite runs
    `systemd-analyze --user verify` on the units where it exists, and checks `harness requests` makes no
    `XDG_CONFIG_HOME/systemd`.
  - Unconfigured, nothing changes: with no request files and the units not linked, nothing calls `harness requests`.
- **Rejected:**
  - n8n committing to `INBOX.md` through the GitHub API: a GitHub write token in n8n, and its commits race the
    driver's own.
  - The queue runner as the consumer: it exits when the queue is empty, so a request would wait for the next run.
  - A third verb (stop, merge, …): none is needed for the card, and each is one more thing a webhook can do to a run.
  - `DirectoryNotEmpty=`: `done/`, `rejected/`, `requests.log` and `.lock` keep the directory non-empty for ever, so
    the service would restart at once after every pass, and five starts in 10 s fail the path unit (systemd.path(5)).
  - Bash parsing the request: a `jq` per field, and the text crossing a pipe and a word split.
  - Node's directory written into the unit at install: a drop-in Michael would redo for each node version.
  - `KillMode=process` in the service instead of the scope: systemd would leave the tmux server in a stopped unit's
    cgroup, and the next start of the unit would kill it.
  - Parsing `continue`'s and `queue add`'s flags in pairs, the real fix for an option-word brief: the spec keeps
    `cmd_continue` out of this run; the refusal holds until then.
  - A real runner in the suite: the runner start is seen through gc-tmux's tmux shim, with `HARNESS_NO_RUNNER` unset
    for that one call.
