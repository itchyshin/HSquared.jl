"""No-fit regression tests for Arc 1 source/output path containment."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
JULIA = os.environ.get("JULIA", "julia")


class CrossDrivePathTests(unittest.TestCase):
    def run_julia(self, source):
        with tempfile.TemporaryDirectory(prefix="arc1-path-test-") as temp:
            script = Path(temp) / "check.jl"
            script.write_text(source, encoding="utf-8")
            result = subprocess.run(
                [JULIA, "--startup-file=no", "--threads=1", str(script)],
                cwd=ROOT, text=True, capture_output=True, check=False,
                env={**os.environ, "OPENBLAS_NUM_THREADS": "1"},
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_output_disjoint_relative_semantics(self):
        execute = (ROOT / "sim/arc1/execute_attempt.jl").as_posix()
        code = (ROOT / "sim/arc1/execute_attempt.jl").read_text(encoding="utf-8")
        self.assertIn("arc1_output_relative_disjoint(rel_output) ||", code)
        source = rf'''using Test
include({json.dumps(execute)})
@test !arc1_output_relative_disjoint(".")
@test !arc1_output_relative_disjoint("results/child")
@test arc1_output_relative_disjoint("../other")
@test arc1_output_relative_disjoint("..")
absolute = abspath("other-drive-or-root")
old_disjoint(rel) = rel == ".." || startswith(rel, ".." * string(Base.Filesystem.path_separator))
@test !old_disjoint(absolute)  # Regression witness: old rule rejected this.
@test arc1_output_relative_disjoint(absolute)
mktempdir() do temp
    root = joinpath(temp, "source"); mkpath(root)
    child = joinpath(root, "child"); mkpath(child)
    sibling = joinpath(temp, "output"); mkpath(sibling)
    @test !arc1_output_relative_disjoint(relpath(root, root))
    @test !arc1_output_relative_disjoint(relpath(child, root))
    @test arc1_output_relative_disjoint(relpath(sibling, root))
end
if Sys.iswindows()
    @test arc1_output_relative_disjoint(raw"..\inside")
else
    @test !arc1_output_relative_disjoint(raw"..\inside")
end
'''
        self.run_julia(source)

    def test_content_tree_absolute_and_symlink_escapes(self):
        code = (ROOT / "tools/arc1_package_checks.py").read_text(encoding="utf-8")
        start = code.index("function pf_relative_escapes(rel)")
        end = code.index("function pf_source_snapshot(root)", start)
        helper = code[start:end]
        source = '''using Test, SHA
pf_sha(path) = bytes2hex(sha256(read(path)))
''' + helper + r'''
@test !pf_relative_escapes(".")
@test !pf_relative_escapes("subdir/file")
@test pf_relative_escapes("..")
@test pf_relative_escapes("../outside")
absolute = abspath("other-drive-or-root")
old_escapes(rel) = rel == ".." || startswith(rel, ".." * string(Base.Filesystem.path_separator))
@test !old_escapes(absolute)  # Regression witness: old rule missed this.
@test pf_relative_escapes(absolute)
if Sys.iswindows()
    @test pf_relative_escapes(raw"..\inside")
else
    @test !pf_relative_escapes(raw"..\inside")
end
if !Sys.iswindows()
    mktempdir() do temp
        root = joinpath(temp, "root"); mkpath(root)
        write(joinpath(root, "inside"), "inside")
        write(joinpath(temp, "outside"), "outside")
        symlink(joinpath(root, "inside"), joinpath(root, "link-inside"))
        @test !isempty(pf_content_tree(root))
        symlink(joinpath(temp, "outside"), joinpath(root, "link-outside"))
        @test_throws ErrorException pf_content_tree(root)
        rm(joinpath(root, "link-outside"))
        outside_dir = joinpath(temp, "outside-dir"); mkpath(outside_dir)
        symlink(outside_dir, joinpath(root, "link-outside-dir"))
        @test_throws ErrorException pf_content_tree(root)
    end
end
'''
        self.run_julia(source)


if __name__ == "__main__":
    unittest.main()
