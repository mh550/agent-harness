# 2026-10-13: the first unattended overnight `/loop`

- **Date:** 2026-10-13 (written 02:25 on the laptop; loop started ~03:30 on the desktop)
- **Project:** umbrella `~/projects` + dj-crate-streaming
- **Source:** `~/projects/HOME-SETUP.md` §5–7, `~/projects/HANDOFF.md`, `~/projects/OVERNIGHT.md` (all `27efc89`;
  bedtime direction in `ccd1734`/`e9f8300` and ON1 "Direction from Michael")
- **Iteration:** 1 (spec-first + unattended overnight loop)
- **Why it matters:** the kickoff is one line. Everything else lives in a file the agent re-reads every iteration
  ("This file is your memory across loop iterations and context compactions"). Note the authorship: a laptop Claude
  session wrote these lines and the walkthrough, and Michael typed them on the desktop.

## The kickoff line (HOME-SETUP.md §6, HANDOFF.md step 7)

```
/loop Follow ~/projects/OVERNIGHT.md: re-read it, do the next unchecked step, tick it, log it, commit.
```

## Before it: handing the setup to a desktop agent (HOME-SETUP.md §1)

```
cd ~/projects && ~/.local/bin/claude
# then say: "Read HANDOFF.md and walk me through it."
```

HANDOFF.md opens: "**From:** the Claude session on Michael's laptop (WSL2), 2026-10-13 · **To:** you, a Claude Code
session on Michael's new Pop!_OS 24.04 desktop · **Your job:** walk Michael through the before-bed setup… **You are
not the overnight session.**"

## Phone test and steering examples (HOME-SETUP.md §5, §7)

> *"Say hi and send me a test push notification."*

> **Steer:** just type in the session, e.g. *"skip M2, go straight to sourcing"*,
> *"approve one live download of the top wanted track"*, *"what's left?"*.

> **Stop:** send *"stop the loop and wrap up"*

## Ground rule that makes Michael's messages first-class (ON1 rule 8)

> **If Michael messages you,** his message overrides this queue. Record the new direction under "Direction from
> Michael" below before acting on it.

## Bedtime direction as recorded (ON1, relayed by the setup agent; excerpt)

> - **2026-10-13 (bedtime, via desktop setup agent):**
>   - Windows is gone. Single-boot Pop!_OS (see decisions.md Open questions #1).
>   - Git remotes use **HTTPS**. The SSH key has a passphrase and gcr-ssh-agent hangs,
>     so never switch remotes to `git@github.com:`.
>   - VPN: Michael has a **paid ProtonVPN plan with port forwarding**. … **No Soulseek account yet.** Expect M4 to be skipped.

(The loop found all four secrets present and ran M4 anyway, per its rule: "If `WG_KEY`… exist".)
