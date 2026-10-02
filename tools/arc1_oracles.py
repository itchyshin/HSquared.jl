#!/usr/bin/env python3
"""Fail-closed runner for the Arc1 G1 components and G6 live R/Julia checks.

Actual runs require an externally reviewed JSON passed with --freeze. This tool
has no freeze-generation mode and accepts no arbitrary shell command. The JSON
schema is documented in FREEZE_SCHEMA below. --self-test launches Julia and R
only against disposable synthetic test fixtures; it never runs project tests.

FREEZE_SCHEMA = {
  "schema": "hsquared-arc1-oracle-freeze-v1",
  "review": {"status": "reviewed", "reviewer": "...", "reviewed_at_utc": "..."},
  "roots": {"julia": "<exact Julia root>", "r": "<exact R root>"},
  "runtime": {"julia": "<exact output of julia --startup-file=no --version>",
              "rscript": "<exact output of Rscript --vanilla --version>"},
  "files": {"julia": {"Project.toml": "<sha256>", "src/...": "<sha256>", ...},
            "r": {"DESCRIPTION": "<sha256>", "R/...": "<sha256>", ...}}
}
The file maps must equal the complete required paths below, with lowercase SHA-256.
"""

from __future__ import annotations

import argparse
import csv as csv_module
import datetime as dt
import hashlib
import json
import os
from pathlib import Path
import re
import signal
import shutil
import subprocess
import sys
import tempfile
import time
import uuid
from typing import Any

RUNNER = Path(__file__).resolve()
JULIA_ROOT = RUNNER.parents[1].resolve()
R_ROOT = Path("/private/tmp/hsquared-auto-fa-r-20261001").resolve()
RUNS_ROOT = JULIA_ROOT / ".unlazy" / "arc1-gaussian-reliability" / "oracles" / "runs"
JULIA_DEPOT = "/private/tmp/hsquared-arc1-bootstrap-depot:/Users/z3437171/.julia"
JULIA_THREADS = "4"
BLAS_THREADS = "1"
PROFILE_WRAPPER = "0"
JULIA_TIMEOUT_S = 300
R_TIMEOUT_S = 360
VERSION_TIMEOUT_S = 20
GATE_TIMEOUT_S = {"g1": 300, "g6": 360}
SCHEMA = "hsquared-arc1-oracle-freeze-v1"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")

JULIA_TESTS = (
    "test/arc1_exact_objectives.jl",
    "test/arc1_optimizer_contracts.jl",
    "test/arc1_profiles.jl",
    "test/arc1_bootstrap.jl",
    "test/arc1_interfaces.jl",
    "test/arc1_simulation_dgp.jl",
    "test/arc1_simulation_reference.jl",
    "test/arc1_simulation_executor.jl",
)
JULIA_SIM_SOURCES = (
    # Every source file in this directory is part of the transitive runner
    # surface; reference/executor include helpers such as engine_io.jl.
)
R_ARC1_TESTS = (
    "tests/testthat/test-arc1-controls.R",
    "tests/testthat/test-arc1-live-parity.R",
    "tests/testthat/test-arc1-uncertainty-controls.R",
    "tests/testthat/test-arc1-uncertainty-live.R",
)


class OracleError(RuntimeError):
    pass


class RunnerInterrupted(KeyboardInterrupt):
    pass


ACTIVE_PROCESS: subprocess.Popen[Any] | None = None


def handle_signal(signum: int, _frame: Any) -> None:
    if ACTIVE_PROCESS is not None:
        terminate_group(ACTIVE_PROCESS)
    raise RunnerInterrupted(f"received signal {signum}")


R_DRIVER = r'''suppressPackageStartupMessages(library(testthat))
pkg <- Sys.getenv("ARC1_ORACLE_PACKAGE_ROOT")
if (!nzchar(pkg)) pkg <- "/private/tmp/hsquared-auto-fa-r-20261001"
expected <- c("test-arc1-controls.R", "test-arc1-live-parity.R",
              "test-arc1-uncertainty-controls.R", "test-arc1-uncertainty-live.R")
selected <- sort(basename(testthat::find_test_scripts(file.path(pkg, "tests", "testthat"), filter = "arc1-", full.names = TRUE)))
if (!identical(selected, sort(expected))) stop("Arc1 test selection mismatch: ", paste(selected, collapse = ", "))
reporter_list <- testthat::ListReporter$new()
reporter_summary <- testthat::SummaryReporter$new(show_praise = FALSE)
reporter <- testthat::MultiReporter$new(list(reporter_list, reporter_summary))
run_error <- NULL
tryCatch(devtools::test(pkg = pkg, filter = "arc1-", stop_on_failure = TRUE, reporter = reporter),
         error = function(e) { run_error <<- conditionMessage(e) })
records <- unclass(reporter_list$get_results())
is_class <- function(x, pattern) inherits(x, pattern) || any(grepl(pattern, class(x), fixed = TRUE))
by_file <- setNames(lapply(expected, function(x) list(assertions = 0L, successes = 0L,
  failures = 0L, errors = 0L, skips = 0L, warnings = 0L)), expected)
for (record in records) {
  file <- if (is.null(record$file)) "" else basename(record$file)
  if (!file %in% expected) next
  nested <- record$results
  by_file[[file]]$assertions <- by_file[[file]]$assertions + length(nested)
  by_file[[file]]$successes <- by_file[[file]]$successes + sum(vapply(nested, is_class, logical(1), pattern = "expectation_success"))
  by_file[[file]]$failures <- by_file[[file]]$failures + sum(vapply(nested, is_class, logical(1), pattern = "expectation_failure"))
  by_file[[file]]$errors <- by_file[[file]]$errors + sum(vapply(nested, is_class, logical(1), pattern = "expectation_error"))
  by_file[[file]]$skips <- by_file[[file]]$skips + sum(vapply(nested, is_class, logical(1), pattern = "expectation_skip"))
  by_file[[file]]$warnings <- by_file[[file]]$warnings + sum(vapply(nested, is_class, logical(1), pattern = "expectation_warning"))
}
counts <- list(files = by_file, error = run_error)
saveRDS(list(records = records, counts = counts), Sys.getenv("ARC1_ORACLE_RESULTS_RDS"))
flat <- do.call(rbind, lapply(names(by_file), function(f) data.frame(file = f, as.data.frame(by_file[[f]]))))
write.csv(flat, Sys.getenv("ARC1_ORACLE_RESULTS_CSV"), row.names = FALSE)
cat("ARC1_TESTTHAT_COUNTS ", paste(vapply(names(by_file), function(f)
  paste(f, paste(unlist(by_file[[f]]), collapse = "/"), sep = "="), character(1)), collapse = " "),
  "\n", sep = "")
if (!is.null(run_error)) cat("ARC1_TESTTHAT_ERROR ", run_error, "\n", sep = "")
bad_file <- any(vapply(by_file, function(x) x$assertions == 0 || x$successes == 0 ||
  x$failures > 0 || x$errors > 0 || x$skips > 0, logical(1)))
bad <- bad_file || !is.null(run_error)
if (bad) quit(status = 1L)
'''


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def file_map() -> dict[str, tuple[Path, list[str]]]:
    julia_src = sorted((JULIA_ROOT / "src").rglob("*.jl"))
    julia_sim = sorted((JULIA_ROOT / "sim" / "arc1").rglob("*.jl"))
    julia_paths = [p.relative_to(JULIA_ROOT).as_posix() for p in julia_src]
    julia_paths += [p.relative_to(JULIA_ROOT).as_posix() for p in julia_sim]
    julia_paths += ["Project.toml", "Manifest.toml", *JULIA_TESTS]

    test_root = R_ROOT / "tests" / "testthat"
    r_src = sorted((R_ROOT / "R").rglob("*.R"))
    r_tests = sorted(test_root.glob("test-arc1-*.R"))
    r_helpers = sorted(test_root.glob("helper*.R"))
    r_fixtures = sorted(p for p in (test_root / "fixtures").rglob("*") if p.is_file())
    r_paths = [p.relative_to(R_ROOT).as_posix() for p in r_src + r_tests + r_helpers + r_fixtures]
    r_paths += ["DESCRIPTION", "NAMESPACE", "tests/testthat.R"]
    groups = {"julia": (JULIA_ROOT, sorted(set(julia_paths))),
              "r": (R_ROOT, sorted(set(r_paths)))}
    for group, (root, paths) in groups.items():
        for rel in paths:
            path = root / rel
            if path.is_symlink() or not path.is_file():
                raise OracleError(f"missing or non-regular required {group} input: {rel}")
    expected_tests = sorted(R_ARC1_TESTS)
    actual_tests = sorted(p.relative_to(R_ROOT).as_posix() for p in r_tests)
    if actual_tests != expected_tests:
        raise OracleError(f"R Arc1 test selection changed: expected {expected_tests}, found {actual_tests}")
    return groups


def snapshot(groups: dict[str, tuple[Path, list[str]]]) -> dict[str, dict[str, str]]:
    return {group: {rel: sha256_file(root / rel) for rel in paths}
            for group, (root, paths) in groups.items()}


def validate_freeze(doc: Any, groups: dict[str, tuple[Path, list[str]]]) -> None:
    if not isinstance(doc, dict) or doc.get("schema") != SCHEMA:
        raise OracleError(f"freeze schema must be {SCHEMA!r}")
    review = doc.get("review")
    if not isinstance(review, dict) or review.get("status") != "reviewed":
        raise OracleError("freeze requires external review metadata with status='reviewed'")
    if any(not isinstance(review.get(k), str) or not review[k].strip()
           for k in ("reviewer", "reviewed_at_utc")):
        raise OracleError("freeze review metadata needs reviewer and reviewed_at_utc")
    roots = {"julia": str(JULIA_ROOT), "r": str(R_ROOT)}
    if doc.get("roots") != roots:
        raise OracleError(f"freeze roots must exactly equal {roots!r}")
    runtime = doc.get("runtime")
    if not isinstance(runtime, dict) or set(runtime) != {"julia", "rscript"}:
        raise OracleError("freeze runtime must contain exactly julia and rscript")
    if any(not isinstance(v, str) or not v.strip() for v in runtime.values()):
        raise OracleError("freeze runtime version strings must be nonempty")
    frozen = doc.get("files")
    if not isinstance(frozen, dict) or set(frozen) != set(groups):
        raise OracleError("freeze files must contain exactly julia and r maps")
    for group, (_, paths) in groups.items():
        values = frozen[group]
        if not isinstance(values, dict) or set(values) != set(paths):
            raise OracleError(f"freeze {group} paths do not exactly match the required input set")
        if any(not isinstance(v, str) or not SHA256_RE.fullmatch(v) for v in values.values()):
            raise OracleError(f"freeze {group} contains a malformed SHA-256 value")


def compare_hashes(actual: dict[str, dict[str, str]], expected: dict[str, dict[str, str]]) -> None:
    differences = []
    for group in sorted(set(actual) | set(expected)):
        a, e = actual.get(group, {}), expected.get(group, {})
        for rel in sorted(set(a) | set(e)):
            if a.get(rel) != e.get(rel):
                differences.append(f"{group}:{rel} expected={e.get(rel)} actual={a.get(rel)}")
    if differences:
        raise OracleError("frozen input mismatch: " + "; ".join(differences[:12]))


def compare_path_sets(actual: dict[str, tuple[Path, list[str]]],
                      expected: dict[str, tuple[Path, list[str]]]) -> None:
    if {k: set(v[1]) for k, v in actual.items()} != {k: set(v[1]) for k, v in expected.items()}:
        raise OracleError("required input path set changed during run")


def julia_argv(test_file: str) -> list[str]:
    if test_file not in JULIA_TESTS:
        raise OracleError(f"Julia test is not allowlisted: {test_file}")
    return julia_driver_argv((JULIA_ROOT / test_file).resolve())


def julia_driver_argv(test_path: Path) -> list[str]:
    wrapper = (
        "using Test; "
        "f=ARGS[1]; "
        "ts=@testset \"Arc1 oracle: $(basename(f))\" begin include(f) end; "
        "c=Test.get_test_counts(ts); "
        "println(\"ARC1_TEST_COUNTS passes=\",c[1]+c[5],\" failures=\",c[2]+c[6],"
        "\" errors=\",c[3]+c[7],\" broken=\",c[4]+c[8]); "
        "(c[1]+c[5] > 0 && c[2]+c[6] == 0 && c[3]+c[7] == 0 && c[4]+c[8] == 0) || exit(1)"
    )
    return ["julia", "--startup-file=no", "--project=.", "-e", wrapper, str(test_path)]


def julia_env() -> dict[str, str]:
    return {"JULIA_DEPOT_PATH": JULIA_DEPOT, "JULIA_NUM_THREADS": JULIA_THREADS,
            "OPENBLAS_NUM_THREADS": BLAS_THREADS,
            "ARC1_SKIP_EXPENSIVE_PROFILE_WRAPPER": PROFILE_WRAPPER}


def terminate_group(proc: subprocess.Popen[Any]) -> str:
    if proc.poll() is not None:
        return "already-exited"
    try:
        os.killpg(proc.pid, signal.SIGTERM)
        proc.wait(timeout=10)
        return "terminated"
    except subprocess.TimeoutExpired:
        try:
            os.killpg(proc.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        proc.wait()
        return "killed"
    except ProcessLookupError:
        proc.wait()
        return "already-exited"


class Runner:
    def __init__(self, gate: str, freeze_path: Path):
        self.gate = gate
        self.freeze_path = freeze_path
        self.groups = file_map()
        stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
        self.out = RUNS_ROOT / f"{stamp}-{uuid.uuid4().hex[:12]}"
        self.out.mkdir(parents=True, exist_ok=False)
        self.start = time.monotonic()
        self.freeze_hash: str | None = None
        self.expected: dict[str, dict[str, str]] | None = None
        self.runner_hash = sha256_file(RUNNER)
        self.meta: dict[str, Any] = {
            "schema": "hsquared-arc1-oracle-run-v1", "gate": gate,
            "runner_sha256": self.runner_hash,
            "run_id": self.out.name, "status": "running",
            "started_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
            "julia_root": str(JULIA_ROOT), "r_root": str(R_ROOT),
            "freeze_path": str(freeze_path), "commands": [], "freeze_checks": []}

    def save(self) -> None:
        (self.out / "run.json").write_text(json.dumps(self.meta, indent=2, sort_keys=True) + "\n")

    def load_freeze(self) -> dict[str, Any]:
        if not self.freeze_path.is_absolute() or self.freeze_path.is_symlink() or not self.freeze_path.is_file():
            raise OracleError("--freeze must be an existing absolute nonsymlink JSON file")
        raw = self.freeze_path.read_bytes()
        self.freeze_hash = hashlib.sha256(raw).hexdigest()
        try:
            doc = json.loads(raw)
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise OracleError(f"external freeze JSON is invalid: {exc}") from exc
        validate_freeze(doc, self.groups)
        self.expected = doc["files"]
        self.meta.update({"freeze_sha256": self.freeze_hash, "review": doc["review"],
                          "runtime_expected": doc["runtime"],
                          "required_file_counts": {k: len(v[1]) for k, v in self.groups.items()}})
        self.verify("initial")
        return doc

    def verify(self, label: str) -> dict[str, dict[str, str]]:
        if sha256_file(RUNNER) != self.runner_hash:
            raise OracleError("runner source changed during the run")
        if self.expected is None or self.freeze_hash is None:
            raise OracleError("freeze was not loaded")
        if sha256_file(self.freeze_path) != self.freeze_hash:
            raise OracleError("external freeze JSON changed during run")
        current_groups = file_map()
        compare_path_sets(current_groups, self.groups)
        actual = snapshot(current_groups)
        compare_hashes(actual, self.expected)
        self.meta["freeze_checks"].append({"label": label,
            "at_utc": dt.datetime.now(dt.timezone.utc).isoformat(), "sha256": actual})
        return actual

    def remaining(self) -> int:
        seconds = GATE_TIMEOUT_S[self.gate] - (time.monotonic() - self.start)
        if seconds <= 0:
            raise OracleError("gate-wide time cap reached")
        return max(1, int(seconds))

    def command(self, name: str, argv: list[str], cwd: Path, overrides: dict[str, str],
                timeout_s: int) -> dict[str, Any]:
        before = self.verify(f"{name}:before")
        log_path = self.out / f"{len(self.meta['commands']) + 1:02d}-{name}.log"
        timeout = min(timeout_s, self.remaining())
        env = os.environ.copy()
        env.update(overrides)
        record: dict[str, Any] = {"name": name, "argv": argv, "cwd": str(cwd),
            "env_overrides": overrides, "timeout_s": timeout, "log": log_path.name,
            "started_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
            "process_status": None, "timed_out": False, "interrupted": False,
            "cleanup": None, "before_sha256": before}
        start = time.monotonic()
        with log_path.open("wb") as log:
            try:
                global ACTIVE_PROCESS
                proc = subprocess.Popen(argv, cwd=cwd, env=env, stdout=log, stderr=subprocess.STDOUT,
                                        shell=False, start_new_session=True)
                ACTIVE_PROCESS = proc
                try:
                    record["process_status"] = proc.wait(timeout=timeout)
                except subprocess.TimeoutExpired:
                    record["timed_out"] = True
                    record["cleanup"] = terminate_group(proc)
                    record["process_status"] = proc.returncode
                except KeyboardInterrupt:
                    record["interrupted"] = True
                    record["cleanup"] = terminate_group(proc)
                    record["process_status"] = proc.returncode
                finally:
                    ACTIVE_PROCESS = None
            except FileNotFoundError as exc:
                record["launch_error"] = str(exc)
                record["process_status"] = 127
            log.flush()
            os.fsync(log.fileno())
        record["elapsed_s"] = round(time.monotonic() - start, 3)
        record["ended_at_utc"] = dt.datetime.now(dt.timezone.utc).isoformat()
        record["log_sha256"] = sha256_file(log_path)
        try:
            record["after_sha256"] = self.verify(f"{name}:after")
        except Exception as exc:
            record["after_hash_error"] = str(exc)
            record["after_sha256"] = None
        self.meta["commands"].append(record)
        self.save()
        if record["timed_out"]:
            raise OracleError(f"{name} timed out; process group {record['cleanup']}")
        if record["interrupted"]:
            raise KeyboardInterrupt
        if record.get("launch_error"):
            raise OracleError(f"cannot launch {name}: {record['launch_error']}")
        if record["process_status"] != 0:
            raise OracleError(f"{name} exit status {record['process_status']}; see {log_path}")
        if record.get("after_hash_error"):
            raise OracleError(f"{name} changed a frozen input: {record['after_hash_error']}")
        return record

    def check_runtime(self, doc: dict[str, Any]) -> None:
        versions = (
            ("julia-version", ["julia", "--startup-file=no", "--version"], JULIA_ROOT,
             {k: v for k, v in julia_env().items() if k != "ARC1_SKIP_EXPENSIVE_PROFILE_WRAPPER"}),
            ("rscript-version", ["Rscript", "--vanilla", "--version"], R_ROOT,
             {"OPENBLAS_NUM_THREADS": BLAS_THREADS}),)
        actual = {}
        for name, argv, cwd, env in versions:
            result = self.command(name, argv, cwd, env, VERSION_TIMEOUT_S)
            actual["julia" if name.startswith("julia") else "rscript"] = (
                self.out.joinpath(result["log"]).read_text(errors="replace").strip())
        if actual != doc["runtime"]:
            raise OracleError(f"runtime mismatch: expected {doc['runtime']!r}; observed {actual!r}")
        self.meta["runtime_observed"] = actual

    def run_g1(self) -> None:
        for test in JULIA_TESTS:
            record = self.command("julia-" + Path(test).stem, julia_argv(test), JULIA_ROOT,
                                  julia_env(), JULIA_TIMEOUT_S)
            output = self.out.joinpath(record["log"]).read_text(errors="replace")
            counts = re.search(r"ARC1_TEST_COUNTS passes=(\d+) failures=(\d+) errors=(\d+) broken=(\d+)", output)
            if not counts or int(counts.group(1)) <= 0 or any(int(counts.group(i)) != 0 for i in range(2, 5)):
                raise OracleError(f"{test} omitted clean positive Julia assertion counts")

    def run_g6(self) -> None:
        driver = self.out / f"arc1_live_driver_{uuid.uuid4().hex[:10]}.R"
        results_path = self.out / "testthat-results.rds"
        driver.write_text(R_DRIVER)
        result_path = results_path
        csv_path = self.out / "testthat-results.csv"
        env = julia_env()
        env.update({"HSQUARED_ARC1_REQUIRE_LIVE": "true",
                    "HSQUARED_JULIA_PROJECT": str(JULIA_ROOT),
                    "JULIA_PROJECT": str(JULIA_ROOT),
                    "ARC1_ORACLE_RESULTS_RDS": str(result_path),
                    "ARC1_ORACLE_RESULTS_CSV": str(csv_path)})
        if not driver.is_absolute() or driver.parent != self.out:
            raise OracleError("generated R driver escaped the unique run directory")
        record = self.command("r-devtools-arc1-live", ["Rscript", "--vanilla", str(driver)],
                              R_ROOT, env, R_TIMEOUT_S)
        if not results_path.is_file() or not csv_path.is_file():
            raise OracleError("R did not retain the full testthat result table and CSV")
        log = self.out.joinpath(record["log"]).read_text(errors="replace")
        if "ARC1_TESTTHAT_COUNTS " not in log:
            raise OracleError("R output lacks required failure/skip/error result counts")
        record["result_table"] = results_path.name
        record["result_table_sha256"] = sha256_file(results_path)
        record["result_csv"] = csv_path.name
        record["result_csv_sha256"] = sha256_file(csv_path)
        self.save()

    def run(self) -> int:
        try:
            doc = self.load_freeze()
            self.save()
            self.check_runtime(doc)
            self.run_g1() if self.gate == "g1" else self.run_g6()
            self.verify("final")
            self.meta.update({"status": "passed", "ended_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
                              "elapsed_s": round(time.monotonic() - self.start, 3)})
            self.save()
            marker = "ARC1_G1_COMPONENTS_PASS" if self.gate == "g1" else "ARC1_G6_LIVE_PASS"
            print(f"{marker} freeze_sha256={self.freeze_hash} run_dir={self.out}")
            return 0
        except KeyboardInterrupt:
            self.meta.update({"status": "interrupted", "error": "runner interrupted"})
            return self.fail(130)
        except Exception as exc:
            self.meta.update({"status": "failed", "error": f"{type(exc).__name__}: {exc}"})
            return self.fail(1)

    def fail(self, code: int) -> int:
        self.meta.update({"ended_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
                          "elapsed_s": round(time.monotonic() - self.start, 3)})
        self.save()
        print(f"ARC1_ORACLE_FAILED gate={self.gate} run_dir={self.out}: {self.meta['error']}", file=sys.stderr)
        return code


def self_test() -> None:
    assert hashlib.sha256(b"abc").hexdigest() == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
    assert julia_argv(JULIA_TESTS[0])[:4] == ["julia", "--startup-file=no", "--project=.", "-e"]
    assert julia_argv(JULIA_TESTS[0])[-1] == str((JULIA_ROOT / JULIA_TESTS[0]).resolve())
    try:
        julia_argv("-e")
    except OracleError:
        pass
    else:
        raise AssertionError("arbitrary Julia command escaped allowlist")
    with tempfile.TemporaryDirectory(prefix="arc1-oracle-selftest-") as temp:
        root = Path(temp)
        path = root / "x"
        path.write_text("stable")
        groups = {"julia": (root, ["x"])}
        compare_path_sets(groups, groups)
        changed_paths = {"julia": (root, ["x", "new-file.jl"])}
        try:
            compare_path_sets(changed_paths, groups)
        except OracleError:
            pass
        else:
            raise AssertionError("changed required file set was not rejected")
        expected = snapshot(groups)
        compare_hashes(snapshot(groups), expected)
        path.write_text("changed")
        try:
            compare_hashes(snapshot(groups), expected)
        except OracleError:
            pass
        else:
            raise AssertionError("frozen hash mismatch was not rejected")
        malformed = {"schema": SCHEMA,
            "review": {"status": "reviewed", "reviewer": "selftest", "reviewed_at_utc": "test"},
            "roots": {"julia": str(root), "r": str(root)},
            "runtime": {"julia": "v", "rscript": "v"},
            "files": {"julia": {"x": "0" * 64}}}
        try:
            validate_freeze(malformed, groups)
        except OracleError:
            pass
        else:
            raise AssertionError("freeze root mismatch was not rejected")
    # Exercise the identical embedded testthat driver against disposable
    # package trees. No project fit or product test suite is run here.
    with tempfile.TemporaryDirectory(prefix="arc1-r-reporter-selftest-") as temp:
        root = Path(temp)
        pkg = root / "pkg"
        tests = pkg / "tests" / "testthat"
        tests.mkdir(parents=True)
        (pkg / "DESCRIPTION").write_text("Package: arc1synthetic\nTitle: Synthetic Oracle Check\nVersion: 0.0.0.9000\nAuthors@R: person('A', 'B', email='a@b.invalid', role=c('aut','cre'))\nDescription: Synthetic testthat reporter self-test.\nLicense: MIT\nEncoding: UTF-8\nConfig/testthat/edition: 3\n")
        (pkg / "NAMESPACE").write_text("")
        cases = {
            "pass": 'test_that("pass", { expect_true(TRUE) })',
            "failure": 'test_that("failure", { expect_true(FALSE) })',
            "skip": 'test_that("skip", { skip("synthetic skip") })',
            "error": 'test_that("error", { stop("synthetic error") })',
            "empty": 'test_that("empty", {})',
        }
        required = [Path(x).name for x in R_ARC1_TESTS]
        for case, snippet in cases.items():
            case_dir = root / case
            case_dir.mkdir()
            for index, filename in enumerate(required):
                body = snippet if index == 0 else f'test_that("other {index}", {{ expect_true(TRUE) }})'
                (tests / filename).write_text(body + "\n")
            rds, result_csv = case_dir / "results.rds", case_dir / "results.csv"
            driver = case_dir / "driver.R"
            driver.write_text(R_DRIVER)
            env = os.environ.copy()
            env.update({"ARC1_ORACLE_PACKAGE_ROOT": str(pkg),
                        "ARC1_ORACLE_RESULTS_RDS": str(rds),
                        "ARC1_ORACLE_RESULTS_CSV": str(result_csv)})
            proc = subprocess.run(["Rscript", "--vanilla", str(driver)], cwd=pkg,
                                  env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                  text=True, timeout=90, check=False)
            if proc.returncode not in ((0,) if case == "pass" else (1,)):
                raise AssertionError(f"synthetic R {case} returned {proc.returncode}: {proc.stdout[-2000:]}")
            if not rds.is_file() or not result_csv.is_file():
                raise AssertionError(f"synthetic R {case} omitted its retained results")
            with result_csv.open(newline="") as stream:
                rows = list(csv_module.DictReader(stream))
            if len(rows) != 4:
                raise AssertionError(f"synthetic R {case} did not report all four files: {rows}")
            first = rows[0]
            expected_field = {"failure": "failures", "skip": "skips", "error": "errors"}.get(case)
            if case == "pass" and (int(first["successes"]) <= 0 or int(first["failures"]) != 0):
                raise AssertionError(f"synthetic R pass was not counted as passing: {first}")
            if expected_field and int(first[expected_field]) <= 0:
                raise AssertionError(f"synthetic R {case} was not categorized: {first}")
            if case == "empty" and (int(first["successes"]) != 0 or int(first["skips"]) == 0):
                raise AssertionError(f"synthetic R empty test was not rejected as no assertions: {first}")
            print(f"ARC1_SYNTHETIC_R {case} exit={proc.returncode} counts={first}")
            shutil.rmtree(tests)
            tests.mkdir()
    julia_env_values = os.environ.copy()
    julia_env_values.update(julia_env())
    with tempfile.TemporaryDirectory(prefix="arc1-julia-wrapper-selftest-") as temp:
        root = Path(temp)
        cases = {
            "pass": "using Test\n@test true\n",
            "failure": "using Test\n@test false\n",
            "skip": "using Test\n@test_skip false\n",
            "empty": "using Test\n",
        }
        for case, body in cases.items():
            path = root / f"{case}.jl"
            path.write_text(body)
            proc = subprocess.run(julia_driver_argv(path), cwd=JULIA_ROOT,
                                  env=julia_env_values, stdout=subprocess.PIPE,
                                  stderr=subprocess.STDOUT, text=True, timeout=90, check=False)
            if case == "pass":
                match = re.search(r"ARC1_TEST_COUNTS passes=(\d+) failures=(\d+) errors=(\d+) broken=(\d+)", proc.stdout)
                if proc.returncode != 0 or not match or int(match.group(1)) <= 0 or any(int(match.group(i)) for i in range(2, 5)):
                    raise AssertionError(f"synthetic Julia pass failed: {proc.stdout[-1500:]}")
            elif case == "failure":
                if proc.returncode == 0 or "Some tests did not pass" not in proc.stdout:
                    raise AssertionError(f"synthetic Julia failure was not detected: {proc.stdout[-1500:]}")
            else:
                match = re.search(r"ARC1_TEST_COUNTS passes=(\d+) failures=(\d+) errors=(\d+) broken=(\d+)", proc.stdout)
                if proc.returncode == 0 or not match:
                    raise AssertionError(f"synthetic Julia {case} outcome was not counted: {proc.stdout[-1500:]}")
                expected = 1 if case == "skip" else 0
                if int(match.group(4)) != expected or int(match.group(1)) != 0:
                    raise AssertionError(f"synthetic Julia {case} count mismatch: {proc.stdout[-1500:]}")
            print(f"ARC1_SYNTHETIC_JULIA {case} exit={proc.returncode} output={proc.stdout.strip().splitlines()[-1:]}")
    print("ARC1_ORACLE_SELF_TEST_PASS")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--self-test", action="store_true", help="deterministic checks with synthetic R/Julia fixtures only")
    parser.add_argument("--gate", choices=("g1", "g6"), help="run only one supported gate")
    parser.add_argument("--freeze", type=Path, help="absolute path to externally reviewed freeze JSON")
    args = parser.parse_args(argv)
    if args.self_test:
        if args.gate or args.freeze:
            parser.error("--self-test cannot be combined with --gate or --freeze")
        self_test()
        return 0
    if not args.gate or not args.freeze or not args.freeze.is_absolute():
        parser.error("actual runs require --gate and an absolute --freeze path")
    for sig in (signal.SIGTERM, signal.SIGHUP):
        signal.signal(sig, handle_signal)
    return Runner(args.gate, args.freeze).run()


if __name__ == "__main__":
    raise SystemExit(main())
