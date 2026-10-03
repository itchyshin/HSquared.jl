#!/usr/bin/env python3
"""Run source-frozen Arc1 G7 package checks without a publish-capable path.

Real checks require an independently reviewed external JSON freeze and an
explicit gate selection. The runner has a fixed command allowlist and no
freeze-generation mode. ``--self-test`` uses synthetic files and disposable
Python/Julia child processes; it never launches project tests or docs builds.

Freeze format: ``hsquared-arc1-package-freeze-v3`` with an independent review
record, exact Julia/R roots and runtime pins, complete ``files`` inventories,
and independently reviewed hashes for the resolved Julia test sandbox and
JuliaCall bootstrap environment. R/all freezes require the latter so the
bridge can initialize without using the frozen target project as its setup env.
The v3 freeze adds ``docs_frontend`` for docs/all gates: exact external
package.json and package-lock.json files, a symlink-aware ``node_modules``
tree hash, and NodeJS_20_jll Node/npm paths, hashes, and version outputs. The
runner has no candidate-freeze generation mode.

Required JSON fields are ``review: {status: "reviewed", reviewer,
reviewed_at_utc, review_receipt_path, review_receipt_sha256}``, ``roots:
{julia: JULIA_ROOT, r: R_ROOT}``, ``runtime: {julia, julia_executable,
rscript, rscript_executable}``, ``files: {julia: {relative_path: sha256},
r: {relative_path: sha256}}``, and ``julia_test_sandbox`` with absolute
Project.toml/Manifest.toml paths and SHA-256 values. R/all additionally require
``julia_call_bootstrap`` with absolute Project.toml/Manifest.toml paths and
SHA-256 values. Docs/all additionally require ``docs_frontend`` with absolute
package/lock/tree/runtime paths and their exact hashes/version strings. The
review receipt, sandbox files, bootstrap files, and frontend paths must be
existing external files whose bytes match their digests.
Runtime strings are exact output from the fixed version commands; executable
paths are resolved paths.
"""

from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import stat
import subprocess
import sys
import tempfile
import time
import uuid
from typing import Any

RUNNER = Path(__file__).resolve()
JULIA_ROOT = RUNNER.parents[1].resolve()
R_ROOT = Path("/private/tmp/hsquared-auto-fa-r-20261001").resolve()
EVIDENCE_ROOT = JULIA_ROOT / ".unlazy" / "arc1-gaussian-reliability" / "evidence" / "package-checks"
JULIA_DEPOT = "/private/tmp/hsq-julia-depot:/Users/z3437171/.julia"
JULIA_THREAD_COUNT = "1"
BLAS_THREAD_COUNT = "1"
R_PATH = "/Users/z3437171/.juliaup/bin:/Users/z3437171/miniconda3/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
RUN_TIMEOUT_S = {"julia": 600, "r": 480, "docs": 180}
COMMAND_TIMEOUT_S = {"version": 20}
SCHEMA = "hsquared-arc1-package-freeze-v3"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
DOCS_FRONTEND_KEYS = {
    "package_json_path", "package_json_sha256", "package_lock_path", "package_lock_sha256",
    "node_modules_path", "node_modules_tree_sha256", "node_path", "node_sha256", "node_version",
    "npm_cli_path", "npm_cli_sha256", "npm_version",
}

JULIA_TREES = (
    "src", "test", "sim", "comparator", "ext", "tools", "docs/src", "docs/design",
    "docs/dev-log/recovery-checkpoints",
)
JULIA_FILES = (
    "Project.toml", "Manifest.toml", "README.md", "docs/Project.toml", "docs/Manifest.toml",
    "docs/make.jl", "docs/legacy_reference_redirect.jl",
    "tools/write_validation_status_page.jl", "tools/arc1_oracles.py",
    "tools/arc1_package_checks.py",
)
JULIA_OPTIONAL_FILES = ("Artifacts.toml", "LocalPreferences.toml", "docs/LocalPreferences.toml")
R_TREES = ("R", "tests", "man", "vignettes", "inst", "data", "demo", "exec", "po", "src", "renv")
R_FILES = (
    "DESCRIPTION", "NAMESPACE", ".Rbuildignore", "LICENSE", "LICENSE.md", "LICENSE.txt",
    "COPYING", "COPYING.md", "COPYING.txt", "README", "README.md",
    "NEWS", "NEWS.md", "CITATION", "renv.lock", "configure", "configure.win",
    "cleanup", "cleanup.win", "INDEX",
)
RUNTIME_KEYS = {"julia", "julia_executable", "rscript", "rscript_executable"}

JULIA_BIN = shutil.which("julia") or "julia"
RSCRIPT_BIN = shutil.which("Rscript") or "Rscript"
ACTIVE_PROCESS: subprocess.Popen[Any] | None = None
ACTIVE_RUN: "PackageRun | None" = None

sys.path.insert(0, str(JULIA_ROOT / "tools"))
try:
    import arc1_oracles as _oracle  # shared process-group cleanup, hashing, and Arc1 test driver
except ImportError as exc:  # fail at import time if the reviewed helper is absent
    raise RuntimeError(f"required shared Arc1 runner utilities are unavailable: {exc}") from exc


class PackageCheckError(RuntimeError):
    pass


class RunInterrupted(KeyboardInterrupt):
    pass


def sha256_file(path: Path) -> str:
    return _oracle.sha256_file(path)


def tree_files(root: Path, rel_dir: str) -> list[str]:
    directory = root / rel_dir
    if directory.is_symlink() or not directory.is_dir():
        raise PackageCheckError(f"required input directory is absent or unsafe: {directory}")
    paths: list[str] = []
    if rel_dir == "vignettes":
        buildignore = root / ".Rbuildignore"
        active_rules = {
            line.strip() for line in buildignore.read_text(encoding="utf-8").splitlines()
            if line.strip() and not line.lstrip().startswith("#")
        } if buildignore.is_file() else set()
        if "^vignettes/articles$" not in active_rules:
            raise PackageCheckError("R build-ignore rule for vignettes/articles changed; review inventory policy")
    for path in sorted(directory.rglob("*")):
        relative_parts = path.relative_to(directory).parts
        if rel_dir == "vignettes" and relative_parts and relative_parts[0] == "articles":
            continue
        if any(part in {"__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache"}
               for part in relative_parts):
            continue
        if path.is_symlink():
            raise PackageCheckError(f"symlink in frozen source inventory: {path}")
        if path.is_file() and path.suffix not in {".pyc", ".pyo"} and path.name != ".DS_Store":
            paths.append(path.relative_to(root).as_posix())
    return paths


def build_file_map(julia_root: Path = JULIA_ROOT, r_root: Path = R_ROOT) -> dict[str, dict[str, Path]]:
    julia: dict[str, Path] = {}
    for rel_dir in JULIA_TREES:
        for rel in tree_files(julia_root, rel_dir):
            julia[rel] = julia_root / rel
    for rel in JULIA_FILES:
        path = julia_root / rel
        if path.is_symlink() or not path.is_file():
            raise PackageCheckError(f"required Julia/R/docs input is absent or unsafe: {path}")
        julia[rel] = path
    for rel in JULIA_OPTIONAL_FILES:
        path = julia_root / rel
        if path.exists():
            if path.is_symlink() or not path.is_file():
                raise PackageCheckError(f"unsafe optional Julia input: {path}")
            julia[rel] = path

    r_files: dict[str, Path] = {}
    for rel_dir in R_TREES:
        directory = r_root / rel_dir
        if directory.exists():
            for rel in tree_files(r_root, rel_dir):
                r_files[rel] = r_root / rel
    for rel in R_FILES:
        path = r_root / rel
        if path.exists():
            if path.is_symlink() or not path.is_file():
                raise PackageCheckError(f"unsafe R package metadata input: {path}")
            r_files[rel] = path
    for required in ("DESCRIPTION", "NAMESPACE", ".Rbuildignore"):
        if required not in r_files:
            raise PackageCheckError(f"required R package input is absent: {required}")
    if not all((r_root / x).is_dir() for x in ("R", "tests", "man")):
        raise PackageCheckError("required R package directories R, tests, and man must exist")
    return {"julia": dict(sorted(julia.items())), "r": dict(sorted(r_files.items()))}


def snapshot(file_map: dict[str, dict[str, Path]]) -> dict[str, dict[str, str]]:
    return {group: {rel: sha256_file(path) for rel, path in files.items()}
            for group, files in file_map.items()}


def validate_snapshot(actual: dict[str, dict[str, str]], expected: dict[str, dict[str, str]]) -> None:
    differences: list[str] = []
    for group in sorted(set(actual) | set(expected)):
        a, e = actual.get(group, {}), expected.get(group, {})
        for rel in sorted(set(a) | set(e)):
            if a.get(rel) != e.get(rel):
                differences.append(f"{group}:{rel} expected={e.get(rel)} actual={a.get(rel)}")
    if differences:
        raise PackageCheckError("frozen inputs differ: " + "; ".join(differences[:20]))


def require_success_marker(name: str, status: int, output: str, marker: str | None) -> None:
    if status != 0:
        raise PackageCheckError(f"{name} exited {status}")
    if marker is not None and marker not in output:
        raise PackageCheckError(f"{name} lacks required success marker {marker!r}")


def validate_freeze(doc: Any, expected_roots: dict[str, str], file_map: dict[str, dict[str, Path]],
                    *, gate: str | None = None) -> None:
    if not isinstance(doc, dict) or doc.get("schema") != SCHEMA:
        raise PackageCheckError(f"freeze schema must be {SCHEMA!r}")
    review = doc.get("review")
    if not isinstance(review, dict) or review.get("status") != "reviewed":
        raise PackageCheckError("freeze needs an independent review record with status='reviewed'")
    for key in ("reviewer", "reviewed_at_utc", "review_receipt_path", "review_receipt_sha256"):
        if not isinstance(review.get(key), str) or not review[key].strip():
            raise PackageCheckError(f"freeze review record needs {key}")
    if not Path(review["review_receipt_path"]).is_absolute():
        raise PackageCheckError("review_receipt_path must be absolute")
    if not SHA256_RE.fullmatch(review["review_receipt_sha256"]):
        raise PackageCheckError("review_receipt_sha256 must be lowercase SHA-256")
    if doc.get("roots") != expected_roots:
        raise PackageCheckError(f"freeze roots must exactly equal {expected_roots!r}")
    frozen_files = doc.get("files")
    if not isinstance(frozen_files, dict) or set(frozen_files) != set(file_map):
        raise PackageCheckError("freeze files must contain exact julia and r groups")
    for group, files in file_map.items():
        values = frozen_files.get(group)
        if not isinstance(values, dict) or set(values) != set(files):
            raise PackageCheckError(f"freeze {group} inventory is incomplete or has undeclared paths")
        if any(not isinstance(digest, str) or not SHA256_RE.fullmatch(digest)
               for digest in values.values()):
            raise PackageCheckError(f"freeze {group} contains an invalid SHA-256")
    runtime = doc.get("runtime")
    if not isinstance(runtime, dict) or set(runtime) != RUNTIME_KEYS or any(
        not isinstance(value, str) or not value.strip() for value in runtime.values()
    ):
        raise PackageCheckError("freeze runtime must pin Julia/R versions and executable paths")
    if runtime["julia_executable"] != str(Path(JULIA_BIN).resolve()) or \
       runtime["rscript_executable"] != str(Path(RSCRIPT_BIN).resolve()):
        raise PackageCheckError("runtime executable paths differ from the approved freeze")
    sandbox = doc.get("julia_test_sandbox")
    required = {"project_path", "manifest_path", "project_sha256", "manifest_sha256"}
    if not isinstance(sandbox, dict) or set(sandbox) != required:
        raise PackageCheckError("freeze needs exact julia_test_sandbox paths and hashes")
    sandbox_paths: dict[str, Path] = {}
    for key, filename in (("project_path", "Project.toml"), ("manifest_path", "Manifest.toml")):
        value = sandbox[key]
        path = Path(value) if isinstance(value, str) else Path()
        if not path.is_absolute() or path.is_symlink() or not path.is_file():
            raise PackageCheckError(f"julia_test_sandbox {key} must be an existing absolute nonsymlink file")
        if path.is_relative_to(EVIDENCE_ROOT) or path.name != filename:
            raise PackageCheckError(f"julia_test_sandbox {key} must name an external {filename}")
        sandbox_paths[key] = path
    if sandbox_paths["project_path"].parent != sandbox_paths["manifest_path"].parent:
        raise PackageCheckError("test sandbox Project.toml and Manifest.toml must share a directory")
    for digest_key, path_key in (("project_sha256", "project_path"), ("manifest_sha256", "manifest_path")):
        digest = sandbox[digest_key]
        if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest) or \
           sha256_file(sandbox_paths[path_key]) != digest:
            raise PackageCheckError(f"julia_test_sandbox {digest_key} does not match its external file")
    try:
        _oracle.validate_julia_call_bootstrap(
            doc.get("julia_call_bootstrap"), required=gate in {"r", "all"})
    except _oracle.OracleError as exc:
        raise PackageCheckError(str(exc)) from exc
    frontend = doc.get("docs_frontend")
    if gate in {"docs", "all"} or frontend is not None:
        validate_docs_frontend(frontend)


def _external_file(spec: dict[str, Any], path_key: str, digest_key: str, *, expected_name: str | None = None) -> Path:
    value = spec.get(path_key)
    path = Path(value) if isinstance(value, str) else Path()
    if not path.is_absolute() or path.is_symlink() or not path.is_file():
        raise PackageCheckError(f"docs_frontend {path_key} must be an existing absolute nonsymlink file")
    if path.is_relative_to(EVIDENCE_ROOT):
        raise PackageCheckError(f"docs_frontend {path_key} must be outside runner-created evidence")
    if expected_name is not None and path.name != expected_name:
        raise PackageCheckError(f"docs_frontend {path_key} must name {expected_name}")
    digest = spec.get(digest_key)
    if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest) or sha256_file(path) != digest:
        raise PackageCheckError(f"docs_frontend {digest_key} does not match its external file")
    return path


def validate_docs_frontend(spec: Any, *, verify_runtime: bool = True) -> dict[str, Any]:
    """Validate the independently frozen VitePress package, lock, tree, and JLL tools."""
    if not isinstance(spec, dict) or set(spec) != DOCS_FRONTEND_KEYS:
        raise PackageCheckError("freeze needs exact docs_frontend package, lock, tree, and Node/npm pins")
    package = _external_file(spec, "package_json_path", "package_json_sha256", expected_name="package.json")
    lockfile = _external_file(spec, "package_lock_path", "package_lock_sha256", expected_name="package-lock.json")
    node_modules_value = spec.get("node_modules_path")
    node_modules = Path(node_modules_value) if isinstance(node_modules_value, str) else Path()
    if not node_modules.is_absolute() or node_modules.is_symlink() or not node_modules.is_dir():
        raise PackageCheckError("docs_frontend node_modules_path must be an existing absolute nonsymlink directory")
    if node_modules.is_relative_to(EVIDENCE_ROOT):
        raise PackageCheckError("docs_frontend node_modules_path must be outside runner-created evidence")
    if package.parent != lockfile.parent or package.parent != node_modules.parent:
        raise PackageCheckError("docs_frontend package.json, lock, and node_modules must share one external root")
    for path_key, digest_key in (("node_path", "node_sha256"), ("npm_cli_path", "npm_cli_sha256")):
        value = spec.get(path_key)
        path = Path(value) if isinstance(value, str) else Path()
        if not path.is_absolute() or path.is_symlink() or not path.is_file() or path.is_relative_to(EVIDENCE_ROOT):
            raise PackageCheckError(f"docs_frontend {path_key} must be an external absolute nonsymlink file")
        digest = spec.get(digest_key)
        if not isinstance(digest, str) or not SHA256_RE.fullmatch(digest) or sha256_file(path) != digest:
            raise PackageCheckError(f"docs_frontend {digest_key} does not match its external executable input")
    for version_key in ("node_version", "npm_version"):
        if not isinstance(spec.get(version_key), str) or not spec[version_key].strip():
            raise PackageCheckError(f"docs_frontend {version_key} must pin exact runtime output")
    actual_tree = frontend_tree_hash(node_modules)
    if actual_tree != spec.get("node_modules_tree_sha256"):
        raise PackageCheckError("docs_frontend node_modules tree hash does not match its external tree")
    try:
        package_doc = json.loads(package.read_text(encoding="utf-8"))
        lock_doc = json.loads(lockfile.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise PackageCheckError(f"docs_frontend package metadata is invalid JSON: {exc}") from exc
    lock_root = lock_doc.get("packages", {}).get("")
    if not isinstance(lock_root, dict) or lock_doc.get("lockfileVersion") != 3:
        raise PackageCheckError("docs_frontend lock must be npm lockfileVersion 3 with a root package record")
    for group in ("dependencies", "devDependencies", "optionalDependencies"):
        if package_doc.get(group, {}) != lock_root.get(group, {}):
            raise PackageCheckError(f"docs_frontend lock root does not match package.json {group}")
    resolved = [item for name, item in lock_doc.get("packages", {}).items()
                if name and isinstance(item, dict) and "resolved" in item]
    if not resolved or any(not isinstance(item.get("integrity"), str) or not item["integrity"]
                           for item in resolved):
        raise PackageCheckError("docs_frontend lock must integrity-pin every resolved dependency")
    if any(not item["resolved"].startswith("https://registry.npmjs.org/") for item in resolved):
        raise PackageCheckError("docs_frontend lock contains a dependency outside registry.npmjs.org")
    if verify_runtime:
        node_path = Path(spec["node_path"])
        npm_cli = Path(spec["npm_cli_path"])
        for label, argv, expected in (
            ("Node", [str(node_path), "--version"], spec["node_version"]),
            ("npm", [str(node_path), str(npm_cli), "--version"], spec["npm_version"]),
        ):
            try:
                result = subprocess.run(argv, check=False, capture_output=True, text=True, timeout=10)
            except (OSError, subprocess.TimeoutExpired) as exc:
                raise PackageCheckError(f"docs_frontend {label} version probe failed: {exc}") from exc
            actual = result.stdout.strip()
            if result.returncode != 0 or actual != expected:
                raise PackageCheckError(f"docs_frontend {label} runtime drift: expected {expected!r}, got {actual!r}")
    return {"package_json_sha256": spec["package_json_sha256"],
            "package_lock_sha256": spec["package_lock_sha256"],
            "node_modules_tree_sha256": actual_tree,
            "node_version": spec["node_version"], "npm_version": spec["npm_version"]}


def _julia_env() -> dict[str, str]:
    return {
        "JULIA_DEPOT_PATH": JULIA_DEPOT,
        "JULIA_NUM_THREADS": JULIA_THREAD_COUNT,
        "JULIA_NUM_PRECOMPILE_TASKS": "1",
        "JULIA_PKG_OFFLINE": "true",
        "OPENBLAS_NUM_THREADS": BLAS_THREAD_COUNT,
        "OMP_NUM_THREADS": BLAS_THREAD_COUNT,
        "VECLIB_MAXIMUM_THREADS": BLAS_THREAD_COUNT,
        "ARC1_SKIP_EXPENSIVE_PROFILE_WRAPPER": "0",
    }


def _r_env(run_dir: Path, bootstrap_dir: Path) -> dict[str, str]:
    env = _julia_env()
    env.update({
        "PATH": str(Path(JULIA_BIN).resolve().parent) + os.pathsep + R_PATH,
        "HSQUARED_JULIA_PROJECT": str(JULIA_ROOT),
        "JULIA_PROJECT": str(bootstrap_dir),
        "JULIA_PKG_OFFLINE": "true",
        "HSQUARED_ARC1_REQUIRE_LIVE": "true",
        "ARC1_ORACLE_PACKAGE_ROOT": str(R_ROOT),
        "ARC1_ORACLE_RESULTS_RDS": str(run_dir / "arc1-live-results.rds"),
        "ARC1_ORACLE_RESULTS_CSV": str(run_dir / "arc1-live-results.csv"),
        "ARC1_R_CHECK_DIR": str(run_dir / "r-check"),
        "ARC1_R_RESULT_FILE": str(run_dir / "r-check-result.json"),
    })
    return env


def _version_command(name: str) -> list[str]:
    if name == "julia":
        return [JULIA_BIN, "--startup-file=no", "--version"]
    if name == "rscript":
        return [RSCRIPT_BIN, "--version"]
    raise PackageCheckError(f"unsupported version check: {name}")


JULIA_TEST_SANDBOX_CALLBACK = r'''
function arc1_capture_pkg_test_sandbox()
    project_file = Base.active_project()
    project_file === nothing && error("Pkg.test sandbox has no active Project.toml")
    sandbox_dir = dirname(project_file)
    manifest_file = joinpath(sandbox_dir, "Manifest.toml")
    isfile(manifest_file) || error("Pkg.test sandbox Manifest.toml is absent")
    capture_dir = ENV["ARC1_TEST_SANDBOX_CAPTURE_DIR"]
    mkpath(capture_dir)
    project_copy = joinpath(capture_dir, "Project.toml")
    manifest_copy = joinpath(capture_dir, "Manifest.toml")
    write(project_copy, read(project_file))
    write(manifest_copy, read(manifest_file))
    project_sha = bytes2hex(sha256(read(project_copy)))
    manifest_sha = bytes2hex(sha256(read(manifest_copy)))
    write(joinpath(capture_dir, "sha256.txt"), project_sha * "\n" * manifest_sha * "\n")
    project_sha == ENV["ARC1_TEST_SANDBOX_PROJECT_SHA256"] || error("Pkg.test sandbox Project.toml hash mismatch")
    manifest_sha == ENV["ARC1_TEST_SANDBOX_MANIFEST_SHA256"] || error("Pkg.test sandbox Manifest.toml hash mismatch")
    println("ARC1_TEST_SANDBOX_VERIFIED")
    return nothing
end
'''


def _julia_command(capture_dir: Path, sandbox: dict[str, Any]) -> tuple[list[str], dict[str, str]]:
    env = _julia_env()
    env.update({
        "ARC1_TEST_SANDBOX_CAPTURE_DIR": str(capture_dir),
        "ARC1_TEST_SANDBOX_PROJECT_SHA256": sandbox["project_sha256"],
        "ARC1_TEST_SANDBOX_MANIFEST_SHA256": sandbox["manifest_sha256"],
    })
    driver = (
        'using LinearAlgebra, SHA; BLAS.set_num_threads(1); using Pkg; '
        + JULIA_TEST_SANDBOX_CALLBACK
        + 'Pkg.test(test_fn=arc1_capture_pkg_test_sandbox, allow_reresolve=false); '
          'println("ARC1_PACKAGE_JULIA_COMPONENT_PASS")'
    )
    return ([JULIA_BIN, "--startup-file=no", "--project=.", "-e", driver], env)


R_PACKAGE_DRIVER = r'''check_dir <- Sys.getenv("ARC1_R_CHECK_DIR")
result_file <- Sys.getenv("ARC1_R_RESULT_FILE")
if (!nzchar(check_dir) || !nzchar(result_file)) stop("missing retained R check paths")
dir.create(dirname(check_dir), recursive=TRUE, showWarnings=FALSE)
x <- devtools::check(document=FALSE, cran=FALSE, error_on="never", check_dir=check_dir)
summary <- list(errors=x$errors, warnings=x$warnings, notes=x$notes)
check_log <- file.path(check_dir, "hsquared.Rcheck", "00check.log")
if (!file.exists(check_log)) stop("R CMD check log was not retained")
status <- grep("^Status: ", readLines(check_log, warn=FALSE), value=TRUE)
status_ok <- identical(status, "Status: OK")
writeLines(sprintf('{"errors":%d,"warnings":%d,"notes":%d,"status_ok":%s}',
    length(x$errors), length(x$warnings), length(x$notes), if (status_ok) "true" else "false"),
    con=result_file)
if (!status_ok) stop("R CMD check status was not exactly Status: OK")
if (length(x$errors) || length(x$warnings) || length(x$notes)) stop("R CMD check must have zero errors, warnings, and notes")
cat("ARC1_PACKAGE_R_CHECK_COMPONENT_PASS\n")
'''

REQUIRED_ARC1_TESTSETS = (
    "ARC1 exact FA spectral objectives and analytic gradients",
    "ARC1 optimizer and opt-in policy contracts",
    "Arc1 repeatability profile exact objective",
    "ARC1 fixed-B selector-repeating h² bootstrap",
    "Arc1 interface boundaries",
    "Arc1 independent simulation DGP",
    "Arc1 Julia source and environment provenance adversaries",
    "Arc1 source-bound one-attempt executor",
    "Arc1 reference-admission flags and rank comparison receipts",
)


def parse_julia_test_output(
    output: str, *, required_arc1_testsets: tuple[str, ...] = REQUIRED_ARC1_TESTSETS
) -> dict[str, Any]:
    """Require full Test summaries, no broken/skipped assertions, and Arc1 testsets."""
    summaries: list[dict[str, Any]] = []
    lines = output.splitlines()
    for index, line in enumerate(lines):
        if "Test Summary:" not in line or "|" not in line:
            continue
        columns = line.split("|", 1)[1].split()
        if index + 1 >= len(lines) or "|" not in lines[index + 1]:
            continue
        testset = lines[index + 1].split("|", 1)[0].strip()
        values = lines[index + 1].split("|", 1)[1].split()
        record: dict[str, Any] = {"summary_line": index + 1, "testset": testset}
        for column, value in zip(columns, values):
            if column in {"Pass", "Fail", "Error", "Broken", "Total"}:
                if not value.isdigit():
                    raise PackageCheckError(f"Julia Test Summary count is not an integer: {line!r} / {lines[index + 1]!r}")
                record[column.lower()] = int(value)
        if "total" not in record or "pass" not in record:
            raise PackageCheckError(f"Julia Test Summary lacks Pass/Total counts: {line!r} / {lines[index + 1]!r}")
        summaries.append(record)
    if not summaries:
        raise PackageCheckError("Julia test output contains no parseable Test Summary table")
    for row in summaries:
        for name in ("fail", "error", "broken"):
            if row.get(name, 0) != 0:
                raise PackageCheckError(f"Julia test summary reports {name}={row[name]}: {row}")
    present = {row["testset"] for row in summaries if row.get("pass", 0) > 0 and row.get("total", 0) > 0}
    absent = [name for name in required_arc1_testsets if name not in present]
    if absent:
        raise PackageCheckError("Julia output omitted or had no passing assertions in required Arc1 testsets: " +
                                "; ".join(absent))
    return {"summary_records": summaries,
            "required_arc1_testsets": list(required_arc1_testsets)}


def _r_check_command(run_dir: Path, bootstrap_dir: Path) -> tuple[list[str], dict[str, str]]:
    driver_path = run_dir / "r-package-check-driver.R"
    driver_path.write_text(R_PACKAGE_DRIVER, encoding="utf-8")
    return ([RSCRIPT_BIN, "--vanilla", str(driver_path)], _r_env(run_dir, bootstrap_dir))


def _r_live_command(run_dir: Path, bootstrap_dir: Path) -> tuple[list[str], dict[str, str]]:
    driver_path = run_dir / "r-arc1-live-driver.R"
    driver_path.write_text(_oracle.R_DRIVER, encoding="utf-8")
    return ([RSCRIPT_BIN, "--vanilla", str(driver_path)], _r_env(run_dir, bootstrap_dir))


def _julia_string(path: Path) -> str:
    # JSON basic strings use the quoting/escapes accepted by Julia string literals.
    return json.dumps(str(path.resolve()), ensure_ascii=False)


def make_local_docs_script(source: str, *, repo: Path, scratch_docs: Path, output_docs: Path,
                           redirect_probe: Path, frontend: dict[str, Any]) -> str:
    """Transform only the frozen make script's fixed setup, helpers, and deploy tail."""
    start = "using Pkg\n\nPkg.develop(PackageSpec(path = joinpath(@__DIR__, \"..\")))\nPkg.instantiate()\n\n"
    if source.count(start) != 1:
        raise PackageCheckError("docs/make.jl setup block differs from the reviewed transformation")
    source = source.replace(start, "", 1)
    package_import = "using DocumenterVitepress\nusing HSquared\n"
    package_assertion = (
        "using DocumenterVitepress\nusing HSquared\n"
        "using TOML\n"
        f"@assert realpath(pathof(HSquared)) == realpath({_julia_string(repo / 'src' / 'HSquared.jl')}) "
        "\"docs environment loaded HSquared outside the frozen Julia source root\"\n"
        "const _arc1_jll_node = DocumenterVitepress.node(adjust_PATH = false, adjust_LIBPATH = false)\n"
        f"@assert realpath(_arc1_jll_node.exec[1]) == realpath({_julia_string(Path(frontend['node_path']))}) "
        "\"DocumenterVitepress NodeJS_20_jll Node differs from the reviewed frontend pin\"\n"
        f"@assert realpath(DocumenterVitepress.npm) == realpath({_julia_string(Path(frontend['npm_cli_path']))}) "
        "\"DocumenterVitepress NodeJS_20_jll npm differs from the reviewed frontend pin\"\n"
    )
    if source.count(package_import) != 1:
        raise PackageCheckError("docs/make.jl package imports differ from the reviewed transformation")
    source = source.replace(package_import, package_assertion, 1)
    generator = (
        'include(joinpath(@__DIR__, "..", "tools", "write_validation_status_page.jl"))\n'
        "write_validation_status_table!()"
    )
    generated = (
        f"include({_julia_string(repo / 'tools' / 'write_validation_status_page.jl')})\n"
        f"write_validation_status_table!({_julia_string(scratch_docs / 'src' / 'validation-status.md')})"
    )
    if source.count(generator) != 1:
        raise PackageCheckError("docs/make.jl status writer call differs from reviewed transformation")
    source = source.replace(generator, generated, 1)
    if source.count("makedocs(;\n") != 1:
        raise PackageCheckError("docs/make.jl must contain one standard makedocs call")
    source = source.replace(
        "makedocs(;\n",
        f"makedocs(;\n    root = {_julia_string(scratch_docs)},\n"
        '    source = "src",\n'
        '    build = "build",\n',
        1,
    )
    vitepress_format = "format = MarkdownVitepress(\n"
    local_vitepress_format = (
        "format = MarkdownVitepress(\n"
        "        install_npm = false,\n"
        "        build_vitepress = true,\n"
        f"        inventory_version = TOML.parsefile({_julia_string(repo / 'Project.toml')})[\"version\"],\n"
    )
    if source.count(vitepress_format) != 1:
        raise PackageCheckError("docs/make.jl must contain one standard MarkdownVitepress format block")
    source = source.replace(vitepress_format, local_vitepress_format, 1)
    redirect = (
        'include(joinpath(@__DIR__, "legacy_reference_redirect.jl"))\n'
        "write_legacy_dev_reference_redirect!(@__DIR__)"
    )
    scratch_redirect = (
        f"include({_julia_string(repo / 'docs' / 'legacy_reference_redirect.jl')})\n"
        f"const _arc1_generated_bases = readlines({_julia_string(output_docs / 'build' / 'bases.txt')})\n"
        "@assert _arc1_generated_bases == [\"\"] \"local docs build expected one blank base\"\n"
        f"cd({_julia_string(scratch_docs)}) do\n"
        "    DocumenterVitepress.node(adjust_PATH = true, adjust_LIBPATH = true) do _\n"
        "        run(`$(DocumenterVitepress.npm) run env -- vitepress build build/.documenter`)\n"
        "    end\n"
        "end\n"
        f"const _arc1_validation_html = {_julia_string(output_docs / 'build' / '1' / 'validation-status.html')}\n"
        "@assert isfile(_arc1_validation_html) \"VitePress did not write build/1/validation-status.html\"\n"
        "println(\"ARC1_PACKAGE_DOCS_HTML_BUILT\")\n"
        f"write_legacy_dev_reference_redirect!({_julia_string(output_docs)})\n"
        f"const _arc1_redirect_probe = {_julia_string(redirect_probe)}\n"
        "mkpath(joinpath(_arc1_redirect_probe, \"build\"))\n"
        "write(joinpath(_arc1_redirect_probe, \"build\", \"bases.txt\"), \"dev\\n\")\n"
        "write_legacy_dev_reference_redirect!(_arc1_redirect_probe)"
    )
    if source.count(redirect) != 1:
        raise PackageCheckError("docs/make.jl legacy redirect call differs from reviewed transformation")
    source = source.replace(redirect, scratch_redirect, 1)
    deploy_at = source.rfind("DocumenterVitepress.deploydocs(")
    if deploy_at < 0:
        raise PackageCheckError("docs/make.jl deploydocs call was not found")
    deploy_tail = source[deploy_at:]
    if not re.fullmatch(r"DocumenterVitepress\.deploydocs\(;[\s\S]*\)\s*", deploy_tail):
        raise PackageCheckError("docs/make.jl deploydocs call is not a single final block")
    source = source[:deploy_at] + 'println("ARC1_PACKAGE_DOCS_COMPONENT_PASS")\n'
    if "deploydocs" in source or "Pkg.instantiate" in source or "Pkg.develop" in source:
        raise PackageCheckError("local docs transformation retained package mutation or deployment code")
    return source


def prepare_docs_environment(run_dir: Path) -> Path:
    """Copy pinned docs environment and rebase only its local HSquared path."""
    source_project = (JULIA_ROOT / "docs" / "Project.toml").read_text(encoding="utf-8")
    source_manifest = (JULIA_ROOT / "docs" / "Manifest.toml").read_text(encoding="utf-8")
    old_source = 'HSquared = {path = ".."}'
    new_source = f"HSquared = {{path = {_julia_string(JULIA_ROOT)}}}"
    if source_project.count(old_source) != 1:
        raise PackageCheckError("docs Project.toml source path differs from the reviewed scratch rebasing rule")
    manifest_matches = list(re.finditer(
        r"(?ms)^\[\[deps\.HSquared\]\]\n(?P<body>.*?)(?=^\[\[deps\.|\Z)", source_manifest
    ))
    if len(manifest_matches) != 1:
        raise PackageCheckError("docs Manifest.toml must contain exactly one HSquared path entry")
    block = manifest_matches[0].group(0)
    path_matches = list(re.finditer(r'(?m)^path = "([^"]+)"$', block))
    if len(path_matches) != 1:
        raise PackageCheckError("docs Manifest.toml HSquared entry has an unexpected path representation")
    old_manifest_path = path_matches[0].group(1)
    rebased_block = block[:path_matches[0].start(1)] + str(JULIA_ROOT) + block[path_matches[0].end(1):]
    rebased_manifest = source_manifest.replace(block, rebased_block, 1)
    rebased_project = source_project.replace(old_source, new_source, 1)
    if rebased_project.replace(new_source, old_source, 1) != source_project or \
       rebased_manifest.replace(rebased_block, block, 1) != source_manifest:
        raise PackageCheckError("scratch docs environment would change more than the local HSquared path")
    env_root = run_dir / "docs-environment"
    env_root.mkdir()
    (env_root / "Project.toml").write_text(rebased_project, encoding="utf-8")
    (env_root / "Manifest.toml").write_text(rebased_manifest, encoding="utf-8")
    return env_root


def copy_docs_frontend(spec: dict[str, Any], scratch_docs: Path) -> dict[str, str]:
    """Copy the frozen npm package into the scratch site without dereferencing links."""
    expected = validate_docs_frontend(spec, verify_runtime=False)
    package = Path(spec["package_json_path"])
    lockfile = Path(spec["package_lock_path"])
    node_modules = Path(spec["node_modules_path"])
    shutil.copyfile(package, scratch_docs / "package.json")
    shutil.copyfile(lockfile, scratch_docs / "package-lock.json")
    shutil.copytree(node_modules, scratch_docs / "node_modules", symlinks=True)
    actual = {
        "package_json_sha256": sha256_file(scratch_docs / "package.json"),
        "package_lock_sha256": sha256_file(scratch_docs / "package-lock.json"),
        "node_modules_tree_sha256": frontend_tree_hash(scratch_docs / "node_modules"),
    }
    if any(actual[key] != expected[key] for key in actual):
        raise PackageCheckError("copied docs frontend differs from its independently frozen package inputs")
    return actual


def _docs_command(run_dir: Path, frontend: dict[str, Any]) -> tuple[list[str], dict[str, str]]:
    scratch_docs = run_dir / "scratch-docs"
    scratch_docs.mkdir()
    shutil.copytree(JULIA_ROOT / "docs" / "src", scratch_docs / "src")
    copy_docs_frontend(frontend, scratch_docs)
    docs_environment = prepare_docs_environment(run_dir)
    output_docs = scratch_docs
    make_source = (JULIA_ROOT / "docs" / "make.jl").read_text(encoding="utf-8")
    transformed = make_local_docs_script(
        make_source, repo=JULIA_ROOT, scratch_docs=scratch_docs, output_docs=output_docs,
        redirect_probe=run_dir / "legacy-redirect-contract", frontend=frontend,
    )
    script = run_dir / "local-docs-make.jl"
    script.write_text(transformed, encoding="utf-8")
    env = _julia_env()
    env.update({"GOMAXPROCS": "2", "UV_THREADPOOL_SIZE": "2"})
    return ([JULIA_BIN, "--startup-file=no", f"--project={docs_environment}", str(script)], env)


class PackageRun:
    def __init__(self, gate: str, freeze_path: Path):
        self.gate = gate
        self.freeze_path = freeze_path
        self.started = time.monotonic()
        self.freeze_hash: str | None = None
        self.review_receipt_path: Path | None = None
        self.review_receipt_hash: str | None = None
        self.expected: dict[str, dict[str, str]] | None = None
        self.file_map: dict[str, dict[str, Path]] | None = None
        self.test_sandbox: dict[str, Any] | None = None
        self.julia_call_bootstrap: dict[str, Any] | None = None
        self.julia_call_bootstrap_dir: Path | None = None
        self.docs_frontend: dict[str, Any] | None = None
        self.runner_hash = sha256_file(RUNNER)
        EVIDENCE_ROOT.mkdir(parents=True, exist_ok=True)
        stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        self.out = EVIDENCE_ROOT / f"{stamp}-{uuid.uuid4().hex[:10]}"
        self.out.mkdir()
        self.meta: dict[str, Any] = {
            "schema": "hsquared-arc1-package-check-run-v1", "gate_selection": gate,
            "status": "initializing", "created_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
            "run_dir": str(self.out), "commands": [], "hash_checks": [], "passed_components": [],
            "runner_sha256": self.runner_hash,
            "environment_receipt": {key: os.environ.get(key) for key in (
                "PATH", "JULIA_PROJECT", "JULIA_LOAD_PATH", "JULIA_PKG_SERVER",
                "R_LIBS", "R_LIBS_USER", "R_PROFILE_USER", "R_ENVIRON_USER",
                "RENV_PATHS_LIBRARY",
            )},
        }
        self.save()

    def save(self) -> None:
        temporary = self.out / "run.json.tmp"
        temporary.write_text(json.dumps(self.meta, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        temporary.replace(self.out / "run.json")

    def load_freeze(self) -> dict[str, Any]:
        if not self.freeze_path.is_absolute() or self.freeze_path.is_symlink() or not self.freeze_path.is_file():
            raise PackageCheckError("--freeze must name an existing absolute nonsymlink JSON file")
        if self.freeze_path.is_relative_to(EVIDENCE_ROOT):
            raise PackageCheckError("reviewed source freeze must be external to runner-created evidence")
        raw = self.freeze_path.read_bytes()
        self.freeze_hash = hashlib.sha256(raw).hexdigest()
        try:
            doc = json.loads(raw)
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise PackageCheckError(f"external source freeze JSON is invalid: {exc}") from exc
        self.file_map = build_file_map()
        validate_freeze(doc, {"julia": str(JULIA_ROOT), "r": str(R_ROOT)}, self.file_map, gate=self.gate)
        self.review_receipt_path = Path(doc["review"]["review_receipt_path"])
        if self.review_receipt_path.is_symlink() or not self.review_receipt_path.is_file() or \
           self.review_receipt_path.is_relative_to(EVIDENCE_ROOT):
            raise PackageCheckError("review receipt must be an existing external nonsymlink file")
        self.review_receipt_hash = sha256_file(self.review_receipt_path)
        if self.review_receipt_hash != doc["review"]["review_receipt_sha256"]:
            raise PackageCheckError("independent review receipt SHA-256 does not match the freeze")
        self.expected = doc["files"]
        self.test_sandbox = doc["julia_test_sandbox"]
        self.docs_frontend = doc.get("docs_frontend")
        self.julia_call_bootstrap = _oracle.validate_julia_call_bootstrap(
            doc.get("julia_call_bootstrap"), required=self.gate in {"r", "all"})
        self.meta.update({"freeze_path": str(self.freeze_path), "freeze_sha256": self.freeze_hash,
                          "review": doc["review"], "review_receipt_sha256": self.review_receipt_hash,
                          "runtime_expected": doc["runtime"],
                          "julia_test_sandbox_expected": {
                              "project_sha256": self.test_sandbox["project_sha256"],
                              "manifest_sha256": self.test_sandbox["manifest_sha256"],
                          },
                          "julia_call_bootstrap_expected": self.julia_call_bootstrap,
                          "docs_frontend_expected": (validate_docs_frontend(self.docs_frontend)
                                                      if self.docs_frontend is not None else None),
                          "input_counts": {key: len(value) for key, value in self.file_map.items()}})
        self.verify_inputs("initial")
        return doc

    def verify_inputs(self, label: str) -> dict[str, dict[str, str]]:
        if self.file_map is None or self.expected is None or self.freeze_hash is None:
            raise PackageCheckError("external freeze has not been loaded")
        if sha256_file(RUNNER) != self.runner_hash:
            raise PackageCheckError("package-check runner changed during this run")
        if sha256_file(self.freeze_path) != self.freeze_hash:
            raise PackageCheckError("external source freeze changed during this run")
        if self.review_receipt_path is None or self.review_receipt_hash is None or \
           sha256_file(self.review_receipt_path) != self.review_receipt_hash:
            raise PackageCheckError("independent source-review receipt changed during this run")
        if self.test_sandbox is not None:
            for path_key, digest_key in (("project_path", "project_sha256"),
                                         ("manifest_path", "manifest_sha256")):
                if sha256_file(Path(self.test_sandbox[path_key])) != self.test_sandbox[digest_key]:
                    raise PackageCheckError(f"reviewed Julia test sandbox changed: {path_key}")
        if self.julia_call_bootstrap is not None:
            try:
                _oracle.validate_julia_call_bootstrap(self.julia_call_bootstrap, required=True)
            except _oracle.OracleError as exc:
                raise PackageCheckError(str(exc)) from exc
        if self.docs_frontend is not None:
            validate_docs_frontend(self.docs_frontend, verify_runtime=False)
        current = build_file_map()
        actual_keys = {group: set(paths) for group, paths in current.items()}
        expected_keys = {group: set(paths) for group, paths in self.file_map.items()}
        if actual_keys != expected_keys:
            raise PackageCheckError("frozen input inventory changed: a scoped source/helper file was added or removed")
        hashes = snapshot(current)
        validate_snapshot(hashes, self.expected)
        self.meta["hash_checks"].append({"label": label, "at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
                                         "sha256": hashes})
        self.save()
        return hashes

    def _remaining(self, component: str) -> int:
        elapsed_component = self.meta.get("component_elapsed_s", {}).get(component, 0.0)
        remaining = RUN_TIMEOUT_S[component] - elapsed_component
        if remaining <= 0:
            raise PackageCheckError(f"{component} time budget exhausted")
        return max(1, int(remaining))

    def run_command(self, name: str, argv: list[str], cwd: Path, env_overrides: dict[str, str],
                    timeout_s: int, *, marker: str | None = None, component: str | None = None) -> dict[str, Any]:
        if self.file_map is not None:
            before = self.verify_inputs(f"{name}:before")
        else:
            before = {}
        log_path = self.out / f"{len(self.meta['commands']) + 1:02d}-{name}.log"
        timeout = min(timeout_s, self._remaining(component)) if component else timeout_s
        env = os.environ.copy()
        env.update(env_overrides)
        bootstrap_dir: Path | None = None
        bootstrap_before: dict[str, str] | None = None
        if "JULIA_PROJECT" in env_overrides and self.julia_call_bootstrap is not None:
            bootstrap_dir = Path(env_overrides["JULIA_PROJECT"]).resolve()
            if self.julia_call_bootstrap_dir is None or bootstrap_dir != self.julia_call_bootstrap_dir:
                raise PackageCheckError("R JULIA_PROJECT does not identify this run's isolated JuliaCall bootstrap")
            bootstrap_before = _oracle.bootstrap_snapshot(bootstrap_dir)
        record: dict[str, Any] = {
            "name": name, "component": component, "argv": argv, "cwd": str(cwd), "env_overrides": env_overrides,
            "timeout_s": timeout, "log": log_path.name, "started_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
            "process_status": None, "timed_out": False, "interrupted": False,
            "cleanup": None, "before_sha256": before,
        }
        if bootstrap_before is not None:
            record["julia_call_bootstrap_path"] = str(bootstrap_dir)
            record["julia_call_bootstrap_before_sha256"] = bootstrap_before
        started = time.monotonic()
        interrupted = False
        with log_path.open("wb") as log:
            proc: subprocess.Popen[Any] | None = None
            try:
                proc = subprocess.Popen(argv, cwd=cwd, env=env, stdout=log, stderr=subprocess.STDOUT,
                                        shell=False, start_new_session=True)
                global ACTIVE_PROCESS
                ACTIVE_PROCESS = proc
                try:
                    record["process_status"] = proc.wait(timeout=timeout)
                except subprocess.TimeoutExpired:
                    record["timed_out"] = True
                    record["cleanup"] = _oracle.terminate_group(proc)
                    record["process_status"] = proc.returncode
                except RunInterrupted:
                    record["interrupted"] = True
                    record["cleanup"] = _oracle.terminate_group(proc)
                    record["process_status"] = proc.returncode
                    interrupted = True
                finally:
                    ACTIVE_PROCESS = None
            except FileNotFoundError as exc:
                record["launch_error"] = str(exc)
                record["process_status"] = 127
            finally:
                log.flush()
                os.fsync(log.fileno())
        record["elapsed_s"] = round(time.monotonic() - started, 3)
        record["ended_at_utc"] = dt.datetime.now(dt.timezone.utc).isoformat()
        record["log_sha256"] = sha256_file(log_path)
        if bootstrap_dir is not None and bootstrap_before is not None:
            try:
                bootstrap_after = _oracle.bootstrap_snapshot(bootstrap_dir)
                record["julia_call_bootstrap_after_sha256"] = bootstrap_after
                record["julia_call_bootstrap_changed"] = bootstrap_after != bootstrap_before
                expected_bootstrap = {
                    "Project.toml": self.julia_call_bootstrap["project_sha256"],
                    "Manifest.toml": self.julia_call_bootstrap["manifest_sha256"],
                }
                if bootstrap_before != expected_bootstrap or bootstrap_after != expected_bootstrap:
                    record["after_hash_error"] = "isolated JuliaCall bootstrap Project/Manifest changed"
            except Exception as exc:
                record["after_hash_error"] = f"cannot hash isolated JuliaCall bootstrap: {exc}"
        if component:
            elapsed = self.meta.setdefault("component_elapsed_s", {})
            elapsed[component] = round(elapsed.get(component, 0.0) + record["elapsed_s"], 3)
        if self.file_map is not None:
            try:
                record["after_sha256"] = self.verify_inputs(f"{name}:after")
            except Exception as exc:
                record["after_hash_error"] = str(exc)
                record["after_sha256"] = None
        self.meta["commands"].append(record)
        self.save()
        if record["timed_out"]:
            raise PackageCheckError(f"{name} timed out; process group cleanup={record['cleanup']}")
        if record["interrupted"]:
            raise RunInterrupted("parent signal interrupted command")
        if record.get("launch_error"):
            raise PackageCheckError(f"cannot launch {name}: {record['launch_error']}")
        output = log_path.read_text(encoding="utf-8", errors="replace")
        try:
            require_success_marker(name, record["process_status"], output, marker)
        except PackageCheckError as exc:
            raise PackageCheckError(f"{exc}; see {log_path}") from exc
        if record.get("after_hash_error"):
            raise PackageCheckError(f"{name} changed a frozen input or bootstrap environment: {record['after_hash_error']}")
        return record

    def check_runtime(self, doc: dict[str, Any]) -> None:
        selected = sorted({"julia", "rscript"} if self.gate in ("r", "all") else {"julia"})
        observed: dict[str, str] = {}
        for name in selected:
            exe = JULIA_ROOT if name == "julia" else R_ROOT
            argv = _version_command(name)
            record = self.run_command(f"{name}-version", argv, exe, _julia_env(),
                                      COMMAND_TIMEOUT_S["version"])
            version_output = (self.out / record["log"]).read_text(encoding="utf-8", errors="replace").strip()
            expected = doc["runtime"][name]
            if version_output != expected:
                raise PackageCheckError(f"{name} runtime mismatch: expected {expected!r}, observed {version_output!r}")
            observed[name] = version_output
        self.meta["runtime_observed"] = observed
        self.save()

    def run_julia(self) -> None:
        if self.test_sandbox is None:
            raise PackageCheckError("reviewed Julia test sandbox is unavailable")
        capture_dir = self.out / "julia-test-sandbox"
        argv, env = _julia_command(capture_dir, self.test_sandbox)
        profile_test_source = (JULIA_ROOT / "test" / "arc1_profiles.jl").read_text(encoding="utf-8")
        if env.get("ARC1_SKIP_EXPENSIVE_PROFILE_WRAPPER") != "0" or \
           'if get(ENV, "ARC1_SKIP_EXPENSIVE_PROFILE_WRAPPER", "0") != "1"' not in profile_test_source or \
           'all-five Arc1 profile wrapper reports one shared point maximum' not in profile_test_source:
            raise PackageCheckError("Arc1 all-five profile wrapper is not proven enabled by the frozen test source")
        record = self.run_command("julia-pkg-test", argv, JULIA_ROOT, env, RUN_TIMEOUT_S["julia"],
                                  marker="ARC1_PACKAGE_JULIA_COMPONENT_PASS", component="julia")
        captured_project = capture_dir / "Project.toml"
        captured_manifest = capture_dir / "Manifest.toml"
        captured_receipt = capture_dir / "sha256.txt"
        if not all(path.is_file() for path in (captured_project, captured_manifest, captured_receipt)):
            raise PackageCheckError("Pkg.test did not retain its sandbox callback capture")
        test_output = (self.out / record["log"]).read_text(encoding="utf-8", errors="replace")
        if "ARC1_TEST_SANDBOX_VERIFIED" not in test_output:
            raise PackageCheckError("Pkg.test did not report successful sandbox verification before tests")
        observed_sandbox = {
            "project_sha256": sha256_file(captured_project),
            "manifest_sha256": sha256_file(captured_manifest),
        }
        if observed_sandbox != {key: self.test_sandbox[key] for key in observed_sandbox}:
            raise PackageCheckError(f"captured Pkg.test sandbox differs from reviewed candidate: {observed_sandbox}")
        expected_receipt = observed_sandbox["project_sha256"] + "\n" + observed_sandbox["manifest_sha256"] + "\n"
        if captured_receipt.read_text(encoding="ascii") != expected_receipt:
            raise PackageCheckError("Pkg.test sandbox callback receipt does not match captured files")
        test_summary = parse_julia_test_output(test_output)
        self.meta["julia_test_summary"] = test_summary
        self.meta.setdefault("component_receipts", {})["julia"] = {
            "status": "passed", "log": record["log"], "log_sha256": record["log_sha256"],
            "test_summary": test_summary, "elapsed_s": record["elapsed_s"],
            "test_sandbox": {**observed_sandbox, "capture_dir": str(capture_dir)},
        }
        self.meta["passed_components"].append("julia")
        self.save()

    def run_r(self) -> None:
        if self.julia_call_bootstrap is None:
            raise PackageCheckError("R package checks require the reviewed JuliaCall bootstrap environment")
        self.julia_call_bootstrap_dir, bootstrap_hashes = _oracle.prepare_julia_call_bootstrap(
            self.julia_call_bootstrap, self.out)
        self.meta["julia_call_bootstrap_run"] = {
            "path": str(self.julia_call_bootstrap_dir), "initial_sha256": bootstrap_hashes,
        }
        self.save()
        live_argv, live_env = _r_live_command(self.out, self.julia_call_bootstrap_dir)
        live_record = self.run_command("r-arc1-mandatory-live", live_argv, R_ROOT, live_env,
                                       RUN_TIMEOUT_S["r"], marker="ARC1_TESTTHAT_COUNTS", component="r")
        # The shared R driver returns nonzero for empty, failed, error, or skipped
        # Arc1 test files, so its zero exit plus retained tables is required.
        for path in (self.out / "arc1-live-results.rds", self.out / "arc1-live-results.csv"):
            if not path.is_file() or path.stat().st_size == 0:
                raise PackageCheckError(f"mandatory-live R driver did not retain {path.name}")
        check_argv, check_env = _r_check_command(self.out, self.julia_call_bootstrap_dir)
        check_record = self.run_command("r-cmd-check", check_argv, R_ROOT, check_env,
                                        RUN_TIMEOUT_S["r"], marker="ARC1_PACKAGE_R_CHECK_COMPONENT_PASS", component="r")
        check_log = self.out / "r-check" / "hsquared.Rcheck" / "00check.log"
        if not check_log.is_file() or "Status: OK" not in check_log.read_text(errors="replace").splitlines():
            raise PackageCheckError("R check directory lacks exact Status: OK result")
        result_file = self.out / "r-check-result.json"
        try:
            check_result = json.loads(result_file.read_text(encoding="utf-8"))
        except (OSError, UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise PackageCheckError(f"R check result is missing or invalid JSON: {exc}") from exc
        if check_result != {"errors": 0, "warnings": 0, "notes": 0, "status_ok": True}:
            raise PackageCheckError(f"R check result did not retain exact clean counts: {check_result!r}")
        self.meta["r_result_sha256"] = sha256_file(result_file)
        self.meta["r_check_log_sha256"] = sha256_file(check_log)
        self.meta["r_check_tree_sha256"] = tree_hash(self.out / "r-check")
        self.meta["r_live_result_sha256"] = {
            "rds": sha256_file(self.out / "arc1-live-results.rds"),
            "csv": sha256_file(self.out / "arc1-live-results.csv"),
        }
        self.meta.setdefault("component_receipts", {})["r"] = {
            "status": "passed", "live_log": live_record["log"], "live_log_sha256": live_record["log_sha256"],
            "check_log": check_record["log"], "check_log_sha256": check_record["log_sha256"],
            "result_sha256": self.meta["r_result_sha256"], "check_tree_sha256": self.meta["r_check_tree_sha256"],
            "elapsed_s": round(live_record["elapsed_s"] + check_record["elapsed_s"], 3),
        }
        self.meta["passed_components"].append("r")
        self.save()

    def run_docs(self) -> None:
        source_page = JULIA_ROOT / "docs" / "src" / "validation-status.md"
        source_page_before = sha256_file(source_page)
        existing_build = JULIA_ROOT / "docs" / "build"
        build_before = tree_hash(existing_build) if existing_build.exists() else None
        if self.docs_frontend is None:
            raise PackageCheckError("docs build requires independently frozen npm frontend inputs")
        argv, env = _docs_command(self.out, self.docs_frontend)
        copied_frontend = {
            "package_json_sha256": sha256_file(self.out / "scratch-docs" / "package.json"),
            "package_lock_sha256": sha256_file(self.out / "scratch-docs" / "package-lock.json"),
            "node_modules_tree_sha256": frontend_tree_hash(self.out / "scratch-docs" / "node_modules"),
        }
        docs_environment = self.out / "docs-environment"
        self.meta["docs_frontend_resource_caps"] = {
            key: env[key] for key in ("GOMAXPROCS", "UV_THREADPOOL_SIZE")
        }
        self.meta["docs_environment_sha256"] = {
            "Project.toml": sha256_file(docs_environment / "Project.toml"),
            "Manifest.toml": sha256_file(docs_environment / "Manifest.toml"),
        }
        docs_record = self.run_command("julia-local-docs", argv, JULIA_ROOT, env,
                                       RUN_TIMEOUT_S["docs"], marker="ARC1_PACKAGE_DOCS_COMPONENT_PASS", component="docs")
        docs_log = (self.out / docs_record["log"]).read_text(encoding="utf-8", errors="replace")
        if "ARC1_PACKAGE_DOCS_HTML_BUILT" not in docs_log:
            raise PackageCheckError("docs script did not retain its post-build HTML marker")
        scratch_frontend_after = {
            "package_json_sha256": sha256_file(self.out / "scratch-docs" / "package.json"),
            "package_lock_sha256": sha256_file(self.out / "scratch-docs" / "package-lock.json"),
            "node_modules_tree_sha256": frontend_tree_hash(self.out / "scratch-docs" / "node_modules"),
        }
        if scratch_frontend_after != copied_frontend:
            raise PackageCheckError("Documenter/VitePress modified the frozen scratch frontend inputs")
        if sha256_file(source_page) != source_page_before:
            raise PackageCheckError("source validation-status page changed during isolated docs build")
        build_after = tree_hash(existing_build) if existing_build.exists() else None
        if build_before != build_after:
            raise PackageCheckError("pre-existing docs/build changed during isolated docs build")
        output_build = self.out / "scratch-docs" / "build"
        if not output_build.is_dir():
            raise PackageCheckError("Documenter did not create the isolated output tree")
        if not (output_build / "bases.txt").is_file():
            raise PackageCheckError("Documenter output lacks bases.txt; legacy redirect could not be checked")
        actual_redirects = validate_legacy_redirect_outputs(output_build)
        redirect_probe_build = self.out / "legacy-redirect-contract" / "build"
        probe_redirects = validate_legacy_redirect_outputs(redirect_probe_build)
        scratch_status = self.out / "scratch-docs" / "src" / "validation-status.md"
        scratch_text = scratch_status.read_text(encoding="utf-8")
        if "<!-- BEGIN GENERATED validation-status-table -->" not in scratch_text or \
           "<!-- END GENERATED validation-status-table -->" not in scratch_text:
            raise PackageCheckError("scratch validation status output lacks its generated table markers")
        rendered_status = output_build / "1" / "validation-status.html"
        if not rendered_status.is_file():
            raise PackageCheckError("Documenter output did not render validation-status.html")
        rendered_text = rendered_status.read_text(encoding="utf-8", errors="replace")
        if "Validation Status" not in rendered_text:
            raise PackageCheckError("rendered validation-status page lacks its expected heading")
        self.meta["docs_source_status_sha256"] = source_page_before
        self.meta["docs_frontend_scratch_sha256"] = scratch_frontend_after
        self.meta["docs_scratch_status_sha256"] = sha256_file(scratch_status)
        self.meta["docs_rendered_status_pages"] = [
            {"path": str(rendered_status.relative_to(output_build)), "sha256": sha256_file(rendered_status)}
        ]
        self.meta["docs_preexisting_build_hash"] = build_before
        self.meta["docs_output_tree_hash"] = tree_hash(output_build)
        self.meta["legacy_redirect_probe_sha256"] = tree_hash(self.out / "legacy-redirect-contract")
        self.meta["legacy_redirects"] = {"actual_build": actual_redirects, "dev_probe": probe_redirects}
        self.meta["docs_environment_after_sha256"] = {
            "Project.toml": sha256_file(docs_environment / "Project.toml"),
            "Manifest.toml": sha256_file(docs_environment / "Manifest.toml"),
        }
        if self.meta["docs_environment_after_sha256"] != self.meta["docs_environment_sha256"]:
            raise PackageCheckError("scratch docs environment changed during local build")
        self.meta.setdefault("component_receipts", {})["docs"] = {
            "status": "passed", "log": self.meta["commands"][-1]["log"],
            "log_sha256": self.meta["commands"][-1]["log_sha256"],
            "script": str(self.out / "local-docs-make.jl"),
            "script_sha256": sha256_file(self.out / "local-docs-make.jl"),
            "output_tree_sha256": self.meta["docs_output_tree_hash"],
            "elapsed_s": self.meta["commands"][-1]["elapsed_s"],
        }
        self.meta["passed_components"].append("docs")
        self.save()

    def run(self) -> int:
        try:
            freeze = self.load_freeze()
            self.save()
            self.check_runtime(freeze)
            ordered = ("julia", "r", "docs") if self.gate == "all" else (self.gate,)
            for component in ordered:
                if component == "julia":
                    self.run_julia()
                elif component == "r":
                    self.run_r()
                else:
                    self.run_docs()
            self.verify_inputs("final")
            self.meta.update({"status": "passed", "ended_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
                              "elapsed_s": round(time.monotonic() - self.started, 3)})
            self.save()
            if self.gate == "all":
                print(f"ARC1_PACKAGE_DOCS_PASS freeze_sha256={self.freeze_hash} run_dir={self.out}")
                print(f"ARC1_PACKAGE_CHECKS_G7_PASS run_dir={self.out}")
            else:
                print(f"ARC1_PACKAGE_{self.gate.upper()}_COMPONENT_PASS freeze_sha256={self.freeze_hash} run_dir={self.out}")
            return 0
        except RunInterrupted as exc:
            self.meta.update({"status": "interrupted", "error": f"{type(exc).__name__}: {exc}"})
            return self.fail(130)
        except KeyboardInterrupt:
            self.meta.update({"status": "interrupted", "error": "runner interrupted"})
            return self.fail(130)
        except Exception as exc:
            self.meta.update({"status": "failed", "error": f"{type(exc).__name__}: {exc}"})
            return self.fail(1)

    def fail(self, status: int) -> int:
        self.meta.update({"ended_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
                          "elapsed_s": round(time.monotonic() - self.started, 3)})
        self.save()
        print(f"ARC1_PACKAGE_CHECK_FAILED gate={self.gate} run_dir={self.out}: {self.meta['error']}",
              file=sys.stderr)
        return status


def tree_hash(path: Path) -> str:
    if path.is_symlink() or not path.is_dir():
        raise PackageCheckError(f"unsafe directory to hash: {path}")
    entries: list[tuple[str, str, str]] = []
    for item in sorted(path.rglob("*")):
        if item.is_symlink():
            raise PackageCheckError(f"symlink in directory hash: {item}")
        rel = item.relative_to(path).as_posix()
        if item.is_dir():
            entries.append(("directory", rel, ""))
        elif item.is_file():
            entries.append(("file", rel, sha256_file(item)))
    return hashlib.sha256(json.dumps(entries, separators=(",", ":")).encode()).hexdigest()


def validate_legacy_redirect_outputs(build_dir: Path) -> dict[str, Any]:
    """Check redirect files against the bases for which the helper emits them."""
    bases_file = build_dir / "bases.txt"
    if not bases_file.is_file():
        raise PackageCheckError("Documenter output lacks bases.txt; legacy redirect could not be checked")
    bases = [base for base in bases_file.read_text(encoding="utf-8").splitlines() if base]
    expected: dict[Path, str] = {}
    for index, base in enumerate(bases, start=1):
        if base == "dev":
            version_dir = build_dir / str(index) / "reference"
            expected[version_dir.parent / "reference.html"] = "../stable/api.html"
            expected[version_dir / "index.html"] = "../../stable/api.html"
    actual = set(build_dir.rglob("reference.html")) | set(build_dir.rglob("reference/index.html"))
    if actual != set(expected):
        raise PackageCheckError(
            "legacy redirect files differ from bases.txt: "
            f"expected {[str(p.relative_to(build_dir)) for p in sorted(expected)]}, "
            f"found {[str(p.relative_to(build_dir)) for p in sorted(actual)]}"
        )
    for path, target in expected.items():
        content = path.read_text(encoding="utf-8", errors="replace")
        refresh = f'<meta http-equiv="refresh" content="0; url={target}">'
        if "Moved to" not in content or f'href="{target}"' not in content or refresh not in content:
            raise PackageCheckError(f"legacy redirect has unexpected target or content: {path}")
    return {"bases": bases, "redirects": [str(p.relative_to(build_dir)) for p in sorted(expected)]}


def frontend_tree_hash(path: Path) -> str:
    """Hash a frozen npm tree while recording, and containing, its bin symlinks."""
    if path.is_symlink() or not path.is_dir():
        raise PackageCheckError(f"unsafe frontend directory to hash: {path}")
    entries: list[tuple[str, str, str]] = [
        ("directory", ".", f"{stat.S_IMODE(path.stat().st_mode):04o}")
    ]
    root = path.resolve()
    for item in sorted(path.rglob("*")):
        rel = item.relative_to(path).as_posix()
        if item.is_symlink():
            try:
                target = item.resolve(strict=True)
            except OSError as exc:
                raise PackageCheckError(f"broken symlink in frontend tree: {item}") from exc
            if not target.is_relative_to(root):
                raise PackageCheckError(f"frontend symlink escapes frozen tree: {item} -> {target}")
            entries.append(("symlink", rel,
                            f"{stat.S_IMODE(item.lstat().st_mode):04o}:{os.readlink(item)}"))
        elif item.is_dir():
            entries.append(("directory", rel, f"{stat.S_IMODE(item.stat().st_mode):04o}"))
        elif item.is_file():
            entries.append(("file", rel,
                            f"{stat.S_IMODE(item.stat().st_mode):04o}:{sha256_file(item)}"))
    return hashlib.sha256(json.dumps(entries, separators=(",", ":")).encode()).hexdigest()


def _self_test_package_run(root: Path) -> None:
    global EVIDENCE_ROOT, build_file_map
    original_evidence_root = EVIDENCE_ROOT
    original_builder = build_file_map
    EVIDENCE_ROOT = root / "synthetic-evidence"
    try:
        frozen_root = root / "runtime-input"
        (frozen_root / "src").mkdir(parents=True)
        frozen_input = frozen_root / "src" / "sentinel.jl"
        frozen_input.write_text("stable", encoding="utf-8")
        synthetic_map = {"julia": {"src/sentinel.jl": frozen_input}, "r": {}}
        build_file_map = lambda: synthetic_map
        receipt = root / "review-receipt.txt"
        receipt.write_text("external synthetic review", encoding="utf-8")
        freeze_path = root / "external-freeze.json"
        freeze_path.write_text("{}", encoding="utf-8")

        def new_run() -> PackageRun:
            run = PackageRun("julia", freeze_path)
            run.file_map = synthetic_map
            run.expected = snapshot(synthetic_map)
            run.freeze_hash = sha256_file(freeze_path)
            run.review_receipt_path = receipt
            run.review_receipt_hash = sha256_file(receipt)
            return run

        run = new_run()
        passed = run.run_command("synthetic-pass", [sys.executable, "-c",
            "print('RUNNER_PASS_MARKER')"], root, {}, 3, marker="RUNNER_PASS_MARKER")
        assert passed["process_status"] == 0 and len(run.meta["commands"]) == 1

        def rejected(label: str, argv: list[str], *, timeout: float, marker: str | None = None,
                     interrupt: bool = False) -> None:
            candidate = new_run()
            real_popen = subprocess.Popen
            try:
                if interrupt:
                    class InterruptingPopen:
                        def __init__(self, *args: Any, **kwargs: Any):
                            self._proc = real_popen(*args, **kwargs)
                            self._interrupt_once = True

                        def __getattr__(self, name: str) -> Any:
                            return getattr(self._proc, name)

                        def wait(self, timeout: float | None = None) -> int:
                            if self._interrupt_once:
                                self._interrupt_once = False
                                _signal_handler(signal.SIGTERM, None)
                            return self._proc.wait(timeout=timeout)

                    subprocess.Popen = InterruptingPopen  # type: ignore[assignment]
                candidate.run_command(label, argv, root, {}, timeout, marker=marker)
            except (PackageCheckError, RunInterrupted):
                assert candidate.meta["commands"], f"{label} did not retain a command receipt"
            else:
                raise AssertionError(f"{label} was incorrectly accepted")
            finally:
                if interrupt:
                    subprocess.Popen = real_popen  # type: ignore[assignment]

        rejected("synthetic-failure", [sys.executable, "-c", "raise SystemExit(9)"], timeout=3)
        rejected("synthetic-marker", [sys.executable, "-c", "print('wrong marker')"],
                 timeout=3, marker="RUNNER_PASS_MARKER")
        rejected("synthetic-timeout", [sys.executable, "-c", "import time; time.sleep(5)"],
                 timeout=0.1)
        rejected("synthetic-interrupt", [sys.executable, "-c", "import time; time.sleep(5)"],
                 timeout=3, interrupt=True)
        rejected("synthetic-hash-change", [sys.executable, "-c",
            f"from pathlib import Path; p=Path({str(frozen_input)!r}); p.write_text('changed'); print('RUNNER_PASS_MARKER')"],
            timeout=3, marker="RUNNER_PASS_MARKER")
        frozen_input.write_text("stable", encoding="utf-8")

        bootstrap_run = new_run()
        template = _oracle.JULIA_CALL_BOOTSTRAP_TEMPLATE
        bootstrap_spec = {
            "project_path": str((template / "Project.toml").resolve()),
            "manifest_path": str((template / "Manifest.toml").resolve()),
            "project_sha256": sha256_file(template / "Project.toml"),
            "manifest_sha256": sha256_file(template / "Manifest.toml"),
        }
        bootstrap_run.julia_call_bootstrap = bootstrap_spec
        bootstrap_run.julia_call_bootstrap_dir, _ = _oracle.prepare_julia_call_bootstrap(
            bootstrap_spec, bootstrap_run.out)
        bootstrap_run.julia_call_bootstrap_dir = bootstrap_run.julia_call_bootstrap_dir.resolve()
        bootstrap_project = bootstrap_run.julia_call_bootstrap_dir / "Project.toml"
        try:
            bootstrap_run.run_command("synthetic-bootstrap-mutation", [sys.executable, "-c",
                f"from pathlib import Path; p=Path({str(bootstrap_project)!r}); p.write_text('changed'); print('RUNNER_PASS_MARKER')"],
                root, {"JULIA_PROJECT": str(bootstrap_run.julia_call_bootstrap_dir)}, 3,
                marker="RUNNER_PASS_MARKER")
        except PackageCheckError:
            command_receipt = bootstrap_run.meta["commands"][-1]
            assert command_receipt["julia_call_bootstrap_changed"] is True
            assert command_receipt["julia_call_bootstrap_before_sha256"] != command_receipt["julia_call_bootstrap_after_sha256"]
        else:
            raise AssertionError("mutated JuliaCall bootstrap environment was accepted")
    finally:
        EVIDENCE_ROOT = original_evidence_root
        build_file_map = original_builder


def _synthetic_docs_frontend(root: Path) -> dict[str, Any]:
    """Create a tiny local fixture for freeze, symlink, copy, and runtime checks."""
    package_root = root / "synthetic-frontend"
    node_modules = package_root / "node_modules"
    vitepress = node_modules / "vitepress"
    (vitepress / "bin").mkdir(parents=True)
    (vitepress / "package.json").write_text('{"name":"vitepress","version":"1.6.4"}\n', encoding="utf-8")
    (vitepress / "bin" / "vitepress.js").write_text("// synthetic CLI\n", encoding="utf-8")
    (node_modules / ".bin").mkdir()
    (node_modules / ".bin" / "vitepress").symlink_to("../vitepress/bin/vitepress.js")
    dependencies = {"vitepress": "1.6.4"}
    package_path = package_root / "package.json"
    package_path.write_text(json.dumps({"dependencies": dependencies}) + "\n", encoding="utf-8")
    lock_path = package_root / "package-lock.json"
    lock_path.write_text(json.dumps({
        "name": "synthetic-docs", "lockfileVersion": 3,
        "packages": {
            "": {"dependencies": dependencies},
            "node_modules/vitepress": {
                "version": "1.6.4",
                "resolved": "https://registry.npmjs.org/vitepress/-/vitepress-1.6.4.tgz",
                "integrity": "sha512-syntheticfixture",
            },
        },
    }) + "\n", encoding="utf-8")
    node_path = package_root / "node"
    npm_cli = package_root / "npm-cli.js"
    fake_node = "#!/usr/bin/env python3\nimport sys\nprint('v20.12.2' if len(sys.argv) == 2 else '10.5.0')\n"
    node_path.write_text(fake_node, encoding="utf-8")
    npm_cli.write_text("# synthetic npm version command\n", encoding="utf-8")
    node_path.chmod(0o755)
    return {
        "package_json_path": str(package_path), "package_json_sha256": sha256_file(package_path),
        "package_lock_path": str(lock_path), "package_lock_sha256": sha256_file(lock_path),
        "node_modules_path": str(node_modules), "node_modules_tree_sha256": frontend_tree_hash(node_modules),
        "node_path": str(node_path), "node_sha256": sha256_file(node_path), "node_version": "v20.12.2",
        "npm_cli_path": str(npm_cli), "npm_cli_sha256": sha256_file(npm_cli), "npm_version": "10.5.0",
    }


def _self_test() -> None:
    assert sha256_file(Path(__file__)) == hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    with tempfile.TemporaryDirectory(prefix="arc1-package-runner-selftest-") as temp:
        root = Path(temp)
        fake_julia = root / "julia"
        fake_r = root / "r"
        for rel_dir in JULIA_TREES:
            (fake_julia / rel_dir).mkdir(parents=True)
            (fake_julia / rel_dir / "fixture.dat").write_text("stable", encoding="utf-8")
        for rel in JULIA_FILES:
            path = fake_julia / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text("stable", encoding="utf-8")
        for rel_dir in R_TREES:
            (fake_r / rel_dir).mkdir(parents=True, exist_ok=True)
        for rel in R_FILES:
            (fake_r / rel).write_text("stable", encoding="utf-8")
        (fake_r / ".Rbuildignore").write_text("^vignettes/articles$\n", encoding="utf-8")
        inventory = build_file_map(fake_julia, fake_r)
        frozen = snapshot(inventory)
        validate_snapshot(snapshot(inventory), frozen)
        (fake_r / ".Rbuildignore").write_text("# ^vignettes/articles$\n", encoding="utf-8")
        try:
            build_file_map(fake_julia, fake_r)
        except PackageCheckError:
            pass
        else:
            raise AssertionError("commented R build-ignore rule was treated as active")
        (fake_r / ".Rbuildignore").write_text("^vignettes/articles$\n", encoding="utf-8")
        cache_dir = fake_julia / "src" / "__pycache__"
        cache_dir.mkdir()
        (cache_dir / "transient.pyc").write_bytes(b"generated")
        (fake_julia / "src" / "transient.pyc").write_bytes(b"generated")
        assert snapshot(build_file_map(fake_julia, fake_r)) == frozen
        source = fake_julia / "src" / "fixture.dat"
        source.write_text("mutated", encoding="utf-8")
        try:
            validate_snapshot(snapshot(build_file_map(fake_julia, fake_r)), frozen)
        except PackageCheckError:
            pass
        else:
            raise AssertionError("synthetic hash mutation was not detected")
        source.write_text("stable", encoding="utf-8")
        source_new = fake_julia / "src" / "new_helper.jl"
        source_new.write_text("new", encoding="utf-8")
        try:
            validate_snapshot(snapshot(build_file_map(fake_julia, fake_r)), frozen)
        except PackageCheckError:
            pass
        else:
            raise AssertionError("synthetic undeclared source addition was not detected")

        review_file = root / "independent-review.txt"
        review_file.write_text("reviewed external fixture", encoding="utf-8")
        sandbox_root = root / "reviewed-sandbox"
        sandbox_root.mkdir()
        sandbox_project = sandbox_root / "Project.toml"
        sandbox_manifest = sandbox_root / "Manifest.toml"
        sandbox_project.write_text('name = "SyntheticTestEnv"\n', encoding="utf-8")
        sandbox_manifest.write_text('manifest_format = "2.0"\n', encoding="utf-8")
        docs_frontend = _synthetic_docs_frontend(root)
        validated_frontend = validate_docs_frontend(docs_frontend)
        assert validated_frontend["node_modules_tree_sha256"] == docs_frontend["node_modules_tree_sha256"]
        copied_frontend_root = root / "copied-frontend"
        copied_frontend_root.mkdir()
        copied_frontend = copy_docs_frontend(docs_frontend, copied_frontend_root)
        assert copied_frontend == {
            "package_json_sha256": docs_frontend["package_json_sha256"],
            "package_lock_sha256": docs_frontend["package_lock_sha256"],
            "node_modules_tree_sha256": docs_frontend["node_modules_tree_sha256"],
        }
        assert (copied_frontend_root / "node_modules" / ".bin" / "vitepress").is_symlink()
        bad_frontend = dict(docs_frontend)
        bad_frontend.pop("node_modules_tree_sha256")
        try:
            validate_docs_frontend(bad_frontend)
        except PackageCheckError:
            pass
        else:
            raise AssertionError("missing docs frontend tree pin was accepted")
        bad_frontend = dict(docs_frontend, package_json_sha256="0" * 64)
        try:
            validate_docs_frontend(bad_frontend)
        except PackageCheckError:
            pass
        else:
            raise AssertionError("drifted docs frontend package pin was accepted")
        bad_frontend = dict(docs_frontend, node_version="v99.0.0")
        try:
            validate_docs_frontend(bad_frontend)
        except PackageCheckError:
            pass
        else:
            raise AssertionError("drifted docs frontend Node version was accepted")
        outside_target = root / "outside-link-target"
        outside_target.write_text("outside", encoding="utf-8")
        link = Path(docs_frontend["node_modules_path"]) / ".bin" / "vitepress"
        link.unlink()
        link.symlink_to(outside_target)
        try:
            frontend_tree_hash(Path(docs_frontend["node_modules_path"]))
        except PackageCheckError:
            pass
        else:
            raise AssertionError("external docs frontend symlink was accepted")
        link.unlink()
        link.symlink_to("../vitepress/bin/vitepress.js")
        bootstrap_template = _oracle.JULIA_CALL_BOOTSTRAP_TEMPLATE
        bootstrap_spec = {
            "project_path": str((bootstrap_template / "Project.toml").resolve()),
            "manifest_path": str((bootstrap_template / "Manifest.toml").resolve()),
            "project_sha256": sha256_file(bootstrap_template / "Project.toml"),
            "manifest_sha256": sha256_file(bootstrap_template / "Manifest.toml"),
        }
        _oracle.validate_julia_call_bootstrap(bootstrap_spec, required=True)
        fake_bootstrap = root / "bootstrap-copy"
        fake_bootstrap.mkdir()
        shutil.copyfile(bootstrap_spec["project_path"], fake_bootstrap / "Project.toml")
        shutil.copyfile(bootstrap_spec["manifest_path"], fake_bootstrap / "Manifest.toml")
        bootstrap_env = _r_env(root, fake_bootstrap)
        assert bootstrap_env["PATH"].split(os.pathsep, 1)[0] == str(Path(JULIA_BIN).resolve().parent)
        assert bootstrap_env["JULIA_PROJECT"] == str(fake_bootstrap)
        assert bootstrap_env["HSQUARED_JULIA_PROJECT"] == str(JULIA_ROOT)
        assert bootstrap_env["JULIA_PKG_OFFLINE"] == "true"
        assert bootstrap_env["JULIA_DEPOT_PATH"] == JULIA_DEPOT
        assert bootstrap_env["JULIA_NUM_THREADS"] == JULIA_THREAD_COUNT
        assert bootstrap_env["OPENBLAS_NUM_THREADS"] == BLAS_THREAD_COUNT
        assert bootstrap_env["HSQUARED_ARC1_REQUIRE_LIVE"] == "true"
        assert bootstrap_env["ARC1_ORACLE_PACKAGE_ROOT"] == str(R_ROOT)
        freeze = {
            "schema": SCHEMA,
            "review": {"status": "reviewed", "reviewer": "synthetic external reviewer",
                       "reviewed_at_utc": "2026-01-01T00:00:00Z",
                       "review_receipt_path": str(review_file),
                       "review_receipt_sha256": sha256_file(review_file)},
            "roots": {"julia": str(fake_julia), "r": str(fake_r)},
            "runtime": {"julia": "julia test version", "rscript": "Rscript test version",
                        "julia_executable": str(Path(JULIA_BIN).resolve()),
                        "rscript_executable": str(Path(RSCRIPT_BIN).resolve())},
            "files": frozen,
            "julia_test_sandbox": {
                "project_path": str(sandbox_project), "manifest_path": str(sandbox_manifest),
                "project_sha256": sha256_file(sandbox_project),
                "manifest_sha256": sha256_file(sandbox_manifest),
            },
            "julia_call_bootstrap": bootstrap_spec,
            "docs_frontend": docs_frontend,
        }
        validate_freeze(freeze, freeze["roots"], inventory)
        validate_freeze(freeze, freeze["roots"], inventory, gate="r")
        validate_freeze(freeze, freeze["roots"], inventory, gate="docs")
        missing_frontend = json.loads(json.dumps(freeze))
        del missing_frontend["docs_frontend"]
        try:
            validate_freeze(missing_frontend, freeze["roots"], inventory, gate="docs")
        except PackageCheckError:
            pass
        else:
            raise AssertionError("docs gate accepted a freeze without frontend pins")
        bad_sandbox_freeze = json.loads(json.dumps(freeze))
        bad_sandbox_freeze["julia_test_sandbox"]["project_sha256"] = "0" * 64
        try:
            validate_freeze(bad_sandbox_freeze, freeze["roots"], inventory)
        except PackageCheckError:
            pass
        else:
            raise AssertionError("mismatched external sandbox hash was accepted")
        incomplete = json.loads(json.dumps(freeze))
        incomplete["files"]["julia"].pop(next(iter(incomplete["files"]["julia"])))
        try:
            validate_freeze(incomplete, freeze["roots"], inventory)
        except PackageCheckError:
            pass
        else:
            raise AssertionError("incomplete external freeze was accepted")

        def child(argv: list[str], timeout: float) -> tuple[int | None, bool, str]:
            log = root / f"child-{uuid.uuid4().hex}.log"
            with log.open("wb") as stream:
                proc = subprocess.Popen(argv, cwd=root, stdout=stream, stderr=subprocess.STDOUT,
                                        shell=False, start_new_session=True)
                try:
                    status = proc.wait(timeout=timeout)
                    return status, False, log.read_text(errors="replace")
                except subprocess.TimeoutExpired:
                    _oracle.terminate_group(proc)
                    return proc.returncode, True, log.read_text(errors="replace")

        status, timed_out, output = child([sys.executable, "-c", "print('SYNTHETIC_PASS')"], 3)
        assert status == 0 and not timed_out and "SYNTHETIC_PASS" in output
        require_success_marker("synthetic-pass", status, output, "SYNTHETIC_PASS")
        try:
            require_success_marker("synthetic-missing-marker", status, output, "NOT_PRESENT")
        except PackageCheckError:
            pass
        else:
            raise AssertionError("missing success marker was accepted")
        status, timed_out, _ = child([sys.executable, "-c", "raise SystemExit(9)"], 3)
        assert status == 9 and not timed_out
        try:
            require_success_marker("synthetic-failure", status, "", "SYNTHETIC_PASS")
        except PackageCheckError:
            pass
        else:
            raise AssertionError("nonzero synthetic process was accepted")
        _, timed_out, _ = child([sys.executable, "-c", "import time; time.sleep(5)"], 0.1)
        assert timed_out

        clean_summary = "Test Summary: | Pass  Total  Time\nArc1 synthetic |    1      1  0.0s\n"
        parsed = parse_julia_test_output(clean_summary, required_arc1_testsets=())
        assert parsed["summary_records"][0]["pass"] == 1
        assert parsed["summary_records"][0]["total"] == 1
        invalid_summaries = (
            "",
            "Test Summary: | Broken  Total  Time\nArc1 synthetic |      1      1  0.0s\n",
            "Test Summary: | Pass  Fail  Total  Time\nArc1 synthetic |    0     1      1  0.0s\n",
        )
        for invalid in invalid_summaries:
            try:
                parse_julia_test_output(invalid, required_arc1_testsets=())
            except PackageCheckError:
                pass
            else:
                raise AssertionError("empty or skipped synthetic Julia summary was accepted")
        julia_probe = subprocess.run(
            [JULIA_BIN, "--startup-file=no", "-e",
             'using Test; @testset "Arc1 synthetic parser" begin @test true; '
             '@test_throws ProcessFailedException run(`/usr/bin/false`) end'],
            cwd=root, env={**os.environ, **_julia_env()},
            capture_output=True, text=True, timeout=20, check=False,
        )
        assert julia_probe.returncode == 0
        parse_julia_test_output(julia_probe.stdout, required_arc1_testsets=())
        callback_dir = root / "callback-capture"
        callback_dir.mkdir()
        start_flag = root / "synthetic-tests-started"
        callback_source = "using SHA\n" + JULIA_TEST_SANDBOX_CALLBACK
        matching_probe = (
            callback_source
            + "arc1_capture_pkg_test_sandbox(); write(" + _julia_string(start_flag) + ", \"started\")\n"
        )
        matching_script = root / "callback-match.jl"
        matching_script.write_text(matching_probe, encoding="utf-8")
        callback_env = {**os.environ, **_julia_env(),
                        "ARC1_TEST_SANDBOX_CAPTURE_DIR": str(callback_dir),
                        "ARC1_TEST_SANDBOX_PROJECT_SHA256": sha256_file(sandbox_project),
                        "ARC1_TEST_SANDBOX_MANIFEST_SHA256": sha256_file(sandbox_manifest)}
        match_result = subprocess.run(
            [JULIA_BIN, "--startup-file=no", f"--project={sandbox_root}", str(matching_script)],
            cwd=root, env=callback_env, capture_output=True, text=True, timeout=20, check=False,
        )
        assert match_result.returncode == 0, match_result.stderr
        assert start_flag.read_text(encoding="utf-8") == "started"
        assert (callback_dir / "Project.toml").read_bytes() == sandbox_project.read_bytes()
        assert (callback_dir / "Manifest.toml").read_bytes() == sandbox_manifest.read_bytes()
        start_flag.unlink()
        mismatch_dir = root / "callback-mismatch"
        mismatch_env = {**callback_env, "ARC1_TEST_SANDBOX_CAPTURE_DIR": str(mismatch_dir),
                        "ARC1_TEST_SANDBOX_PROJECT_SHA256": "0" * 64}
        mismatch_script = root / "callback-mismatch.jl"
        mismatch_script.write_text(matching_probe, encoding="utf-8")
        mismatch_result = subprocess.run(
            [JULIA_BIN, "--startup-file=no", f"--project={sandbox_root}", str(mismatch_script)],
            cwd=root, env=mismatch_env, capture_output=True, text=True, timeout=20, check=False,
        )
        assert mismatch_result.returncode != 0
        assert not start_flag.exists(), "callback mismatch did not fail before synthetic tests start"
        assert (mismatch_dir / "sha256.txt").is_file(), "mismatch diagnostics were not retained"
        positive_arc1_summary = "Test Summary: | Pass  Total  Time\n" + \
            REQUIRED_ARC1_TESTSETS[0] + " |    1      1  0.0s\n"
        parsed_arc1 = parse_julia_test_output(
            positive_arc1_summary, required_arc1_testsets=(REQUIRED_ARC1_TESTSETS[0],)
        )
        assert parsed_arc1["summary_records"][0]["testset"] == REQUIRED_ARC1_TESTSETS[0]
        zero_arc1_summary = "Test Summary: | Pass  Total  Time\n" + \
            REQUIRED_ARC1_TESTSETS[0] + " |    0      0  0.0s\n"
        try:
            parse_julia_test_output(zero_arc1_summary,
                                    required_arc1_testsets=(REQUIRED_ARC1_TESTSETS[0],))
        except PackageCheckError:
            pass
        else:
            raise AssertionError("required Arc1 testset with zero assertions was accepted")

        redirect_build = root / "redirect-check" / "build"
        redirect_build.mkdir(parents=True)
        (redirect_build / "bases.txt").write_text("\n", encoding="utf-8")
        blank_redirects = validate_legacy_redirect_outputs(redirect_build)
        assert blank_redirects == {"bases": [], "redirects": []}
        (redirect_build / "bases.txt").write_text("\ndev\n", encoding="utf-8")
        try:
            validate_legacy_redirect_outputs(redirect_build)
        except PackageCheckError:
            pass
        else:
            raise AssertionError("missing dev redirect files were accepted")
        (redirect_build / "1" / "reference").mkdir(parents=True)
        (redirect_build / "1" / "reference.html").write_text(
            '<meta http-equiv="refresh" content="0; url=../stable/api.html">'
            '<p>Moved to <a href="../stable/api.html">API reference</a>.</p>', encoding="utf-8")
        (redirect_build / "1" / "reference" / "index.html").write_text(
            '<meta http-equiv="refresh" content="0; url=../../stable/api.html">'
            '<p>Moved to <a href="../../stable/api.html">API reference</a>.</p>', encoding="utf-8")
        dev_redirects = validate_legacy_redirect_outputs(redirect_build)
        assert dev_redirects == {
            "bases": ["dev"],
            "redirects": ["1/reference/index.html", "1/reference.html"],
        }

        _self_test_package_run(root)
        docs_source = (JULIA_ROOT / "docs" / "make.jl").read_text(encoding="utf-8")
        original_docs_project = sha256_file(JULIA_ROOT / "docs" / "Project.toml")
        original_docs_manifest = sha256_file(JULIA_ROOT / "docs" / "Manifest.toml")
        docs_env_parent = root / "prepared-docs"
        docs_env_parent.mkdir()
        docs_env = prepare_docs_environment(docs_env_parent)
        assert str(JULIA_ROOT) in (docs_env / "Project.toml").read_text()
        assert str(JULIA_ROOT) in (docs_env / "Manifest.toml").read_text()
        assert sha256_file(JULIA_ROOT / "docs" / "Project.toml") == original_docs_project
        assert sha256_file(JULIA_ROOT / "docs" / "Manifest.toml") == original_docs_manifest
        command_root = root / "assembled-docs-command"
        command_root.mkdir()
        docs_argv, docs_env = _docs_command(command_root, docs_frontend)
        assert docs_argv[0] == JULIA_BIN and docs_argv[1] == "--startup-file=no"
        assert docs_argv[2].startswith("--project=")
        assert str(command_root / "docs-environment") == docs_argv[2].removeprefix("--project=")
        assert "--project=docs" not in docs_argv
        assert docs_env["GOMAXPROCS"] == "2" and docs_env["UV_THREADPOOL_SIZE"] == "2"
        transformed = make_local_docs_script(
            docs_source, repo=JULIA_ROOT, scratch_docs=root / "docs-scratch", output_docs=root / "docs-output",
            redirect_probe=root / "redirect-probe", frontend=docs_frontend,
        )
        transformed_path = root / "transformed-docs-selftest.jl"
        transformed_path.write_text(transformed, encoding="utf-8")
        parse_probe = subprocess.run(
            [JULIA_BIN, "--startup-file=no", "-e",
             f"Meta.parseall(read({_julia_string(transformed_path)}, String)); println(\"DOCS_SCRIPT_PARSE_PASS\")"],
            cwd=root, env={**os.environ, **_julia_env()}, capture_output=True, text=True, timeout=20, check=False,
        )
        assert parse_probe.returncode == 0 and "DOCS_SCRIPT_PARSE_PASS" in parse_probe.stdout, parse_probe.stderr
        assert "DocumenterVitepress.deploydocs" not in transformed
        assert "Pkg.develop" not in transformed and "Pkg.instantiate" not in transformed
        assert "write_validation_status_table!(" in transformed
        assert "write_legacy_dev_reference_redirect!(" in transformed
        assert "pathof(HSquared)" in transformed
        assert str(JULIA_ROOT / "src" / "HSquared.jl") in transformed
        assert "install_npm = false" in transformed and "build_vitepress = true" in transformed
        assert "TOML.parsefile(" in transformed and str(JULIA_ROOT / "Project.toml") in transformed
        assert "DocumenterVitepress.node(adjust_PATH = false" in transformed
        assert docs_frontend["node_path"] in transformed and docs_frontend["npm_cli_path"] in transformed
        command_source = Path(docs_argv[-1]).read_text(encoding="utf-8")
        assert "DocumenterVitepress.deploydocs" not in command_source
        assert "pathof(HSquared)" in command_source
        assert str(root / "docs-scratch" / "src") in transformed
        assert f"root = {_julia_string(root / 'docs-scratch')}" in transformed
        assert 'source = "src"' in transformed and 'build = "build"' in transformed
        assert f"write_legacy_dev_reference_redirect!({_julia_string(root / 'docs-output')})" in transformed
        assert f"const _arc1_redirect_probe = {_julia_string(root / 'redirect-probe')}" in transformed
        assert 'write(joinpath(_arc1_redirect_probe, "build", "bases.txt"), "dev\\n")' in transformed
        assert f"const _arc1_generated_bases = readlines({_julia_string(root / 'docs-output' / 'build' / 'bases.txt')})" in transformed
        assert '@assert _arc1_generated_bases == [""]' in transformed
        assert f"cd({_julia_string(root / 'docs-scratch')}) do" in transformed
        assert "DocumenterVitepress.node(adjust_PATH = true, adjust_LIBPATH = true) do _" in transformed
        assert "run(`$(DocumenterVitepress.npm) run env -- vitepress build build/.documenter`)" in transformed
        assert f"_arc1_validation_html = {_julia_string(root / 'docs-output' / 'build' / '1' / 'validation-status.html')}" in transformed
        assert '@assert isfile(_arc1_validation_html)' in transformed
        assert "ARC1_PACKAGE_DOCS_HTML_BUILT" in transformed
        assert transformed.index("ARC1_PACKAGE_DOCS_HTML_BUILT") < transformed.index("ARC1_PACKAGE_DOCS_COMPONENT_PASS")
    print("synthetic_cases=pass,nonzero,missing_marker,timeout,interrupt,input_mutation,bootstrap_mutation,julia_summary,empty_summary,broken_summary,docs_env_rebase,test_sandbox_match,test_sandbox_mismatch_before_tests,frontend_missing_pin,frontend_version_drift,frontend_tree_copy,frontend_symlink_escape,blank_base_redirects,missing_dev_redirect,valid_dev_redirects,manual_docs_argv_cwd,html_required_before_pass_marker,run_failure_propagation,node_resource_caps")
    print("ARC1_PACKAGE_CHECKS_SYNTHETIC_SELFTEST_PASS")


def _signal_handler(signum: int, _frame: Any) -> None:
    if ACTIVE_PROCESS is not None:
        _oracle.terminate_group(ACTIVE_PROCESS)
    raise RunInterrupted(f"received signal {signum}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--freeze", type=Path, help="absolute path to an independently reviewed external JSON freeze")
    parser.add_argument("--gate", choices=("julia", "r", "docs", "all"),
                        help="explicit check selection; all runs Julia, R, and docs sequentially once")
    parser.add_argument("--self-test", action="store_true", help="run only disposable synthetic runner checks")
    args = parser.parse_args(argv)
    if args.self_test:
        _self_test()
        return 0
    if not args.freeze or not args.gate:
        parser.error("real checks require both --freeze and explicit --gate")
    global ACTIVE_RUN
    for sig in (signal.SIGTERM, signal.SIGHUP, signal.SIGINT):
        signal.signal(sig, _signal_handler)
    run = PackageRun(args.gate, args.freeze.expanduser())
    ACTIVE_RUN = run
    return run.run()


if __name__ == "__main__":
    raise SystemExit(main())
