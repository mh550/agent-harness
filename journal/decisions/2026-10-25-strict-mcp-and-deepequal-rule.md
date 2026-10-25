# Headless sessions load only their project's MCP servers; the prompt bounds big diffs and reruns

*(2026-10-25, run agent-harness-2026-10-25-lifecycle, feature L1-07; spec `docs/specs/2026-10-25-resource-lifecycle.md`
§L1 items 6 and 7 (B9, and the OOM finding's step 4); the OOM finding in
`findings-and-research/2026-10-24-oom-from-unbounded-test-diff.md`)*

- **Finding:**
  - A headless `claude -p` session loads every MCP server it can find: the user's, any project-scoped server
    approved on the box, the plugins'. Each one is a process in the session's 6G scope (L1-03) and a block of tool
    definitions in every prompt, for servers a run never uses; and a run in one project could reach another
    project's servers (n8n's live MCP from any run).
  - On 2026-10-24 a red-phase test compared two large values with `deepEqual`; the diff grew to 6.5–9.6 GB, and the
    session reran the same command four times after each kill. The caps (L1-03, L1-05) now stop the box going down;
    nothing told the session not to write the test that way, or not to rerun it unbounded.
- **Checked against the real CLI** (`claude --help`, Claude Code 2.1.310, on this box, 2026-10-25), the two lines the
  flags rely on:

  ```
    --mcp-config <configs...>             Load MCP servers from JSON files or
                                          strings (space-separated)
    --strict-mcp-config                   Only use MCP servers from --mcp-config,
                                          ignoring all other MCP configurations
  ```

- **Choice:**
  - **`session()` always passes `--strict-mcp-config`**, and `--mcp-config "$WT/.mcp.json"` only when the worktree has
    that file. A project that wants servers in its runs commits its `.mcp.json` (n8n-home does; the 2026-10-24 setup
    script moved its servers there), so the run worktree carries it. Without one, sessions get no MCP servers at all.
    Every session kind (initializer, coding, verify, retro) takes the same line; the debrief and desks don't go
    through `session()` and are unchanged.
  - **One line in `run.log` at the run start**, beside the permissions line: `MCP servers: .mcp.json
    (--strict-mcp-config --mcp-config)` or `MCP servers: none (--strict-mcp-config; no .mcp.json)`. Not a
    `harness-log.md` note: like the permissions line, it is the same every session of a run, and the phone log
    would carry it for nothing.
  - **`prompts/parts/rules.md` gains the rule** the spec names: a red-phase test never compares large values with
    `deepEqual` (a length, a hash or the first mismatch instead), and after an exit 137 or a hang the same command is
    not rerun but bounded (a `check.sh` subset, `--test-name-pattern`). It reaches every session's prompt
    (initializer, coding, verify, retro) in every project with a `CLAUDE.md` (the part is included only then), which is every project
    the harness runs today (`harness init` writes one).
- **Rejected:**
  - **Passing `--mcp-config` for the project's own checkout** (`$PROJECT_DIR/.mcp.json`): an uncommitted file there
    would reach runs no one reviewed; the worktree's copy is the committed one.
  - **No `--strict-mcp-config` when a project has no `.mcp.json`**: the session would again load whatever the user's
    configuration holds, the thing this guards against.
  - **The rule in `prompts/coding.md`'s Work list instead**: the spec names `rules.md`; the coding template stays the
    shared static prefix (decisions/2026-10-21-static-first-prompts). Moving it is a one-line change if a project
    without `CLAUDE.md` ever runs.
