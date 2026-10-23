#!/usr/bin/env python3
"""Tests of tools/check_capability_citations.py.

A guard only ever seen green is an untested guard. This plants a tiny
repo-shaped fixture and asserts the checker fails on injected drift, then
passes on restoration — the same contract DRM.jl recorded for the source
tool (broken single, broken range, broken list, plus HSquared EXISTS /
ANCHOR / joinpath-WIRED cases).
"""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
from pathlib import Path

CHECKER = Path(__file__).resolve().parent / "check_capability_citations.py"


def run_checker(root: Path, extra: list[str] | None = None) -> tuple[int, str]:
    cmd = [sys.executable, str(CHECKER), *(extra or [])]
    proc = subprocess.run(cmd, cwd=root, capture_output=True, text=True)
    return proc.returncode, proc.stdout + proc.stderr


def write_tree(root: Path, files: dict[str, str]) -> None:
    for rel, body in files.items():
        path = root / rel
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(body, encoding="utf-8")


GOOD_HSQUARED = """module HSquared
include("foo.jl")
include("bar.jl")
include("baz.jl")
end
"""

GOOD_FOO = "foo() = 1\n" * 8
GOOD_BAR = "bar() = 2\n" * 8
GOOD_BAZ = "baz() = 3\n" * 8
GOOD_RUNTESTS = (
    "using HSquared\n"
    + ("# pad\n" * 100)
    + """include("foo.jl")
include(joinpath(@__DIR__, "test_wired.jl"))
# include(joinpath(@__DIR__, "test_commented.jl"))
fit_direct_maternal_reml(y) = y
"""
)
GOOD_WIRED = ' @testset "wired" begin end\n'
_PAD = "padding " * 80
GOOD_DOC = f"""# Capability Status
`src/foo.jl` is included at `src/HSquared.jl:2`.
{_PAD}
`src/bar.jl` is included at `src/HSquared.jl:3`.
{_PAD}
Correctness (`test/runtests.jl:105`): `fit_direct_maternal_reml` recovers G_dm.
{_PAD}
Pinned in-CI: `test/test_wired.jl`.
{_PAD}
Evidence also in `sim/phase_ok.jl` and `docs/design/note.md`.
"""


def assert_fail(root: Path, needle: str, label: str) -> None:
    code, out = run_checker(root)
    if code != 1:
        raise SystemExit(f"{label}: expected exit 1, got {code}\n{out}")
    if needle not in out:
        raise SystemExit(f"{label}: expected {needle!r} in output\n{out}")
    print(f"FAIL-AS-DESIGNED  {label}")


def assert_pass(root: Path, label: str) -> None:
    code, out = run_checker(root)
    if code != 0:
        raise SystemExit(f"{label}: expected exit 0, got {code}\n{out}")
    print(f"PASS              {label}")


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        write_tree(
            root,
            {
                "docs/design/capability-status.md": GOOD_DOC,
                "src/HSquared.jl": GOOD_HSQUARED,
                "src/foo.jl": GOOD_FOO,
                "src/bar.jl": GOOD_BAR,
                "src/baz.jl": GOOD_BAZ,
                "test/runtests.jl": GOOD_RUNTESTS,
                "test/test_wired.jl": GOOD_WIRED,
                "test/test_commented.jl": "commented\n",
                "sim/phase_ok.jl": "1\n",
                "docs/design/note.md": "note\n",
            },
        )

        assert_pass(root, "clean fixture")

        # broken single (out of range)
        write_tree(
            root,
            {
                "docs/design/capability-status.md": GOOD_DOC.replace(
                    "`src/HSquared.jl:2`", "`src/HSquared.jl:99`"
                )
            },
        )
        assert_fail(root, "OUT OF RANGE", "broken single citation")

        # missing file
        write_tree(
            root,
            {
                "docs/design/capability-status.md": GOOD_DOC.replace(
                    "`src/HSquared.jl:2`", "`src/missing.jl:1`"
                )
            },
        )
        assert_fail(root, "FILE DOES NOT EXIST", "missing file")

        # stale include (foo is at :2, not :3)
        write_tree(
            root,
            {
                "docs/design/capability-status.md": (
                    "`src/foo.jl` is included at `src/HSquared.jl:3`.\n"
                )
            },
        )
        assert_fail(root, "STALE:", "stale include")

        # broken list (cited 2,3 but actual 2,3 swapped claim 2,4)
        write_tree(
            root,
            {
                "docs/design/capability-status.md": (
                    "`src/foo.jl` and `src/bar.jl` are included at `src/HSquared.jl:2,4`.\n"
                )
            },
        )
        assert_fail(root, "STALE: cited", "broken list")

        # broken range that misses an include (3 nearby files so this is
        # not the equal-length list branch)
        write_tree(
            root,
            {
                "docs/design/capability-status.md": (
                    "`src/foo.jl` and `src/bar.jl` and `src/baz.jl` "
                    "live at `src/HSquared.jl:1-2`.\n"
                )
            },
        )
        assert_fail(root, "does not contain", "broken range")

        # stale anchor: line exists but names the wrong API
        write_tree(
            root,
            {
                "docs/design/capability-status.md": (
                    "Correctness (`test/runtests.jl:1`): `fit_direct_maternal_reml`.\n"
                )
            },
        )
        assert_fail(root, "STALE ANCHOR", "stale anchor")

        # same defect inside a long table row (the live ledger shape)
        write_tree(
            root,
            {
                "docs/design/capability-status.md": (
                    "| Direct-maternal | covered | "
                    "`fit_direct_maternal_reml` estimates G_dm. "
                    + ("later prose. " * 40)
                    + "Correctness (`test/runtests.jl:1`). |\n"
                )
            },
        )
        assert_fail(root, "STALE ANCHOR", "stale anchor in table row")

        # EXISTS miss
        write_tree(
            root,
            {"docs/design/capability-status.md": "See `sim/does_not_exist.jl`.\n"},
        )
        assert_fail(root, "FILE DOES NOT EXIST", "missing repo-rooted path")

        # WIRED: in-CI file not included
        write_tree(
            root,
            {
                "docs/design/capability-status.md": (
                    "PINNED IN CI: `test/test_commented.jl`.\n"
                )
            },
        )
        assert_fail(root, "does not include it", "commented include is not wired")

        # restore
        write_tree(root, {"docs/design/capability-status.md": GOOD_DOC})
        assert_pass(root, "restored fixture")

    print("OK -- citation guard fails on injected drift and passes on restoration.")
    return 0


if __name__ == "__main__":
    os.chdir(Path(__file__).resolve().parent)
    sys.exit(main())
