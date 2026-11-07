# SoulSync review: how it works, how it compares, what to take

### Michael's decisions

| Decision | In five words | SoulSync | Citation |
|---|---|---|---|
| D24 (`ours:docs/specs/2026-10-17-amperfy-pivot.md:19`) | Lossless or ≥256, fakes rejected | **Conflicts.** The quality gate reads the header's claim, the default profile never rejects, and nothing detects a transcode after download; its YouTube source makes the re-encoded fake D24 forbids. [06-verification.md](06-verification.md#the-difference-that-matters) | `SoulSync:core/quality/schema.py:171-172`, `SoulSync:core/imports/file_integrity.py:445-470`, `SoulSync:core/settings.py:1106-1115` |
