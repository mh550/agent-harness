#!/usr/bin/env bash
# Usage: lib/merge-sorted.sh <O> <A> <B>   → a git merge driver for one-item-per-line LC_ALL=C sorted files: A becomes the three-way union
# Both sides' lines, once each, minus every base line either side removed (a plain union would bring a deleted name
# back). A side out of order exits 1 with A untouched: git reports the conflict as usual and a resolve session takes it.
# Opted into per file by `.gitattributes` `merge=sorted-union`; the harness sets the driver in its worktrees' own
# config (merge_drivers, lib/record.sh; decisions/2026-10-29-conflict-resolution).
set -uo pipefail
export LC_ALL=C
O=$1 A=$2 B=$3
sort -c "$A" 2> /dev/null && sort -c "$B" 2> /dev/null || exit 1
d=$(mktemp -d) || exit 1; trap 'rm -rf "$d"' EXIT
sort -u "$O" > "$d/o"; sort -u "$A" > "$d/a"; sort -u "$B" > "$d/b"
{ comm -23 "$d/o" "$d/a"; comm -23 "$d/o" "$d/b"; } | sort -u > "$d/removed"
sort -u "$d/a" "$d/b" | comm -23 - "$d/removed" > "$d/result" || exit 1
cat "$d/result" > "$A"   # in place: git reads %A back by its path, and the inode stays
