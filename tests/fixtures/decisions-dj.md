# Decisions

The current rule set for dj-crate-streaming. When a decision is overturned, its entry is rewritten in place to the
rule that holds now, with one "Updated in place <date>: …" line naming what replaced it; history is in git. Newest
last; a new one takes the next free number. `*default*` = taken as the simplest reversible default, for Michael to
confirm. Gathered on 2026-10-25 from `docs/specs/2026-10-13-next-session-design.md` §0 (D1–D23) and
`docs/specs/2026-10-17-amperfy-pivot.md` (D24 on), with each ID kept.

## D24 on (the 2026-10-17 pivot and later)

| # | Decision | Replaces |
|---|---|---|
| D24 | **One download quality.** A file is acceptable when it is lossless (flac preferred, then wav / aiff / alac) or lossy at **256 kbps or more** (mp3 or m4a). ogg, opus, wma and anything lower are refused. Verification is strict for every download (a re-encoded fake is rejected). A lossy file at or above the floor is kept; "flac preferred" only steers which candidate wins when we download, it never queues an upgrade by itself. | D9 tiers as a user choice, D15 (imports default to medium), D17 (floors), the M8 ruling on listening-tier upgrades |
| D25 | **Streaming quality belongs to the client and Navidrome.** We store the one good file; Navidrome's per-player transcoding (Amperfy: its own Wi-Fi / cellular settings) turns it into whatever the connection needs. Our own stream presets stay in the code only as notes for the future client (see "For the future client"). | D19 as a feature of this app |
| D26 | **Source the exact track.** The default is the version the playlist row names (Spotify's). A 12" / extended mix is never preferred and never stands in for a radio edit. `deploy/policy.toml` has no `[versions.*]` table. The version machinery (parse, compare, propose) stays, because it still tells versions apart. | D16 (all of it: crate preference, stand-ins, import and scorer bonuses) |
| D36 *default* | **The cleanup's trash step runs only with the worker stopped**, holding `<dirname(CRATES_DB)>/worker.lock`, so beets has one writer (`plan` and `repoint` run beside the daemon). | refines D18 (one beets writer) for D31; instead of M9 §3's worker replacement jobs |
| D53 *default* | **A matched release gives an album request without a year its first-release year** (S4-02; S4-01's question (a)). When `match_request_release` finds the MusicBrainz release whose tracks are the rows one to one, the release group's `first-release-date` (the lookup asks `inc=release-groups`) becomes `requests.year` if the request has none, so a Spotify album link files at `$album ($year)/` and every file carries that year. Only a first match before any row of the request was approved fills it: a row may already be filed at `$album/` (D51), and a year then would split the album into two folders. A year the request has is kept, and no release group or no date leaves it unknown (D51 clears it on the files). The release group's date, not the matched release's own: ties prefer a digital release, often a reissue. Alternative: keep D51 for every Spotify album (no year from MusicBrainz). | spec 2026-10-22 S2-03, S2-06 |
