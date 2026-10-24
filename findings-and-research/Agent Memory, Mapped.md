For the LiveKit Agents conversation · Tue Oct 20, 2026

# Agent Memory, Mapped

Seventeen diagrams of how memory and context work in AI agents: what goes in the window, how memory is written and read, what voice adds, how LiveKit Agents 2.0 structures threads and lanes, and how Michael's own harness already does much of this with files. Each figure has a short caption and one key idea.

A companion field guide carries the detail in prose. On a phone, wide diagrams scroll sideways inside their frame; tap Fit to shrink one to the screen.

## One visual language throughout

Procedural instructions, prompts, rules

State authoritative, typed

Long-term memory facts, profile, ledger

History / episodic turns, progress log

Journal append-only record

Human steering inbox, review

Critical path latency the user feels

Dashed outline planned, beta-only or proposed

## Figures

### Foundations

1. 01[The memory map](#map)
2. 02[Anatomy of a context window](#window)
3. 03[Write, select, compress, isolate](#moves)
4. 04[Long-term memory lifecycle](#lifecycle)
5. 05[The compaction ladder](#compaction)

### Voice

1. 06[A voice turn on a timeline](#voice-turn)
2. 07[Only what was heard is true](#heard)

### LiveKit Agents 2.0

1. 08[Agents 2.0: thread anatomy](#thread)
2. 09[One writer per lane](#one-writer)
3. 10[Across days: a background task](#across-days)
4. 11[Delegation vs handoff](#delegation)
5. 12[Turn policies](#policies)

### Orchestration

1. 13[Supervisor and workers](#supervisor)

### Michael's harness

1. 14[The harness as a memory system](#harness)
2. 15[Proposed: a journal and a context pack](#journal-pack)
3. 16[Measuring harness changes](#measuring)

### Demo

1. 17[The demo](#demo)

FIG 01

## The memory map

Problem

Coding harness · dev time

Voice / text agent · production

**Context engineering**What tokens are in the window for this call?

Each prompt = role template + run brief + CLAUDE.md + policy. Subagents take browser checks and reviews.

Instructions + chat_ctx + injected facts + tool results. Every token adds time to first token.

**Durable state**What is the authoritative progress of this task?

feature_list.json: a session may flip only its own `passes`; the driver reverts other edits.

2.0 lane state: typed, ≤ 64 KiB, leased. In v1, `userdata` on the session.

**Long-term memory**What do we know across sessions?

progress.md across sessions; the ledger and retros across runs.

profile · facts · past-call summaries keyed by a stable user id, preloaded at connect.

**Handoff context**What crosses an agent boundary?

What each fresh session's prompt carries. The verifier is told not to trust the progress notes and re-runs the steps.

Full history, truncated, summarized, or a structured package (intent, entities, actions taken, goal).

**Safety & measurement**Who can write it, can it be deleted, did a change help?

Agents can't edit rules or the feature list. Measure cost per verified feature and cache hit rate.

Poisoning, PII/PHI, per-user scoping, erasure. Measure recall, wrong-memory rate, end of turn → first audio.

“Memory” is really five problems, and each one shows up in both settings. The left column is Michael's coding harness at dev time; the right is a voice or text agent in production. The questions match even where the stores differ.

**Key idea**Before designing any memory, name which of the five problems it solves.

From: agent-memory-briefing.md §1

FIG 02

## Anatomy of a context window

One model call reads its context top to bottom, and the provider reuses the longest unchanged prefix from cache. Put what never changes first and what changes every call last. Per-user memory sits right after the shared static block, so that block still caches across users and calls.

**Key idea**Static first, volatile last. Every token costs attention, money and, in voice, time to first token.

From: briefing §2 (items 1–2), §3 (long calls)

FIG 03

## Write, select, compress, isolate

LangChain's four moves cover nearly every context technique. Write saves information outside the window, select brings the right piece back in, compress shrinks what is already there, and isolate splits work across separate windows.

**Key idea**Treat the window as a budget: move things out, pull them back by reference, shrink what stays, split what does not fit.

From: research-notes.md, context engineering details

FIG 04

## Long-term memory lifecycle

Long-term memory is a loop. The turn only reads memory, preloaded or fetched by a tool, and injects it. Extraction, consolidation and forgetting run in the background with a separate writer, so they add no turn latency and can use a stronger model. A changed fact is invalidated, not erased.

**Key idea**Read on the hot path, write in the background, and keep only durable, heard, user-stated facts.

From: briefing §2 (items 6–9), research notes (Mem0, Graphiti, Letta)

FIG 05

## The compaction ladder

Compaction runs from light to heavy, and each rung frees more room and loses more. Clearing old tool results is cheap and restorable. A summary must keep references so detail can be reloaded. A fresh session keeps only what the handoff file says.

**Key idea**Use the lightest rung that frees enough room, and make every summary restorable by reference.

From: briefing §2 (item 5), research notes

FIG 06

## A voice turn on a timeline

In voice, memory costs latency as well as money. The example budget is about 800 ms from end of turn to first audio. Preload memory in parallel with `ctx.connect()` and extract after the turn or call. A blocking lookup in `on_user_turn_completed` edits `chat_ctx`, which throws away the preemptive reply, so generation is paid for twice.

**Key idea**Keep every memory read and write off the red path.

From: briefing §3; research notes, voice and LiveKit details

FIG 07

## Only what was heard is true

The LLM generates more than the user hears. On an interruption, LiveKit commits the assistant message cut to what was played, with `interrupted=True`. A memory extractor must read that committed text, never the full generation, or the agent will remember promises it never said out loud.

**Key idea**Only heard text may become memory.

From: briefing §3 (only what was heard is true)

FIG 08

## Agents 2.0: thread anatomy

beta

A 2.0 thread is one conversation with a person across channels and time, found only by its id. Each agent that takes part gets a lane; a lane belongs to an agent, not to a door, so the phone line and the text endpoint write the same lane. One append-only journal is shared by all lanes. Each thread is its own memory: memory across a person's threads is left to the application.

**Key idea**Thread = the conversation; lane = one agent's slice; state = what it learned; journal = what happened.

From: 2.0 docs: threads.md, lanes.md, journal.md, channels.md, planned-channels.md

FIG 09

## One writer per lane

beta

A run takes the lane's lease before loading anything, and its commit is fenced on the version it loaded and its lease token. A text that arrives mid-call waits its turn; the next voice turn sees the newer version and reloads history and state before the model reads them. Below: the two failure cases.

**Key idea**The lease stops two runs at once; the fence stops a stale run from writing.

From: 2.0 docs: lanes.md, voice.md

FIG 10

## Across days: a background task

planned

A background task is a delegation whose reply is not awaited. The tool calls `A2ADelegate.send()` and the turn ends. The task waits on its own lane until the outside system posts back with its task id, or agent-service's clock fires `on_timeout`. The result lands as a message on the caller's lane, and the next turn reads it.

**Key idea**Long waits live in the thread, not in a worker: no frame or local variable survives a run.

From: 2.0 docs: planned-agent-tasks.md (designed, not built)

FIG 11

## Delegation vs handoff

beta

Delegation keeps the caller's history clean: the expert works on a fresh history and the caller sees only the tool call and its result. A handoff changes who is speaking: the new agent continues on the same history. In stable v1, a handed-off agent starts fresh unless you pass context in one of four ways.

**Key idea**Decide at each boundary what crosses: everything, the last few turns, a summary, or a structured package.

From: 2.0 docs: multi-agent.md; briefing §4 (v1 handoff)

FIG 12

## Turn policies

beta

When a message arrives during a running turn, the endpoint's policy decides what happens, per channel. SMS, WhatsApp and email are planned channels, but their batch default is already specified. A fifth policy, `reject`, fails the new request until the client cancels the running task.

**Key idea**Voice barge-in and texting bursts need opposite policies on the same thread.

From: 2.0 docs: text-endpoints.md

FIG 13

## Supervisor and workers

The supervisor keeps the plan and pointers, not transcripts. Workers run in isolated contexts and return a short report with file references, while the details stay on disk. Only one worker writes a given surface. The verifier gets a clean context, and the human reviews the plan, where a bad line costs the most.

**Key idea**Extra agents contribute intelligence, not actions.

From: briefing §6

FIG 14

## The harness as a memory system

Michael's harness keeps its memory in files. A deterministic bash driver starts one fresh session per feature, and each session knows only what is on disk. Every file has one memory role and its own write rules. After a run, the retro feeds the ledger, and the ledger feeds a calibration line to the next initializer.

**Key idea**Fresh context per feature, state on disk: agents do judgment, the driver does bookkeeping.

From: agent-harness/docs/architecture.md §2–§5, §11

FIG 15

## Proposed: a journal and a context pack

proposed

Make an append-only journal of structured entries the source of truth instead of free-text `progress.md`. The driver, not a model, builds a capped context pack for each session, and `progress.md` becomes a rendered view for the phone. This makes dead ends and discoveries first-class, two of the gaps found in the code.

**Key idea**Record once in structure, select deterministically, render for people.

From: briefing §5, gaps 4, 5 and 7

FIG 16

## Measuring harness changes

proposed

Judge every harness change on a fixed replay set of past tasks and record the same metrics for every harness version. Keep a change only if it beats the baseline. Today `metrics.mjs` records cost, turns and time but no token or cache figures, so token telemetry comes first.

**Key idea**A harness change is a hypothesis until the replay set says otherwise.

From: briefing §5, gaps 1 and 6; research notes (evals)

FIG 17

## The demo

planned

A small demo of these ideas on Michael's portfolio site, planned for tomorrow. Voice and text share one session; memory is preloaded at connect and extracted in the background; the page shows what was remembered and what it cost in latency, and lets the visitor erase it.

**Key idea**Show memory working: what was preloaded, what was extracted, what it cost, and that it can be forgotten.

From: the demo plan (not built yet)

Built from Michael's research briefing and notes (Oct 19, 2026), the LiveKit Agents 2.0 docs on the `agents-2.0` branch (PR #7757, read Oct 19), and the agent-harness architecture doc and prompts. Agents 2.0 is a public beta PR on staging; anything marked planned there is designed, not built. Example values in figures (names, amounts, ids) are illustrations.