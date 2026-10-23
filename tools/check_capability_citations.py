#!/usr/bin/env python3
"""Detect stale file citations in docs/design/capability-status.md.

Adapted from DRM.jl `tools/check_capability_citations.py` (MIT, 2026
Shinichi Nakagawa). Same prove-or-skip contract: a failure always means
something; unresolved citations are SKIPPED, never guessed.

Why this exists
---------------
capability-status.md is the engine-side ledger. A row that points at the
wrong line, a missing file, or a test that never runs is unauditable, which
for this ledger is indistinguishable from unsupported.

HSquared.jl's ledger is not DRM.jl's. DRM cites `src/X.jl:N` include lines.
This ledger mostly cites repo-rooted paths without line numbers, plus the
occasional `test/runtests.jl:N` correctness pin. The DRM RANGE / INCLUDE /
WIRED checks are kept; EXISTS and ANCHOR cover the local shape.

What it checks
--------------
1. RANGE     -- every `file.jl:N` / `file.md:N` exists and N is in range.
2. INCLUDE   -- when nearby prose names a file that `path` actually
                `include`s, the cited line must be that include.
                Also understands `include(joinpath(@__DIR__, "foo.jl"))`,
                which is how `test/runtests.jl` wires sibling tests.
3. ANCHOR    -- a single-line `.jl` citation whose nearby prose names a
                distinctive API (`fit_*`, `*_reml`, `*_mme`, `*_interval`)
                must have that name in a window around the cited line.
                RANGE-only would accept a drifted line that still exists.
4. EXISTS    -- every repo-rooted backtick path (`test/`, `src/`, `docs/`,
                `sim/`, `comparator/`, `ext/`, `tools/`) names a real file.
                Ellipsis paths and bare basenames are skipped.
5. WIRED     -- a `test/test_*.jl` the doc calls in-CI / default-suite must
                actually be included by test/runtests.jl. Commented-out
                includes do not count.

Usage:
    python3 tools/check_capability_citations.py
    python3 tools/check_capability_citations.py --verbose

Exit codes: 0 = nothing provably stale, 1 = at least one provable failure.
"""

from __future__ import annotations

import argparse
import os
import re
import sys

DOC = "docs/design/capability-status.md"
RUNTESTS = "test/runtests.jl"

CITATION = re.compile(r"`([A-Za-z0-9_./-]+\.(?:jl|md|R)):([0-9]+(?:[-,][0-9]+)*)`")
NEARBY_JL = re.compile(r"`([A-Za-z0-9_./-]+\.jl)`")
PATH_ONLY = re.compile(
    r"`((?:test|src|docs|sim|comparator|ext|tools)/[A-Za-z0-9_./-]+\.(?:jl|md|R|tsv))`"
)
# Last quoted .jl inside include(...), so joinpath(@__DIR__, "foo.jl") counts.
INCLUDE_JL = re.compile(r'include\([^)]*"([^"]+\.jl)"')
API_NAME = re.compile(
    r"\b(fit_[A-Za-z0-9_]+|[A-Za-z][A-Za-z0-9_]+_reml|"
    r"[A-Za-z][A-Za-z0-9_]+_mme|[A-Za-z][A-Za-z0-9_]+_interval)\b"
)
WIRED_NEAR = re.compile(
    r"in the default suite|default-suite|in-CI|PINNED IN CI|PINNED as of",
    re.I,
)
ANCHOR_WINDOW = 80
DOC_WINDOW = 400


def expand(spec: str) -> list[int]:
    out: list[int] = []
    for part in spec.split(","):
        if "-" in part:
            lo, hi = (int(x) for x in part.split("-", 1))
            if hi < lo:
                lo, hi = hi, lo
            out.extend(range(lo, hi + 1))
        else:
            out.append(int(part))
    return out


def include_lines(path: str, lines: list[str]) -> dict[str, int]:
    """basename -> 1-based line of its include in `path`."""
    found: dict[str, int] = {}
    for i, line in enumerate(lines, start=1):
        # Strip a trailing Julia comment FIRST. A commented-out
        # `# include("test_x.jl")` must not count as wired.
        code = line.split("#", 1)[0]
        for m in INCLUDE_JL.finditer(code):
            found.setdefault(os.path.basename(m.group(1)), i)
    return found


def nearby_window(text: str, start: int, end: int) -> str:
    """Prefer the enclosing markdown table row; else a fixed character window.

    HSquared capability rows are one long line. A 400-character window around a
    mid-cell `file.jl:N` citation misses the API name at the start of the row.
    """
    line_start = text.rfind("\n", 0, start) + 1
    if line_start < len(text) and text[line_start] == "|":
        line_end = text.find("\n", end)
        return text[line_start : line_end if line_end != -1 else len(text)]
    return text[max(0, start - DOC_WINDOW) : end + DOC_WINDOW]


def nearby_api_names(window: str) -> list[str]:
    seen: list[str] = []
    for name in API_NAME.findall(window):
        if name not in seen:
            seen.append(name)
    return seen


def source_window(lines: list[str], center: int, radius: int) -> str:
    lo = max(1, center - radius)
    hi = min(len(lines), center + radius)
    # lines is split on "\n"; index 0 is file line 1.
    return "\n".join(lines[lo - 1 : hi])


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    ap.add_argument("--verbose", action="store_true", help="also report SKIPPED and OK citations")
    ap.add_argument("--doc", default=DOC, help="capability ledger to check")
    ap.add_argument("--runtests", default=RUNTESTS, help="test runner that wires includes")
    args = ap.parse_args(argv)

    if not os.path.exists(args.doc):
        print(f"ERROR: {args.doc} not found -- run from the repository root.", file=sys.stderr)
        return 1

    text = open(args.doc, encoding="utf-8").read()
    src_cache: dict[str, list[str]] = {}
    inc_cache: dict[str, dict[str, int]] = {}

    failures: list[str] = []
    skipped: list[str] = []
    ok = 0
    line_checked: set[tuple[str, str]] = set()

    def load(path: str) -> list[str]:
        if path not in src_cache:
            src_cache[path] = open(path, encoding="utf-8").read().split("\n")
        return src_cache[path]

    def includes(path: str) -> dict[str, int]:
        if path not in inc_cache:
            inc_cache[path] = include_lines(path, load(path))
        return inc_cache[path]

    for m in CITATION.finditer(text):
        path, spec = m.group(1), m.group(2)
        doc_line = text[: m.start()].count("\n") + 1
        tag = f"{args.doc}:{doc_line}  `{path}:{spec}`"
        line_checked.add((path, spec))

        # --- check 1: RANGE -------------------------------------------------
        if not os.path.exists(path):
            failures.append(f"{tag} -> FILE DOES NOT EXIST")
            continue
        lines = load(path)
        nums = expand(spec)
        out_of_range = [n for n in nums if not (0 < n <= len(lines))]
        if out_of_range:
            failures.append(
                f"{tag} -> LINE(S) {out_of_range} OUT OF RANGE ({path} has {len(lines)} lines)"
            )
            continue

        # --- check 2: INCLUDE -----------------------------------------------
        window = nearby_window(text, m.start(), m.end())
        candidates = {
            os.path.basename(j)
            for j in NEARBY_JL.findall(window)
            if os.path.basename(j) != os.path.basename(path)
        }
        table = includes(path) if path.endswith(".jl") else {}
        resolvable = sorted(candidates & table.keys())

        if len(nums) == 1 and len(resolvable) == 1:
            target = resolvable[0]
            actual = table[target]
            if actual != nums[0]:
                failures.append(
                    f'{tag} -> STALE: `include("{target}")` is at {path}:{actual}, not {nums[0]}'
                )
            else:
                ok += 1
                if args.verbose:
                    print(f'OK   {tag} -> include("{target}") at :{actual}')
            continue

        if len(resolvable) > 1 and len(resolvable) == len(nums):
            expected = sorted(table[t] for t in resolvable)
            got = sorted(nums)
            if expected != got:
                pairs = ", ".join(
                    f"{t} -> :{table[t]}" for t in sorted(resolvable, key=lambda t: table[t])
                )
                failures.append(f"{tag} -> STALE: cited {got}, actual {expected}  ({pairs})")
            else:
                ok += 1
                if args.verbose:
                    print(f"OK   {tag} -> {len(resolvable)} include(s) at {expected}")
            continue

        if len(resolvable) >= 2 and "-" in spec and "," not in spec:
            lo, hi = min(nums), max(nums)
            outside = [t for t in resolvable if not (lo <= table[t] <= hi)]
            if outside:
                where = ", ".join(
                    f"{t} -> :{table[t]}" for t in sorted(outside, key=lambda t: table[t])
                )
                failures.append(f"{tag} -> STALE: range {lo}-{hi} does not contain {where}")
            else:
                ok += 1
                if args.verbose:
                    print(f"OK   {tag} -> range {lo}-{hi} spans {len(resolvable)} include(s)")
            continue

        # --- check 3: ANCHOR ------------------------------------------------
        # Only when INCLUDE could not resolve. Otherwise a nearby fit_* from
        # another sentence would poison an include citation.
        if not resolvable and path.endswith(".jl") and len(nums) == 1:
            apis = nearby_api_names(window)
            if apis:
                hay = source_window(lines, nums[0], ANCHOR_WINDOW)
                hit = [a for a in apis if a in hay]
                if not hit:
                    failures.append(
                        f"{tag} -> STALE ANCHOR: nearby {apis} not in "
                        f"±{ANCHOR_WINDOW} lines of {path}:{nums[0]}"
                    )
                    continue
                ok += 1
                if args.verbose:
                    print(f"OK   {tag} -> anchor {hit} near :{nums[0]}")
                continue

        skipped.append(
            f"{tag} -> not precisely resolvable "
            f"({len(nums)} line(s), {len(resolvable)} include match(es))"
        )

    # --- check 4: EXISTS ----------------------------------------------------
    seen_paths: set[str] = set()
    for m in PATH_ONLY.finditer(text):
        path = m.group(1)
        if "..." in path or path in seen_paths:
            continue
        seen_paths.add(path)
        doc_line = text[: m.start()].count("\n") + 1
        tag = f"{args.doc}:{doc_line}  `{path}`"
        if not os.path.exists(path):
            failures.append(f"{tag} -> FILE DOES NOT EXIST")
        else:
            ok += 1
            if args.verbose:
                print(f"OK   {tag} -> exists")

    # --- check 5: WIRED -----------------------------------------------------
    if os.path.exists(args.runtests):
        wired = includes(args.runtests)
        for tf in sorted(set(re.findall(r"`(?:test/)?(test_[A-Za-z0-9_]+\.jl)`", text))):
            if not os.path.exists(os.path.join("test", tf)):
                continue
            for tm in re.finditer(re.escape(tf), text):
                near = text[max(0, tm.start() - 300) : tm.end() + 300]
                if WIRED_NEAR.search(near):
                    if tf not in wired:
                        failures.append(
                            f"{args.doc}: `{tf}` is described as in-CI / default-suite, "
                            f"but {args.runtests} does not include it"
                        )
                    else:
                        ok += 1
                        if args.verbose:
                            print(f"OK   `{tf}` wired at {args.runtests}:{wired[tf]}")
                    break

    if args.verbose and skipped:
        print(f"\nSKIPPED ({len(skipped)}) -- not provably wrong, not checked:")
        for s in skipped:
            print(f"  {s}")

    if failures:
        print(f"\nSTALE CITATIONS ({len(failures)}):\n")
        for f in failures:
            print(f"  {f}")
        print(
            f"\nFAIL -- {len(failures)} provable failure(s). "
            f"({ok} verified, {len(skipped)} not precisely resolvable.)\n"
            "A capability ledger whose citations do not resolve cannot be audited. Re-point them."
        )
        return 1

    print(
        f"OK -- {ok} citation(s) verified against the source, "
        f"{len(skipped)} skipped as not precisely resolvable."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
