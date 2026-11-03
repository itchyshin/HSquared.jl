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
import inspect
import json
import os
import posixpath
from pathlib import Path
import re
import shutil
import signal
import stat
import subprocess
import sys
import tempfile
import tarfile
import time
import tomllib
import uuid
from typing import Any

RUNNER = Path(__file__).resolve()
JULIA_ROOT = RUNNER.parents[1].resolve()
DEFAULT_R_ROOT = Path("/private/tmp/hsquared-auto-fa-r-20261001")


def _resolve_r_root() -> Path:
    override = os.environ.get("HSQUARED_ARC1_R_ROOT", "").strip()
    return Path(override).expanduser().resolve() if override else DEFAULT_R_ROOT.resolve()


R_ROOT = _resolve_r_root()
EVIDENCE_ROOT = JULIA_ROOT / ".unlazy" / "arc1-gaussian-reliability" / "evidence" / "package-checks"
JULIA_DEPOT = "/private/tmp/hsq-julia-depot:/Users/z3437171/.julia"
JULIA_THREAD_COUNT = "1"
BLAS_THREAD_COUNT = "1"
R_PATH = "/Users/z3437171/.juliaup/bin:/Users/z3437171/miniconda3/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
# The retained G7 projection is about 1,785 s after the longer executor test;
# leave bounded headroom while keeping the component below the 3 h campaign line.
RUN_TIMEOUT_S = {"julia": 2400, "r": 7200, "docs": 180}
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


def freeze_roots() -> dict[str, str]:
    """Return the exact source roots this process requires its freeze to pin."""
    return {"julia": str(JULIA_ROOT), "r": str(R_ROOT)}


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
        "ARC1_PROFILE_V3_ONLY": "0",
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


def julia_noinstall_preflight_source(sandbox: dict[str, Any], capture_dir: Path,
                                     freeze_sha256: str, *,
                                     expected_julia_executable: Path | None = None,
                                     expected_julia_version: str | None = None,
                                     source_file_inventory: dict[str, str] | None = None,
                                     expected_depot_path: list[str] | None = None) -> str:
    """Build the read-only Julia inventory shared by the before/after checks."""
    project_path = Path(sandbox["project_path"]).resolve()
    manifest_path = Path(sandbox["manifest_path"]).resolve()
    if project_path.parent != manifest_path.parent:
        raise PackageCheckError("reviewed Julia test sandbox files must share a directory")
    env = _julia_command(Path("/tmp/arc1-preflight-driver.jl"), sandbox)[1]
    expected_load = env["JULIA_LOAD_PATH"].split(os.pathsep)
    expected_depot = expected_depot_path or env["JULIA_DEPOT_PATH"].split(os.pathsep)
    expected_julia_executable = (expected_julia_executable or Path(JULIA_BIN).resolve()).resolve()
    expected_julia_version = expected_julia_version or "unknown"
    source_file_inventory = source_file_inventory or {}
    source = r'''using Dates, Pkg, SHA, TOML, UUIDs, Tar
const PF_PROJECT = @@PROJECT@@
const PF_MANIFEST = @@MANIFEST@@
const PF_CAPTURE = @@CAPTURE@@
const PF_SOURCE_ROOT = @@SOURCE_ROOT@@
const PF_FREEZE_SHA256 = @@FREEZE_SHA256@@
const PF_RUNNER_SHA256 = @@RUNNER_SHA256@@
const PF_JULIA_EXECUTABLE = @@JULIA_EXECUTABLE@@
const PF_JULIA_LAUNCHER_SHA256 = @@JULIA_LAUNCHER_SHA256@@
const PF_JULIA_VERSION = @@JULIA_VERSION@@
const PF_SOURCE_FILE_INVENTORY = @@SOURCE_FILE_INVENTORY@@
const PF_EXPECTED_LOAD_PATH = @@LOAD_PATH@@
const PF_EXPECTED_DEPOT_PATH = @@DEPOT_PATH@@
const PF_PROJECT_SHA256 = @@PROJECT_SHA256@@
const PF_MANIFEST_SHA256 = @@MANIFEST_SHA256@@
const PF_PACKAGE_DEPENDENCIES = Pkg.dependencies()
const ARC1_PREFLIGHT_BEFORE_PATH = joinpath(PF_CAPTURE, "julia-noinstall-preflight-before.toml")
const ARC1_PREFLIGHT_AFTER_PATH = joinpath(PF_CAPTURE, "julia-noinstall-preflight-after.toml")
const PF_EXPECTED_WEAKDEPS = Set(["AlgebraOfGraphics", "CUDA", "Makie"])
pf_sha(path) = bytes2hex(sha256(read(path)))
pf_tree(path) = bytes2hex(Pkg.GitTools.tree_hash(path))
pf_uuid(value) = string(UUID(string(value)))
function pf_content_tree(path)
    rows = String[]
    for (directory, dirs, files) in walkdir(path; follow_symlinks=false)
        filter!(name -> name != ".git", dirs)
        sort!(dirs); sort!(files)
        for name in dirs
            entry = joinpath(directory, name)
            if islink(entry)
                target = readlink(entry)
                resolved = realpath(entry)
                rel_resolved = relpath(resolved, realpath(path))
                (rel_resolved == ".." || startswith(rel_resolved, "..$(Base.Filesystem.path_separator)")) &&
                    error("escaping symlink in package content tree")
                push!(rows, relpath(entry, path) * "\0symlink\0" * target)
            end
        end
        for name in files
            file = joinpath(directory, name)
            rel = relpath(file, path)
            if islink(file)
                target = readlink(file)
                resolved = realpath(file)
                rel_resolved = relpath(resolved, realpath(path))
                (rel_resolved == ".." || startswith(rel_resolved, "..$(Base.Filesystem.path_separator)")) &&
                    error("escaping symlink in package content tree")
                push!(rows, replace(rel, Base.Filesystem.path_separator => '/') * "\0symlink\0" * target)
            else
                isfile(file) || error("non-file in package content tree")
                push!(rows, replace(rel, Base.Filesystem.path_separator => '/') * "\0file\0" * pf_sha(file))
            end
        end
    end
    return bytes2hex(sha256(join(sort!(rows), "\n")))
end
function pf_source_snapshot(root)
    rows = Dict{String,Any}[]
    digest_rows = String[]
    for (relative_path, expected_sha256) in PF_SOURCE_FILE_INVENTORY
        path = normpath(joinpath(root, split(relative_path, '/')...))
        realpath(dirname(path)) == dirname(path) || error("frozen source parent resolves through a symlink: $relative_path")
        isfile(path) && !islink(path) || error("frozen source file is missing or unsafe: $relative_path")
        observed = pf_sha(path)
        observed == expected_sha256 || error("frozen source file differs from external freeze: $relative_path")
        push!(rows, Dict("relative_path" => relative_path, "sha256" => observed))
        push!(digest_rows, relative_path * "\0" * observed)
    end
    isempty(rows) && error("frozen source inventory is empty")
    sort!(rows; by=x -> x["relative_path"])
    return rows, bytes2hex(sha256(join(sort!(digest_rows), "\n")))
end
function pf_value(value)
    if value isa AbstractDict
        return Dict(string(k) => pf_value(v) for (k, v) in value)
    elseif value isa AbstractVector || value isa Tuple
        return [pf_value(v) for v in value]
    elseif value isa UUID || value isa VersionNumber || value isa Symbol
        return string(value)
    elseif value === nothing
        return "<nothing>"
    elseif value isa AbstractString || value isa Bool || value isa Integer || value isa AbstractFloat
        return value
    end
    return repr(value)
end
function pf_project(root)
    path = joinpath(root, "Project.toml")
    isfile(path) && !islink(path) || error("manifest source Project.toml missing or unsafe: $path")
    return TOML.parsefile(path), path
end
function pf_root(source_file)
    path = realpath(source_file)
    basename(dirname(path)) == "src" || error("manifest package source is outside src: $path")
    return realpath(dirname(dirname(path)))
end
function pf_manifest_source_path(name, uuid, dependencies; expected_tree=nothing, depots=DEPOT_PATH)
    package_id = Base.PkgId(UUID(uuid), name)
    candidates = String[]
    info = get(dependencies, UUID(uuid), nothing)
    if info !== nothing && hasproperty(info, :source)
        source = getproperty(info, :source)
        if source !== nothing
            candidate = joinpath(String(source), "src", name * ".jl")
            isfile(candidate) && !islink(candidate) && push!(candidates, candidate)
        end
    end
    located = Base.locate_package(package_id)
    located !== nothing && isfile(located) && !islink(located) && push!(candidates, located)
    if expected_tree !== nothing
        # A depot can contain the reviewed tree even when an earlier depot has
        # an incomplete package directory returned by Pkg.dependencies(). Use
        # only roots whose Project UUID and Git tree match the frozen Manifest.
        for depot in depots
            package_dir = joinpath(depot, "packages", name)
            isdir(package_dir) && !islink(package_dir) || continue
            for slug in readdir(package_dir)
                root = joinpath(package_dir, slug)
                isdir(root) && !islink(root) || continue
                project_path = joinpath(root, "Project.toml")
                source_path = joinpath(root, "src", name * ".jl")
                isfile(project_path) && !islink(project_path) && isfile(source_path) && !islink(source_path) || continue
                project = TOML.parsefile(project_path)
                get(project, "uuid", "") == string(uuid) || continue
                lowercase(String(expected_tree)) == pf_manifest_package_tree(root, expected_tree) || continue
                push!(candidates, source_path)
            end
        end
    end
    for candidate in sort!(unique(candidates))
        if expected_tree !== nothing
            root = realpath(dirname(dirname(candidate)))
            lowercase(String(expected_tree)) == pf_manifest_package_tree(root, expected_tree) || continue
        end
        return candidate
    end
    return nothing
end
function pf_manifest_package_tree(root, expected_tree)
    # Julia's coverage runtime can leave `*.cov` files inside shared package
    # depots. They are generated data, not package source, so compare the
    # remaining package tree to the Manifest while retaining their bytes in
    # the separate content-tree receipt.
    coverage_files = String[]
    for (directory, _, files) in walkdir(root)
        for filename in files
            endswith(filename, ".cov") || continue
            path = joinpath(directory, filename)
            isfile(path) && !islink(path) || error("unsafe package coverage artifact: $path")
            push!(coverage_files, relpath(path, root))
        end
    end
    generated_deps_directory = joinpath(root, "deps")
    islink(generated_deps_directory) && error("unsafe generated package build-output directory: $generated_deps_directory")
    ispath(generated_deps_directory) && !isdir(generated_deps_directory) &&
        error("unsafe generated package build-output directory: $generated_deps_directory")
    generated_deps_file = joinpath(generated_deps_directory, "deps.jl")
    islink(generated_deps_file) && error("unsafe generated package build output: $generated_deps_file")
    ispath(generated_deps_file) && !isfile(generated_deps_file) &&
        error("unsafe generated package build output: $generated_deps_file")
    expected = expected_tree === nothing ? nothing : lowercase(String(expected_tree))
    actual_tree = isempty(coverage_files) ? pf_tree(root) : nothing
    if actual_tree !== nothing && (expected === nothing ||
        actual_tree == expected || !isfile(generated_deps_file))
        return actual_tree
    end
    isempty(coverage_files) && !isfile(generated_deps_file) && return actual_tree
    staging_parent = mktempdir()
    staging_root = joinpath(staging_parent, "package")
    try
        cp(root, staging_root; force=true, follow_symlinks=false)
        for relative in coverage_files
            rm(joinpath(staging_root, relative); force=true)
        end
        observed = pf_tree(staging_root)
        if expected === nothing || observed == expected || !isfile(generated_deps_file)
            return observed
        end
        rm(joinpath(staging_root, "deps", "deps.jl"); force=true)
        generated_excluded_tree = pf_tree(staging_root)
        return generated_excluded_tree == expected ? generated_excluded_tree : observed
    finally
        rm(staging_parent; recursive=true, force=true)
    end
end
function pf_validate_loaded_source_path(name, uuid, loaded_path, expected_root)
    loaded_path === nothing && error("loaded manifest package has no source path: $name/$uuid")
    observed = realpath(String(loaded_path))
    expected = realpath(joinpath(String(expected_root), "src", String(name) * ".jl"))
    observed == expected || error("loaded package source differs from its reviewed Manifest tree: $name/$uuid")
    return observed
end
function pf_loaded_manifest_sources(sources)
    by_id = Dict((String(source["name"]), String(source["uuid"])) => source for source in sources)
    loaded = Dict{String,Any}[]
    for (package_id, module_value) in Base.loaded_modules
        key = (String(package_id.name), string(package_id.uuid))
        source = get(by_id, key, nothing)
        source === nothing && continue
        module_path = pathof(module_value)
        module_path === nothing && error("loaded manifest package has no source path: $(key[1])/$(key[2])")
        verified = pf_validate_loaded_source_path(key[1], key[2], module_path, source["source_path"])
        push!(loaded, Dict("name" => key[1], "uuid" => key[2], "path" => verified))
    end
    sort!(loaded; by=x -> (x["name"], x["uuid"]))
    return loaded
end
function pf_manifest_kind(uuid, entry, stdlib_ids)
    declared_path = get(entry, "path", nothing)
    expected_tree = get(entry, "git-tree-sha1", nothing)
    declared_path !== nothing && return "path"
    expected_tree !== nothing && return "git-tree"
    haskey(stdlib_ids, uuid) && return "stdlib"
    error("manifest source git-tree-sha1 is missing: $uuid")
end
function pf_manifest_source(name, uuid, entry, stdlib_ids)
    location = pf_manifest_source_path(name, uuid, PF_PACKAGE_DEPENDENCIES;
        expected_tree=get(entry, "git-tree-sha1", nothing))
    location === nothing && error("manifest source is not locatable without installation: $name/$uuid")
    root = pf_root(location)
    project, project_path = pf_project(root)
    get(project, "uuid", "") == uuid || error("manifest source UUID differs from Project.toml: $name")
    expected_tree = get(entry, "git-tree-sha1", nothing)
    declared_path = get(entry, "path", nothing)
    kind = pf_manifest_kind(uuid, entry, stdlib_ids)
    if kind == "stdlib"
        return Dict("name" => name, "uuid" => uuid, "kind" => "stdlib", "source_path" => root,
            "project_path" => project_path, "git_tree_sha1" => pf_tree(root),
            "content_tree_sha256" => pf_content_tree(root),
            "version" => string(get(project, "version", VERSION)))
    end
    if declared_path !== nothing
        path = String(declared_path)
        path = isabspath(path) ? path : joinpath(dirname(PF_MANIFEST), path)
        ispath(path) && !islink(path) || error("manifest source path missing or unsafe: $path")
        realpath(path) == root || error("manifest path differs from located package source: $name")
        if expected_tree === nothing && name == "HSquared" && root == realpath(PF_SOURCE_ROOT)
            source_files, snapshot_sha256 = pf_source_snapshot(root)
            return Dict("name" => name, "uuid" => uuid, "kind" => "path-snapshot",
                "source_path" => root, "project_path" => project_path,
                "source_files" => source_files, "content_tree_sha256" => snapshot_sha256,
                "version" => string(get(entry, "version", get(project, "version", "unknown"))))
        end
        expected_tree === nothing && error("non-HSquared path source lacks git-tree-sha1: $name")
        tree = pf_manifest_package_tree(root, expected_tree)
        if lowercase(String(expected_tree)) != tree
            error("manifest path source tree differs from git-tree-sha1: $name")
        end
    else
        expected_tree === nothing && error("manifest source git-tree-sha1 is missing: $name")
        tree = pf_manifest_package_tree(root, expected_tree)
        lowercase(String(expected_tree)) == tree ||
            error("manifest source git-tree-sha1 differs: $name")
    end
    if declared_path !== nothing && expected_tree !== nothing
        tree = pf_manifest_package_tree(root, expected_tree)
    end
    if declared_path === nothing && expected_tree === nothing
        error("manifest source git-tree-sha1 is missing or differs: $name")
    end
    return Dict("name" => name, "uuid" => uuid, "kind" => kind, "source_path" => root,
        "project_path" => project_path, "git_tree_sha1" => tree, "content_tree_sha256" => pf_content_tree(root),
        "version" => string(get(entry, "version", get(project, "version", "unknown"))))
end
function pf_sources(manifest)
    stdlib_ids = Dict{String,String}()
    for name in readdir(Sys.STDLIB)
        path = joinpath(Sys.STDLIB, name, "Project.toml")
        if isfile(path)
            project = TOML.parsefile(path)
            haskey(project, "uuid") && (stdlib_ids[pf_uuid(project["uuid"])] = name)
        end
    end
    sources = Dict{String,Any}[]
    by_id = Dict{Tuple{String,String},Dict{String,Any}}()
    for name in sort!(collect(keys(get(manifest, "deps", Dict{String,Any}()))))
        raw = manifest["deps"][name]
        for entry in (raw isa AbstractVector ? raw : [raw])
            entry isa AbstractDict || error("malformed manifest source: $name")
            uuid = pf_uuid(get(entry, "uuid", ""))
            record = pf_manifest_source(String(name), uuid, entry, stdlib_ids)
            push!(sources, record)
            by_id[(String(name), uuid)] = record
        end
    end
    isempty(sources) && error("reviewed Manifest.toml has no package sources")
    sort!(sources; by=x -> (x["name"], x["uuid"]))
    return sources, by_id, stdlib_ids
end
function pf_closure(by_id, stdlib_ids)
    closure = Dict{String,Any}[]
    omitted = Dict{String,Any}[]
    visited = Set{Tuple{String,String}}()
    function visit(name, uuid)
        key = (String(name), String(uuid))
        key in visited && return
        push!(visited, key)
        record = get(by_id, key, nothing)
        if record === nothing
            get(stdlib_ids, key[2], "") == key[1] ||
                error("dependency closure member is outside reviewed Manifest.toml: $(key[1])")
            location = pf_manifest_source_path(key[1], key[2], PF_PACKAGE_DEPENDENCIES)
            location === nothing && error("stdlib dependency is unavailable: $(key[1])")
            root = pf_root(location)
            project, project_path = pf_project(root)
            record = Dict("name" => key[1], "uuid" => key[2], "kind" => "stdlib",
                "source_path" => root, "project_path" => project_path,
                "git_tree_sha1" => pf_tree(root), "content_tree_sha256" => pf_content_tree(root),
                "version" => string(get(project, "version", VERSION)))
        end
        push!(closure, record)
        # Pkg normalizes Project.toml: a dependency listed in both [deps] and
        # [weakdeps] is retained only as weak. Traversing raw TOML here would
        # incorrectly require it in the reviewed Manifest.
        project = Pkg.Types.read_project(record["project_path"])
        for (section, weak) in (("deps", false), ("weakdeps", true))
            for (dep_name, dep_uuid_raw) in getproperty(project, Symbol(section))
                dep_uuid = pf_uuid(dep_uuid_raw)
                dep_key = (String(dep_name), dep_uuid)
                if haskey(by_id, dep_key)
                    visit(dep_key...)
                    continue
                end
                located = pf_manifest_source_path(dep_key[1], dep_key[2], PF_PACKAGE_DEPENDENCIES)
                if located === nothing
                    weak || error("strong dependency is unavailable without installation: $(record["name"]) -> $dep_name")
                    push!(omitted, Dict("owner" => record["name"], "owner_uuid" => record["uuid"],
                        "name" => String(dep_name), "uuid" => dep_uuid))
                else
                    visit(String(dep_name), dep_uuid)
                end
            end
        end
    end
    aqua = Base.identify_package("Aqua")
    hsquared = Base.identify_package("HSquared")
    aqua === nothing && error("Aqua is absent from reviewed test environment")
    hsquared === nothing && error("HSquared is absent from reviewed test environment")
    visit(aqua.name, string(aqua.uuid))
    visit(hsquared.name, string(hsquared.uuid))
    sort!(closure; by=x -> (x["name"], x["uuid"]))
    sort!(omitted; by=x -> (x["owner"], x["name"], x["uuid"]))
    root_record = get(by_id, ("HSquared", string(hsquared.uuid)), nothing)
    root_record === nothing && error("HSquared root is absent from reviewed Manifest.toml")
    root_project = TOML.parsefile(root_record["project_path"])
    weak_names = Set(String.(collect(keys(get(root_project, "weakdeps", Dict{String,Any}())))))
    weak_names == PF_EXPECTED_WEAKDEPS || error("HSquared weak dependency policy changed")
    absent = Set(x["name"] for x in omitted if x["owner"] == "HSquared")
    absent == PF_EXPECTED_WEAKDEPS || error("CUDA/Makie/AlgebraOfGraphics must remain unavailable")
    return closure, omitted, aqua, hsquared
end
function pf_artifact_metadata_file(root)
    for filename in ("JuliaArtifacts.toml", "Artifacts.toml")
        path = joinpath(root, filename)
        if ispath(path)
            isfile(path) && !islink(path) || error("unsafe artifact metadata file: $path")
            return path
        end
    end
    return nothing
end
function pf_artifacts(sources)
    platform = Pkg.BinaryPlatforms.HostPlatform()
    host_tags = Set(String.(collect(keys(Pkg.BinaryPlatforms.tags(platform)))))
    static_tags = Set(["arch", "os", "libc", "call_abi", "libgfortran_version", "libstdcxx_version",
        "libcxx_version", "cxxstring_abi", "julia_version", "os_version", "sanitize", "mpi", "cuda"])
    metadata = Set(["git-tree-sha1", "download", "lazy"])
    artifacts = Dict{String,Any}[]
    artifact_sources = Dict{String,Any}[]
    unresolved = Dict{String,Any}[]
    for source in sources
        source["kind"] == "stdlib" && continue
        artifact_file = pf_artifact_metadata_file(source["source_path"])
        artifact_file === nothing && continue
        ispath(joinpath(source["source_path"], ".pkg", "select_artifacts.jl")) &&
            error("dynamic select_artifacts.jl cannot be resolved without installation")
        ispath(joinpath(source["source_path"], "select_artifacts.jl")) &&
            error("unsupported package-root dynamic select_artifacts.jl selector")
        raw = TOML.parsefile(artifact_file)
        for (artifact_name, value) in raw
            variants = value isa AbstractVector ? value : [value]
            for variant in variants, key in keys(variant)
                key in metadata && continue
                if !(String(key) in host_tags || String(key) in static_tags)
                    push!(unresolved, Dict("package" => source["name"],
                        "artifact" => String(artifact_name), "selector" => String(key)))
                end
            end
        end
        isempty(unresolved) || error("unresolved dynamic artifact selector in $artifact_file")
        selected = Pkg.Artifacts.select_downloadable_artifacts(artifact_file;
            platform=platform, include_lazy=true, pkg_uuid=UUID(source["uuid"]))
        selected_records = Dict{String,Any}[]
        for name in sort!(collect(keys(selected)))
            info = selected[name]
            tree = lowercase(String(get(info, "git-tree-sha1", "")))
            occursin(r"^[0-9a-f]{40}$", tree) || error("selected artifact lacks exact tree hash: $name")
            path = Pkg.Artifacts.artifact_path(Base.SHA1(hex2bytes(tree)); honor_overrides=false)
            isdir(path) && !islink(path) || error("selected artifact is not already installed: $name/$tree")
            realpath(path) == path || error("selected artifact path resolves through a symlink: $name")
            observed = pf_tree(path)
            observed == tree || error("selected artifact tree differs from expected hash: $name")
            push!(artifacts, Dict("package" => source["name"], "package_uuid" => source["uuid"],
                "name" => String(name), "git_tree_sha1" => tree, "path" => path,
                "observed_tree_sha1" => observed, "content_tree_sha256" => pf_content_tree(path),
                "lazy" => Bool(get(info, "lazy", false))))
            push!(selected_records, Dict("name" => String(name), "git_tree_sha1" => tree,
                "lazy" => Bool(get(info, "lazy", false))))
        end
        push!(artifact_sources, Dict("package" => source["name"], "package_uuid" => source["uuid"],
            "metadata_file" => realpath(artifact_file), "metadata_sha256" => pf_sha(artifact_file),
            "selected" => selected_records))
    end
    sort!(artifacts; by=x -> (x["package"], x["name"], x["git_tree_sha1"]))
    sort!(artifact_sources; by=x -> (x["package"], x["package_uuid"]))
    return artifacts, artifact_sources, unresolved
end
function pf_registries()
    candidates = String[]
    tarball_mode = Pkg.Registry.registry_read_from_tarball()
    for depot in DEPOT_PATH
        registry_dir = joinpath(depot, "registries")
        isdir(registry_dir) || continue
        entries = readdir(registry_dir; join=true)
        any(islink, entries) && error("symlink in reachable registry directory: $registry_dir")
        directories = filter(isdir, entries)
        compressed = tarball_mode ? filter(path -> endswith(path, ".toml"), entries) : String[]
        compressed_names = Set(splitext(basename(path))[1] for path in compressed)
        filter!(path -> !(basename(path) in compressed_names), directories)
        append!(candidates, directories)
        for descriptor in compressed
            info = try TOML.parsefile(descriptor) catch; Dict{String,Any}() end
            payload = get(info, "path", nothing)
            if get(info, "git-tree-sha1", nothing) isa String &&
               get(info, "uuid", nothing) isa String && payload isa String &&
               isfile(joinpath(dirname(descriptor), payload))
                push!(candidates, descriptor)
            end
        end
    end
    filter!(path -> isdir(path) ? isfile(joinpath(path, "Registry.toml")) : isfile(path), candidates)
    sort!(unique!(realpath.(candidates)))
    records = Dict{String,Any}[]
    reachable = Pkg.Registry.reachable_registries(; depots=DEPOT_PATH)
    actual_paths = sort!(unique!([realpath(String(registry.path)) for registry in reachable]))
    actual_paths == candidates || error("reachable registry inventory differs from depot candidate inventory")
    for registry in reachable
        registry_path = realpath(String(registry.path))
        compressed = isfile(registry_path)
        descriptor = compressed ? registry_path : joinpath(registry_path, "Registry.toml")
        isfile(descriptor) && !islink(descriptor) || error("reachable registry descriptor missing: $descriptor")
        info = TOML.parsefile(descriptor)
        if compressed
            relative_payload = get(info, "path", nothing)
            relative_payload isa String || error("reachable compressed registry has no fixed payload path")
            payload = joinpath(dirname(descriptor), relative_payload)
            isfile(payload) && !islink(payload) || error("reachable registry payload missing: $payload")
            tree = lowercase(String(get(info, "git-tree-sha1", "")))
            observed = string(Tar.tree_hash(`$(Pkg.PlatformEngines.exe7z()) x $payload -so`))
            lowercase(observed) == tree || error("compressed registry tree differs from descriptor")
        else
            payload = registry_path
            isdir(payload) && !islink(payload) || error("reachable registry directory is missing: $payload")
            tree_info = joinpath(payload, ".tree_info.toml")
            tree = isfile(tree_info) ? lowercase(String(TOML.parsefile(tree_info)["git-tree-sha1"])) : pf_tree(payload)
            observed = pf_tree(payload)
            observed == tree || error("reachable registry tree differs from its tree-info file")
        end
        push!(records, Dict("name" => String(registry.name), "uuid" => string(registry.uuid),
            "registry_path" => registry_path, "compressed" => compressed,
            "descriptor_path" => realpath(descriptor), "descriptor_sha256" => pf_sha(descriptor),
            "payload_path" => realpath(payload), "payload_sha256" => isfile(payload) ? pf_sha(payload) : pf_content_tree(payload),
            "git_tree_sha1" => tree, "observed_tree_sha1" => observed, "repo" => String(registry.repo)))
    end
    return sort!(records; by=x -> (x["name"], x["uuid"]))
end
function pf_preferences(closure)
    result = Dict{String,Any}()
    for package in closure
        result[package["uuid"]] = pf_value(Base.get_preferences(UUID(package["uuid"])))
    end
    paths = String[joinpath(PF_SOURCE_ROOT, "LocalPreferences.toml"),
        joinpath(dirname(PF_PROJECT), "LocalPreferences.toml")]
    append!(paths, [joinpath(depot, "prefs", "LocalPreferences.toml") for depot in DEPOT_PATH])
    files = Dict{String,Any}[]
    for path in sort!(unique(paths))
        if ispath(path)
            isfile(path) && !islink(path) || error("unsafe LocalPreferences.toml: $path")
            push!(files, Dict("path" => realpath(path), "sha256" => pf_sha(path)))
        end
    end
    return result, files
end
function pf_override_files()
    files = Dict{String,Any}[]
    for path in sort!(unique([joinpath(depot, "artifacts", "Overrides.toml") for depot in DEPOT_PATH]))
        if ispath(path)
            isfile(path) && !islink(path) || error("unsafe artifact override file: $path")
            push!(files, Dict("path" => realpath(path), "present" => true, "sha256" => pf_sha(path)))
        else
            push!(files, Dict("path" => path, "present" => false, "sha256" => ""))
        end
    end
    return files
end
function arc1_noinstall_preflight()
    active = Base.active_project()
    active !== nothing && realpath(active) == realpath(PF_PROJECT) || error("active Julia project differs from frozen sandbox")
    pf_sha(PF_PROJECT) == PF_PROJECT_SHA256 || error("reviewed test Project.toml changed")
    pf_sha(PF_MANIFEST) == PF_MANIFEST_SHA256 || error("reviewed test Manifest.toml changed")
    realpath(PF_JULIA_EXECUTABLE) == PF_JULIA_EXECUTABLE || error("frozen Julia launcher path is unresolved")
    pf_sha(PF_JULIA_EXECUTABLE) == PF_JULIA_LAUNCHER_SHA256 || error("frozen Julia launcher changed")
    runtime_executable = realpath(Base.julia_cmd().exec[1])
    isfile(runtime_executable) && !islink(runtime_executable) || error("Julia runtime executable is missing or unsafe")
    string(VERSION) == PF_JULIA_VERSION || error("Julia runtime version differs from external freeze")
    String.(LOAD_PATH) == PF_EXPECTED_LOAD_PATH || error("effective Julia LOAD_PATH changed")
    String.(DEPOT_PATH) == PF_EXPECTED_DEPOT_PATH || error("effective ordered Julia DEPOT_PATH changed")
    manifest = TOML.parsefile(PF_MANIFEST)
    sources, by_id, stdlib_ids = pf_sources(manifest)
    closure, omitted, aqua, _ = pf_closure(by_id, stdlib_ids)
    overrides = pf_value(Pkg.Artifacts.load_overrides())
    overrides isa AbstractDict || error("effective artifact override report is malformed")
    all(value isa AbstractDict && isempty(value) for value in values(overrides)) ||
        error("effective artifact overrides are nonempty")
    override_env = Dict(String(k) => String(v) for (k,v) in ENV if startswith(String(k), "JULIA_ARTIFACT_OVERRIDE"))
    isempty(override_env) || error("artifact override environment variables are nonempty")
    artifacts, artifact_sources, unresolved = pf_artifacts(sources)
    isempty(unresolved) || error("unresolved artifact selector")
    aqua_source = only(filter(x -> x["name"] == "Aqua" && x["uuid"] == string(aqua.uuid), sources))
    preferences, preference_files = pf_preferences(closure)
    loaded_sources = pf_loaded_manifest_sources(sources)
    report = Dict{String,Any}(
        "schema" => "arc1-julia-noinstall-preflight-v1", "status" => "passed",
        "created_at_utc" => Dates.format(Dates.now(Dates.UTC), dateformat"yyyy-mm-ddTHH:MM:SS.sssZ"),
        "freeze_sha256" => PF_FREEZE_SHA256, "runner_sha256" => PF_RUNNER_SHA256,
        "driver_sha256" => pf_sha(PROGRAM_FILE), "julia_executable" => realpath(PF_JULIA_EXECUTABLE),
        "julia_launcher_sha256" => pf_sha(PF_JULIA_EXECUTABLE),
        "julia_runtime_executable" => runtime_executable,
        "julia_runtime_executable_sha256" => pf_sha(runtime_executable),
        "julia_version" => string(VERSION), "host_platform" => Pkg.BinaryPlatforms.triplet(Pkg.BinaryPlatforms.HostPlatform()),
        "host_platform_tags" => pf_value(Pkg.BinaryPlatforms.tags(Pkg.BinaryPlatforms.HostPlatform())),
        "load_path" => String.(LOAD_PATH), "depot_path" => String.(DEPOT_PATH),
        "sandbox" => Dict("project_path" => realpath(PF_PROJECT), "project_sha256" => pf_sha(PF_PROJECT),
            "manifest_path" => realpath(PF_MANIFEST), "manifest_sha256" => pf_sha(PF_MANIFEST)),
        "manifest_sources" => sources,
        "loaded_manifest_sources" => loaded_sources,
        "aqua" => Dict("name" => String(aqua.name), "uuid" => string(aqua.uuid),
            "version" => String(aqua_source["version"]), "source_path" => String(aqua_source["source_path"]),
            "git_tree_sha1" => String(aqua_source["git_tree_sha1"])),
        "dependency_closure" => closure, "omitted_weak_dependencies" => omitted,
        "artifacts" => artifacts, "artifact_sources" => artifact_sources,
        "unresolved_artifact_selectors" => unresolved,
        "effective_artifact_overrides" => overrides, "artifact_override_environment" => override_env,
        "artifact_override_files" => pf_override_files(),
        "preferences" => preferences, "preference_files" => preference_files,
        "registry_tarball_mode" => Pkg.Registry.registry_read_from_tarball(),
        "registries" => pf_registries())
    canonical = copy(report)
    delete!(canonical, "created_at_utc")
    delete!(canonical, "loaded_manifest_sources")
    buffer = IOBuffer()
    TOML.print(buffer, canonical; sorted=true)
    report["canonical_sha256"] = bytes2hex(sha256(take!(buffer)))
    return report
end
function arc1_write_preflight(path, report)
    buffer = IOBuffer()
    TOML.print(buffer, report; sorted=true)
    bytes = take!(buffer)
    write(path, bytes)
    return bytes2hex(sha256(bytes))
end
'''
    replacements = {
        "@@PROJECT@@": _julia_string(project_path), "@@MANIFEST@@": _julia_string(manifest_path),
        "@@CAPTURE@@": _julia_string(capture_dir), "@@SOURCE_ROOT@@": _julia_string(JULIA_ROOT),
        "@@FREEZE_SHA256@@": json.dumps(freeze_sha256), "@@RUNNER_SHA256@@": json.dumps(sha256_file(RUNNER)),
        "@@JULIA_EXECUTABLE@@": _julia_string(expected_julia_executable),
        "@@JULIA_LAUNCHER_SHA256@@": json.dumps(sha256_file(expected_julia_executable)),
        "@@JULIA_VERSION@@": json.dumps(expected_julia_version),
        "@@SOURCE_FILE_INVENTORY@@": "[" + ", ".join(
            "(" + json.dumps(name) + ", " + json.dumps(digest) + ")"
            for name, digest in sorted(source_file_inventory.items())) + "]",
        "@@LOAD_PATH@@": "[" + ", ".join(json.dumps(x) for x in expected_load) + "]",
        "@@DEPOT_PATH@@": "[" + ", ".join(json.dumps(x) for x in expected_depot) + "]",
        "@@PROJECT_SHA256@@": json.dumps(sandbox["project_sha256"]),
        "@@MANIFEST_SHA256@@": json.dumps(sandbox["manifest_sha256"]),
    }
    for key, value in replacements.items():
        source = source.replace(key, value)
    return source


def julia_test_driver_source(sandbox: dict[str, Any], capture_dir: Path, *,
                            freeze_sha256: str | None = None,
                            expected_julia_executable: str | None = None,
                            expected_julia_version: str | None = None,
                            source_file_inventory: dict[str, str] | None = None,
                            expected_depot_path: list[str] | None = None) -> str:
    """Build the auditable, no-Pkg driver for the exact reviewed test environment."""
    project_path = Path(sandbox["project_path"]).resolve()
    manifest_path = Path(sandbox["manifest_path"]).resolve()
    if project_path.parent != manifest_path.parent:
        raise PackageCheckError("reviewed Julia test sandbox files must share a directory")
    runtime_expected = ACTIVE_RUN.meta.get("runtime_expected", {}) if ACTIVE_RUN is not None else {}
    freeze_sha = freeze_sha256 or (ACTIVE_RUN.freeze_hash if ACTIVE_RUN is not None and ACTIVE_RUN.freeze_hash else "0" * 64)
    expected_executable = Path(expected_julia_executable or
        runtime_expected.get("julia_executable", str(Path(JULIA_BIN).resolve()))).resolve()
    expected_version = (expected_julia_version or
        str(runtime_expected.get("julia", "")).removeprefix("julia version ") or "unknown")
    preflight_source = julia_noinstall_preflight_source(sandbox, capture_dir, freeze_sha,
        expected_julia_executable=expected_executable, expected_julia_version=expected_version,
        source_file_inventory=source_file_inventory or {}, expected_depot_path=expected_depot_path)
    return f'''using SHA, TOML

const ARC1_EXPECTED_PROJECT = {_julia_string(project_path)}
const ARC1_EXPECTED_MANIFEST = {_julia_string(manifest_path)}
const ARC1_CAPTURE_DIR = {_julia_string(capture_dir.resolve())}
const ARC1_EXPECTED_PROJECT_SHA256 = {json.dumps(sandbox["project_sha256"])}
const ARC1_EXPECTED_MANIFEST_SHA256 = {json.dumps(sandbox["manifest_sha256"])}
const ARC1_SOURCE_ROOT = {_julia_string(JULIA_ROOT.resolve())}
const ARC1_TEST_FILE = {_julia_string((JULIA_ROOT / "test" / "runtests.jl").resolve())}

{preflight_source}

mkpath(ARC1_CAPTURE_DIR)
preflight_before = arc1_noinstall_preflight()
preflight_before_sha = arc1_write_preflight(ARC1_PREFLIGHT_BEFORE_PATH, preflight_before)
println("ARC1_NO_INSTALL_PREFLIGHT_BEFORE_SHA256=", preflight_before_sha)
println("ARC1_NO_INSTALL_PREFLIGHT_CANONICAL_SHA256=", preflight_before["canonical_sha256"])

arc1_sha256(path) = bytes2hex(sha256(read(path)))
function arc1_verify_frozen_sandbox()
    active_project = Base.active_project()
    active_project === nothing && error("Arc1 direct test runner has no active Project.toml")
    realpath(active_project) == realpath(ARC1_EXPECTED_PROJECT) ||
        error("Arc1 direct test runner is using an unexpected Project.toml")
    active_manifest = joinpath(dirname(active_project), "Manifest.toml")
    arc1_sha256(active_project) == ARC1_EXPECTED_PROJECT_SHA256 ||
        error("reviewed Julia test Project.toml changed")
    arc1_sha256(active_manifest) == ARC1_EXPECTED_MANIFEST_SHA256 ||
        error("reviewed Julia test Manifest.toml changed")
    manifest = TOML.parsefile(active_manifest)
    entries = get(get(manifest, "deps", Dict{{String,Any}}()), "HSquared", nothing)
    entries isa Vector && length(entries) == 1 || error("test Manifest.toml must pin one HSquared checkout")
    package_path = get(only(entries), "path", nothing)
    package_path isa String && realpath(package_path) == realpath(ARC1_SOURCE_ROOT) ||
        error("test Manifest.toml HSquared path differs from the frozen source checkout")
    return active_project, active_manifest
end

active_project, active_manifest = arc1_verify_frozen_sandbox()
mkpath(ARC1_CAPTURE_DIR)
project_copy = joinpath(ARC1_CAPTURE_DIR, "Project.toml")
manifest_copy = joinpath(ARC1_CAPTURE_DIR, "Manifest.toml")
write(project_copy, read(active_project))
write(manifest_copy, read(active_manifest))
project_sha = arc1_sha256(project_copy)
manifest_sha = arc1_sha256(manifest_copy)
write(joinpath(ARC1_CAPTURE_DIR, "sha256.txt"),
      project_sha * string(Char(10)) * manifest_sha * string(Char(10)))
project_sha == ARC1_EXPECTED_PROJECT_SHA256 || error("captured test Project.toml hash mismatch")
manifest_sha == ARC1_EXPECTED_MANIFEST_SHA256 || error("captured test Manifest.toml hash mismatch")
println("ARC1_TEST_SANDBOX_VERIFIED")

hsquared_module = Base.require(Base.PkgId(Base.UUID("a0667dea-0f38-44e8-9150-4fda00624eac"), "HSquared"))
realpath(pathof(hsquared_module)) == realpath(joinpath(ARC1_SOURCE_ROOT, "src", "HSquared.jl")) ||
    error("loaded HSquared module did not come from the frozen source checkout")
println("ARC1_LOADED_HSQUARED_SOURCE_VERIFIED")

cd(dirname(ARC1_TEST_FILE))
include(ARC1_TEST_FILE)
arc1_verify_frozen_sandbox()
preflight_after = arc1_noinstall_preflight()
preflight_after_sha = arc1_write_preflight(ARC1_PREFLIGHT_AFTER_PATH, preflight_after)
isempty(preflight_after["loaded_manifest_sources"]) && error("no reviewed manifest package source was loaded")
println("ARC1_LOADED_MANIFEST_SOURCES_VERIFIED count=", length(preflight_after["loaded_manifest_sources"]))
before_identity = TOML.parsefile(ARC1_PREFLIGHT_BEFORE_PATH)
before_canonical = copy(before_identity)
after_canonical = copy(preflight_after)
delete!(before_canonical, "created_at_utc"); delete!(before_canonical, "canonical_sha256")
delete!(after_canonical, "created_at_utc"); delete!(after_canonical, "canonical_sha256")
delete!(before_canonical, "loaded_manifest_sources"); delete!(after_canonical, "loaded_manifest_sources")
isequal(before_canonical, after_canonical) || error("preflight identity changed during direct Julia tests")
preflight_before["canonical_sha256"] == preflight_after["canonical_sha256"] ||
    error("preflight canonical hashes differ before and after direct Julia tests")
println("ARC1_NO_INSTALL_PREFLIGHT_AFTER_SHA256=", preflight_after_sha)
println("ARC1_NO_INSTALL_PREFLIGHT_IDENTICAL")
println("ARC1_PACKAGE_JULIA_COMPONENT_PASS")
'''


def _julia_command(driver_path: Path, sandbox: dict[str, Any]) -> tuple[list[str], dict[str, str]]:
    project_path = Path(sandbox["project_path"]).resolve()
    manifest_path = Path(sandbox["manifest_path"]).resolve()
    if project_path.parent != manifest_path.parent:
        raise PackageCheckError("reviewed Julia test sandbox files must share a directory")
    env = _julia_env()
    env["JULIA_LOAD_PATH"] = "@:@stdlib"
    argv = [JULIA_BIN, "--startup-file=no", "--check-bounds=yes", "--threads=1",
            f"--project={project_path.parent}", str(driver_path.resolve())]
    return argv, env


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


def _profile_test_suite_enabled(env: dict[str, str], source: str) -> bool:
    """Require the broad profile suite and reject the stale v3-only test guard."""
    return (
        env.get("ARC1_SKIP_EXPENSIVE_PROFILE_WRAPPER") == "0"
        and env.get("ARC1_PROFILE_V3_ONLY") == "0"
        and 'if get(ENV, "ARC1_SKIP_EXPENSIVE_PROFILE_WRAPPER", "0") != "1"' in source
        and 'if get(ENV, "ARC1_PROFILE_V3_ONLY", "0") != "1"' in source
        and 'all-five Arc1 profile wrapper reports one shared point maximum' in source
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
        self.julia_depot_overlay: Path | None = None
        self.julia_depot_overlay_records: list[dict[str, str]] = []
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
        validate_freeze(doc, freeze_roots(), self.file_map, gate=self.gate)
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
        overlay_manifests: list[Path] = []
        if self.gate in {"julia", "all"}:
            overlay_manifests.append(Path(self.test_sandbox["manifest_path"]))
        if self.gate in {"r", "all"} and self.julia_call_bootstrap is not None:
            overlay_manifests.append(Path(self.julia_call_bootstrap["manifest_path"]))
        if self.gate in {"docs", "all"}:
            overlay_manifests.append(JULIA_ROOT / "docs" / "Manifest.toml")
        self.julia_depot_overlay = self.out / "julia-package-depot-overlay"
        base_depots = [Path(value) for value in JULIA_DEPOT.split(os.pathsep) if value]
        self.julia_depot_overlay_records = prepare_manifest_depot_overlay(
            overlay_manifests, base_depots, self.julia_depot_overlay)
        self.meta["julia_depot_overlay"] = {
            "path": str(self.julia_depot_overlay),
            "source_map_sha256": sha256_file(self.julia_depot_overlay / "source-map.json"),
            "packages": self.julia_depot_overlay_records,
        }
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
        if self.julia_depot_overlay is not None:
            overlay_map = self.julia_depot_overlay / "source-map.json"
            if not overlay_map.is_file() or sha256_file(overlay_map) != \
               self.meta.get("julia_depot_overlay", {}).get("source_map_sha256"):
                raise PackageCheckError("validated Julia package depot overlay map changed")
            for row in self.julia_depot_overlay_records:
                link = Path(row["overlay_path"])
                source = Path(row["source_path"])
                if not link.is_symlink() or link.resolve() != source.resolve() or \
                   _manifest_git_tree_sha1(source, row["git_tree_sha1"]) != row["git_tree_sha1"] or \
                   _content_tree_sha256(source) != row["content_tree_sha256"]:
                    raise PackageCheckError(f"validated Julia package depot overlay changed: {row['name']}")
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

    def _with_julia_package_overlay(self, env: dict[str, str]) -> dict[str, str]:
        result = dict(env)
        if self.julia_depot_overlay is not None:
            result["JULIA_DEPOT_PATH"] = str(self.julia_depot_overlay) + os.pathsep + \
                result.get("JULIA_DEPOT_PATH", JULIA_DEPOT)
        return result

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
            "cleanup": None, "log_sealed": False, "before_sha256": before,
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
                    record["cleanup"] = _oracle.terminate_group(proc)
                    record["process_group_leak"] = record["cleanup"] != "already-exited"
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
        record["log_sealed"] = record["cleanup"] != "group-still-alive"
        record["log_sha256"] = sha256_file(log_path) if record["log_sealed"] else None
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
        if not record["log_sealed"]:
            raise PackageCheckError(f"{name} log remains unsealed; process group did not exit")
        if record.get("process_group_leak"):
            raise PackageCheckError(f"{name} exited while descendants remained; group cleanup={record['cleanup']}")
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
        capture_dir.mkdir()
        for path_key, digest_key in (("project_path", "project_sha256"),
                                     ("manifest_path", "manifest_sha256")):
            source = Path(self.test_sandbox[path_key])
            if source.is_symlink() or not source.is_file() or sha256_file(source) != self.test_sandbox[digest_key]:
                raise PackageCheckError(f"reviewed Julia test sandbox changed before copy: {path_key}")
            shutil.copyfile(source, capture_dir / source.name)
        captured_project = capture_dir / "Project.toml"
        captured_manifest = capture_dir / "Manifest.toml"
        observed_sandbox = {"project_sha256": sha256_file(captured_project),
                            "manifest_sha256": sha256_file(captured_manifest)}
        expected_sandbox = {key: self.test_sandbox[key] for key in observed_sandbox}
        if observed_sandbox != expected_sandbox:
            raise PackageCheckError(f"copied Julia test sandbox differs from reviewed candidate: {observed_sandbox}")
        (capture_dir / "sha256.txt").write_text(
            observed_sandbox["project_sha256"] + "\n" + observed_sandbox["manifest_sha256"] + "\n",
            encoding="ascii",
        )
        driver_path = self.out / "julia-test-driver.jl"
        argv, env = _julia_command(driver_path, self.test_sandbox)
        env = self._with_julia_package_overlay(env)
        driver_source = julia_test_driver_source(
            self.test_sandbox, capture_dir, freeze_sha256=self.freeze_hash,
            expected_julia_executable=str(Path(self.meta["runtime_expected"]["julia_executable"]).resolve()),
            expected_julia_version=str(self.meta["runtime_expected"]["julia"]).removeprefix("julia version "),
            source_file_inventory=self.expected["julia"],
            expected_depot_path=env["JULIA_DEPOT_PATH"].split(os.pathsep))
        driver_path.write_text(driver_source, encoding="utf-8")
        driver_hash = sha256_file(driver_path)
        profile_test_source = (JULIA_ROOT / "test" / "arc1_profiles.jl").read_text(encoding="utf-8")
        if not _profile_test_suite_enabled(env, profile_test_source):
            raise PackageCheckError("required Arc1 profile tests are not proven enabled by the frozen environment and test source")
        record = self.run_command("julia-direct-test-suite", argv, JULIA_ROOT, env, RUN_TIMEOUT_S["julia"],
                                  marker="ARC1_PACKAGE_JULIA_COMPONENT_PASS", component="julia")
        captured_receipt = capture_dir / "sha256.txt"
        if not all(path.is_file() for path in (captured_project, captured_manifest, captured_receipt)):
            raise PackageCheckError("direct Julia tests did not retain the frozen sandbox capture")
        test_output = (self.out / record["log"]).read_text(encoding="utf-8", errors="replace")
        for marker in ("ARC1_TEST_SANDBOX_VERIFIED", "ARC1_LOADED_HSQUARED_SOURCE_VERIFIED"):
            if marker not in test_output:
                raise PackageCheckError(f"direct Julia tests did not report required identity marker: {marker}")
        marker_values: dict[str, str] = {}
        for name in ("ARC1_NO_INSTALL_PREFLIGHT_BEFORE_SHA256",
                     "ARC1_NO_INSTALL_PREFLIGHT_AFTER_SHA256",
                     "ARC1_NO_INSTALL_PREFLIGHT_CANONICAL_SHA256"):
            found = re.findall(rf"^{name}=([0-9a-f]{{64}})$", test_output, flags=re.MULTILINE)
            if len(found) != 1:
                raise PackageCheckError(f"direct Julia log lacks one exact {name} marker")
            marker_values[name] = found[0]
        if "ARC1_NO_INSTALL_PREFLIGHT_IDENTICAL" not in test_output:
            raise PackageCheckError("direct Julia log lacks the identical before/after preflight marker")
        runtime_expected = self.meta.get("runtime_expected", {})
        runtime_observed = self.meta.get("runtime_observed", {})
        version_output = str(runtime_expected.get("julia", ""))
        expected_version = version_output.removeprefix("julia version ")
        expected_executable = str(Path(runtime_expected.get("julia_executable", "")).resolve())
        if expected_executable != str(Path(JULIA_BIN).resolve()):
            raise PackageCheckError("launch Julia executable differs from the reviewed runtime executable path")
        host_identity = _probe_julia_host_identity(Path(expected_executable), expected_version=expected_version)
        expected_preflight = {
            "freeze_sha256": str(self.freeze_hash), "runner_sha256": self.runner_hash,
            "driver_sha256": driver_hash,
            "source_root": str(JULIA_ROOT.resolve()), "source_files": dict(self.expected["julia"]),
            "sandbox": {
                "project_path": str(Path(self.test_sandbox["project_path"]).resolve()),
                "project_sha256": self.test_sandbox["project_sha256"],
                "manifest_path": str(Path(self.test_sandbox["manifest_path"]).resolve()),
                "manifest_sha256": self.test_sandbox["manifest_sha256"],
            },
            "load_path": env["JULIA_LOAD_PATH"].split(os.pathsep),
            "depot_path": env["JULIA_DEPOT_PATH"].split(os.pathsep),
            "julia_executable": expected_executable,
            "julia_launcher_sha256": sha256_file(Path(expected_executable)),
            "julia_version": expected_version,
            "host_identity": host_identity,
        }
        preflight_before_path = capture_dir / "julia-noinstall-preflight-before.toml"
        preflight_after_path = capture_dir / "julia-noinstall-preflight-after.toml"
        preflight_before_sha = marker_values["ARC1_NO_INSTALL_PREFLIGHT_BEFORE_SHA256"]
        preflight_after_sha = marker_values["ARC1_NO_INSTALL_PREFLIGHT_AFTER_SHA256"]
        if sha256_file(preflight_before_path) != preflight_before_sha or \
           sha256_file(preflight_after_path) != preflight_after_sha:
            raise PackageCheckError("retained Julia preflight TOML hashes differ from the test log markers")
        preflight_before = validate_noinstall_preflight_receipt(
            preflight_before_path, preflight_before_sha, expected_preflight)
        preflight_after = validate_noinstall_preflight_receipt(
            preflight_after_path, preflight_after_sha, expected_preflight)
        if preflight_before.get("canonical_sha256") != preflight_after.get("canonical_sha256") or \
           preflight_before.get("canonical_sha256") != marker_values["ARC1_NO_INSTALL_PREFLIGHT_CANONICAL_SHA256"]:
            raise PackageCheckError("pre/post no-install preflight canonical hashes differ")
        before_identity = {key: value for key, value in preflight_before.items()
                           if key not in {"created_at_utc", "canonical_sha256", "loaded_manifest_sources"}}
        after_identity = {key: value for key, value in preflight_after.items()
                          if key not in {"created_at_utc", "canonical_sha256", "loaded_manifest_sources"}}
        if before_identity != after_identity:
            raise PackageCheckError("pre/post no-install preflight canonical evidence differs")
        preflight_receipt = {
            "schema": "arc1-julia-noinstall-preflight-v1", "status": "passed",
            "created_at_utc": preflight_before["created_at_utc"],
            "receipt_path": str(preflight_before_path.resolve()), "receipt_sha256": preflight_before_sha,
            "post_test_receipt_path": str(preflight_after_path.resolve()),
            "post_test_receipt_sha256": preflight_after_sha,
            "canonical_sha256": preflight_before["canonical_sha256"], "canonical_equal": True,
            "log_marker": "ARC1_NO_INSTALL_PREFLIGHT_IDENTICAL",
        }
        self.meta["julia_noinstall_preflight"] = preflight_receipt
        after_sandbox = {"project_sha256": sha256_file(Path(self.test_sandbox["project_path"])),
                         "manifest_sha256": sha256_file(Path(self.test_sandbox["manifest_path"]))}
        if after_sandbox != observed_sandbox:
            raise PackageCheckError(f"reviewed Julia test sandbox changed during direct tests: {after_sandbox}")
        after_capture = {"project_sha256": sha256_file(captured_project),
                         "manifest_sha256": sha256_file(captured_manifest)}
        if after_capture != observed_sandbox:
            raise PackageCheckError(f"retained Julia test sandbox capture changed during tests: {after_capture}")
        expected_receipt = observed_sandbox["project_sha256"] + "\n" + observed_sandbox["manifest_sha256"] + "\n"
        if captured_receipt.read_text(encoding="ascii") != expected_receipt:
            raise PackageCheckError("direct Julia test sandbox receipt does not match captured files")
        test_summary = parse_julia_test_output(test_output)
        self.meta["julia_test_summary"] = test_summary
        self.meta["julia_test_driver"] = {"path": driver_path.name, "sha256": driver_hash}
        self.meta.setdefault("component_receipts", {})["julia"] = {
            "status": "passed", "log": record["log"], "log_sha256": record["log_sha256"],
            "test_summary": test_summary, "elapsed_s": record["elapsed_s"],
            "test_sandbox": {**observed_sandbox, "capture_dir": str(capture_dir)},
            "test_sandbox_after_sha256": after_sandbox,
            "test_sandbox_capture_after_sha256": after_capture,
            "test_driver": {"path": driver_path.name, "sha256": driver_hash},
            "noinstall_preflight": preflight_receipt,
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
        live_env = self._with_julia_package_overlay(live_env)
        live_record = self.run_command("r-arc1-mandatory-live", live_argv, R_ROOT, live_env,
                                       RUN_TIMEOUT_S["r"], marker="ARC1_TESTTHAT_COUNTS", component="r")
        # The shared R driver returns nonzero for empty, failed, error, or skipped
        # Arc1 test files, so its zero exit plus retained tables is required.
        for path in (self.out / "arc1-live-results.rds", self.out / "arc1-live-results.csv"):
            if not path.is_file() or path.stat().st_size == 0:
                raise PackageCheckError(f"mandatory-live R driver did not retain {path.name}")
        check_argv, check_env = _r_check_command(self.out, self.julia_call_bootstrap_dir)
        check_env = self._with_julia_package_overlay(check_env)
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
        env = self._with_julia_package_overlay(env)
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


def _content_tree_sha256(path: Path) -> str:
    if path.is_symlink() or not path.is_dir():
        raise PackageCheckError(f"content tree root is missing or unsafe: {path}")
    root = path.resolve()
    rows: list[str] = []
    for candidate in sorted(path.rglob("*"), key=lambda item: item.relative_to(path).as_posix()):
        relative = candidate.relative_to(path).as_posix()
        if relative == ".git" or relative.startswith(".git/"):
            continue
        if candidate.is_symlink():
            try:
                resolved = candidate.resolve(strict=True)
            except OSError as exc:
                raise PackageCheckError(f"broken symlink in retained content tree: {candidate}") from exc
            if not resolved.is_relative_to(root):
                raise PackageCheckError(f"escaping symlink in retained content tree: {candidate}")
            rows.append(f"{relative}\0symlink\0{os.readlink(candidate)}")
        elif candidate.is_file():
            rows.append(f"{relative}\0file\0{sha256_file(candidate)}")
    return hashlib.sha256("\n".join(rows).encode("utf-8")).hexdigest()


def _frozen_source_snapshot(root: Path, inventory: dict[str, str]) -> tuple[list[dict[str, str]], str]:
    root = root.resolve()
    records: list[dict[str, str]] = []
    digest_rows: list[str] = []
    for relative_path, expected_sha256 in sorted(inventory.items()):
        candidate = root / relative_path
        if candidate.is_symlink() or not candidate.is_file() or \
           not candidate.resolve().is_relative_to(root):
            raise PackageCheckError(f"frozen source file is missing or unsafe: {relative_path}")
        observed = sha256_file(candidate)
        if observed != expected_sha256:
            raise PackageCheckError(f"frozen source file differs from external freeze: {relative_path}")
        records.append({"relative_path": relative_path, "sha256": observed})
        digest_rows.append(f"{relative_path}\0{observed}")
    if not records:
        raise PackageCheckError("frozen source inventory is empty")
    return records, hashlib.sha256("\n".join(digest_rows).encode("utf-8")).hexdigest()


ARTIFACT_SELECTOR_METADATA = {"git-tree-sha1", "download", "lazy"}
ARTIFACT_SELECTOR_KNOWN = {
    "arch", "os", "libc", "call_abi", "libgfortran_version", "libstdcxx_version",
    "libcxx_version", "cxxstring_abi", "julia_version", "os_version", "sanitize", "mpi", "cuda",
}
# BinaryPlatforms applies non-equality comparison strategies to version-like
# tags. The retained Python verifier deliberately rejects these rather than
# attempting to reproduce Julia's comparator and match-loss ordering.
ARTIFACT_SELECTOR_COMPARATOR_TAGS = {
    "os_version", "libstdcxx_version", "libcxx_version",
    "julia_version", "cuda",
}
ARTIFACT_ARCH_CANONICAL = {
    "aarch64", "armv6l", "armv7l", "i686", "powerpc64le", "riscv64", "wasm32", "x86_64",
}
ARTIFACT_OS_CANONICAL = {"freebsd", "linux", "macos", "openbsd", "windows"}


def _artifact_metadata_path(root: Path) -> Path | None:
    for filename in ("JuliaArtifacts.toml", "Artifacts.toml"):
        path = root / filename
        if path.exists():
            if path.is_symlink() or not path.is_file():
                raise PackageCheckError(f"unsafe package artifact metadata: {path}")
            return path
    return None


def _dynamic_artifact_selectors(root: Path) -> list[Path]:
    return [path for path in (root / ".pkg" / "select_artifacts.jl", root / "select_artifacts.jl")
            if path.exists()]


def _select_artifacts_for_host(metadata: dict[str, Any], host_tags: dict[str, Any]) -> list[dict[str, Any]]:
    selected: list[dict[str, Any]] = []
    for name, raw in metadata.items():
        if isinstance(raw, dict):
            # Julia treats a single table as unconditional artifact metadata;
            # platform keys in it do not select among platform variants.
            variants = [raw]
            unconditional = True
        elif isinstance(raw, list):
            variants = raw
            unconditional = False
        else:
            raise PackageCheckError(f"artifact metadata has unsupported shape: {name}")
        matches: list[dict[str, Any]] = []
        for variant in variants:
            if not isinstance(variant, dict):
                raise PackageCheckError(f"artifact selector variant is malformed: {name}")
            selectors = {str(key): value for key, value in variant.items()
                         if str(key) not in ARTIFACT_SELECTOR_METADATA}
            if unconditional:
                matches.append(variant)
                continue
            unknown = set(selectors) - ARTIFACT_SELECTOR_KNOWN
            if unknown:
                raise PackageCheckError(f"unknown artifact selector keys for {name}: {sorted(unknown)}")
            if "arch" not in selectors or "os" not in selectors or \
               not isinstance(selectors.get("arch"), str) or not isinstance(selectors.get("os"), str):
                raise PackageCheckError(f"array selector requires string arch and os for {name}")
            for key, value in selectors.items():
                if not isinstance(value, str):
                    raise PackageCheckError(f"selector value must be a canonical lowercase string for {name}: {key}")
                if value != value.lower():
                    raise PackageCheckError(f"noncanonical selector value for {name}: {key}")
            # Platform constructors normalize these fields before matching.
            # Accept only canonical spellings so the Python reconstruction
            # cannot omit a Julia match through an unimplemented alias.
            arch = selectors["arch"]
            if arch not in ARTIFACT_ARCH_CANONICAL:
                raise PackageCheckError(f"noncanonical artifact arch selector for {name}: {arch}")
            if arch != str(host_tags.get("arch", "")):
                continue
            os_name = selectors["os"]
            if os_name not in ARTIFACT_OS_CANONICAL:
                raise PackageCheckError(f"noncanonical artifact os selector for {name}: {os_name}")
            if os_name != str(host_tags.get("os", "")):
                continue
            if selectors.get("os") == "linux" and str(host_tags.get("os", "")) == "linux":
                if "libc" not in selectors:
                    raise PackageCheckError(f"Linux selector omits normalized libc for {name}")
                if "call_abi" in host_tags and "call_abi" not in selectors:
                    raise PackageCheckError(f"Linux selector omits normalized call_abi for {name}")
            comparator_tags = set(selectors) & ARTIFACT_SELECTOR_COMPARATOR_TAGS
            if comparator_tags:
                raise PackageCheckError(
                    f"comparator-based selector is outside the verified Python subset for {name}: "
                    f"{sorted(comparator_tags)}")
            missing_tags = set(selectors) - set(host_tags)
            if missing_tags:
                raise PackageCheckError(
                    f"host platform lacks selector tag for {name}: {sorted(missing_tags)}")
            if "libgfortran_version" in selectors:
                version = selectors["libgfortran_version"]
                if not re.fullmatch(r"(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)\.(?:0|[1-9][0-9]*)", version):
                    raise PackageCheckError(f"noncanonical libgfortran version selector for {name}")
            if all(str(host_tags[key]) == str(value) for key, value in selectors.items()):
                matches.append(variant)
        if not matches:
            continue
        if len(matches) != 1:
            raise PackageCheckError(f"multiple host-matching variants outside the verified subset for {name}")
        variant = matches[0]
        tree, lazy = str(variant.get("git-tree-sha1", "")), bool(variant.get("lazy", False))
        if "download" not in variant:
            continue
        if not re.fullmatch(r"[0-9a-f]{40}", tree):
            raise PackageCheckError(f"selected artifact lacks an exact tree hash: {name}")
        selected.append({"name": str(name), "git_tree_sha1": tree, "lazy": lazy})
    return sorted(selected, key=lambda item: (item["name"], item["git_tree_sha1"]))


def _registry_candidates(depots: list[str], tarball_mode: bool) -> set[str]:
    candidates: set[str] = set()
    for depot_value in depots:
        registry_dir = Path(depot_value) / "registries"
        if not registry_dir.exists():
            continue
        if registry_dir.is_symlink() or not registry_dir.is_dir():
            raise PackageCheckError(f"unsafe Julia registry directory: {registry_dir}")
        entries = list(registry_dir.iterdir())
        if any(entry.is_symlink() for entry in entries):
            raise PackageCheckError(f"symlink in Julia registry directory: {registry_dir}")
        compressed = [entry for entry in entries if tarball_mode and entry.suffix == ".toml" and entry.is_file()]
        compressed_names = {entry.stem for entry in compressed}
        for entry in entries:
            if entry.is_dir() and entry.name not in compressed_names and (entry / "Registry.toml").is_file():
                candidates.add(str(entry.resolve()))
        for descriptor in compressed:
            try:
                with descriptor.open("rb") as stream:
                    data = tomllib.load(stream)
            except (OSError, tomllib.TOMLDecodeError):
                continue
            payload = data.get("path")
            if isinstance(data.get("git-tree-sha1"), str) and isinstance(data.get("uuid"), str) and \
               isinstance(payload, str) and (descriptor.parent / payload).is_file():
                candidates.add(str(descriptor.resolve()))
    return candidates


def _safe_extract_registry_tarball(path: Path, destination: Path) -> Path:
    destination.mkdir(parents=True)
    try:
        archive = tarfile.open(path, mode="r:*")
    except (OSError, tarfile.TarError) as exc:
        raise PackageCheckError(f"reachable registry archive is invalid: {path}") from exc
    with archive:
        for member in archive.getmembers():
            name = member.name.replace("\\", "/")
            normalized = posixpath.normpath(name)
            if name.startswith("/") or normalized == ".." or normalized.startswith("../"):
                raise PackageCheckError(f"registry archive contains path traversal: {member.name}")
            target = destination.joinpath(*Path(normalized).parts)
            if not target.resolve().is_relative_to(destination.resolve()):
                raise PackageCheckError(f"registry archive path escapes extraction root: {member.name}")
            if member.isdir():
                target.mkdir(parents=True, exist_ok=True)
            elif member.isfile():
                target.parent.mkdir(parents=True, exist_ok=True)
                source = archive.extractfile(member)
                if source is None:
                    raise PackageCheckError(f"registry archive member cannot be read: {member.name}")
                with source, target.open("wb") as output:
                    shutil.copyfileobj(source, output)
                target.chmod(0o755 if member.mode & 0o111 else 0o644)
            elif member.issym():
                link_target = member.linkname
                resolved_link = posixpath.normpath(posixpath.join(posixpath.dirname(normalized), link_target))
                if link_target.startswith("/") or resolved_link == ".." or resolved_link.startswith("../"):
                    raise PackageCheckError(f"registry archive contains escaping symlink: {member.name}")
                target.parent.mkdir(parents=True, exist_ok=True)
                target.symlink_to(link_target)
            else:
                raise PackageCheckError(f"registry archive contains unsupported member type: {member.name}")
    registry_files = list(destination.rglob("Registry.toml"))
    if len(registry_files) != 1:
        raise PackageCheckError("registry archive must contain exactly one Registry.toml")
    return registry_files[0].parent


def _git_tree_sha1(path: Path) -> str:
    """Compute Git's content tree identity without requiring a repository or index."""
    if path.is_symlink() or not path.is_dir():
        raise PackageCheckError(f"git tree root is missing or unsafe: {path}")

    def object_hash(kind: bytes, content: bytes) -> bytes:
        return hashlib.sha1(kind + b" " + str(len(content)).encode("ascii") + b"\0" + content).digest()

    def tree(directory: Path) -> bytes:
        entries: list[tuple[bytes, bytes]] = []
        for child in directory.iterdir():
            if child.name == ".git":
                continue
            encoded_name = os.fsencode(child.name)
            if child.is_symlink():
                target = os.fsencode(os.readlink(child))
                mode, digest = b"120000", object_hash(b"blob", target)
                sort_name = encoded_name
            elif child.is_dir():
                mode, digest = b"40000", tree(child)
                sort_name = encoded_name + b"/"
            elif child.is_file():
                executable = bool(child.stat().st_mode & 0o111)
                mode = b"100755" if executable else b"100644"
                digest = object_hash(b"blob", child.read_bytes())
                sort_name = encoded_name
            else:
                raise PackageCheckError(f"unsupported filesystem entry in git tree: {child}")
            entries.append((sort_name, mode + b" " + encoded_name + b"\0" + digest))
        body = b"".join(entry for _, entry in sorted(entries, key=lambda item: item[0]))
        return object_hash(b"tree", body)

    return tree(path).hex()


def _manifest_git_tree_sha1(path: Path, expected_tree: str | None = None) -> str:
    """Match a Manifest tree while excluding coverage and proven Conda build output."""
    if path.is_symlink() or not path.is_dir():
        raise PackageCheckError(f"manifest package tree root is missing or unsafe: {path}")
    coverage_files = sorted(path.rglob("*.cov"))
    for coverage_file in coverage_files:
        if coverage_file.is_symlink() or not coverage_file.is_file():
            raise PackageCheckError(f"unsafe package coverage artifact: {coverage_file}")
    generated_deps_directory = path / "deps"
    if generated_deps_directory.is_symlink() or \
       (generated_deps_directory.exists() and not generated_deps_directory.is_dir()):
        raise PackageCheckError(f"unsafe generated package build-output directory: {generated_deps_directory}")
    generated_deps_file = generated_deps_directory / "deps.jl"
    if generated_deps_file.is_symlink() or (generated_deps_file.exists() and not generated_deps_file.is_file()):
        raise PackageCheckError(f"unsafe generated package build output: {generated_deps_file}")
    if not coverage_files:
        actual = _git_tree_sha1(path)
        if expected_tree is None or actual == expected_tree or not generated_deps_file.is_file():
            return actual
    with tempfile.TemporaryDirectory(prefix="arc1-manifest-package-tree-") as temporary:
        staged = Path(temporary) / "package"
        shutil.copytree(path, staged, symlinks=True)
        for coverage_file in coverage_files:
            (staged / coverage_file.relative_to(path)).unlink()
        observed = _git_tree_sha1(staged)
        if observed == expected_tree or not generated_deps_file.is_file():
            return observed
        (staged / "deps" / "deps.jl").unlink()
        generated_excluded_tree = _git_tree_sha1(staged)
        return generated_excluded_tree if generated_excluded_tree == expected_tree else observed


def prepare_manifest_depot_overlay(manifest_paths: list[Path], base_depots: list[Path],
                                   overlay_root: Path) -> list[dict[str, str]]:
    """Precede shared depots with symlinks to exact, validated Manifest trees."""
    if overlay_root.exists() or overlay_root.is_symlink():
        raise PackageCheckError(f"Julia package depot overlay path already exists: {overlay_root}")
    overlay_root.mkdir(parents=True)
    records: dict[tuple[str, str, str], dict[str, str]] = {}
    for manifest_path in manifest_paths:
        try:
            with manifest_path.open("rb") as stream:
                manifest = tomllib.load(stream)
        except (OSError, tomllib.TOMLDecodeError) as exc:
            raise PackageCheckError(f"cannot read reviewed Julia Manifest for depot overlay: {manifest_path}: {exc}") from exc
        for name, raw in manifest.get("deps", {}).items():
            for entry in raw if isinstance(raw, list) else [raw]:
                if not isinstance(entry, dict):
                    raise PackageCheckError(f"malformed Manifest entry for depot overlay: {name}")
                tree = entry.get("git-tree-sha1")
                uuid_value = entry.get("uuid")
                if tree is None or entry.get("path") is not None:
                    continue
                if not isinstance(tree, str) or not re.fullmatch(r"[0-9a-f]{40}", tree) or \
                   not isinstance(uuid_value, str):
                    raise PackageCheckError(f"malformed Manifest source pin for depot overlay: {name}")
                key = (name, uuid_value, tree)
                if key in records:
                    continue
                source_root: Path | None = None
                for depot in base_depots:
                    package_dir = depot / "packages" / name
                    if package_dir.is_symlink() or not package_dir.is_dir():
                        continue
                    for candidate in sorted(package_dir.iterdir()):
                        if candidate.is_symlink() or not candidate.is_dir():
                            continue
                        project_file = candidate / "Project.toml"
                        if project_file.is_symlink() or not project_file.is_file():
                            continue
                        try:
                            with project_file.open("rb") as stream:
                                package_project = tomllib.load(stream)
                            if str(package_project.get("uuid")) != uuid_value:
                                continue
                            if _manifest_git_tree_sha1(candidate, tree) != tree:
                                continue
                        except (OSError, tomllib.TOMLDecodeError, PackageCheckError):
                            continue
                        source_root = candidate.resolve()
                        break
                    if source_root is not None:
                        break
                if source_root is None:
                    raise PackageCheckError(
                        f"no installed package source matches reviewed Manifest tree: {name}/{uuid_value}/{tree}")
                link_path = overlay_root / "packages" / name / source_root.name
                link_path.parent.mkdir(parents=True, exist_ok=True)
                os.symlink(source_root, link_path, target_is_directory=True)
                records[key] = {"name": name, "uuid": uuid_value, "git_tree_sha1": tree,
                                "source_path": str(source_root), "overlay_path": str(link_path),
                                "content_tree_sha256": _content_tree_sha256(source_root)}
    result = sorted(records.values(), key=lambda row: (row["name"], row["uuid"], row["git_tree_sha1"]))
    (overlay_root / "source-map.json").write_text(json.dumps(result, sort_keys=True, indent=2) + "\n",
                                                   encoding="utf-8")
    return result


def _probe_julia_host_identity(launcher: Path, *, expected_version: str) -> dict[str, Any]:
    """Query the pinned runtime's Pkg artifact platform and runtime identity."""
    probe_source = r'''using Pkg, SHA, TOML
platform = Pkg.BinaryPlatforms.HostPlatform()
runtime = realpath(Base.julia_cmd().exec[1])
TOML.print(stdout, Dict(
    "julia_version" => string(VERSION),
    "host_platform" => Pkg.BinaryPlatforms.triplet(platform),
    "host_platform_tags" => Dict(String(k) => string(v) for (k, v) in Pkg.BinaryPlatforms.tags(platform)),
    "julia_runtime_executable" => runtime,
    "julia_runtime_executable_sha256" => bytes2hex(sha256(read(runtime))),
); sorted=true)
'''
    probe_env = os.environ.copy()
    for key in ("JULIA_PROJECT", "JULIA_LOAD_PATH", "JULIA_DEPOT_PATH"):
        probe_env.pop(key, None)
    probe_env["JULIA_LOAD_PATH"] = "@stdlib"
    command = [str(launcher.resolve()), "--startup-file=no", "--history-file=no",
               "--threads=1", "--project=@stdlib", "-e", probe_source]
    result = subprocess.run(command, cwd=JULIA_ROOT, env=probe_env,
                            text=True, capture_output=True, timeout=90, check=False)
    if result.returncode != 0:
        raise PackageCheckError(f"pinned Julia exact-launcher host identity probe failed: {result.stderr[-2000:]}")
    try:
        identity = tomllib.loads(result.stdout)
    except tomllib.TOMLDecodeError as exc:
        raise PackageCheckError("pinned Julia exact-launcher host identity probe returned invalid TOML") from exc
    if identity.get("julia_version") != expected_version or \
       not isinstance(identity.get("host_platform"), str) or not identity["host_platform"] or \
       not isinstance(identity.get("host_platform_tags"), dict) or not identity["host_platform_tags"]:
        raise PackageCheckError("pinned Julia exact-launcher host identity probe returned incomplete identity")
    runtime = Path(str(identity.get("julia_runtime_executable", "")))
    if not runtime.is_absolute() or runtime.is_symlink() or not runtime.is_file() or \
       sha256_file(runtime) != identity.get("julia_runtime_executable_sha256"):
        raise PackageCheckError("pinned Julia exact-launcher host identity probe returned unsafe runtime identity")
    return identity


def validate_noinstall_preflight_receipt(path: Path, expected_sha256: str,
                                         expected: dict[str, Any]) -> dict[str, Any]:
    if path.is_symlink() or not path.is_file():
        raise PackageCheckError("retained no-install preflight receipt is missing or unsafe")
    raw = path.read_bytes()
    if hashlib.sha256(raw).hexdigest() != expected_sha256:
        raise PackageCheckError("retained preflight receipt SHA-256 differs from its package receipt")
    try:
        report = tomllib.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, tomllib.TOMLDecodeError) as exc:
        raise PackageCheckError(f"retained no-install preflight TOML is invalid: {exc}") from exc
    if report.get("schema") != "arc1-julia-noinstall-preflight-v1" or report.get("status") != "passed":
        raise PackageCheckError("no-install preflight report lacks the reviewed schema or passed status")
    for key in ("freeze_sha256", "runner_sha256", "driver_sha256"):
        if report.get(key) != expected.get(key):
            raise PackageCheckError(f"no-install preflight {key} differs from the current frozen identity")
    if report.get("sandbox") != expected.get("sandbox"):
        raise PackageCheckError("no-install preflight sandbox hashes differ from the external freeze")
    if report.get("load_path") != expected.get("load_path") or \
       report.get("depot_path") != expected.get("depot_path"):
        raise PackageCheckError("no-install preflight Julia LOAD_PATH or DEPOT_PATH differs from the command")
    if report.get("julia_executable") != expected.get("julia_executable") or \
       report.get("julia_launcher_sha256") != expected.get("julia_launcher_sha256") or \
       report.get("julia_version") != expected.get("julia_version") or \
       not isinstance(report.get("host_platform"), str) or not report["host_platform"] or \
       not re.fullmatch(r"[0-9a-f]{64}", str(report.get("canonical_sha256", ""))):
        raise PackageCheckError("no-install preflight runtime or host identity is incomplete")
    runtime_binary = Path(str(report.get("julia_runtime_executable", "")))
    runtime_binary_sha = str(report.get("julia_runtime_executable_sha256", ""))
    if not runtime_binary.is_absolute() or runtime_binary.is_symlink() or not runtime_binary.is_file() or \
       not re.fullmatch(r"[0-9a-f]{64}", runtime_binary_sha) or sha256_file(runtime_binary) != runtime_binary_sha:
        raise PackageCheckError("actual Julia runtime executable identity is missing or changed")
    if expected.get("julia_runtime_executable") is not None and \
       (str(runtime_binary) != expected["julia_runtime_executable"] or
        runtime_binary_sha != expected.get("julia_runtime_executable_sha256")):
        raise PackageCheckError("actual Julia runtime binary differs from the retained expected identity")
    host_identity = expected.get("host_identity")
    if not isinstance(host_identity, dict) or \
       report.get("host_platform") != host_identity.get("host_platform") or \
       report.get("host_platform_tags") != host_identity.get("host_platform_tags") or \
       str(runtime_binary) != host_identity.get("julia_runtime_executable") or \
       runtime_binary_sha != host_identity.get("julia_runtime_executable_sha256"):
        raise PackageCheckError("preflight host platform or runtime identity differs from the exact-launcher Base probe")
    try:
        timestamp = dt.datetime.fromisoformat(str(report.get("created_at_utc", "")).replace("Z", "+00:00"))
    except ValueError as exc:
        raise PackageCheckError("no-install preflight timestamp is invalid") from exc
    if timestamp.tzinfo is None or timestamp.utcoffset() != dt.timedelta(0):
        raise PackageCheckError("no-install preflight timestamp must be UTC")
    try:
        with Path(report["sandbox"]["manifest_path"]).open("rb") as stream:
            manifest = tomllib.load(stream)
        with Path(expected["sandbox"]["project_path"]).open("rb") as stream:
            test_project = tomllib.load(stream)
    except (OSError, tomllib.TOMLDecodeError, KeyError) as exc:
        raise PackageCheckError(f"cannot parse reviewed test Manifest/Project for preflight validation: {exc}") from exc
    sources = report.get("manifest_sources")
    if not isinstance(sources, list) or not sources:
        raise PackageCheckError("no-install preflight manifest source inventory is missing")
    loaded_sources = report.get("loaded_manifest_sources")
    if not isinstance(loaded_sources, list):
        raise PackageCheckError("no-install preflight loaded manifest source inventory is missing")
    source_ids: set[tuple[str, str]] = set()
    source_by_id: dict[tuple[str, str], dict[str, Any]] = {}
    for source in sources:
        if not isinstance(source, dict) or not isinstance(source.get("name"), str) or \
           not isinstance(source.get("uuid"), str):
            raise PackageCheckError("no-install preflight manifest source identity is malformed")
        source_ids.add((source["name"], source["uuid"]))
        source_by_id[(source["name"], source["uuid"])] = source
        source_path = Path(str(source.get("source_path", "")))
        project_path = Path(str(source.get("project_path", "")))
        if source.get("kind") == "path-snapshot":
            expected_source_files = expected.get("source_files")
            reported_source_files = source.get("source_files")
            if not isinstance(expected_source_files, dict) or not isinstance(reported_source_files, list) or \
               source_path.resolve() != Path(expected.get("source_root", "")).resolve():
                raise PackageCheckError("frozen HSquared source snapshot identity is missing")
            expected_rows, expected_snapshot_sha = _frozen_source_snapshot(source_path, expected_source_files)
            if reported_source_files != expected_rows or source.get("content_tree_sha256") != expected_snapshot_sha:
                raise PackageCheckError("HSquared source snapshot differs from the reviewed freeze")
            if project_path.resolve() != (source_path / "Project.toml").resolve():
                raise PackageCheckError("HSquared path-snapshot Project.toml is not at its source root")
            with project_path.open("rb") as stream:
                package_project = tomllib.load(stream)
            if str(package_project.get("uuid")) != source["uuid"]:
                raise PackageCheckError("HSquared path-snapshot Project.toml UUID differs")
            continue
        if source_path.is_symlink() or not source_path.is_dir() or project_path.is_symlink() or \
           not project_path.is_file() or project_path.resolve() != (source_path / "Project.toml").resolve() or \
           not re.fullmatch(r"[0-9a-f]{40}",
               str(source.get("git_tree_sha1", ""))) or not re.fullmatch(r"[0-9a-f]{64}",
               str(source.get("content_tree_sha256", ""))):
            raise PackageCheckError(f"manifest source path or tree identity is missing: {source.get('name')}")
        if _content_tree_sha256(source_path) != source["content_tree_sha256"]:
            raise PackageCheckError(f"manifest source content hash differs: {source.get('name')}")
        if _manifest_git_tree_sha1(source_path, source["git_tree_sha1"]) != source["git_tree_sha1"]:
            raise PackageCheckError(f"manifest source git tree differs: {source.get('name')}")
        try:
            with project_path.open("rb") as stream:
                package_project = tomllib.load(stream)
        except (OSError, tomllib.TOMLDecodeError) as exc:
            raise PackageCheckError(f"manifest source Project.toml is invalid: {source.get('name')}") from exc
        if str(package_project.get("uuid")) != source["uuid"]:
            raise PackageCheckError(f"manifest source Project.toml UUID differs: {source.get('name')}")
    manifest_ids: set[tuple[str, str]] = set()
    manifest_entries: dict[tuple[str, str], dict[str, Any]] = {}
    for name, raw in manifest.get("deps", {}).items():
        for entry in raw if isinstance(raw, list) else [raw]:
            if not isinstance(entry, dict) or not isinstance(entry.get("uuid"), str):
                raise PackageCheckError(f"reviewed Manifest source is malformed: {name}")
            key = (name, entry["uuid"])
            manifest_ids.add(key)
            manifest_entries[key] = entry
    if source_ids != manifest_ids:
        raise PackageCheckError("preflight source inventory differs from the exact reviewed Manifest")
    loaded_ids: set[tuple[str, str]] = set()
    for loaded in loaded_sources:
        if not isinstance(loaded, dict) or not isinstance(loaded.get("name"), str) or \
           not isinstance(loaded.get("uuid"), str) or not isinstance(loaded.get("path"), str):
            raise PackageCheckError("loaded manifest source identity is malformed")
        key = (loaded["name"], loaded["uuid"])
        source = source_by_id.get(key)
        observed_path = Path(loaded["path"])
        if source is None or not observed_path.is_absolute() or observed_path.is_symlink() or \
           not observed_path.is_file() or observed_path.resolve() != \
           (Path(source["source_path"]).resolve() / "src" / f"{loaded['name']}.jl").resolve():
            raise PackageCheckError(f"loaded manifest source differs from its reviewed source root: {key[0]}")
        if key in loaded_ids:
            raise PackageCheckError(f"loaded manifest source identity is duplicated: {key[0]}")
        loaded_ids.add(key)
    for key, entry in manifest_entries.items():
        source = source_by_id[key]
        declared_tree = entry.get("git-tree-sha1")
        declared_path = entry.get("path")
        if declared_tree is not None and source.get("git_tree_sha1") != declared_tree:
            raise PackageCheckError(f"manifest source tree differs from reviewed Manifest: {key[0]}")
        if declared_path is not None:
            root = Path(expected["sandbox"]["manifest_path"]).parent
            source_path = Path(source["source_path"])
            resolved_declared = (Path(declared_path) if Path(declared_path).is_absolute()
                                 else root / declared_path).resolve()
            if resolved_declared != source_path.resolve() or source.get("kind") not in {"path", "path-snapshot"}:
                raise PackageCheckError(f"manifest source path differs from reviewed Manifest: {key[0]}")
        elif declared_tree is not None and source.get("kind") != "git-tree":
            raise PackageCheckError(f"manifest source kind differs from reviewed tree pin: {key[0]}")
        elif declared_tree is None and source.get("kind") not in {"stdlib", "path-snapshot"}:
            raise PackageCheckError(f"unhashed manifest source is not a standard library: {key[0]}")
    aqua = report.get("aqua")
    aqua_project = test_project.get("extras", {}).get("Aqua") or test_project.get("deps", {}).get("Aqua")
    aqua_entry = manifest_entries.get(("Aqua", str(aqua_project)))
    if not isinstance(aqua, dict) or aqua_entry is None or aqua.get("uuid") != str(aqua_project) or \
       aqua.get("version") != aqua_entry.get("version") or aqua.get("git_tree_sha1") != aqua_entry.get("git-tree-sha1") or \
       aqua.get("source_path") != source_by_id[("Aqua", str(aqua_project))]["source_path"]:
        raise PackageCheckError("Aqua identity or version differs from the reviewed test Manifest")
    sandbox_expected = expected["sandbox"]
    if report["sandbox"]["project_path"] != str(Path(sandbox_expected["project_path"]).resolve()) or \
       report["sandbox"]["manifest_path"] != str(Path(sandbox_expected["manifest_path"]).resolve()):
        raise PackageCheckError(f"preflight sandbox paths differ from external pins: {report['sandbox']!r}")
    closure = report.get("dependency_closure")
    if not isinstance(closure, list) or not closure:
        raise PackageCheckError("no-install preflight dependency closure is missing")
    closure_by_id: dict[tuple[str, str], dict[str, Any]] = {}
    for package in closure:
        if not isinstance(package, dict) or not isinstance(package.get("name"), str) or \
           not isinstance(package.get("uuid"), str) or package.get("kind") not in {"stdlib", "git-tree", "path", "path-snapshot"}:
            raise PackageCheckError("no-install preflight dependency closure member is malformed")
        identity = (package["name"], package["uuid"])
        if identity in closure_by_id:
            raise PackageCheckError(f"no-install preflight dependency closure has duplicate {package['name']}")
        closure_by_id[identity] = package
        if package["kind"] != "stdlib" and identity not in source_ids:
            raise PackageCheckError(f"dependency closure contains an unreviewed member: {package['name']}")
        if identity in source_by_id:
            source = source_by_id[identity]
            for field in ("source_path", "project_path", "content_tree_sha256"):
                if package.get(field) != source.get(field):
                    raise PackageCheckError(f"dependency closure source differs from manifest inventory: {package['name']}")
            if source.get("git_tree_sha1") is not None and package.get("git_tree_sha1") != source.get("git_tree_sha1"):
                raise PackageCheckError(f"dependency closure git tree differs from manifest inventory: {package['name']}")
            if package.get("source_files") != source.get("source_files"):
                raise PackageCheckError(f"dependency closure frozen source inventory differs: {package['name']}")
        elif package["kind"] == "stdlib":
            stdlib_path = Path(str(package.get("source_path", "")))
            stdlib_project = Path(str(package.get("project_path", "")))
            if stdlib_path.is_symlink() or not stdlib_path.is_dir() or stdlib_project.is_symlink() or \
               stdlib_project.resolve() != (stdlib_path / "Project.toml").resolve() or \
               _content_tree_sha256(stdlib_path) != package.get("content_tree_sha256") or \
               _git_tree_sha1(stdlib_path) != package.get("git_tree_sha1"):
                raise PackageCheckError(f"stdlib dependency source differs: {package['name']}")
            try:
                with stdlib_project.open("rb") as stream:
                    stdlib_doc = tomllib.load(stream)
            except (OSError, tomllib.TOMLDecodeError) as exc:
                raise PackageCheckError(f"stdlib Project.toml is invalid: {package['name']}") from exc
            if str(stdlib_doc.get("uuid")) != package["uuid"]:
                raise PackageCheckError(f"stdlib dependency UUID differs: {package['name']}")
    aqua_identity = (str(aqua["name"]), str(aqua["uuid"]))
    hsquared_identity = ("HSquared", next((uuid for name, uuid in source_ids if name == "HSquared"), ""))
    if aqua_identity not in closure_by_id or hsquared_identity not in closure_by_id:
        raise PackageCheckError("dependency closure must contain exact Aqua and HSquared roots")
    expected_closure: set[tuple[str, str]] = set()
    expected_omitted_rows: set[tuple[str, str, str, str]] = set()
    pending = [aqua_identity, hsquared_identity]
    while pending:
        identity = pending.pop()
        if identity in expected_closure:
            continue
        package = closure_by_id.get(identity)
        if package is None:
            raise PackageCheckError(f"dependency closure omits reachable package: {identity[0]}")
        expected_closure.add(identity)
        try:
            with Path(package["project_path"]).open("rb") as stream:
                package_project = tomllib.load(stream)
        except (OSError, tomllib.TOMLDecodeError, KeyError) as exc:
            raise PackageCheckError(f"dependency closure Project.toml is invalid: {identity[0]}") from exc
        strong_dependencies = package_project.get("deps", {})
        weak_dependencies = package_project.get("weakdeps", {})
        for dep_name, dep_uuid in strong_dependencies.items():
            # Pkg.Types.Project removes exact name+UUID pairs duplicated in
            # [weakdeps] from its normalized .deps map.
            if weak_dependencies.get(dep_name) == dep_uuid:
                continue
            pending.append((str(dep_name), str(dep_uuid)))
        for dep_name, dep_uuid in weak_dependencies.items():
            dependency = (str(dep_name), str(dep_uuid))
            if dependency in source_ids or dependency in closure_by_id:
                pending.append(dependency)
            else:
                expected_omitted_rows.add((identity[0], identity[1], dependency[0], dependency[1]))
    if expected_closure != set(closure_by_id):
        raise PackageCheckError("dependency closure contains unreachable or missing packages")
    omitted = report.get("omitted_weak_dependencies")
    if not isinstance(omitted, list):
        raise PackageCheckError("no-install preflight omitted weak dependency inventory is missing")
    omitted_rows = {(item.get("owner"), item.get("owner_uuid"), item.get("name"), item.get("uuid"))
                    for item in omitted if isinstance(item, dict)}
    if len(omitted_rows) != len(omitted) or omitted_rows != expected_omitted_rows:
        raise PackageCheckError("no-install preflight omitted weak dependencies differ from reachable package projects")
    expected_omitted = {("HSquared", name) for name in ("AlgebraOfGraphics", "CUDA", "Makie")}
    if not expected_omitted.issubset({(row[0], row[2]) for row in omitted_rows}):
        raise PackageCheckError("no-install preflight omitted HSquared weak dependencies differ from policy")
    hsquared_project = source_by_id.get(("HSquared", next((uuid for name, uuid in source_ids if name == "HSquared"), "")))
    if hsquared_project is None:
        raise PackageCheckError("no-install preflight lacks the current HSquared root source")
    try:
        with Path(hsquared_project["project_path"]).open("rb") as stream:
            hsquared_project_doc = tomllib.load(stream)
    except (OSError, tomllib.TOMLDecodeError) as exc:
        raise PackageCheckError("current HSquared Project.toml is unavailable") from exc
    expected_weak = hsquared_project_doc.get("weakdeps", {})
    if set(expected_weak) != {name for _, name in expected_omitted}:
        raise PackageCheckError("current HSquared weak dependencies differ from explicit omission policy")
    if any((item.get("name"), item.get("uuid")) in source_ids or
           (item.get("owner") == "HSquared" and
            item.get("uuid") != str(expected_weak.get(item.get("name"))))
           for item in omitted if isinstance(item, dict)):
        raise PackageCheckError("an expected omitted weak dependency is present in the reviewed manifest")
    selectors = report.get("unresolved_artifact_selectors")
    if not isinstance(selectors, list) or selectors:
        raise PackageCheckError("no-install preflight has an unresolved artifact selector")
    host_tags = report.get("host_platform_tags")
    if not isinstance(host_tags, dict) or not host_tags:
        raise PackageCheckError("no-install preflight host platform tag inventory is missing")
    artifact_sources = report.get("artifact_sources")
    if not isinstance(artifact_sources, list):
        raise PackageCheckError("no-install preflight artifact metadata inventory is missing")
    artifact_source_by_id: dict[tuple[str, str], dict[str, Any]] = {}
    expected_artifact_keys: set[tuple[str, str, str, str, bool]] = set()
    for artifact_source in artifact_sources:
        if not isinstance(artifact_source, dict):
            raise PackageCheckError("artifact metadata inventory row is malformed")
        identity = (str(artifact_source.get("package", "")), str(artifact_source.get("package_uuid", "")))
        if identity in artifact_source_by_id or identity not in source_by_id:
            raise PackageCheckError("artifact metadata inventory has a duplicate or unreviewed package")
        artifact_source_by_id[identity] = artifact_source
    expected_artifact_source_ids: set[tuple[str, str]] = set()
    for identity, source in source_by_id.items():
        if source.get("kind") == "stdlib":
            continue
        package_root = Path(source["source_path"])
        if any(_dynamic_artifact_selectors(package_root)):
            raise PackageCheckError(f"dynamic artifact selector is unsupported for {identity[0]}")
        metadata_path = _artifact_metadata_path(package_root)
        if metadata_path is None:
            continue
        expected_artifact_source_ids.add(identity)
        artifact_source = artifact_source_by_id.get(identity)
        if artifact_source is None or artifact_source.get("metadata_file") != str(metadata_path.resolve()) or \
           artifact_source.get("metadata_sha256") != sha256_file(metadata_path):
            raise PackageCheckError(f"artifact metadata source is missing or changed for {identity[0]}")
        try:
            with metadata_path.open("rb") as stream:
                metadata_doc = tomllib.load(stream)
        except (OSError, tomllib.TOMLDecodeError) as exc:
            raise PackageCheckError(f"artifact metadata TOML is invalid for {identity[0]}") from exc
        selected = _select_artifacts_for_host(metadata_doc, host_tags)
        if artifact_source.get("selected") != selected:
            raise PackageCheckError(f"selected artifact inventory differs from metadata for {identity[0]}")
        for item in selected:
            expected_artifact_keys.add((identity[0], identity[1], item["name"], item["git_tree_sha1"], item["lazy"]))
    if set(artifact_source_by_id) != expected_artifact_source_ids:
        raise PackageCheckError("artifact metadata inventory omits or adds a package source")
    artifacts = report.get("artifacts")
    if not isinstance(artifacts, list):
        raise PackageCheckError("no-install preflight artifact inventory is missing")
    actual_artifact_keys: set[tuple[str, str, str, str, bool]] = set()
    for artifact in artifacts:
        if not isinstance(artifact, dict) or (artifact.get("package"), artifact.get("package_uuid")) not in source_ids:
            raise PackageCheckError("no-install preflight artifact is outside the reviewed package closure")
        artifact_path = Path(str(artifact.get("path", "")))
        tree_hash = str(artifact.get("git_tree_sha1", ""))
        content_hash = str(artifact.get("content_tree_sha256", ""))
        if artifact_path.is_symlink() or not artifact_path.is_dir() or \
           artifact_path.name != tree_hash or not re.fullmatch(r"[0-9a-f]{40}", tree_hash) or \
           artifact.get("observed_tree_sha1") != tree_hash or not re.fullmatch(r"[0-9a-f]{64}", content_hash):
            raise PackageCheckError(f"selected artifact path or tree is missing: {artifact.get('name')}")
        if _content_tree_sha256(artifact_path) != content_hash:
            raise PackageCheckError(f"selected artifact content hash differs: {artifact.get('name')}")
        if _git_tree_sha1(artifact_path) != tree_hash:
            raise PackageCheckError(f"selected artifact git tree differs: {artifact.get('name')}")
        key = (str(artifact.get("package")), str(artifact.get("package_uuid")),
               str(artifact.get("name")), tree_hash, bool(artifact.get("lazy", False)))
        if key in actual_artifact_keys:
            raise PackageCheckError(f"duplicate selected artifact record: {artifact.get('name')}")
        actual_artifact_keys.add(key)
    if actual_artifact_keys != expected_artifact_keys:
        raise PackageCheckError("selected artifact inventory is incomplete or contains unexpected artifacts")
    if not isinstance(report.get("preferences"), dict) or not isinstance(report.get("preference_files"), list):
        raise PackageCheckError("no-install preflight effective preference state is missing")
    override_files = report.get("artifact_override_files")
    if not isinstance(override_files, list):
        raise PackageCheckError("no-install preflight artifact override file inventory is missing")
    for override_file in override_files:
        if not isinstance(override_file, dict):
            raise PackageCheckError("no-install preflight artifact override file record is malformed")
        override_path = Path(str(override_file.get("path", "")))
        if override_file.get("present"):
            if override_path.is_symlink() or not override_path.is_file() or \
               sha256_file(override_path) != override_file.get("sha256"):
                raise PackageCheckError("artifact override file is missing or changed")
        elif override_path.exists():
            raise PackageCheckError("artifact override file appeared after preflight")
    raw_overrides = report.get("effective_artifact_overrides")
    if not isinstance(raw_overrides, dict) or any(not isinstance(value, dict) or value
                                                   for value in raw_overrides.values()):
        raise PackageCheckError("no-install preflight detected an effective artifact override")
    if report.get("artifact_override_environment") != {}:
        raise PackageCheckError("no-install preflight detected an artifact override environment variable")
    registries = report.get("registries")
    if not isinstance(registries, list) or not registries:
        raise PackageCheckError("no-install preflight reachable registry state is missing")
    tarball_mode = report.get("registry_tarball_mode")
    if not isinstance(tarball_mode, bool):
        raise PackageCheckError("no-install preflight registry loading mode is missing")
    expected_registry_paths = _registry_candidates(report["depot_path"], tarball_mode)
    reported_registry_paths = [str(item.get("registry_path", "")) for item in registries if isinstance(item, dict)]
    if len(reported_registry_paths) != len(registries) or len(set(reported_registry_paths)) != len(registries) or \
       set(reported_registry_paths) != expected_registry_paths:
        raise PackageCheckError("reachable registry inventory omits or duplicates a depot registry")
    for registry in registries:
        if not isinstance(registry, dict):
            raise PackageCheckError("no-install preflight registry record is malformed")
        registry_path = Path(str(registry.get("registry_path", "")))
        compressed = bool(registry.get("compressed"))
        descriptor = Path(str(registry.get("descriptor_path", "")))
        payload = Path(str(registry.get("payload_path", "")))
        if registry_path.resolve() != registry_path or registry_path.is_symlink() or \
           descriptor.is_symlink() or not descriptor.is_file() or payload.is_symlink() or \
           not (payload.is_file() or payload.is_dir()):
            raise PackageCheckError("reachable registry descriptor or payload is missing or unsafe")
        expected_descriptor = registry_path if compressed else registry_path / "Registry.toml"
        expected_payload = None
        if compressed:
            with descriptor.open("rb") as stream:
                descriptor_doc = tomllib.load(stream)
            relative_payload = descriptor_doc.get("path")
            if not isinstance(relative_payload, str):
                raise PackageCheckError("compressed registry descriptor lacks its payload path")
            expected_payload = (descriptor.parent / relative_payload).resolve()
        else:
            expected_payload = registry_path.resolve()
        if descriptor.resolve() != expected_descriptor.resolve() or payload.resolve() != expected_payload:
            raise PackageCheckError("reachable registry paths differ from the registry index")
        if sha256_file(descriptor) != registry.get("descriptor_sha256"):
            raise PackageCheckError("reachable registry descriptor content changed")
        try:
            with descriptor.open("rb") as stream:
                descriptor_doc = tomllib.load(stream)
        except (OSError, tomllib.TOMLDecodeError) as exc:
            raise PackageCheckError("reachable registry descriptor is invalid") from exc
        if compressed:
            tree_hash = descriptor_doc.get("git-tree-sha1")
            with tempfile.TemporaryDirectory(prefix="arc1-registry-verify-") as temp_dir:
                extracted_root = _safe_extract_registry_tarball(payload, Path(temp_dir) / "registry")
                observed_tree = _git_tree_sha1(extracted_root)
                registry_toml = extracted_root / "Registry.toml"
                with registry_toml.open("rb") as stream:
                    registry_doc = tomllib.load(stream)
                observed_payload_sha = sha256_file(payload)
        else:
            tree_info = registry_path / ".tree_info.toml"
            tree_hash = tomllib.loads(tree_info.read_text(encoding="utf-8")).get("git-tree-sha1") \
                if tree_info.is_file() else _git_tree_sha1(payload)
            observed_tree = _git_tree_sha1(payload)
            registry_doc_path = payload / "Registry.toml"
            with registry_doc_path.open("rb") as stream:
                registry_doc = tomllib.load(stream)
            observed_payload_sha = _content_tree_sha256(payload)
        if tree_hash != registry.get("git_tree_sha1") or observed_tree != registry.get("observed_tree_sha1") or \
           observed_tree != tree_hash or registry_doc.get("name") != registry.get("name") or \
           str(registry_doc.get("uuid")) != registry.get("uuid"):
            raise PackageCheckError("reachable registry tree or identity differs from its content")
        if observed_payload_sha != registry.get("payload_sha256"):
            raise PackageCheckError("reachable registry payload content changed")
    return report


def _self_test_toml(document: dict[str, Any]) -> str:
    lines: list[str] = []

    def atom(value: Any) -> str:
        if isinstance(value, str):
            return json.dumps(value)
        if value is True:
            return "true"
        if value is False:
            return "false"
        if isinstance(value, (int, float)):
            return str(value)
        if isinstance(value, list) and all(not isinstance(item, (dict, list)) for item in value):
            return "[" + ", ".join(atom(item) for item in value) + "]"
        raise TypeError(f"unsupported synthetic TOML value: {value!r}")

    def table(values: dict[str, Any], path: tuple[str, ...], *, header: bool) -> None:
        if header:
            lines.append("[" + ".".join(path) + "]")
        for key, value in values.items():
            if not isinstance(value, dict) and not (
                isinstance(value, list) and value and isinstance(value[0], dict)
            ):
                lines.append(f"{key} = {atom(value)}")
        for key, value in values.items():
            nested_path = path + (key,)
            if isinstance(value, dict):
                table(value, nested_path, header=True)
            elif isinstance(value, list) and value and isinstance(value[0], dict):
                for item in value:
                    lines.append("[[" + ".".join(nested_path) + "]]")
                    table(item, nested_path, header=False)

    table(document, (), header=False)
    return "\n".join(lines) + "\n"


def _self_test_julia_noinstall_preflight() -> None:
    with tempfile.TemporaryDirectory(prefix="arc1-noinstall-selftest-") as temporary:
        root = Path(temporary)
        sandbox = root / "sandbox"
        sandbox.mkdir()
        project = sandbox / "Project.toml"
        manifest = sandbox / "Manifest.toml"
        project.write_text('[extras]\nAqua = "4c88cf16-eb10-579e-8560-4a9242c79595"\n', encoding="utf-8")
        source = root / "source" / "Aqua"
        (source / "src").mkdir(parents=True)
        (source / "src" / "Aqua.jl").write_text("module Aqua end\n", encoding="utf-8")
        aqua_uuid = "4c88cf16-eb10-579e-8560-4a9242c79595"
        hsquared_uuid = "a0667dea-0f38-44e8-9150-4fda00624eac"
        duplicate_uuid = "11111111-2222-4333-8444-555555555555"
        (source / "Project.toml").write_text(
            f'name = "Aqua"\nuuid = "{aqua_uuid}"\nversion = "0.8.0"\n'
            '[deps]\nAbsentDuplicate = "' + duplicate_uuid + '"\n'
            '[weakdeps]\nAbsentDuplicate = "' + duplicate_uuid + '"\n', encoding="utf-8")
        hsquared_source = root / "source" / "HSquared"
        hsquared_source.mkdir()
        hsquared_project = hsquared_source / "Project.toml"
        hsquared_project.write_text(
            f'name = "HSquared"\nuuid = "{hsquared_uuid}"\nversion = "0.9.0"\n'
            '[weakdeps]\nAlgebraOfGraphics = "cbdf2221-f076-402e-a563-3d30da359d67"\n'
            'CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"\n'
            'Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"\n', encoding="utf-8")
        aqua_tree = _manifest_git_tree_sha1(source)
        coverage_artifact = source / "src" / "Aqua.jl.12345.cov"
        coverage_artifact.write_text("generated coverage data", encoding="utf-8")
        assert _manifest_git_tree_sha1(source) == aqua_tree
        original_module = (source / "src" / "Aqua.jl").read_text(encoding="utf-8")
        (source / "src" / "Aqua.jl").write_text("module Aqua; changed = true; end\n", encoding="utf-8")
        assert _manifest_git_tree_sha1(source) != aqua_tree
        (source / "src" / "Aqua.jl").write_text(original_module, encoding="utf-8")
        build_output_source = root / "source" / "Conda-like"
        (build_output_source / "src").mkdir(parents=True)
        (build_output_source / "deps").mkdir()
        (build_output_source / "Project.toml").write_text(
            'name = "CondaLike"\nuuid = "22222222-3333-4444-8555-666666666666"\n', encoding="utf-8")
        (build_output_source / "src" / "CondaLike.jl").write_text("module CondaLike end\n", encoding="utf-8")
        (build_output_source / "deps" / ".gitignore").write_text("deps.jl\n", encoding="utf-8")
        build_output_tree = _git_tree_sha1(build_output_source)
        content_before_build = _content_tree_sha256(build_output_source)
        generated_deps = build_output_source / "deps" / "deps.jl"
        generated_deps.write_text("const generated_build_output = true\n", encoding="utf-8")
        assert _manifest_git_tree_sha1(build_output_source, build_output_tree) == build_output_tree
        assert _manifest_git_tree_sha1(build_output_source, _git_tree_sha1(build_output_source)) == \
            _git_tree_sha1(build_output_source)
        assert _content_tree_sha256(build_output_source) != content_before_build
        external_deps = root / "external-deps-target"
        external_deps.mkdir()
        external_generated_file = external_deps / "deps.jl"
        external_generated_file.write_text("preserve external target\n", encoding="utf-8")
        unsafe_build_output_source = root / "unsafe-build-output-source"
        (unsafe_build_output_source / "src").mkdir(parents=True)
        (unsafe_build_output_source / "Project.toml").write_text(
            'name = "UnsafeBuildOutputLike"\nuuid = "33333333-4444-4555-8666-777777777777"\n',
            encoding="utf-8")
        (unsafe_build_output_source / "src" / "UnsafeBuildOutputLike.jl").write_text(
            "module UnsafeBuildOutputLike end\n", encoding="utf-8")
        (unsafe_build_output_source / "deps").symlink_to(external_deps, target_is_directory=True)
        try:
            _manifest_git_tree_sha1(unsafe_build_output_source, "0" * 40)
        except PackageCheckError as exc:
            assert "build-output directory" in str(exc)
        else:
            raise AssertionError("Manifest tree helper accepted a symlinked deps directory")
        assert external_generated_file.read_text(encoding="utf-8") == "preserve external target\n"
        hsquared_inventory = {"Project.toml": sha256_file(hsquared_project)}
        hsquared_snapshot, hsquared_content_hash = _frozen_source_snapshot(hsquared_source, hsquared_inventory)
        (hsquared_source / "run-evidence.log").write_text("mutable evidence", encoding="utf-8")
        assert _frozen_source_snapshot(hsquared_source, hsquared_inventory) == (hsquared_snapshot, hsquared_content_hash)
        manifest.write_text(
            'manifest_format = "2.0"\n'
            '[[deps.Aqua]]\n'
            f'git-tree-sha1 = "{aqua_tree}"\nuuid = "{aqua_uuid}"\nversion = "0.8.0"\n'
            '[[deps.HSquared]]\n'
            f'path = {json.dumps(str(hsquared_source))}\nuuid = "{hsquared_uuid}"\nversion = "0.9.0"\n',
            encoding="utf-8")
        artifact_source = root / "artifact-source"
        artifact_source.mkdir()
        (artifact_source / "payload.bin").write_bytes(b"fixture artifact")
        artifact_tree = _git_tree_sha1(artifact_source)
        (source / "Artifacts.toml").write_text(
            f'[fixture]\ngit-tree-sha1 = "{artifact_tree}"\nlazy = true\n'
            '[[fixture.download]]\nurl = "https://fixture.invalid/artifact.tar.gz"\n'
            f'sha256 = "{"a" * 64}"\n', encoding="utf-8")
        aqua_tree = _manifest_git_tree_sha1(source)
        manifest.write_text(
            'manifest_format = "2.0"\n'
            '[[deps.Aqua]]\n'
            f'git-tree-sha1 = "{aqua_tree}"\nuuid = "{aqua_uuid}"\nversion = "0.8.0"\n'
            '[[deps.HSquared]]\n'
            f'path = {json.dumps(str(hsquared_source))}\nuuid = "{hsquared_uuid}"\nversion = "0.9.0"\n',
            encoding="utf-8")
        artifact = root / "depot" / "artifacts" / artifact_tree
        artifact.parent.mkdir(parents=True)
        shutil.copytree(artifact_source, artifact)
        registry_dir = root / "depot" / "registries"
        registry_dir.mkdir(parents=True)
        registry_tree_dir = root / "registry-tree"
        registry_tree_dir.mkdir()
        registry_uuid = "23338594-aafe-5451-b93e-139f81909106"
        (registry_tree_dir / "Registry.toml").write_text(
            f'name = "General"\nuuid = "{registry_uuid}"\n[packages]\n', encoding="utf-8")
        registry_tree = _git_tree_sha1(registry_tree_dir)
        registry_payload = registry_dir / "Registry.tar.gz"
        with tarfile.open(registry_payload, "w:gz") as archive:
            archive.add(registry_tree_dir / "Registry.toml", arcname="Registry.toml")
        registry_descriptor = registry_dir / "General.toml"
        registry_descriptor.write_text(
            f'git-tree-sha1 = "{registry_tree}"\nuuid = "{registry_uuid}"\npath = "Registry.tar.gz"\n', encoding="utf-8")
        registry_tree_check = subprocess.run(
            [JULIA_BIN, "--startup-file=no", "--threads=1", "-e",
             "using Pkg, Tar; got=string(Tar.tree_hash(`$(Pkg.PlatformEngines.exe7z()) x $(ARGS[1]) -so`)); "
             "got == ARGS[2] || error(\"compressed registry tree mismatch: \" * got); "
             "println(\"ARC1_REGISTRY_TAR_HASH_PASS\")", "--", str(registry_payload), registry_tree],
            cwd=JULIA_ROOT, env={**os.environ, "OPENBLAS_NUM_THREADS": "1"},
            text=True, capture_output=True, timeout=90, check=False)
        if registry_tree_check.returncode != 0 or "ARC1_REGISTRY_TAR_HASH_PASS" not in registry_tree_check.stdout:
            raise AssertionError("Julia Pkg compressed registry tree hash check failed: " +
                                 registry_tree_check.stderr)
        source_content_hash = _content_tree_sha256(source)
        artifact_content_hash = _content_tree_sha256(artifact)
        host_identity = _probe_julia_host_identity(Path(JULIA_BIN), expected_version="1.10.0")
        pkg_platform = subprocess.run(
            [JULIA_BIN, "--startup-file=no", "--history-file=no", "--threads=1",
             "--project=@stdlib", "-e",
             "using Pkg; print(Pkg.BinaryPlatforms.triplet(Pkg.BinaryPlatforms.HostPlatform()))"],
            cwd=JULIA_ROOT, env={**os.environ, "JULIA_LOAD_PATH": "@stdlib",
                                 "OPENBLAS_NUM_THREADS": "1"},
            text=True, capture_output=True, timeout=90, check=False)
        if pkg_platform.returncode != 0 or host_identity["host_platform"] != pkg_platform.stdout.strip():
            raise AssertionError("exact-launcher host identity probe differs from Pkg's artifact platform")
        launcher = Path(JULIA_BIN).resolve()
        runtime_binary = Path(host_identity["julia_runtime_executable"])
        launcher_sha256 = sha256_file(launcher)
        runtime_sha256 = str(host_identity["julia_runtime_executable_sha256"])
        receipt_path = root / "preflight.toml"
        receipt = {
            "schema": "arc1-julia-noinstall-preflight-v1", "status": "passed",
            "created_at_utc": "2026-10-05T00:00:00Z", "canonical_sha256": "b" * 64,
            "freeze_sha256": "c" * 64, "runner_sha256": "d" * 64,
            "driver_sha256": "e" * 64, "julia_executable": str(launcher.resolve()),
            "julia_launcher_sha256": launcher_sha256,
            "julia_runtime_executable": str(runtime_binary.resolve()),
            "julia_runtime_executable_sha256": runtime_sha256,
            "julia_version": "1.10.0", "host_platform": host_identity["host_platform"],
            "host_platform_tags": host_identity["host_platform_tags"],
            "load_path": ["@", "@stdlib"], "depot_path": [str(root / "depot")],
            "sandbox": {"project_path": str(project.resolve()), "project_sha256": sha256_file(project),
                        "manifest_path": str(manifest.resolve()), "manifest_sha256": sha256_file(manifest)},
            "manifest_sources": [{"name": "Aqua", "uuid": aqua_uuid, "kind": "git-tree",
                "source_path": str(source), "project_path": str(source / "Project.toml"),
                "git_tree_sha1": aqua_tree, "content_tree_sha256": source_content_hash},
                {"name": "HSquared", "uuid": hsquared_uuid, "kind": "path-snapshot",
                 "source_path": str(hsquared_source), "project_path": str(hsquared_source / "Project.toml"),
                 "source_files": hsquared_snapshot, "content_tree_sha256": hsquared_content_hash}],
            "loaded_manifest_sources": [{"name": "Aqua", "uuid": aqua_uuid,
                "path": str((source / "src" / "Aqua.jl").resolve())}],
            "aqua": {"name": "Aqua", "uuid": aqua_uuid, "version": "0.8.0",
                     "source_path": str(source), "git_tree_sha1": aqua_tree},
            "dependency_closure": [
                {"name": "Aqua", "uuid": aqua_uuid, "kind": "git-tree",
                 "source_path": str(source), "project_path": str(source / "Project.toml"),
                 "git_tree_sha1": aqua_tree, "content_tree_sha256": source_content_hash},
                {"name": "HSquared", "uuid": hsquared_uuid, "kind": "path-snapshot",
                 "source_path": str(hsquared_source), "project_path": str(hsquared_source / "Project.toml"),
                 "source_files": hsquared_snapshot, "content_tree_sha256": hsquared_content_hash},
            ],
            "omitted_weak_dependencies": [{
                "owner": "Aqua", "owner_uuid": aqua_uuid,
                "name": "AbsentDuplicate", "uuid": duplicate_uuid}] + [
                {"owner": "HSquared", "owner_uuid": hsquared_uuid, "name": name, "uuid": uuid}
                for name, uuid in (("AlgebraOfGraphics", "cbdf2221-f076-402e-a563-3d30da359d67"),
                    ("CUDA", "052768ef-5323-5732-b1bb-66c8b64840ba"),
                    ("Makie", "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"))],
            "artifacts": [{"package": "Aqua", "package_uuid": aqua_uuid,
                "name": "fixture", "git_tree_sha1": artifact_tree, "observed_tree_sha1": artifact_tree,
                "path": str(artifact), "content_tree_sha256": artifact_content_hash, "lazy": True}],
            "artifact_sources": [{"package": "Aqua", "package_uuid": aqua_uuid,
                "metadata_file": str((source / "Artifacts.toml").resolve()),
                "metadata_sha256": sha256_file(source / "Artifacts.toml"),
                "selected": [{"name": "fixture", "git_tree_sha1": artifact_tree, "lazy": True}]}],
            "unresolved_artifact_selectors": [],
            "effective_artifact_overrides": {"UUID": {}, "hash": {}},
            "artifact_override_environment": {}, "artifact_override_files": [],
            "preferences": {}, "preference_files": [],
            "registry_tarball_mode": True,
            "registries": [{"name": "General", "uuid": registry_uuid,
                "registry_path": str(registry_descriptor.resolve()), "compressed": True,
                "descriptor_path": str(registry_descriptor), "descriptor_sha256": sha256_file(registry_descriptor),
                "payload_path": str(registry_payload), "payload_sha256": sha256_file(registry_payload),
                "git_tree_sha1": registry_tree, "observed_tree_sha1": registry_tree}],
        }
        expected = {"freeze_sha256": "c" * 64, "runner_sha256": "d" * 64,
                    "driver_sha256": "e" * 64,
                    "sandbox": receipt["sandbox"], "julia_executable": "/fixture/julia",
                    "julia_launcher_sha256": launcher_sha256,
                    "julia_runtime_executable": str(runtime_binary.resolve()),
                    "julia_runtime_executable_sha256": runtime_sha256,
                    "source_root": str(hsquared_source.resolve()), "source_files": hsquared_inventory,
                    "load_path": ["@", "@stdlib"], "depot_path": [str(root / "depot")],
                    "julia_version": "1.10.0", "host_identity": host_identity}
        expected["julia_executable"] = str(launcher.resolve())
        receipt_path.write_text(_self_test_toml(receipt), encoding="utf-8")
        raw_hash = sha256_file(receipt_path)

        def rejected(label: str, mutate: Any, error_fragment: str) -> None:
            candidate = json.loads(json.dumps(receipt))
            mutate(candidate)
            candidate_path = root / f"{label}.toml"
            candidate_path.write_text(_self_test_toml(candidate), encoding="utf-8")
            try:
                validate_noinstall_preflight_receipt(
                    candidate_path, sha256_file(candidate_path), expected)
            except PackageCheckError as exc:
                assert error_fragment in str(exc), (label, exc)
            else:
                raise AssertionError(f"preflight accepted adversary: {label}")

        validate_noinstall_preflight_receipt(receipt_path, raw_hash, expected)
        rejected("stale-loaded-source", lambda x: x["loaded_manifest_sources"][0].update(
            path=str((root / "stale" / "Aqua.jl").resolve())), "loaded manifest source differs")
        rejected("unexpected-weak", lambda x: x["dependency_closure"].append(
            {"name": "CUDA", "uuid": "cuda-uuid", "kind": "git-tree"}), "dependency closure")
        rejected("unexpected-selector", lambda x: x["unresolved_artifact_selectors"].append(
            {"package": "Aqua", "selector": "runtime_hook"}), "unresolved artifact selector")
        rejected("unexpected-override", lambda x: x["effective_artifact_overrides"]["hash"].update(
            {"a" * 40: "/tmp/override"}), "artifact override")
        rejected("missing-source", lambda x: x["manifest_sources"][0].update(
            source_path=str(root / "absent-source")), "manifest source path")
        rejected("missing-artifact", lambda x: x["artifacts"][0].update(
            path=str(root / "absent-artifact")), "selected artifact path")
        rejected("missing-selected-artifact", lambda x: x["artifacts"].clear(),
                 "selected artifact inventory")
        rejected("duplicate-selected-artifact", lambda x: x["artifacts"].append(
            dict(x["artifacts"][0])), "duplicate selected artifact")
        rejected("missing-artifact-source", lambda x: x["artifact_sources"].clear(),
                 "artifact metadata source is missing")
        rejected("missing-artifact-source-selection", lambda x: x["artifact_sources"][0]["selected"].clear(),
                 "selected artifact inventory differs from metadata")
        rejected("duplicate-artifact-source", lambda x: x["artifact_sources"].append(
            dict(x["artifact_sources"][0])), "duplicate or unreviewed package")
        rejected("missing-registry", lambda x: x["registries"].clear(),
                 "reachable registry state")
        rejected("duplicate-registry", lambda x: x["registries"].append(dict(x["registries"][0])),
                 "reachable registry inventory")
        rejected("wrong-registry-tree", lambda x: x["registries"][0].update(
            observed_tree_sha1="0" * 40), "reachable registry tree")
        rejected("wrong-launcher", lambda x: x.update(julia_executable=str(runtime_binary)),
                 "runtime or host identity")
        rejected("wrong-runtime-hash", lambda x: x.update(
            julia_runtime_executable_sha256="0" * 64), "actual Julia runtime executable")
        rejected("wrong-host-platform-tags", lambda x: x["host_platform_tags"].update(os="linux"),
                 "exact-launcher Base probe")
        rejected("wrong-host-platform-triplet", lambda x: x.update(host_platform="x86_64-linux-gnu"),
                 "exact-launcher Base probe")
        rejected("wrong-source-snapshot", lambda x: x["manifest_sources"][1]["source_files"][0].update(
            sha256="0" * 64), "source snapshot differs")
        rejected("tampered-source-inventory", lambda x: x["manifest_sources"][1].update(
            content_tree_sha256="0" * 64), "source snapshot differs")
        selector = hsquared_source / ".pkg" / "select_artifacts.jl"
        selector.parent.mkdir()
        selector.write_text("# unsupported dynamic selector\n", encoding="utf-8")
        try:
            rejected("julia-1.10-root-pkg-selector", lambda x: None,
                     "dynamic artifact selector")
        finally:
            selector.unlink()
            selector.parent.rmdir()
        higher_precedence = source / "JuliaArtifacts.toml"
        higher_precedence.write_text("fixture = []\n", encoding="utf-8")
        assert _artifact_metadata_path(source) == higher_precedence
        higher_precedence.unlink()
        selector_host = {"arch": "x86_64", "os": "linux", "libc": "glibc",
                         "libgfortran_version": "5.0.0", "os_version": "13.0",
                         "libstdcxx_version": "3.4.30"}
        plain_dict_selected = _select_artifacts_for_host({"fixture": {
            "arch": "aarch64", "git-tree-sha1": "a" * 40,
            "download": [{"url": "https://fixture.invalid/a", "sha256": "b" * 64}],
        }}, selector_host)
        assert plain_dict_selected == [{"name": "fixture", "git_tree_sha1": "a" * 40, "lazy": False}]
        exact_subset_selected = _select_artifacts_for_host({"fixture": [
            {"arch": "aarch64", "os": "macos", "libgfortran_version": "5.0.0",
             "git-tree-sha1": "c" * 40,
             "download": [{"url": "https://fixture.invalid/foreign", "sha256": "d" * 64}]},
            {"arch": "x86_64", "os": "linux", "libc": "glibc", "libgfortran_version": "5.0.0",
             "git-tree-sha1": "e" * 40,
             "download": [{"url": "https://fixture.invalid/current", "sha256": "f" * 64}]},
        ]}, selector_host)
        assert exact_subset_selected == [{"name": "fixture", "git_tree_sha1": "e" * 40, "lazy": False}]
        def selector_rejected(label: str, metadata: dict[str, Any], fragment: str) -> None:
            try:
                _select_artifacts_for_host(metadata, selector_host)
            except PackageCheckError as exc:
                assert fragment in str(exc), (label, exc)
            else:
                raise AssertionError(f"artifact selector parity accepted {label}")
        selector_rejected("missing host tag", {"fixture": [{
            "arch": "x86_64", "os": "linux", "libc": "glibc",
            "sanitize": "none", "git-tree-sha1": "a" * 40,
            "download": [{"url": "https://fixture.invalid/a", "sha256": "b" * 64}],
        }]}, "host platform lacks selector tag")
        selector_rejected("bounded version selector", {"fixture": [{
            "arch": "x86_64", "os": "linux", "libc": "glibc", "os_version": "13.0",
            "git-tree-sha1": "a" * 40,
            "download": [{"url": "https://fixture.invalid/a", "sha256": "b" * 64}],
        }]}, "comparator-based selector")
        selector_rejected("noncanonical arch alias", {"fixture": [{
            "arch": "amd64", "os": "linux", "libc": "glibc", "git-tree-sha1": "a" * 40,
            "download": [{"url": "https://fixture.invalid/a", "sha256": "b" * 64}],
        }]}, "noncanonical artifact arch selector")
        selector_rejected("uppercase libc", {"fixture": [{
            "arch": "x86_64", "os": "linux", "libc": "GLIBC", "git-tree-sha1": "a" * 40,
            "download": [{"url": "https://fixture.invalid/a", "sha256": "b" * 64}],
        }]}, "noncanonical selector value")
        selector_rejected("numeric extra selector", {"fixture": [{
            "arch": "x86_64", "os": "linux", "libc": "glibc", "sanitize": 1,
            "git-tree-sha1": "a" * 40,
            "download": [{"url": "https://fixture.invalid/a", "sha256": "b" * 64}],
        }]}, "selector value must be a canonical lowercase string")
        selector_rejected("missing required os selector", {"fixture": [{
            "arch": "x86_64", "libc": "glibc", "git-tree-sha1": "a" * 40,
            "download": [{"url": "https://fixture.invalid/a", "sha256": "b" * 64}],
        }]}, "array selector requires string arch and os")
        selector_rejected("leading-zero libgfortran version", {"fixture": [{
            "arch": "x86_64", "os": "linux", "libc": "glibc",
            "libgfortran_version": "05.0.0", "git-tree-sha1": "a" * 40,
            "download": [{"url": "https://fixture.invalid/a", "sha256": "b" * 64}],
        }]}, "noncanonical libgfortran version selector")
        selector_rejected("omitted normalized Linux libc", {"fixture": [{
            "arch": "x86_64", "os": "linux", "git-tree-sha1": "a" * 40,
            "download": [{"url": "https://fixture.invalid/a", "sha256": "b" * 64}],
        }]}, "Linux selector omits normalized libc")
        selector_rejected("matching variant tie", {"fixture": [
            {"arch": "x86_64", "os": "linux", "libc": "glibc",
             "git-tree-sha1": "a" * 40,
             "download": [{"url": "https://fixture.invalid/a", "sha256": "b" * 64}]},
            {"arch": "x86_64", "os": "linux", "libc": "glibc",
             "git-tree-sha1": "a" * 40,
             "download": [{"url": "https://fixture.invalid/b", "sha256": "c" * 64}]},
        ]}, "multiple host-matching variants")
        root_selector = source / "select_artifacts.jl"
        root_selector.write_text("# unsupported\n", encoding="utf-8")
        assert root_selector in _dynamic_artifact_selectors(source)
        root_selector.unlink()
        symlink_tree = root / "symlink-tree"
        symlink_tree.mkdir()
        (symlink_tree / "target.bin").write_bytes(b"target")
        (symlink_tree / "link.bin").symlink_to("target.bin")
        symlink_hash = _content_tree_sha256(symlink_tree)
        assert symlink_hash == hashlib.sha256((
            f"link.bin\0symlink\0target.bin\ntarget.bin\0file\0{sha256_file(symlink_tree / 'target.bin')}"
        ).encode("utf-8")).hexdigest()
        preflight = julia_noinstall_preflight_source(
            {"project_path": str(project), "manifest_path": str(manifest),
             "project_sha256": sha256_file(project), "manifest_sha256": sha256_file(manifest)},
            root / "capture", "c" * 64, expected_julia_executable=launcher,
            expected_julia_version="1.10.0", source_file_inventory=hsquared_inventory)
        content_start = preflight.index("function pf_content_tree(path)")
        content_end = preflight.index("\nfunction pf_source_snapshot(root)", content_start)
        julia_tree_source = "using SHA\npf_sha(path) = bytes2hex(sha256(read(path)))\n" + \
            preflight[content_start:content_end] + "\nprintln(pf_content_tree(ARGS[1]))\n"
        julia_tree = subprocess.run(
            [JULIA_BIN, "--startup-file=no", "--threads=1", "-e", julia_tree_source, "--", str(symlink_tree)],
            cwd=JULIA_ROOT, env={**os.environ, "OPENBLAS_NUM_THREADS": "1"},
            text=True, capture_output=True, timeout=90, check=False)
        if julia_tree.returncode != 0 or julia_tree.stdout.strip() != symlink_hash:
            raise AssertionError("Julia/Python symlink-aware content tree hashes differ: " + julia_tree.stderr)
        (symlink_tree / "broken.bin").symlink_to("missing.bin")
        try:
            _content_tree_sha256(symlink_tree)
        except PackageCheckError as exc:
            assert "broken symlink" in str(exc)
        else:
            raise AssertionError("content tree accepted a broken symlink")
        (symlink_tree / "broken.bin").unlink()
        outside = root / "outside.bin"
        outside.write_bytes(b"outside")
        (symlink_tree / "escape.bin").symlink_to(outside)
        try:
            _content_tree_sha256(symlink_tree)
        except PackageCheckError as exc:
            assert "escaping symlink" in str(exc)
        else:
            raise AssertionError("content tree accepted an escaping symlink")
        receipt_path.write_text(receipt_path.read_text(encoding="utf-8") + "# tampered\n",
                                encoding="utf-8")
        try:
            validate_noinstall_preflight_receipt(receipt_path, raw_hash, expected)
        except PackageCheckError as exc:
            assert "receipt SHA-256" in str(exc)
        else:
            raise AssertionError("preflight accepted a tampered retained receipt")
        driver = julia_test_driver_source(expected["sandbox"], root / "capture")
        assert "Pkg.dependencies()" in driver
        source_locator_start = driver.index("function pf_manifest_source_path(")
        source_locator_end = driver.index("\nfunction pf_manifest_kind", source_locator_start)
        source_locator = driver[source_locator_start:source_locator_end]
        package_tree_start = driver.index("function pf_manifest_package_tree(")
        package_tree_end = driver.index("\nfunction pf_manifest_source(", package_tree_start)
        package_tree_helper = driver[package_tree_start:package_tree_end]
        source_fixture = root / "unloaded-transitive" / "src"
        source_fixture.mkdir(parents=True)
        source_file = source_fixture / "UnloadedTransitive.jl"
        source_file.write_text("module UnloadedTransitive end\n", encoding="utf-8")
        missing_root = root / "missing-depot-source"
        missing_root.mkdir()
        missing_uuid = "11111111-2222-4333-8444-555555555555"
        (missing_root / "Project.toml").write_text(
            f'name = "UnloadedTransitive"\nuuid = "{missing_uuid}"\nversion = "0.1.0"\n',
            encoding="utf-8")
        fallback_depot = root / "fallback-depot"
        fallback_root = fallback_depot / "packages" / "UnloadedTransitive" / "fixture-slug"
        (fallback_root / "src").mkdir(parents=True)
        (fallback_root / "Project.toml").write_text(
            f'name = "UnloadedTransitive"\nuuid = "{missing_uuid}"\nversion = "0.1.0"\n',
            encoding="utf-8")
        (fallback_root / "deps").mkdir()
        (fallback_root / "deps" / ".gitignore").write_text("deps.jl\n", encoding="utf-8")
        fallback_file = fallback_root / "src" / "UnloadedTransitive.jl"
        fallback_file.write_text("module UnloadedTransitive end\n", encoding="utf-8")
        fallback_tree = _git_tree_sha1(fallback_root)
        (fallback_root / "deps" / "deps.jl").write_text("const generated_build_output = true\n", encoding="utf-8")
        assert _manifest_git_tree_sha1(fallback_root, fallback_tree) == fallback_tree
        slug_result = subprocess.run(
            [JULIA_BIN, "--startup-file=no", "--history-file=no", "--threads=1", "--project=@stdlib", "-e",
             'using UUIDs; print(Base.version_slug(UUID(ARGS[1]), Base.SHA1(ARGS[2])))',
             "--", missing_uuid, fallback_tree],
            cwd=JULIA_ROOT, env={**os.environ, "OPENBLAS_NUM_THREADS": "1"},
            text=True, capture_output=True, timeout=90, check=False)
        if slug_result.returncode != 0 or not re.fullmatch(r"[A-Za-z0-9]{5}", slug_result.stdout.strip()):
            raise AssertionError("Julia package slug fixture failed: " + slug_result.stderr)
        fallback_root.rename(fallback_root.parent / slug_result.stdout.strip())
        fallback_root = fallback_root.parent / slug_result.stdout.strip()
        fallback_file = fallback_root / "src" / "UnloadedTransitive.jl"
        external_deps = root / "external-build-output-target"
        external_deps.mkdir()
        external_generated = external_deps / "deps.jl"
        external_generated.write_text("preserve external target", encoding="utf-8")
        unsafe_root = root / "unsafe-generated-deps-parent"
        (unsafe_root / "src").mkdir(parents=True)
        (unsafe_root / "Project.toml").write_text(
            f'name = "UnsafeGeneratedDepsParent"\nuuid = "33333333-4444-4555-8666-777777777777"\n',
            encoding="utf-8")
        (unsafe_root / "src" / "UnsafeGeneratedDepsParent.jl").write_text(
            "module UnsafeGeneratedDepsParent end\n", encoding="utf-8")
        (unsafe_root / "deps").symlink_to(external_deps, target_is_directory=True)
        stale_depot = root / "stale-depot"
        stale_slug = stale_depot / "packages" / "UnloadedTransitive" / fallback_root.name
        stale_slug.mkdir(parents=True)
        (stale_slug / "Project.toml").write_text(
            f'name = "UnloadedTransitive"\nuuid = "{missing_uuid}"\nversion = "0.1.0"\n',
            encoding="utf-8")
        (stale_slug / "src").mkdir()
        stale_root = root / "stale-loaded-source"
        (stale_root / "src").mkdir(parents=True)
        (stale_root / "Project.toml").write_text(
            f'name = "UnloadedTransitive"\nuuid = "{missing_uuid}"\nversion = "0.1.0"\n',
            encoding="utf-8")
        (stale_root / "src" / "UnloadedTransitive.jl").write_text(
            "module UnloadedTransitive end\n", encoding="utf-8")
        loaded_env = root / "loaded-package-env"
        loaded_env.mkdir()
        (loaded_env / "Project.toml").write_text(
            'name = "LoadedPathFixture"\nuuid = "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee"\n'
            f'[deps]\nUnloadedTransitive = "{missing_uuid}"\n', encoding="utf-8")
        (loaded_env / "Manifest.toml").write_text(
            'manifest_format = "2.0"\n[[deps.UnloadedTransitive]]\n'
            f'git-tree-sha1 = "{fallback_tree}"\nuuid = "{missing_uuid}"\nversion = "0.1.0"\n',
            encoding="utf-8")
        overlay_root = root / "source-validated-overlay"
        overlay_records = prepare_manifest_depot_overlay(
            [loaded_env / "Manifest.toml"], [stale_depot, fallback_depot], overlay_root)
        assert len(overlay_records) == 1 and overlay_records[0]["source_path"] == str(fallback_root.resolve())
        source_script = (
            "using Pkg, UUIDs, TOML\n" + source_locator + "\n"
            "pf_tree(path) = bytes2hex(Pkg.GitTools.tree_hash(path))\n"
            + package_tree_helper + "\n"
            + f'pf_manifest_package_tree({_julia_string(fallback_root)}, "{fallback_tree}") == "{fallback_tree}" || error("Julia package-tree identity did not exclude generated deps.jl")\n'
            + f'unsafe_root={_julia_string(unsafe_root)}\n'
            + 'unsafe_deps_rejected=try; pf_manifest_package_tree(unsafe_root,"0000000000000000000000000000000000000000"); false; catch; true; end\n'
            + 'unsafe_deps_rejected || error("Julia package-tree helper accepted a symlinked deps directory")\n'
            + f'isfile({_julia_string(external_generated)}) || error("Julia package-tree helper removed an external generated file")\n'
            + 'uuid=UUID("11111111-2222-4333-8444-555555555555")\n'
            + f'source={_julia_string(source_fixture.parent)}\n'
            + 'Base.locate_package(Base.PkgId(uuid,"UnloadedTransitive")) === nothing || error("fixture unexpectedly loadable")\n'
            + 'resolved=pf_manifest_source_path("UnloadedTransitive",string(uuid),Dict(uuid=>(source=source,)))\n'
            + f'resolved == {_julia_string(source_file)} || error("Pkg dependency source was not resolved: " * repr(resolved))\n'
            + f'missing_source={_julia_string(missing_root)}\n'
            + f'fallback_depot={_julia_string(fallback_depot)}\n'
            + f'fallback_root={_julia_string(fallback_root)}\n'
            + f'overlay_root={_julia_string(overlay_root)}\n'
            + f'expected_tree="{fallback_tree}"\n'
            + f'write(joinpath({_julia_string(fallback_root)}, "src", "UnloadedTransitive.jl.12345.cov"), "generated coverage")\n'
            + 'fallback=pf_manifest_source_path("UnloadedTransitive",string(uuid),Dict(uuid=>(source=missing_source,)); expected_tree=expected_tree, depots=[fallback_depot])\n'
            + f'fallback == {_julia_string(fallback_file)} || error("matching depot source was not resolved: " * repr(fallback))\n'
            + f'pf_validate_loaded_source_path("UnloadedTransitive",string(uuid),fallback,{_julia_string(fallback_root)}) == realpath({_julia_string(fallback_file)}) || error("validated loaded source path changed")\n'
            + f'pushfirst!(DEPOT_PATH,overlay_root)\n'
            + f'pushfirst!(LOAD_PATH,{_julia_string(loaded_env)})\n'
            + 'loaded_module=Base.require(Base.PkgId(uuid,"UnloadedTransitive")); loaded_path=pathof(loaded_module)\n'
            + f'realpath(loaded_path) == realpath({_julia_string(fallback_file)}) || error("overlay did not load the validated second-depot module: " * repr(loaded_path))\n'
            + 'loaded_records=try; pf_loaded_manifest_sources([Dict("name"=>"UnloadedTransitive","uuid"=>string(uuid),"source_path"=>fallback_root)]); false; catch; true; end\n'
            + 'loaded_records && error("loaded module from validated overlay was rejected")\n'
            + f'stale_root={_julia_string(stale_root)}\n'
            + 'stale_failed=try; pf_validate_loaded_source_path("UnloadedTransitive",string(uuid),joinpath(stale_root,"src","UnloadedTransitive.jl"),fallback_root); false; catch; true; end\n'
            + 'stale_failed || error("stale first-depot loaded source was accepted")\n'
            + 'println("ARC1_UNLOADED_MANIFEST_SOURCE_PASS")\n')
        source_script_path = root / "unloaded-manifest-source.jl"
        source_script_path.write_text(source_script, encoding="utf-8")
        source_result = subprocess.run(
            [JULIA_BIN, "--startup-file=no", "--history-file=no", "--threads=1",
             "--project=@stdlib", str(source_script_path)],
            cwd=JULIA_ROOT, env={**os.environ, "OPENBLAS_NUM_THREADS": "1",
                                 "JULIA_DEPOT_PATH": os.pathsep.join(
                                     (str(stale_depot), str(fallback_depot), str(root / "julia-depot")))},
            text=True, capture_output=True, timeout=90, check=False)
        if source_result.returncode != 0 or "ARC1_UNLOADED_MANIFEST_SOURCE_PASS" not in source_result.stdout:
            raise AssertionError("unloaded manifest package source fixture failed: " + source_result.stderr)
        assert 'hsquared_module = Base.require(Base.PkgId' in driver
        assert 'pathof(hsquared_module)' in driver
        assert 'hsquared = Base.require(Base.PkgId' not in driver
        duplicate_project = root / "duplicate-strong-weak" / "Project.toml"
        duplicate_project.parent.mkdir()
        duplicate_uuid = "11111111-2222-4333-8444-555555555555"
        duplicate_project.write_text(
            f'name = "DuplicateStrongWeakFixture"\nuuid = "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee"\n'
            '[deps]\nAbsentDuplicate = "' + duplicate_uuid + '"\n'
            '[weakdeps]\nAbsentDuplicate = "' + duplicate_uuid + '"\n', encoding="utf-8")
        duplicate_manifest = duplicate_project.parent / "Manifest.toml"
        duplicate_manifest.write_text('manifest_format = "2.0"\n[deps]\n', encoding="utf-8")
        normalized_probe = subprocess.run(
            [JULIA_BIN, "--startup-file=no", "--history-file=no", "--threads=1", "--project=@stdlib",
             "-e", "using Pkg, TOML; function probe(); raw=TOML.parsefile(ARGS[1]); manifest=TOML.parsefile(ARGS[2]); "
             "raw_failed=false; try; for name in keys(raw[\"deps\"]); "
             "haskey(get(manifest, \"deps\", Dict()), name) || error(\"raw strong dependency absent from manifest\"); "
             "end; catch e; raw_failed=occursin(\"raw strong dependency absent from manifest\", sprint(showerror,e)); end; "
             "raw_failed || error(\"raw dependency traversal unexpectedly passed\"); "
             "println(\"ARC1_RAW_DUPLICATE_DEP_RED_EXPECTED\"); "
             "p=Pkg.Types.read_project(ARGS[1]); "
             "haskey(p.deps, \"AbsentDuplicate\") && error(\"duplicate weak dep retained as strong\"); "
             "for name in keys(p.deps); haskey(get(manifest, \"deps\", Dict()), name) || error(\"normalized strong dependency absent from manifest\"); end; "
             "string(p.weakdeps[\"AbsentDuplicate\"]) == ARGS[3] || error(\"normalized weak dep missing\"); "
             "println(\"ARC1_NORMALIZED_DUPLICATE_DEP_PASS\"); end; probe()", str(duplicate_project),
             str(duplicate_manifest), duplicate_uuid],
            cwd=JULIA_ROOT, env={**os.environ, "OPENBLAS_NUM_THREADS": "1"},
            text=True, capture_output=True, timeout=90, check=False)
        if normalized_probe.returncode != 0 or \
           "ARC1_RAW_DUPLICATE_DEP_RED_EXPECTED" not in normalized_probe.stdout or \
           "ARC1_NORMALIZED_DUPLICATE_DEP_PASS" not in normalized_probe.stdout:
            raise AssertionError("Julia Pkg duplicate strong/weak normalization probe failed: " + normalized_probe.stderr)
        closure_start = driver.index("function pf_closure(by_id, stdlib_ids)")
        closure_end = driver.index("\nfunction pf_artifact_metadata_file(root)", closure_start)
        closure_source = driver[closure_start:closure_end]
        source_locator_start = driver.index("function pf_manifest_source_path(")
        source_locator_end = driver.index("\nfunction pf_manifest_kind", source_locator_start)
        source_locator = driver[source_locator_start:source_locator_end]
        walk_root = root / "generated-dependency-walk"
        walk_env = walk_root / "env"
        walk_env.mkdir(parents=True)
        walk_aqua = walk_root / "Aqua"
        walk_hsquared = walk_root / "HSquared"
        for package_root in (walk_aqua, walk_hsquared):
            (package_root / "src").mkdir(parents=True)
        walk_aqua_uuid = "4c88cf16-eb10-579e-8560-4a9242c79595"
        walk_hsquared_uuid = "a0667dea-0f38-44e8-9150-4fda00624eac"
        walk_transitive_uuid = "11111111-2222-4333-8444-555555555556"
        walk_duplicate_uuid = "11111111-2222-4333-8444-555555555555"
        (walk_aqua / "Project.toml").write_text(
            f'name = "Aqua"\nuuid = "{walk_aqua_uuid}"\nversion = "0.8.0"\n'
            '[deps]\nUnloadedTransitive = "' + walk_transitive_uuid + '"\n'
            '[weakdeps]\nAbsentDuplicate = "' + walk_duplicate_uuid + '"\n', encoding="utf-8")
        (walk_hsquared / "Project.toml").write_text(
            f'name = "HSquared"\nuuid = "{walk_hsquared_uuid}"\nversion = "0.9.0"\n'
            '[weakdeps]\n'
            'AlgebraOfGraphics = "cbdf2221-f076-402e-a563-3d30da359d67"\n'
            'CUDA = "052768ef-5323-5732-b1bb-66c8b64840ba"\n'
            'Makie = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"\n', encoding="utf-8")
        walk_transitive = walk_root / "UnloadedTransitive"
        (walk_transitive / "src").mkdir(parents=True)
        (walk_transitive / "Project.toml").write_text(
            f'name = "UnloadedTransitive"\nuuid = "{walk_transitive_uuid}"\nversion = "0.1.0"\n',
            encoding="utf-8")
        (walk_transitive / "src" / "UnloadedTransitive.jl").write_text(
            "module UnloadedTransitive end\n", encoding="utf-8")
        walk_incomplete = walk_root / "incomplete-depot-copy"
        walk_incomplete.mkdir()
        (walk_incomplete / "Project.toml").write_text(
            f'name = "UnloadedTransitive"\nuuid = "{walk_transitive_uuid}"\nversion = "0.1.0"\n',
            encoding="utf-8")
        (walk_aqua / "src" / "Aqua.jl").write_text("module Aqua end\n", encoding="utf-8")
        (walk_hsquared / "src" / "HSquared.jl").write_text("module HSquared end\n", encoding="utf-8")
        (walk_env / "Project.toml").write_text(
            'name = "GeneratedWalkFixture"\nuuid = "aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee"\n'
            '[deps]\nAqua = "' + walk_aqua_uuid + '"\nHSquared = "' + walk_hsquared_uuid + '"\n',
            encoding="utf-8")
        (walk_env / "Manifest.toml").write_text(
            'manifest_format = "2.0"\n'
            '[[deps.Aqua]]\npath = ' + json.dumps(str(walk_aqua)) +
            '\nuuid = "' + walk_aqua_uuid + '"\nversion = "0.8.0"\n'
            '[[deps.HSquared]]\npath = ' + json.dumps(str(walk_hsquared)) +
            '\nuuid = "' + walk_hsquared_uuid + '"\nversion = "0.9.0"\n', encoding="utf-8")
        walk_script = (
            "using Pkg, TOML, UUIDs\n"
            "const PF_EXPECTED_WEAKDEPS = Set([\"AlgebraOfGraphics\", \"CUDA\", \"Makie\"])\n"
            + f'const PF_PACKAGE_DEPENDENCIES = Dict(UUID("{walk_transitive_uuid}")=>(source=ARGS[5],))\n'
            "pf_uuid(value) = string(UUID(string(value)))\n"
            + source_locator + "\n" + closure_source + "\n"
            + "aqua = Dict{String,Any}(\"name\"=>\"Aqua\",\"uuid\"=>ARGS[1],\"project_path\"=>ARGS[3])\n"
            + "hsq = Dict{String,Any}(\"name\"=>\"HSquared\",\"uuid\"=>ARGS[2],\"project_path\"=>ARGS[4])\n"
            + "transitive = Dict{String,Any}(\"name\"=>\"UnloadedTransitive\",\"uuid\"=>\"" + walk_transitive_uuid + "\",\"project_path\"=>ARGS[6])\n"
            + "records = Dict((\"Aqua\",ARGS[1])=>aqua,(\"HSquared\",ARGS[2])=>hsq,(\"UnloadedTransitive\",transitive[\"uuid\"])=>transitive)\n"
            + "closure,omitted,_,_=pf_closure(records,Dict{String,String}())\n"
            + "only(filter(x->x[\"name\"]==\"AbsentDuplicate\",omitted)); "
            + "length(closure)==3 || error(\"unexpected generated dependency closure\")\n"
            + "println(\"ARC1_GENERATED_DEPENDENCY_WALK_PASS\")\n")
        walk_script_path = walk_root / "generated_walk.jl"
        walk_script_path.write_text(walk_script, encoding="utf-8")
        walk_result = subprocess.run(
            [JULIA_BIN, "--startup-file=no", "--history-file=no", "--threads=1",
             f"--project={walk_env}", str(walk_script_path), walk_aqua_uuid, walk_hsquared_uuid,
             str(walk_aqua / "Project.toml"), str(walk_hsquared / "Project.toml"),
             str(walk_incomplete), str(walk_transitive / "Project.toml")],
            cwd=JULIA_ROOT, env={**os.environ, "JULIA_LOAD_PATH": "@:@stdlib", "OPENBLAS_NUM_THREADS": "1"},
            text=True, capture_output=True, timeout=90, check=False)
        if walk_result.returncode != 0 or "ARC1_GENERATED_DEPENDENCY_WALK_PASS" not in walk_result.stdout:
            raise AssertionError("generated dependency walk fixture failed: " + walk_result.stderr)
        assert 'Pkg.Types.read_project(record["project_path"])' in closure_source
        assert 'getproperty(project, Symbol(section))' in closure_source and '("deps", false), ("weakdeps", true)' in closure_source
        assert "TOML.parsefile(record[\"project_path\"])" not in closure_source
        before_call = driver.index("preflight_before = arc1_noinstall_preflight()")
        load_package = driver.index("Base.require(Base.PkgId")
        include_tests = driver.index("include(ARC1_TEST_FILE)")
        after_call = driver.index("preflight_after = arc1_noinstall_preflight()")
        assert before_call < load_package < include_tests < after_call
        assert driver.count("const ARC1_PREFLIGHT_BEFORE_PATH =") == 1
        assert driver.count("const ARC1_PREFLIGHT_AFTER_PATH =") == 1
        assert "arc1_write_preflight(ARC1_PREFLIGHT_BEFORE_PATH" in driver
        assert "arc1_write_preflight(ARC1_PREFLIGHT_AFTER_PATH" in driver
        assert 'key not in {"created_at_utc", "canonical_sha256", "loaded_manifest_sources"}' in inspect.getsource(PackageRun.run_julia)
        assert "realpath(Base.julia_cmd().exec[1]) == realpath(PF_JULIA_EXECUTABLE)" not in driver
        assert "const PF_JULIA_LAUNCHER_SHA256 =" in driver
        assert '"julia_runtime_executable" => runtime_executable' in driver
        # Julia stdlib UUIDs can also have a registry/tree-pinned Manifest
        # entry. Exercise the generated classification rule independently of
        # the host's installed package set.
        kind_start = driver.index("function pf_manifest_kind(uuid, entry, stdlib_ids)")
        kind_end = driver.index("\nfunction pf_manifest_source", kind_start)
        kind_source = driver[kind_start:kind_end]
        kind_script = (
            "using UUIDs\n"
            + kind_source + "\n"
            + 'ids=Dict("8bb1440f-4735-579b-a4ab-409b98df4dab"=>"DelimitedFiles")\n'
            + 'pinned=Dict("git-tree-sha1"=>"9e2f36d000000000000000000000000000000000")\n'
            + 'pf_manifest_kind("8bb1440f-4735-579b-a4ab-409b98df4dab",pinned,ids)=="git-tree" || error("tree-pinned stdlib misclassified")\n'
            + 'pf_manifest_kind("8bb1440f-4735-579b-a4ab-409b98df4dab",Dict{String,Any}(),ids)=="stdlib" || error("unhashed stdlib misclassified")\n'
            + 'pf_manifest_kind("8bb1440f-4735-579b-a4ab-409b98df4dab",Dict("path"=>"local"),ids)=="path" || error("path stdlib misclassified")\n'
            + 'println("ARC1_STDLIB_MANIFEST_KIND_PASS")\n')
        kind_script_path = root / "manifest-kind.jl"
        kind_script_path.write_text(kind_script, encoding="utf-8")
        kind_result = subprocess.run(
            [JULIA_BIN, "--startup-file=no", "--history-file=no", "--threads=1", "--project=@stdlib", str(kind_script_path)],
            cwd=JULIA_ROOT, env={**os.environ, "OPENBLAS_NUM_THREADS": "1"},
            text=True, capture_output=True, timeout=90, check=False)
        if kind_result.returncode != 0 or "ARC1_STDLIB_MANIFEST_KIND_PASS" not in kind_result.stdout:
            raise AssertionError("stdlib manifest-kind regression failed: " + kind_result.stderr)
        driver_path = root / "julia-test-driver.jl"
        driver_path.write_text(driver, encoding="utf-8")
        parse = subprocess.run(
            [JULIA_BIN, "--startup-file=no", "--threads=1", "-e",
             "Meta.parseall(read(ARGS[1], String)); println(\"ARC1_DRIVER_PARSE_PASS\")", str(driver_path)],
            cwd=JULIA_ROOT, env={**os.environ, "OPENBLAS_NUM_THREADS": "1"},
            text=True, capture_output=True, timeout=90, check=False)
        if parse.returncode != 0 or "ARC1_DRIVER_PARSE_PASS" not in parse.stdout:
            raise AssertionError(f"generated Julia driver did not parse: {parse.stdout}\n{parse.stderr}")


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


def _self_test_profile_environment_overrides() -> None:
    """Inherited skip switches must lose to each G7 Julia/R command environment."""
    inherited_names = ("ARC1_SKIP_EXPENSIVE_PROFILE_WRAPPER", "ARC1_PROFILE_V3_ONLY")
    prior = {name: os.environ.get(name) for name in inherited_names}
    try:
        for name in inherited_names:
            os.environ[name] = "1"
        julia_overrides = _julia_env()
        effective_julia = os.environ.copy()
        effective_julia.update(julia_overrides)
        assert all(julia_overrides[name] == "0" for name in inherited_names)
        assert all(effective_julia[name] == "0" for name in inherited_names)
        _, command_env = _julia_command(Path("/tmp/arc1-env-self-test/julia-test-driver.jl"), {
            "project_path": "/tmp/arc1-reviewed-sandbox/Project.toml",
            "manifest_path": "/tmp/arc1-reviewed-sandbox/Manifest.toml",
            "project_sha256": "a" * 64, "manifest_sha256": "b" * 64,
        })
        assert all(command_env[name] == "0" for name in inherited_names)
        assert command_env["JULIA_LOAD_PATH"] == "@:@stdlib"
        r_overrides = _r_env(Path("/tmp/arc1-env-self-test"), Path("/tmp/arc1-bootstrap-self-test"))
        assert all(r_overrides[name] == "0" for name in inherited_names)
    finally:
        for name, value in prior.items():
            if value is None:
                os.environ.pop(name, None)
            else:
                os.environ[name] = value


def _self_test_profile_test_suite_guard() -> None:
    env = {
        "ARC1_SKIP_EXPENSIVE_PROFILE_WRAPPER": "0",
        "ARC1_PROFILE_V3_ONLY": "0",
    }
    full_suite = '''
if get(ENV, "ARC1_SKIP_EXPENSIVE_PROFILE_WRAPPER", "0") != "1"
if get(ENV, "ARC1_PROFILE_V3_ONLY", "0") != "1"
all-five Arc1 profile wrapper reports one shared point maximum
'''
    assert _profile_test_suite_enabled(env, full_suite)
    assert not _profile_test_suite_enabled(env, full_suite.replace('!= "1"', '== "1"'))
    assert not _profile_test_suite_enabled({**env, "ARC1_PROFILE_V3_ONLY": "1"}, full_suite)
    assert not _profile_test_suite_enabled(env, full_suite.replace("all-five", "one-five"))


def _self_test() -> None:
    _self_test_julia_noinstall_preflight()
    assert sha256_file(Path(__file__)) == hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    assert RUN_TIMEOUT_S["julia"] == 2400
    assert RUN_TIMEOUT_S["r"] >= 7200
    _self_test_profile_environment_overrides()
    _self_test_profile_test_suite_guard()
    with tempfile.TemporaryDirectory(prefix="arc1-package-root-selftest-") as temp:
        selected_root = Path(temp, "selected-r-root").resolve()
        env = os.environ.copy()
        env["HSQUARED_ARC1_R_ROOT"] = str(selected_root)
        probe = r"""
import sys
from pathlib import Path
sys.path.insert(0, sys.argv[1])
import arc1_package_checks as package, arc1_oracles as oracle
expected = Path(sys.argv[2])
assert package.R_ROOT == expected and oracle.R_ROOT == expected
assert package.freeze_roots()['r'] == oracle.freeze_roots()['r'] == str(expected)
receipt = expected.parent / 'synthetic-review-receipt.txt'
receipt.write_text('reviewed')
doc = {'schema': package.SCHEMA,
       'review': {'status': 'reviewed', 'reviewer': 'self-test', 'reviewed_at_utc': 'test',
                  'review_receipt_path': str(receipt), 'review_receipt_sha256': 'a' * 64},
       'roots': package.freeze_roots()}
try:
    package.validate_freeze(doc, package.freeze_roots(), {})
except package.PackageCheckError as exc:
    assert 'freeze roots' not in str(exc) and 'freeze files' in str(exc)
else:
    raise AssertionError('incomplete synthetic freeze unexpectedly passed')
doc['roots']['r'] = str(expected.parent / 'wrong-r-root')
try:
    package.validate_freeze(doc, package.freeze_roots(), {})
except package.PackageCheckError as exc:
    assert 'freeze roots must exactly equal' in str(exc)
else:
    raise AssertionError('package freeze accepted the wrong R root')
"""
        result = subprocess.run([sys.executable, "-c", probe, str(RUNNER.parent), str(selected_root)],
                                env=env, capture_output=True, text=True, check=False)
        if result.returncode != 0:
            raise AssertionError(f"synthetic package-runner R-root override was not shared: {result.stderr}")
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
        wrong_root_freeze = json.loads(json.dumps(freeze))
        wrong_root_freeze["roots"]["r"] = str(root / "different-r-root")
        try:
            validate_freeze(wrong_root_freeze, freeze["roots"], inventory)
        except PackageCheckError as exc:
            assert "freeze roots must exactly equal" in str(exc)
        else:
            raise AssertionError("package freeze accepted an R root different from the selected root")
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

        def synthetic_package_run(label: str) -> PackageRun:
            run_dir = root / label
            run_dir.mkdir()
            run = PackageRun.__new__(PackageRun)
            run.out = run_dir
            run.meta = {"commands": []}
            run.file_map = None
            run.julia_call_bootstrap = None
            run.julia_call_bootstrap_dir = None
            return run

        def command_record(label: str, argv: list[str], timeout: float) -> dict[str, Any]:
            run = synthetic_package_run(label)
            try:
                run.run_command(label, argv, root, {}, timeout, marker="SYNTHETIC_PASS")
            except (PackageCheckError, RunInterrupted):
                pass
            else:
                raise AssertionError(f"synthetic {label} command unexpectedly passed")
            return run.meta["commands"][0]

        descendant_output = root / "package-descendant-output.log"
        descendant_code = (
            "import pathlib,time; f=pathlib.Path(" + repr(str(descendant_output)) + ").open('a')\n"
            "while True:\n f.write('x\\n'); f.flush(); time.sleep(0.02)"
        )
        parent_code = (
            "import subprocess,sys,time; subprocess.Popen([sys.executable, '-c', sys.argv[1]]); "
            "time.sleep(0.1); print('SYNTHETIC_PASS')"
        )
        leaked_parent = command_record("parent-first-leak",
                                       [sys.executable, "-c", parent_code, descendant_code], 3)
        assert leaked_parent["process_status"] == 0 and leaked_parent["process_group_leak"]
        assert leaked_parent["cleanup"] in ("terminated", "killed")
        assert leaked_parent["log_sealed"] and leaked_parent["log_sha256"]
        sealed_log = root / "parent-first-leak" / leaked_parent["log"]
        sealed_hash = sha256_file(sealed_log)
        time.sleep(0.15)
        assert sha256_file(sealed_log) == sealed_hash

        timeout_record = command_record("timeout", [sys.executable, "-c", "import time; time.sleep(5)"], 0.1)
        assert timeout_record["timed_out"] and timeout_record["log_sealed"]
        assert timeout_record["cleanup"] in ("terminated", "killed") and timeout_record["log_sha256"]

        real_popen = subprocess.Popen
        def interrupting_popen(*args: Any, **kwargs: Any) -> subprocess.Popen[Any]:
            process = real_popen(*args, **kwargs)
            real_wait = process.wait
            first_wait = True
            def wait_once(*wait_args: Any, **wait_kwargs: Any) -> int:
                nonlocal first_wait
                if first_wait:
                    first_wait = False
                    raise RunInterrupted("synthetic interruption")
                return real_wait(*wait_args, **wait_kwargs)
            process.wait = wait_once  # type: ignore[method-assign]
            return process
        subprocess.Popen = interrupting_popen
        try:
            interrupt_record = command_record("interrupted", [sys.executable, "-c", "import time; time.sleep(5)"], 3)
        finally:
            subprocess.Popen = real_popen
        assert interrupt_record["interrupted"] and interrupt_record["log_sealed"]
        assert interrupt_record["cleanup"] in ("terminated", "killed") and interrupt_record["log_sha256"]

        real_terminate = _oracle.terminate_group
        _oracle.terminate_group = lambda _proc: "group-still-alive"
        try:
            unresolved_record = command_record("unresolved-group", [sys.executable, "-c", "print('SYNTHETIC_PASS')"], 3)
        finally:
            _oracle.terminate_group = real_terminate
        assert not unresolved_record["log_sealed"] and unresolved_record["log_sha256"] is None

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
        sandbox_spec = {
            "project_path": str(sandbox_project), "manifest_path": str(sandbox_manifest),
            "project_sha256": sha256_file(sandbox_project),
            "manifest_sha256": sha256_file(sandbox_manifest),
        }
        capture_dir = root / "direct-test-capture"
        driver_path = root / "julia-test-driver.jl"
        driver_source = julia_test_driver_source(sandbox_spec, capture_dir)
        assert "Pkg.test" not in driver_source and "Pkg.resolve" not in driver_source
        assert "ARC1_LOADED_HSQUARED_SOURCE_VERIFIED" in driver_source
        assert "include(ARC1_TEST_FILE)" in driver_source
        argv, driver_env = _julia_command(driver_path, sandbox_spec)
        assert "--startup-file=no" in argv and "--check-bounds=yes" in argv and "--threads=1" in argv
        assert f"--project={sandbox_root.resolve()}" in argv and argv[-1] == str(driver_path.resolve())
        assert "Pkg.test" not in "\n".join(argv)
        assert driver_env["JULIA_LOAD_PATH"] == "@:@stdlib"
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
    print("synthetic_cases=pass,nonzero,missing_marker,timeout,interrupt,input_mutation,bootstrap_mutation,julia_summary,empty_summary,broken_summary,docs_env_rebase,frozen_sandbox_command,no_pkg_resolution,source_identity_markers,frontend_missing_pin,frontend_version_drift,frontend_tree_copy,frontend_symlink_escape,blank_base_redirects,missing_dev_redirect,valid_dev_redirects,manual_docs_argv_cwd,html_required_before_pass_marker,run_failure_propagation,node_resource_caps,parent_first_log_sealing,timeout_receipt_sealing,interrupt_receipt_sealing,unresolved_group_fail_closed")
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
