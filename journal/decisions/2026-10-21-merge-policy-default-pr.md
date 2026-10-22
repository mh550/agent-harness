# The default MERGE_POLICY is `pr`: a run self-merges only where a project opts in

*(2026-10-21, Michael: "harness runs should merge their own verified milestones in pre-release projects"; this PR)*

- **Finding:** `MERGE_POLICY` defaulted to `auto`, so a project that set nothing had its verified
  milestones merged into `main` unattended. A survey of the seven `~/projects/*` repos with a `.harness/` dir
  found five on `auto` — but only three of those (`hit_list`, `pathways`, `rane-one-mixxx`) are genuinely
  pre-release with no production. The other two sit on `auto` only because nothing opted them out:
  `voice-concierge` (an enabled, active `systemd --user` service runs its live checkout on `main`) and
  `dj-crate-streaming` (its `main` is the source `scripts/deploy.sh` builds the running music stack from). The
  two production-on-`main` repos that must not self-merge, `portfolio_site` (Vercel deploys `main`) and
  `agent-harness` (every run starts from `origin/main`, so a bad auto-merge is the next run's base), already set
  `MERGE_POLICY=pr` by hand. So the dangerous setting was the one in force by default, and `POLICY`
  (`build-only`/`live-staged`) is no proxy for it: `portfolio_site` is `build-only` yet production.
- **Choice:** default `MERGE_POLICY=pr`. A verified milestone opens its PR and waits; a project self-merges only
  by setting `MERGE_POLICY=auto` in its `.harness/config.sh`. The knob and its three values are unchanged — only
  which value applies when nothing sets one. Self-merge becomes an explicit, per-repo opt-in, which matches
  "changes to the harness wait for Michael" and "the tree that lands is the tree that was verified": the one
  unreviewed outbound action is no longer the silent default. One coupling the flip exposed is fixed with it:
  `harness merge <run>`, whose job is to land verified milestones on demand, used to merge only because the
  ambient default was `auto`; it now merges whatever the project's `MERGE_POLICY` (its `HARNESS_MERGE_ONLY` pass
  overrides the propose-and-wait branch), so a `pr` repo still has a one-command "land it now".
- **Rejected:** a new `RELEASE_STAGE=prerelease|production` setting that `MERGE_POLICY` follows from — a second
  knob for one decision, able to disagree with the knob that already encodes it, and keyed on a stage that
  `POLICY` already fails to capture (`portfolio_site`). Coupling `auto` to `POLICY=build-only` — same bad proxy,
  and it would silently re-enable `auto` for a future `build-only` project that is actually production. Keeping
  the `auto` default and only flipping the two mis-defaulted repos to `pr` — fixes today's repos but leaves the
  next un-configured repo auto-merging by default, the failure this is meant to end.
