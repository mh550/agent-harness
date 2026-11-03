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
  - The runner's re-check at dequeue is Q1-02's, added here in place.
- **Rejected:**
  - **The working tree as the reference:** an unpushed spec passes there and is still absent from the worktree the
    run is made from; `queue add` may also be run from another checkout or by project name.
  - **Checking only at `queue add`:** the ref moves between queueing and the start (a branch deleted, a spec moved),
    so the runner re-checks at dequeue (Q1-02).
  - **Failing the runner's start and leaving the entry in `done/`:** what happens today to a start that fails: the
    run is lost silently, a `failed:` in a log nobody reads at night.
  - **The initializer guessing from the title:** what happened; a night on half a scope.
