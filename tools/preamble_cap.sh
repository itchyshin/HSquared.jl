#!/usr/bin/env bash
# preamble_cap.sh -- guard the ALWAYS-LOADED preamble against the accretion ratchet.
#
# WHY THIS EXISTS
#   `CLAUDE.md` @imports `AGENTS.md`, so every byte of AGENTS.md is re-read at the front of every
#   session in this repo. In July 2026 its `## Live Phase Snapshot` reached 31 dated entries and
#   690 lines -- 92% of the file, ~19,200 tokens -- because the block said "Refresh this block in
#   every after-task report" and 31 agents in a row read "refresh" as "prepend". Nothing ever
#   evicted, because nothing ever checked.
#
#   The cost was never money. The preamble sits at the front of the prompt prefix and is the most
#   cacheable object in a session (~0.1x input from turn two). The cost is SALIENCE: `## Core Scope`
#   sat below 690 lines of history asserting "Phase 1 has started", four phases behind ROADMAP.md,
#   for weeks. A guard buried in a wall of prose is a guard that does not fire.
#
# WHY A SCRIPT AND NOT A RULE
#   Because the rule already existed and lost. Worse: after the 2026-07-08 eviction, a trial merge of
#   `feat/2026-07-08-plotting-aog` into the trimmed branch merged CLEANLY and produced TWO entries --
#   the feature branch had prepended one, the trim had deleted the ones below it, and the regions
#   never overlapped. Git raised nothing. A prose instruction cannot survive a merge; this can.
#
# WHAT IT CHECKS
#   1. AGENTS.md is present and readable        -> else UNKNOWN (exit 2), never a silent pass
#   2. exactly <=1 `- **As of` snapshot entry   -> else exit 1 (archive the rest, verbatim)
#   3. AGENTS.md <= CAP_BYTES                   -> else exit 1 (evict / demote / mechanise)
#
#   Deliberately NOT checked: whether the durable sections make stale phase claims. That needs
#   judgement, and a check that pretends to judgement is worse than none. ROADMAP.md and
#   docs/design/capability-status.md are the ledgers; AGENTS.md must make no current claims.
#
# Usage:  tools/preamble_cap.sh [repo_root]        (default: the directory above this script)
#         CAP_BYTES=20000 tools/preamble_cap.sh    (override the byte cap)
# Exit:   0 = within cap · 1 = OVER, act before committing · 2 = could not verify (UNKNOWN)

set -uo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CAP_BYTES="${CAP_BYTES:-14000}"     # ~3,500 tok. The R twin `hsquared` carries the same doctrine in 6,000 B.
MAX_ENTRIES=1

A="$ROOT/AGENTS.md"

# (1) UNKNOWN over silently-clean. A check that cannot read its target has not passed.
if [ ! -f "$A" ] || [ ! -r "$A" ] || [ ! -s "$A" ]; then
  echo "PREAMBLE CAP: cannot read $A -- state UNKNOWN, not clean." >&2
  echo "  (a 0-byte file here usually means a Dropbox online-only placeholder; hydrate it)" >&2
  exit 2
fi

bytes=$(wc -c < "$A" | tr -d ' ')
entries=$(grep -c '^- \*\*As of' "$A" || true)

echo "PREAMBLE CAP -- AGENTS.md is @imported by CLAUDE.md, so this is paid every session."
printf '  size            : %6d B  (~%d tok)   cap %d B\n' "$bytes" "$((bytes / 4))" "$CAP_BYTES"
printf '  snapshot entries: %6d               cap %d\n' "$entries" "$MAX_ENTRIES"

fail=0

if [ "$entries" -gt "$MAX_ENTRIES" ]; then
  fail=1
  echo
  echo "OVER -- $entries snapshot entries; the cap is $MAX_ENTRIES."
  grep -n '^- \*\*As of' "$A" | cut -c1-100 | sed 's/^/    /'
  cat <<'EOF'

    Move every entry but the newest, VERBATIM, to docs/dev-log/phase-snapshot-archive.md.
    Do not summarise them: brevity bias erases exactly the detail that made them worth keeping.
    This most often fires after merging a branch that prepended an entry -- git merges that
    cleanly and says nothing.
EOF
fi

if [ "$bytes" -gt "$CAP_BYTES" ]; then
  fail=1
  echo
  printf 'OVER -- AGENTS.md is %d B, cap %d (over by %d).\n' "$bytes" "$CAP_BYTES" "$((bytes - CAP_BYTES))"
  cat <<'EOF'

    Do ONE of these. Do NOT simply raise the cap -- the cap is the forcing function.
      (a) EVICT     -- history belongs in docs/dev-log/, not in a preamble. Journal it, delete it.
      (b) DEMOTE    -- detail an agent needs only sometimes belongs in a file it reads ON DEMAND
                       (a subdirectory CLAUDE.md, a skill, .claude/agents/*.md).
      (c) MECHANISE -- a rule a script can enforce should be a script. Scripts cost zero preamble.
EOF
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "CAP OK -- preamble within budget."
  exit 0
fi
echo "PREAMBLE CAP FAILED. This is a Definition-of-Done item; fix before committing."
exit 1
