#!/usr/bin/env bash
# Stand-in for lib/context.sh in tests (HARNESS_CONTEXT, as HARNESS_CURL is curl's): `<run-id> | --since <ts> --out <dir>
# [--id <id>]` copies tests/fixtures/context-bundle.json to <dir>/context.json, writes an empty <dir>/context.md, prints
# <dir>. The fixture is the real lib/context.sh's `harness context parked --id 00000000-0000-4000-8000-000000000001` on
# tests/lib.sh's status_stubs (2026-11-07, A2-04), its $T written /tmp/T.
out=""
while (( $# )); do [[ $1 == --out ]] && { out=$2; shift; }; shift; done
[[ -n $out ]] || { echo "stub-context: no --out" >&2; exit 2; }
mkdir -p "$out" && cp "$(dirname "$0")/fixtures/context-bundle.json" "$out/context.json" && : > "$out/context.md" && echo "$out"
