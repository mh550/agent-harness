# A run's services also stop on pause, on a long usage-limit wait and on a memory wait

*(2026-10-25, run agent-harness-2026-10-25-lifecycle, feature L2-04; spec `docs/specs/2026-10-25-resource-lifecycle.md`
§L2 item 3, plan `docs/plans/2026-10-25-L2-run-services.md` §5.3–5.6, §6.3–6.7)*

- **Finding:** after L2-03 the services stop on `finish` and in the EXIT trap only. A paused run, or one waiting out a
  usage-limit window (up to five hours), kept its dev server and its containers up for nobody: hit_list's Supabase
  stack ran 15 h. The memory gate already called `services_down`, under the name `memory`.
- **Choice:**
  - **Pause:** the pause branch calls `services_down paused` before its poll, then commits and pushes
    (`HARNESS: paused`): nothing else commits during a pause, so the note would stay off Michael's phone until it ends.
  - **STOP** needs nothing new: `finish "stopped by Michael"` already runs `services_down`, so the note is
    `services stopped (stopped by Michael)`.
  - **Usage-limit wait:** `limit_wait` calls `services_down "usage-limit wait"` when the wait (already capped at the
    deadline) is strictly over `SVC_IDLE_STOP_MIN` minutes, before its `usage-limit window` note. **D1 *default*:
    `SVC_IDLE_STOP_MIN=10`**: an init takes seconds to a minute, so a wait of ten minutes or less isn't worth a restart.
  - **Memory wait:** `mem_gate`'s call is now `services_down "memory wait"`, and `verify()` re-runs the init after a
    wait (`mem_gate || run_init`, pulled into L2-03).
  - After each, the next `run_init` (a coding session's or a verify's) starts the services again: a resumed run needs
    nothing new. `services_down` stays once per started init (`SVC_UP`), so a second pause before any init is silent.
- **Rejected:**
  - **Stopping on every wait**, a short usage-limit window included: a restart per wait costs more (an init, a
    `supabase start`) than a few idle minutes of a capped scope.
  - **Stopping only on a long pause:** a pause has no known length; Michael pauses to look, and the next init restarts
    the services anyway.
  - **A separate key per stop point:** one threshold covers the only wait whose length is known in advance.
