#!/usr/bin/env bash
# build_check_log.sh — render or validate the split HSquared.jl check log.
#
# Provenance: behaviour ported from DRM.jl/tools/build_check_log.jl
# (MIT License, Copyright (c) 2026 Shinichi Nakagawa) and taught back from
# hsquared#165 `tools/build_check_log.sh`. DRM.jl shards are one Markdown
# table row each. HSquared.jl (and hsquared) shards are prose files. This
# script keeps the DRM.jl contract — frozen monolith + per-slice files +
# `--check` — and validates the prose shape already used here.
#
# The log is split to avoid merge collisions (see docs/dev-log/check-log.d/README.md):
#   • docs/dev-log/check-log.md  — historical log (do not append).
#   • docs/dev-log/check-log.d/  — one prose file per slice; new files never
#                                  conflict with each other.
#
# This script does NOT rewrite check-log.md. A generated, committed monolith
# would re-introduce the collisions the split removes.
#
# Usage:
#   bash tools/build_check_log.sh                 # frozen log + shard index to stdout
#   bash tools/build_check_log.sh --check         # exit 1 if any shard is malformed
#   bash tools/build_check_log.sh --selftest      # tests of the checker
#   bash tools/build_check_log.sh --check /path   # optional repo root
#
# Exit: 0 = ok · 1 = malformed / selftest fail · 2 = could not verify (UNKNOWN)

set -uo pipefail

usage() {
  sed -n '19,25p' "$0" | sed 's/^# \{0,1\}//'
}

CHECK=0
SELFTEST=0
ROOT=""

for arg in "$@"; do
  case "$arg" in
    --check) CHECK=1 ;;
    --selftest) SELFTEST=1 ;;
    -h|--help) usage; exit 0 ;;
    *)
      if [ -n "$ROOT" ]; then
        echo "build_check_log: unexpected argument: $arg" >&2
        exit 2
      fi
      ROOT="$arg"
      ;;
  esac
done

if [ -z "$ROOT" ]; then
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

FROZEN="$ROOT/docs/dev-log/check-log.md"
ENTRYDIR="$ROOT/docs/dev-log/check-log.d"

# A valid shard name is dated so parallel PRs sort and never collide.
valid_name() {
  printf '%s\n' "$1" | grep -Eq '^[0-9]{4}-[0-9]{2}-[0-9]{2}-.+\.md$'
}

# First non-empty line must be an ATX heading (# …).
first_heading() {
  # Prints the heading text (no leading hashes) or nothing.
  local line
  while IFS= read -r line || [ -n "$line" ]; do
    [ -z "${line//[[:space:]]/}" ] && continue
    case "$line" in
      '#'[[:space:]]* | '##'[[:space:]]* | '###'[[:space:]]* | '####'[[:space:]]* | '#####'[[:space:]]* | '######'[[:space:]]*)
        printf '%s\n' "$line" | sed 's/^#\{1,6\}[[:space:]]*//'
        return 0
        ;;
      *)
        return 1
        ;;
    esac
  done
  return 1
}

nonempty_count() {
  # grep -c prints 0 even when it exits 1 (no match). Do not `|| echo 0`.
  grep -c '[[:graph:]]' "$1" 2>/dev/null || true
}

entry_files() {
  [ -d "$ENTRYDIR" ] || return 0
  # Portable: no mapfile. Sorted filenames, README excluded.
  find "$ENTRYDIR" -maxdepth 1 -name '*.md' ! -name 'README.md' -print | LC_ALL=C sort
}

scan_entries() {
  bad=()
  titles=()
  names=()
  local f base n first
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    base="$(basename "$f")"
    if ! valid_name "$base"; then
      bad+=("$base: filename must be YYYY-MM-DD-<slug>.md")
      continue
    fi
    if [ ! -s "$f" ]; then
      bad+=("$base: empty file")
      continue
    fi
    n="$(nonempty_count "$f")"
    if [ "$n" -lt 2 ]; then
      bad+=("$base: need a heading plus at least one body line (got $n non-empty)")
      continue
    fi
    if ! first="$(first_heading < "$f")"; then
      bad+=("$base: first non-empty line is not an ATX heading")
      continue
    fi
    names+=("$base")
    titles+=("$first")
  done < <(entry_files)
}

render() {
  if [ ! -f "$FROZEN" ] || [ ! -r "$FROZEN" ]; then
    echo "build_check_log: cannot read $FROZEN — state UNKNOWN, not clean." >&2
    return 2
  fi
  if [ ! -d "$ENTRYDIR" ]; then
    echo "build_check_log: missing $ENTRYDIR — state UNKNOWN, not clean." >&2
    return 2
  fi

  scan_entries
  cat "$FROZEN"
  if [ "${#names[@]}" -gt 0 ]; then
    printf '\n## Entries in `check-log.d/`\n\n'
    printf 'Live append surface. Do not append to the monolith above.\n\n'
    printf '| File | Title |\n|---|---|\n'
    local i
    for i in "${!names[@]}"; do
      printf '| `%s` | %s |\n' "${names[$i]}" "${titles[$i]}"
    done
  fi
  if [ "${#bad[@]}" -gt 0 ]; then
    echo >&2
    echo "⚠ malformed check-log.d/ entries (skipped from the index):" >&2
    local b
    for b in "${bad[@]}"; do
      echo "  ✗ $b" >&2
    done
  fi
  return 0
}

do_check() {
  if [ ! -f "$FROZEN" ] || [ ! -r "$FROZEN" ]; then
    echo "build_check_log: cannot read $FROZEN — state UNKNOWN, not clean." >&2
    return 2
  fi
  if [ ! -d "$ENTRYDIR" ]; then
    echo "build_check_log: missing $ENTRYDIR — state UNKNOWN, not clean." >&2
    return 2
  fi

  scan_entries
  if [ "${#bad[@]}" -eq 0 ]; then
    echo "check-log.d/: all ${#names[@]} entries well-formed"
    return 0
  fi
  echo "check-log.d/ malformed entries:" >&2
  local b
  for b in "${bad[@]}"; do
    echo "  ✗ $b" >&2
  done
  return 1
}

do_selftest() {
  local tmp rc
  tmp="$(mktemp -d "${TMPDIR:-/tmp}/hsqjl-checklog.XXXXXX")"
  trap 'rm -rf "$tmp"' RETURN
  mkdir -p "$tmp/docs/dev-log/check-log.d"
  printf '# Frozen\n\nHistorical only.\n' > "$tmp/docs/dev-log/check-log.md"

  printf '# Good slice\n\nBody line with a result: PASS.\n' \
    > "$tmp/docs/dev-log/check-log.d/2026-09-03-good.md"
  "$0" --check "$tmp" >/dev/null
  rc=$?
  [ "$rc" -eq 0 ] || { echo "selftest: good shard should pass, got $rc" >&2; return 1; }

  : > "$tmp/docs/dev-log/check-log.d/2026-09-03-empty.md"
  "$0" --check "$tmp" >/dev/null
  rc=$?
  [ "$rc" -eq 1 ] || { echo "selftest: empty shard should fail, got $rc" >&2; return 1; }
  rm -f "$tmp/docs/dev-log/check-log.d/2026-09-03-empty.md"

  printf 'not a heading\n\nbody\n' \
    > "$tmp/docs/dev-log/check-log.d/2026-09-03-nohead.md"
  "$0" --check "$tmp" >/dev/null
  rc=$?
  [ "$rc" -eq 1 ] || { echo "selftest: no-heading shard should fail, got $rc" >&2; return 1; }
  rm -f "$tmp/docs/dev-log/check-log.d/2026-09-03-nohead.md"

  printf '# Only a title\n' \
    > "$tmp/docs/dev-log/check-log.d/2026-09-03-short.md"
  "$0" --check "$tmp" >/dev/null
  rc=$?
  [ "$rc" -eq 1 ] || { echo "selftest: title-only shard should fail, got $rc" >&2; return 1; }
  rm -f "$tmp/docs/dev-log/check-log.d/2026-09-03-short.md"

  printf '# Undated name\n\nbody\n' \
    > "$tmp/docs/dev-log/check-log.d/undated-name.md"
  "$0" --check "$tmp" >/dev/null
  rc=$?
  [ "$rc" -eq 1 ] || { echo "selftest: undated name should fail, got $rc" >&2; return 1; }
  rm -f "$tmp/docs/dev-log/check-log.d/undated-name.md"

  rm -f "$tmp/docs/dev-log/check-log.md"
  "$0" --check "$tmp" >/dev/null
  rc=$?
  [ "$rc" -eq 2 ] || { echo "selftest: missing frozen log should be UNKNOWN (2), got $rc" >&2; return 1; }

  echo "selftest: ok (empty / no-heading / title-only / undated / UNKNOWN)"
  return 0
}

if [ "$SELFTEST" -eq 1 ]; then
  do_selftest
  exit $?
fi
if [ "$CHECK" -eq 1 ]; then
  do_check
  exit $?
fi
render
exit $?
