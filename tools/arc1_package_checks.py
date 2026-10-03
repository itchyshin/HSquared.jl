#!/usr/bin/env python3
"""Run source-frozen Arc1 G7 package checks without a publish-capable path.

Real checks require an independently reviewed external JSON freeze and an
explicit gate selection. The runner has a fixed command allowlist and no
freeze-generation mode. ``--self-test`` uses synthetic files and disposable
Python/Julia child processes; it never launches project tests or docs builds.

Freeze format: ``hsquared-arc1-package-freeze-v1`` with an independent review
record, exact Julia/R roots and runtime pins, and ``files`` maps whose keys
must equal the complete inventories discovered under the fixed source trees.
The runner has no candidate-freeze generation mode.

Required JSON fields are ``review: {status: "reviewed", reviewer,
reviewed_at_utc, review_receipt_path, review_receipt_sha256}``, ``roots:
{julia: JULIA_ROOT, r: R_ROOT}``, ``runtime: {julia, julia_executable,
rscript, rscript_executable}``, and ``files: {julia: {relative_path: sha256},
r: {relative_path: sha256}}``. The review receipt must be an existing external
file whose bytes match its digest. Runtime strings are exact output from the
fixed version commands; executable paths are resolved paths.
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
SCHEMA = "hsquared-arc1-package-freeze-v1"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")

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


def validate_freeze(doc: Any, expected_roots: dict[str, str], file_map: dict[str, dict[str, Path]]) -> None:
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


def _r_env(run_dir: Path) -> dict[str, str]:
    env = _julia_env()
    env.update({
        "PATH": R_PATH,
        "HSQUARED_JULIA_PROJECT": str(JULIA_ROOT),
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
        return [RSCRIPT_BIN, "--vanilla", "--version"]
    raise PackageCheckError(f"unsupported version check: {name}")


def _julia_command() -> tuple[list[str], dict[str, str]]:
    driver = (
        'using LinearAlgebra; BLAS.set_num_threads(1); using Pkg; '
        'Pkg.test(allow_reresolve=false); println("ARC1_PACKAGE_JULIA_COMPONENT_PASS")'
    )
    return ([JULIA_BIN, "--startup-file=no", "--project=.", "-e", driver], _julia_env())


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


def _r_check_command(run_dir: Path) -> tuple[list[str], dict[str, str]]:
    driver_path = run_dir / "r-package-check-driver.R"
    driver_path.write_text(R_PACKAGE_DRIVER, encoding="utf-8")
    return ([RSCRIPT_BIN, "--vanilla", str(driver_path)], _r_env(run_dir))


def _r_live_command(run_dir: Path) -> tuple[list[str], dict[str, str]]:
    driver_path = run_dir / "r-arc1-live-driver.R"
    driver_path.write_text(_oracle.R_DRIVER, encoding="utf-8")
    return ([RSCRIPT_BIN, "--vanilla", str(driver_path)], _r_env(run_dir))


def _julia_string(path: Path) -> str:
    # JSON basic strings use the quoting/escapes accepted by Julia string literals.
    return json.dumps(str(path.resolve()), ensure_ascii=False)


def make_local_docs_script(source: str, *, repo: Path, scratch_docs: Path, output_docs: Path) -> str:
    """Transform only the frozen make script's fixed setup, helpers, and deploy tail."""
    start = "using Pkg\n\nPkg.develop(PackageSpec(path = joinpath(@__DIR__, \"..\")))\nPkg.instantiate()\n\n"
    if source.count(start) != 1:
        raise PackageCheckError("docs/make.jl setup block differs from the reviewed transformation")
    source = source.replace(start, "", 1)
    package_import = "using DocumenterVitepress\nusing HSquared\n"
    package_assertion = (
        "using DocumenterVitepress\nusing HSquared\n"
        f"@assert realpath(pathof(HSquared)) == realpath({_julia_string(repo / 'src' / 'HSquared.jl')}) "
        "\"docs environment loaded HSquared outside the frozen Julia source root\"\n"
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
    redirect = (
        'include(joinpath(@__DIR__, "legacy_reference_redirect.jl"))\n'
        "write_legacy_dev_reference_redirect!(@__DIR__)"
    )
    scratch_redirect = (
        f"include({_julia_string(repo / 'docs' / 'legacy_reference_redirect.jl')})\n"
        f"write_legacy_dev_reference_redirect!({_julia_string(output_docs)})"
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


def _docs_command(run_dir: Path) -> tuple[list[str], dict[str, str]]:
    scratch_docs = run_dir / "scratch-docs"
    scratch_docs.mkdir()
    shutil.copytree(JULIA_ROOT / "docs" / "src", scratch_docs / "src")
    docs_environment = prepare_docs_environment(run_dir)
    output_docs = scratch_docs
    make_source = (JULIA_ROOT / "docs" / "make.jl").read_text(encoding="utf-8")
    transformed = make_local_docs_script(
        make_source, repo=JULIA_ROOT, scratch_docs=scratch_docs, output_docs=output_docs
    )
    script = run_dir / "local-docs-make.jl"
    script.write_text(transformed, encoding="utf-8")
    return ([JULIA_BIN, "--startup-file=no", f"--project={docs_environment}", str(script)], _julia_env())


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
        validate_freeze(doc, {"julia": str(JULIA_ROOT), "r": str(R_ROOT)}, self.file_map)
        self.review_receipt_path = Path(doc["review"]["review_receipt_path"])
        if self.review_receipt_path.is_symlink() or not self.review_receipt_path.is_file() or \
           self.review_receipt_path.is_relative_to(EVIDENCE_ROOT):
            raise PackageCheckError("review receipt must be an existing external nonsymlink file")
        self.review_receipt_hash = sha256_file(self.review_receipt_path)
        if self.review_receipt_hash != doc["review"]["review_receipt_sha256"]:
            raise PackageCheckError("independent review receipt SHA-256 does not match the freeze")
        self.expected = doc["files"]
        self.meta.update({"freeze_path": str(self.freeze_path), "freeze_sha256": self.freeze_hash,
                          "review": doc["review"], "review_receipt_sha256": self.review_receipt_hash,
                          "runtime_expected": doc["runtime"],
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
        record: dict[str, Any] = {
            "name": name, "component": component, "argv": argv, "cwd": str(cwd), "env_overrides": env_overrides,
            "timeout_s": timeout, "log": log_path.name, "started_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
            "process_status": None, "timed_out": False, "interrupted": False,
            "cleanup": None, "before_sha256": before,
        }
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
            raise PackageCheckError(f"{name} changed a frozen input: {record['after_hash_error']}")
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
        argv, env = _julia_command()
        profile_test_source = (JULIA_ROOT / "test" / "arc1_profiles.jl").read_text(encoding="utf-8")
        if env.get("ARC1_SKIP_EXPENSIVE_PROFILE_WRAPPER") != "0" or \
           'if get(ENV, "ARC1_SKIP_EXPENSIVE_PROFILE_WRAPPER", "0") != "1"' not in profile_test_source or \
           'all-five Arc1 profile wrapper reports one shared point maximum' not in profile_test_source:
            raise PackageCheckError("Arc1 all-five profile wrapper is not proven enabled by the frozen test source")
        record = self.run_command("julia-pkg-test", argv, JULIA_ROOT, env, RUN_TIMEOUT_S["julia"],
                                  marker="ARC1_PACKAGE_JULIA_COMPONENT_PASS", component="julia")
        test_output = (self.out / record["log"]).read_text(encoding="utf-8", errors="replace")
        test_summary = parse_julia_test_output(test_output)
        self.meta["julia_test_summary"] = test_summary
        self.meta.setdefault("component_receipts", {})["julia"] = {
            "status": "passed", "log": record["log"], "log_sha256": record["log_sha256"],
            "test_summary": test_summary, "elapsed_s": record["elapsed_s"],
        }
        self.meta["passed_components"].append("julia")
        self.save()

    def run_r(self) -> None:
        live_argv, live_env = _r_live_command(self.out)
        live_record = self.run_command("r-arc1-mandatory-live", live_argv, R_ROOT, live_env,
                                       RUN_TIMEOUT_S["r"], marker="ARC1_TESTTHAT_COUNTS", component="r")
        # The shared R driver returns nonzero for empty, failed, error, or skipped
        # Arc1 test files, so its zero exit plus retained tables is required.
        for path in (self.out / "arc1-live-results.rds", self.out / "arc1-live-results.csv"):
            if not path.is_file() or path.stat().st_size == 0:
                raise PackageCheckError(f"mandatory-live R driver did not retain {path.name}")
        check_argv, check_env = _r_check_command(self.out)
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
        argv, env = _docs_command(self.out)
        docs_environment = self.out / "docs-environment"
        self.meta["docs_environment_sha256"] = {
            "Project.toml": sha256_file(docs_environment / "Project.toml"),
            "Manifest.toml": sha256_file(docs_environment / "Manifest.toml"),
        }
        self.run_command("julia-local-docs", argv, JULIA_ROOT, env,
                         RUN_TIMEOUT_S["docs"], marker="ARC1_PACKAGE_DOCS_COMPONENT_PASS", component="docs")
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
        redirects = list(output_build.rglob("reference.html")) + list(output_build.rglob("reference/index.html"))
        if not redirects or not all("Moved to" in p.read_text(errors="replace") for p in redirects):
            raise PackageCheckError("legacy redirect helper did not retain expected redirect output")
        scratch_status = self.out / "scratch-docs" / "src" / "validation-status.md"
        scratch_text = scratch_status.read_text(encoding="utf-8")
        if "<!-- BEGIN GENERATED validation-status-table -->" not in scratch_text or \
           "<!-- END GENERATED validation-status-table -->" not in scratch_text:
            raise PackageCheckError("scratch validation status output lacks its generated table markers")
        rendered_status = list(output_build.rglob("validation-status.html"))
        if not rendered_status:
            raise PackageCheckError("Documenter output did not render validation-status.html")
        rendered_text = rendered_status[0].read_text(encoding="utf-8", errors="replace")
        if "Validation Status" not in rendered_text:
            raise PackageCheckError("rendered validation-status page lacks its expected heading")
        self.meta["docs_source_status_sha256"] = source_page_before
        self.meta["docs_scratch_status_sha256"] = sha256_file(scratch_status)
        self.meta["docs_rendered_status_pages"] = [
            {"path": str(p.relative_to(output_build)), "sha256": sha256_file(p)} for p in rendered_status
        ]
        self.meta["docs_preexisting_build_hash"] = build_before
        self.meta["docs_output_tree_hash"] = tree_hash(output_build)
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
    finally:
        EVIDENCE_ROOT = original_evidence_root
        build_file_map = original_builder


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
        }
        validate_freeze(freeze, freeze["roots"], inventory)
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
             'using Test; @testset "Arc1 synthetic parser" begin @test true end'],
            cwd=root, env={**os.environ, **_julia_env()},
            capture_output=True, text=True, timeout=20, check=False,
        )
        assert julia_probe.returncode == 0
        parse_julia_test_output(julia_probe.stdout, required_arc1_testsets=())
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
        docs_argv, _ = _docs_command(command_root)
        assert docs_argv[0] == JULIA_BIN and docs_argv[1] == "--startup-file=no"
        assert docs_argv[2].startswith("--project=")
        assert str(command_root / "docs-environment") == docs_argv[2].removeprefix("--project=")
        assert "--project=docs" not in docs_argv
        transformed = make_local_docs_script(
            docs_source, repo=JULIA_ROOT, scratch_docs=root / "docs-scratch", output_docs=root / "docs-output"
        )
        assert "DocumenterVitepress.deploydocs" not in transformed
        assert "Pkg.develop" not in transformed and "Pkg.instantiate" not in transformed
        assert "write_validation_status_table!(" in transformed
        assert "write_legacy_dev_reference_redirect!(" in transformed
        assert "pathof(HSquared)" in transformed
        assert str(JULIA_ROOT / "src" / "HSquared.jl") in transformed
        command_source = Path(docs_argv[-1]).read_text(encoding="utf-8")
        assert "DocumenterVitepress.deploydocs" not in command_source
        assert "pathof(HSquared)" in command_source
        assert str(root / "docs-scratch" / "src") in transformed
        assert f"root = {_julia_string(root / 'docs-scratch')}" in transformed
        assert 'source = "src"' in transformed and 'build = "build"' in transformed
        assert f"write_legacy_dev_reference_redirect!({_julia_string(root / 'docs-output')})" in transformed
    print("synthetic_cases=pass,nonzero,missing_marker,timeout,interrupt,input_mutation,julia_summary,empty_summary,broken_summary,docs_env_rebase")
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
