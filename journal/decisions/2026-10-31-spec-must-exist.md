# A run never starts on a spec that isn't there: `harness start` and `queue add` refuse a spec absent from the run's base ref

*(2026-11-03, run `agent-harness-2026-11-03`, Q1-01; spec `docs/specs/2026-10-31-suite-cpu.md` Q1)*

- **Finding:** F named `docs/specs/2026-10-30-suite-cpu-and-flakes.md` and wrote no file. `harness queue add
  ~/projects/agent-harness --spec <that path>` accepted it: `cmd_queue add` passed the arguments to `queue_add` unread,
  and `cmd_start`'s only test was that `--spec` or `--brief` was given. The runner started the run; the initializer
  found the path on no branch, read the title, and built half the scope (F1, PR #71). The run's worktree is made from
  `origin/main` (or `--base`), so what a session can read is what that ref holds, not what Michael's working tree holds.
- **Choice:**
  - `lib/spec.sh` `spec_missing <project dir> <ref> <path>…` fetches `origin` (a failed fetch is one line on stderr,
    and the check reads the last fetched ref), tests each path with `git cat-file -e <ref>:<path>`, and for the first
    one missing prints `spec <path>: not in <ref> (fetched now); commit and push it, or name its ref with --base` and
    returns 1.
  - `bin/harness` `spec_refuse` runs it for a new run with `--spec`, or with the project's `SPEC_FILES` when no
    `--spec` is given (split on spaces, as `SPEC_FILES` is), against `--base` when given, else
    `origin/$MAIN_BRANCH`; a miss is `die` with the line (exit 1). `cmd_start` calls it before the first `queue_add`
    (the busy-project and `MAX_PARALLEL_RUNS` paths queue before the worktree exists), so a queued entry is a checked
    one; `cmd_queue add` calls it before `queue_add`, with the project's config read in a subshell.
  - Not checked: a resume (a given run id whose worktree `$WT_ROOT/<project>/<run>` exists: its spec persists in
    `run.env` and was checked when it started), a `--brief` start with no spec, and `queue add --continue` (the run
    has its spec).
  - *default:* the reference is the project's `origin/main` (or `--base`), not the working tree: the run's worktree
    is made from that ref (`cmd_start`'s `git worktree add … origin/main`), `queue add` may be called from anywhere by
    project name, and a file in the working tree that is not pushed is exactly what the initializer cannot read.
  - No `harness-log.md` note: no run exists. The refusal is the command's output and exit code.
  - **The runner re-checks at dequeue and parks, never starts** (Q1-02): `lib/queue.sh`, once an entry is chosen and
    the limit and weekly gates are past (so a closed window is not a fetch per poll), and before the live checkout's
    sync and the `mv` to `done/`, runs `lib/spec.sh` `spec_entry` on it: a `start` entry decoded as the runner decodes
    it (one argument per line, a newline as `\x1f`), the run id, `--spec` and `--base` read by `spec_args` (the parser
    `queue add` uses too), the project's config in a subshell for `SPEC_FILES`, then `spec_new_run`, the check
    `harness start` runs (a resume and `--brief` alone pass). On a miss the entry moves to `queue/held/` with a `.why`
    holding the line and the time (`<line> (<YYYY-MM-DD HH:MM>)`, the shape `harness queue park` writes), one
    `parked <entry>.args: spec <path>: not in <ref> …` line goes to `runner.log`, and the loop goes on to the next
    entry at once. A branch deleted or a spec moved between `queue add` and the start parks; a spec pushed after
    `queue add` passes; an entry planted by hand is checked here for the first time. `harness queue list` shows it
    with its reason; `queue unpark` puts it back once the file is pushed. A name already taken in `held/` parks under
    `<name>-<YYYYmmddHHMMSS>.args` (a held name would stop the queue at that entry); a failed `mv` is a `could not
    park` line and a poll's wait, never a tight loop. A failed fetch's line goes to `runner.log`. An entry whose
    project is no repository is not parked (its start fails and says why, as before); a check that fails without a
    line (a project config that exits) parks with `spec check failed in <project> (exit <n>)`, never an empty reason.
  - *default:* no notification for a park: the runner's log and `harness queue list` carry it, and the debrief reads
    the runner's log.
- **Rejected:**
  - **The working tree as the reference:** an unpushed spec passes there and is still absent from the worktree the
    run is made from; `queue add` may also be run from another checkout or by project name.
  - **Checking only at `queue add`:** the ref moves between queueing and the start (a branch deleted, a spec moved),
    so the runner re-checks at dequeue (Q1-02).
  - **The runner starting the entry and letting `harness start` refuse it:** the start dies with the line, but the
    entry is already in `done/` (the next rejection); the park keeps it, with its reason, for `unpark`.
  - **Failing the runner's start and leaving the entry in `done/`:** what happens today to a start that fails: the
    run is lost silently, a `failed:` in a log nobody reads at night.
  - **The initializer guessing from the title:** what happened; a night on half a scope.

Updated in place 2026-11-03: the runner's re-check at dequeue and its park (Q1-02).
