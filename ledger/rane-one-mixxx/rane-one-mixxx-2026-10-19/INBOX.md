status: run
<!-- Steer this run from the GitHub app: edit this file on branch harness/rane-one-mixxx-2026-10-19.
     Change the first line to "status: pause" or "status: stop"; write answers to questions under "## Answers".
     The harness pulls before every session; every session reads this file at startup. -->

## Question (2026-10-19 18:05, M1-04): amend step 3? It cannot hold as written
M1-04 step 3 wants the Mixxx version line in `dev-profile/mixxx.log`. Mixxx 2.5.6 can't write it there while it
runs with `--controller-debug`, and step 1 (and CLAUDE.md) require that flag. Checked against the `2.5.6` tag:
`VersionStore::logBuildDetails` logs "Mixxx 2.5.6 … is starting" with `qDebug` in the default category, and
`controllerDebugCategoryFilter` (`src/util/logging.cpp`) turns Debug off for every category except `js` and
`controller.*`. No env var or `--log-level` gets around that. The only other version line, "Configuration file is
at the current version", is printed before `Logging::initialize`, so it goes to stdout only. All 8 dev logs so
far: 0 version lines. The launcher already handles this (D10): it treats Mixxx as started when a **new** `mixxx.log`
exists and this launch's `dev-profile/mixxx-dev.stdout` has `Configuration file is at the current version "2.5.6"`.
I won't write a line into Mixxx's log myself, because that would be faking it.
**Please pick one** (my recommendation is a):
- **a)** Amend step 3: "… produces a new `dev-profile/mixxx.log` within 60 s, and `dev-profile/mixxx-dev.stdout`
  contains `Configuration file is at the current version "2.5.6"` …" (the rest of the step unchanged).
- **b)** Drop `--controller-debug` from the dev launch. That changes CLAUDE.md, and it hides the mapping's debug output.

## Answers
