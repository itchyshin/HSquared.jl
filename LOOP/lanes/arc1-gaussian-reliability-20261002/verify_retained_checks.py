#!/usr/bin/env python3
"""Read-only verification of an already completed Arc1 runner receipt.

This verifies retained process evidence against externally supplied receipt
and freeze SHA-256 pins. It never starts Julia, R, package tests, docs builds,
or scientific fits. Synthetic test fixtures are integrity tests only.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import importlib
import json
import os
import re
import sys
import tomllib
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parents[3]
ORACLE_RUN_SCHEMA = "hsquared-arc1-oracle-run-v1"
PACKAGE_RUN_SCHEMA = "hsquared-arc1-package-check-run-v1"
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
REQUIRED_R_TESTS = (
    "test-arc1-controls.R", "test-arc1-live-parity.R",
    "test-arc1-bootstrap-v2-live.R", "test-arc1-profile-v4-live.R",
    "test-arc1-profile-v4-transport-isolation.R",
    "test-arc1-uncertainty-controls.R", "test-arc1-uncertainty-live.R",
)
ORACLE_JULIA_TESTS = (
    "test/arc1_exact_objectives.jl", "test/arc1_optimizer_contracts.jl",
    "test/arc1_profiles.jl", "test/arc1_bootstrap.jl", "test/arc1_interfaces.jl",
    "test/arc1_simulation_dgp.jl", "test/arc1_simulation_reference.jl",
    "test/arc1_simulation_executor.jl",
)
class ReceiptError(RuntimeError):
    """A retained run does not prove the requested gate."""


def _need(condition: Any, message: str) -> None:
    if not condition:
        raise ReceiptError(message)


def _sha_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    if path.is_symlink() or not path.is_file():
        raise ReceiptError(f"missing or unsafe regular file: {path}")
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _canonical_preflight_sha256(path: Path) -> str:
    """Rebuild the runner's sorted TOML canonical bytes without volatile root keys."""
    try:
        lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    except (OSError, UnicodeDecodeError) as exc:
        raise ReceiptError(f"cannot read retained preflight TOML for canonical verification: {exc}") from exc
    retained: list[str] = []
    in_table = False
    for line in lines:
        if line.startswith("["):
            in_table = True
        if not in_table and (line.startswith("created_at_utc = ") or
                             line.startswith("canonical_sha256 = ")):
            continue
        retained.append(line)
    return _sha_bytes("".join(retained).encode("utf-8"))


def _pinned_file(path: Path, expected_sha256: str, label: str) -> bytes:
    _need(path.is_absolute(), f"{label} path must be absolute")
    _need(SHA256_RE.fullmatch(expected_sha256) is not None, f"{label} SHA-256 is malformed")
    _need(not path.is_symlink() and path.is_file(), f"{label} must be a regular nonsymlink file")
    raw = path.read_bytes()
    _need(_sha_bytes(raw) == expected_sha256, f"{label} differs from its externally supplied SHA-256")
    return raw


def _load_json(path: Path, expected_sha256: str, label: str) -> dict[str, Any]:
    raw = _pinned_file(path, expected_sha256, label)
    try:
        value = json.loads(raw)
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ReceiptError(f"{label} is not valid JSON: {exc}") from exc
    _need(isinstance(value, dict), f"{label} must be a JSON object")
    return value


def _within(path: Path, root: Path) -> bool:
    try:
        path.resolve().relative_to(root.resolve())
        return True
    except ValueError:
        return False


def _safe_artifact(run_dir: Path, relative: Any, label: str) -> Path:
    _need(isinstance(relative, str) and relative, f"{label} path is missing")
    rel = Path(relative)
    if rel.is_absolute():
        _need(_within(rel, run_dir), f"{label} absolute path escapes its run directory")
        rel = rel.resolve().relative_to(run_dir.resolve())
    _need(".." not in rel.parts, f"{label} path escapes its run directory")
    candidate = run_dir / rel
    current = run_dir
    for part in rel.parts:
        current = current / part
        _need(not current.is_symlink(), f"{label} path contains a symlink")
    _need(candidate.is_file() and _within(candidate, run_dir), f"{label} is missing or outside its run directory")
    return candidate


def _safe_directory(run_dir: Path, relative: Any, label: str) -> Path:
    _need(isinstance(relative, str) and relative, f"{label} path is missing")
    rel = Path(relative)
    if rel.is_absolute():
        _need(_within(rel, run_dir), f"{label} absolute path escapes its run directory")
        rel = rel.resolve().relative_to(run_dir.resolve())
    _need(".." not in rel.parts, f"{label} path escapes its run directory")
    candidate = run_dir / rel
    current = run_dir
    for part in rel.parts:
        current = current / part
        _need(not current.is_symlink(), f"{label} path contains a symlink")
    _need(candidate.is_dir() and _within(candidate, run_dir), f"{label} is missing or outside its run directory")
    return candidate


def _hash_artifact(run_dir: Path, relative: Any, expected: Any, label: str) -> Path:
    _need(isinstance(expected, str) and SHA256_RE.fullmatch(expected) is not None,
          f"{label} SHA-256 is missing or malformed")
    path = _safe_artifact(run_dir, relative, label)
    _need(sha256_file(path) == expected, f"{label} bytes do not match the retained SHA-256")
    return path


def _parse_csv_results(path: Path, label: str) -> None:
    try:
        with path.open(newline="", encoding="utf-8") as stream:
            reader = csv.DictReader(stream)
            rows = list(reader)
    except (OSError, UnicodeDecodeError, csv.Error) as exc:
        raise ReceiptError(f"{label} is not a readable CSV: {exc}") from exc
    _need(reader.fieldnames is not None and
          set(reader.fieldnames) == {"file", "assertions", "successes", "failures", "errors", "skips", "warnings"},
          f"{label} columns are incomplete or unexpected")
    names = [row.get("file", "") for row in rows]
    _need(len(rows) == len(REQUIRED_R_TESTS) and set(names) == set(REQUIRED_R_TESTS) and
          len(set(names)) == len(names), f"{label} does not have exactly the {len(REQUIRED_R_TESTS)} required Arc1 test files")
    for row in rows:
        try:
            counts = {name: int(row[name]) for name in
                      ("assertions", "successes", "failures", "errors", "skips", "warnings")}
        except (KeyError, TypeError, ValueError) as exc:
            raise ReceiptError(f"{label} has a malformed test count") from exc
        _need(counts["assertions"] > 0 and counts["successes"] > 0 and
              all(counts[name] == 0 for name in ("failures", "errors", "skips", "warnings")),
              f"{label} records a failed, skipped, empty, or warning-producing Arc1 file")


def _load_adapters(gate: str, artifact_kind: str) -> Any:
    tools_dir = REPO_ROOT / "tools"
    if str(tools_dir) not in sys.path:
        sys.path.insert(0, str(tools_dir))
    try:
        if artifact_kind == "oracle":
            return importlib.import_module("arc1_oracles")
        return importlib.import_module("arc1_package_checks")
    except Exception as exc:
        raise ReceiptError(f"cannot load reviewed {artifact_kind} inventory helper: {exc}") from exc


def _validate_external_review(freeze: dict[str, Any], adapter: Any, artifact_kind: str) -> None:
    review = freeze.get("review")
    _need(isinstance(review, dict) and review.get("status") == "reviewed" and
          isinstance(review.get("reviewer"), str) and review["reviewer"].strip() and
          isinstance(review.get("reviewed_at_utc"), str) and review["reviewed_at_utc"].strip(),
          "freeze lacks reviewed metadata")
    if artifact_kind == "oracle":
        # The current oracle-freeze-v1 schema binds reviewer metadata but has no
        # external review receipt fields. The caller's explicit freeze SHA is
        # therefore the external binding; do not invent a stronger record.
        return
    path_text, expected = review.get("review_receipt_path"), review.get("review_receipt_sha256")
    _need(isinstance(path_text, str) and Path(path_text).is_absolute(),
          "package freeze lacks an absolute external review receipt path")
    _need(isinstance(expected, str) and SHA256_RE.fullmatch(expected) is not None,
          "package freeze review receipt hash is missing or malformed")
    review_path = Path(path_text)
    _need(not review_path.is_symlink() and review_path.is_file(), "external package review receipt is absent or unsafe")
    evidence_root = getattr(adapter, "EVIDENCE_ROOT", getattr(adapter, "RUNS_ROOT", None))
    _need(evidence_root is not None and not _within(review_path, evidence_root),
          "runner review receipt is inside runner evidence")
    _need(sha256_file(review_path) == expected, "external package review receipt changed")


def _inventory(adapter: Any, freeze: dict[str, Any], gate: str, artifact_kind: str) -> dict[str, dict[str, str]]:
    try:
        if artifact_kind == "oracle":
            groups = adapter.file_map()
            adapter.validate_freeze(freeze, groups, gate=gate.lower())
            current = adapter.snapshot(groups)
        else:
            file_map = adapter.build_file_map()
            adapter.validate_freeze(freeze, {"julia": str(adapter.JULIA_ROOT),
                                              "r": str(adapter.R_ROOT)},
                                    file_map, gate=gate.lower() if gate != "G6" else "all")
            if gate in {"G7", "G6"}:
                adapter.validate_docs_frontend(freeze["docs_frontend"], verify_runtime=False)
            current = adapter.snapshot(file_map)
    except Exception as exc:
        raise ReceiptError(f"runner rejected the freeze or current input inventory: {exc}") from exc
    _need(freeze.get("files") == current,
          "current Julia/R source inventory differs from the externally pinned freeze")
    return current


def _check_command_logs(run_dir: Path, commands: Any, expected_names: list[str],
                        frozen_files: dict[str, dict[str, str]], *, package: bool,
                        julia_root: str, r_root: str,
                        expected_argv: dict[str, list[str]]) -> dict[str, dict[str, Any]]:
    _need(isinstance(commands, list) and [x.get("name") for x in commands if isinstance(x, dict)] == expected_names,
          "receipt command list is incomplete, reordered, or contains extra commands")
    by_name: dict[str, dict[str, Any]] = {}
    for record in commands:
        _need(isinstance(record, dict), "command record must be an object")
        name = record["name"]
        _need(record.get("argv") == expected_argv.get(name),
              f"{name} executed argv differs from the current reviewed runner command")
        _need(record.get("process_status") == 0, f"{name} did not exit successfully")
        _need(record.get("timed_out") is False and record.get("interrupted") is False,
              f"{name} timed out or was interrupted")
        _need(not record.get("launch_error") and not record.get("after_hash_error"),
              f"{name} has a launch or source-integrity error")
        log = _hash_artifact(run_dir, record.get("log"), record.get("log_sha256"), f"{name} log")
        output = log.read_text(encoding="utf-8", errors="replace")
        is_r = name.startswith("r-") or name == "rscript-version"
        expected_cwd = r_root if is_r else julia_root
        _need(record.get("cwd") == expected_cwd, f"{name} ran from an unexpected working directory")
        _need(record.get("before_sha256") == frozen_files and record.get("after_sha256") == frozen_files,
              f"{name} before/after source snapshots differ from the reviewed freeze")
        by_name[name] = {"record": record, "output": output, "log": log}
    return by_name


def _check_snapshot_history(history: Any, commands: list[dict[str, Any]], frozen_files: dict[str, dict[str, str]],
                            label: str) -> None:
    _need(isinstance(history, list) and history, f"receipt lacks {label} source history")
    labels = [item.get("label") for item in history if isinstance(item, dict)]
    _need(labels and labels[0] == "initial" and labels[-1] == "final",
          f"{label} source history lacks initial/final verification")
    _need(len(labels) == len(history) and all(item.get("sha256") == frozen_files for item in history),
          f"{label} source history records a missing or mismatched source snapshot")
    history_labels = set(labels)
    for command in commands:
        name = command["name"]
        _need(f"{name}:before" in history_labels and f"{name}:after" in history_labels,
              f"source history omits before/after checks for {name}")


def _verify_oracle(gate: str, receipt: dict[str, Any], run_dir: Path, freeze: dict[str, Any],
                   adapter: Any, frozen_files: dict[str, dict[str, str]]) -> None:
    expected_gate = gate.lower()
    _need(receipt.get("schema") == ORACLE_RUN_SCHEMA and receipt.get("gate") == expected_gate,
          "oracle receipt schema or gate does not match the requested gate")
    _need(receipt.get("run_id") == run_dir.name, "oracle receipt run_id differs from its retained directory")
    _need(receipt.get("julia_root") == str(adapter.JULIA_ROOT) and
          receipt.get("r_root") == str(adapter.R_ROOT), "oracle receipt roots differ from the current runner")
    _need(receipt.get("freeze_path") == str(freeze["_path"]) and
          receipt.get("freeze_sha256") == freeze["_sha256"], "oracle receipt freeze identity differs from external pins")
    _need(receipt.get("review") == freeze["review"], "oracle receipt review metadata differs from frozen record")
    _need(receipt.get("runtime_expected") == freeze["runtime"] and
          receipt.get("runtime_observed") == freeze["runtime"], "oracle runtime evidence differs from frozen runtime")
    _need(receipt.get("runner_sha256") == sha256_file(adapter.RUNNER), "oracle runner hash is stale")
    raw_groups = adapter.file_map()
    expected_counts = {key: len(value[1]) if isinstance(value, tuple) and len(value) == 2 else len(value)
                       for key, value in raw_groups.items()}
    _need(receipt.get("required_file_counts") == expected_counts,
          "oracle receipt input counts differ from the reviewed inventory")

    if gate == "G1":
        test_names = ["julia-" + Path(test).stem for test in adapter.JULIA_TESTS]
        command_names = ["julia-version", "rscript-version", *test_names]
    else:
        command_names = ["julia-version", "rscript-version", "r-devtools-arc1-live"]
    expected_argv = {
        "julia-version": ["julia", "--startup-file=no", "--version"],
        "rscript-version": ["Rscript", "--version"],
    }
    if gate == "G1":
        expected_argv.update({"julia-" + Path(test).stem: adapter.julia_argv(test)
                              for test in adapter.JULIA_TESTS})
    else:
        live_record = next((x for x in receipt["commands"] if x.get("name") == "r-devtools-arc1-live"), {})
        live_argv = live_record.get("argv", [])
        _need(isinstance(live_argv, list) and len(live_argv) == 3 and
              live_argv[:2] == ["Rscript", "--vanilla"] and isinstance(live_argv[2], str),
              "G6 mandatory-live R command argv is malformed")
        expected_argv["r-devtools-arc1-live"] = live_argv
    logs = _check_command_logs(run_dir, receipt.get("commands"), command_names, frozen_files,
                               package=False, julia_root=str(adapter.JULIA_ROOT), r_root=str(adapter.R_ROOT),
                               expected_argv=expected_argv)
    commands = receipt["commands"]
    _check_snapshot_history(receipt.get("freeze_checks"), commands, frozen_files, "oracle")
    _need(receipt.get("runtime_observed", {}).get("julia") in logs["julia-version"]["output"],
          "Julia version log does not match the frozen version")
    _need(receipt.get("runtime_observed", {}).get("rscript") in logs["rscript-version"]["output"],
          "R version log does not match the frozen version")

    if gate == "G1":
        for name in test_names:
            output = logs[name]["output"]
            _need(logs[name]["record"].get("env_overrides") == adapter.julia_env(),
                  f"{name} resource/profile environment differs from the reviewed oracle runner")
            match = re.search(r"ARC1_TEST_COUNTS passes=(\d+) failures=(\d+) errors=(\d+) broken=(\d+)", output)
            _need(match is not None and int(match.group(1)) > 0 and
                  all(int(match.group(i)) == 0 for i in range(2, 5)),
                  f"{name} lacks clean positive test counts")
    else:
        command = logs["r-devtools-arc1-live"]["record"]
        _need("ARC1_TESTTHAT_COUNTS " in logs["r-devtools-arc1-live"]["output"],
              "G6 mandatory-live R log lacks its counts marker")
        csv_file = _hash_artifact(run_dir, command.get("result_csv"), command.get("result_csv_sha256"),
                                  "G6 result CSV")
        rds_file = _hash_artifact(run_dir, command.get("result_table"), command.get("result_table_sha256"),
                                  "G6 RDS result table")
        _parse_csv_results(csv_file, "G6 result CSV")
        bootstrap = freeze.get("julia_call_bootstrap")
        expected_bootstrap = {"Project.toml": bootstrap["project_sha256"],
                              "Manifest.toml": bootstrap["manifest_sha256"]}
        observed_bootstrap = receipt.get("julia_call_bootstrap_run", {}).get("initial_sha256")
        _need(observed_bootstrap == expected_bootstrap, "G6 bootstrap copy differs from reviewed pins")
        _need(command.get("julia_call_bootstrap_changed") is False and
              command.get("julia_call_bootstrap_before_sha256") == expected_bootstrap and
              command.get("julia_call_bootstrap_after_sha256") == expected_bootstrap,
              "G6 JuliaCall bootstrap changed during the test")
        driver_path = command.get("argv", [None, None, None])[-1]
        _need(isinstance(driver_path, str) and Path(driver_path).parent.resolve() == run_dir.resolve(),
              "G6 R driver is missing or escaped its unique run directory")
        driver = _safe_artifact(run_dir, Path(driver_path).name, "G6 generated R driver")
        _need(driver.read_text(encoding="utf-8") == adapter.R_DRIVER,
              "G6 executed driver differs from the pinned runner's mandatory-live selection")
        live_env = command.get("env_overrides")
        _need(isinstance(live_env, dict) and live_env.get("ARC1_ORACLE_PACKAGE_ROOT") == str(adapter.R_ROOT) and
              live_env.get("ARC1_ORACLE_RESULTS_CSV") == str(csv_file) and
              live_env.get("ARC1_ORACLE_RESULTS_RDS") == str(rds_file) and
              live_env.get("HSQUARED_ARC1_REQUIRE_LIVE") == "true" and
              live_env.get("JULIA_NUM_THREADS") == "4" and live_env.get("OPENBLAS_NUM_THREADS") == "1",
              "G6 executed environment is not bound to the retained R results and reviewed thread limits")


def _validate_retained_registry_inventory(report: dict[str, Any], adapter: Any) -> None:
    """Check registry inventory completeness and internal pins without reading its files."""
    registries = report.get("registries")
    _need(isinstance(registries, list) and registries,
          "G7 retained no-install preflight registry inventory is missing")
    tarball_mode = report.get("registry_tarball_mode")
    depot_path = report.get("depot_path")
    _need(isinstance(tarball_mode, bool) and isinstance(depot_path, list) and depot_path and
          all(isinstance(item, str) and Path(item).is_absolute() for item in depot_path),
          "G7 retained no-install preflight registry mode or depot identity is malformed")
    expected_paths = adapter._registry_candidates(depot_path, tarball_mode)
    seen_paths: set[str] = set()
    for row in registries:
        _need(isinstance(row, dict), "G7 retained registry record is malformed")
        path = row.get("registry_path")
        descriptor = row.get("descriptor_path")
        payload = row.get("payload_path")
        name, uuid = row.get("name"), row.get("uuid")
        _need(isinstance(path, str) and Path(path).is_absolute() and path not in seen_paths and
              isinstance(descriptor, str) and Path(descriptor).is_absolute() and
              isinstance(payload, str) and Path(payload).is_absolute() and
              isinstance(name, str) and name and isinstance(uuid, str) and
              re.fullmatch(r"[0-9a-fA-F-]{36}", uuid) is not None,
              "G7 retained registry identity or paths are malformed")
        seen_paths.add(path)
        _need(isinstance(row.get("compressed"), bool) and
              re.fullmatch(r"[0-9a-f]{64}", str(row.get("descriptor_sha256", ""))) is not None and
              re.fullmatch(r"[0-9a-f]{64}", str(row.get("payload_sha256", ""))) is not None and
              re.fullmatch(r"[0-9a-f]{40}", str(row.get("git_tree_sha1", ""))) is not None and
              row.get("observed_tree_sha1") == row.get("git_tree_sha1") and
              isinstance(row.get("repo"), str) and row["repo"].startswith("https://"),
              "G7 retained registry content pins or identity are malformed")
        if row["compressed"]:
            _need(Path(descriptor) == Path(path) and Path(payload).parent == Path(path).parent and
                  Path(payload).name.endswith((".tar.gz", ".tgz")),
                  "G7 retained compressed registry paths are inconsistent")
        else:
            _need(Path(descriptor) == Path(path) / "Registry.toml" and Path(payload) == Path(path),
                  "G7 retained unpacked registry paths are inconsistent")
    _need(seen_paths == expected_paths,
          "G7 retained registry inventory omits or duplicates a depot registry")


def _validate_retained_preflight_snapshot(path: Path, expected_sha256: str,
                                         expected: dict[str, Any], adapter: Any) -> dict[str, Any]:
    """Validate frozen preflight semantics while allowing later registry-file updates.

    The package validator checks the retained Manifest, path sources, dependency closure,
    artifact selection and overrides before it inspects registry bytes. Only the three
    registry-content mismatch errors at the end of that validator are eligible for the
    historical-snapshot path below. All other failures remain fatal.
    """
    raw = _pinned_file(path, expected_sha256, "G7 retained no-install preflight snapshot")
    try:
        report = tomllib.loads(raw.decode("utf-8"))
    except (UnicodeDecodeError, tomllib.TOMLDecodeError) as error:
        raise ReceiptError(f"G7 retained no-install preflight TOML is invalid: {error}") from error
    _need(report.get("schema") == "arc1-julia-noinstall-preflight-v1" and
          report.get("status") == "passed", "G7 retained no-install preflight lacks passed status")
    for key in ("freeze_sha256", "runner_sha256", "driver_sha256", "sandbox",
                "load_path", "depot_path", "julia_executable", "julia_launcher_sha256",
                "julia_version", "julia_runtime_executable", "julia_runtime_executable_sha256"):
        _need(report.get(key) == expected.get(key),
              f"G7 retained no-install preflight {key} differs from frozen identity")
    host_identity = expected.get("host_identity")
    _need(isinstance(host_identity, dict), "G7 frozen Julia host identity is missing")
    for key, value in host_identity.items():
        report_key = "julia_runtime_executable" if key == "julia_runtime_executable" else key
        report_value = report.get(report_key)
        if key == "julia_runtime_executable_sha256":
            report_value = report.get(key)
        _need(report_value == value, f"G7 retained no-install preflight host identity differs for {key}")
    try:
        adapter.validate_noinstall_preflight_receipt(path, expected_sha256, expected)
    except Exception as error:
        allowed_registry_drift = {
            "reachable registry descriptor content changed",
            "reachable registry tree or identity differs from its content",
            "reachable registry payload content changed",
        }
        _need(str(error) in allowed_registry_drift,
              f"G7 retained no-install preflight semantic validation failed: {error}")
        _validate_retained_registry_inventory(report, adapter)
    _need(report.get("canonical_sha256") == _canonical_preflight_sha256(path),
          "G7 retained no-install preflight canonical digest is invalid")
    return report


def _verify_package(gate: str, receipt: dict[str, Any], run_dir: Path, freeze: dict[str, Any],
                    adapter: Any, frozen_files: dict[str, dict[str, str]]) -> None:
    _need(receipt.get("schema") == PACKAGE_RUN_SCHEMA and receipt.get("gate_selection") == "all",
          "package receipt is not an all-components G7 run")
    _need(receipt.get("run_dir") == str(run_dir), "package receipt run_dir differs from its retained directory")
    _need(receipt.get("freeze_path") == str(freeze["_path"]) and
          receipt.get("freeze_sha256") == freeze["_sha256"], "package receipt freeze identity differs from external pins")
    _need(receipt.get("runner_sha256") == sha256_file(adapter.RUNNER), "package-check runner hash is stale")
    _need(receipt.get("review") == freeze["review"] and
          receipt.get("review_receipt_sha256") == freeze["review"]["review_receipt_sha256"],
          "package review binding differs from the external freeze")
    _need(receipt.get("runtime_expected") == freeze["runtime"] and
          receipt.get("runtime_observed") == {key: freeze["runtime"][key]
                                               for key in ("julia", "rscript")},
          "package runtime evidence differs from the reviewed freeze")
    _need(receipt.get("passed_components") == ["julia", "r", "docs"],
          "G7 requires Julia, R, and docs as the complete passed component set")
    _need(receipt.get("input_counts") == {key: len(value) for key, value in frozen_files.items()},
          "package receipt input counts differ from the reviewed inventory")
    expected_names = ["julia-version", "rscript-version", "julia-direct-test-suite", "r-arc1-mandatory-live",
                      "r-cmd-check", "julia-local-docs"]
    sandbox = freeze.get("julia_test_sandbox")
    _need(isinstance(sandbox, dict), "package freeze lacks its reviewed Julia test sandbox")
    julia_driver_path = run_dir / "julia-test-driver.jl"
    julia_argv, expected_julia_env = adapter._julia_command(julia_driver_path, sandbox)
    docs_argv = [adapter.JULIA_BIN, "--startup-file=no",
                 f"--project={run_dir / 'docs-environment'}", str(run_dir / "local-docs-make.jl")]
    expected_argv = {
        "julia-version": adapter._version_command("julia"),
        "rscript-version": adapter._version_command("rscript"),
        "julia-direct-test-suite": julia_argv,
        "r-arc1-mandatory-live": [adapter.RSCRIPT_BIN, "--vanilla", str(run_dir / "r-arc1-live-driver.R")],
        "r-cmd-check": [adapter.RSCRIPT_BIN, "--vanilla", str(run_dir / "r-package-check-driver.R")],
        "julia-local-docs": docs_argv,
    }
    logs = _check_command_logs(run_dir, receipt.get("commands"), expected_names, frozen_files,
                               package=True, julia_root=str(adapter.JULIA_ROOT), r_root=str(adapter.R_ROOT),
                               expected_argv=expected_argv)
    julia_env = logs["julia-direct-test-suite"]["record"].get("env_overrides")
    _need(isinstance(julia_env, dict) and julia_env == expected_julia_env and
          julia_env.get("JULIA_LOAD_PATH") == "@:@stdlib" and
          julia_env.get("JULIA_NUM_THREADS") == "1" and julia_env.get("OPENBLAS_NUM_THREADS") == "1",
          "G7 Julia direct-test environment is not isolated to the reviewed sandbox and one-thread limits")
    r_live_env = logs["r-arc1-mandatory-live"]["record"].get("env_overrides")
    _need(isinstance(r_live_env, dict) and
          r_live_env.get("ARC1_ORACLE_PACKAGE_ROOT") == str(adapter.R_ROOT) and
          r_live_env.get("ARC1_ORACLE_RESULTS_CSV") == str(run_dir / "arc1-live-results.csv") and
          r_live_env.get("ARC1_ORACLE_RESULTS_RDS") == str(run_dir / "arc1-live-results.rds") and
          r_live_env.get("HSQUARED_ARC1_REQUIRE_LIVE") == "true" and
          r_live_env.get("JULIA_NUM_THREADS") == "1" and r_live_env.get("OPENBLAS_NUM_THREADS") == "1",
          "G7 live-R environment is not bound to retained outputs and mandatory-live mode")
    r_check_env = logs["r-cmd-check"]["record"].get("env_overrides")
    _need(isinstance(r_check_env, dict) and r_check_env.get("ARC1_R_CHECK_DIR") == str(run_dir / "r-check") and
          r_check_env.get("ARC1_R_RESULT_FILE") == str(run_dir / "r-check-result.json"),
          "G7 R check environment does not point to its retained result directory")
    for name in ("r-arc1-mandatory-live", "r-cmd-check"):
        driver = _safe_artifact(run_dir, Path(expected_argv[name][-1]).name, f"{name} generated driver")
        expected_driver = adapter._oracle.R_DRIVER if name == "r-arc1-mandatory-live" else adapter.R_PACKAGE_DRIVER
        _need(driver.read_text(encoding="utf-8") == expected_driver,
              f"{name} generated driver differs from the current reviewed runner")
    _check_snapshot_history(receipt.get("hash_checks"), receipt["commands"], frozen_files, "package")
    for name in ("julia-version", "rscript-version"):
        _need(freeze["runtime"][name.removesuffix("-version")] in logs[name]["output"],
              f"{name} log does not match the frozen runtime")
    _need("ARC1_TEST_SANDBOX_VERIFIED" in logs["julia-direct-test-suite"]["output"] and
          "ARC1_LOADED_HSQUARED_SOURCE_VERIFIED" in logs["julia-direct-test-suite"]["output"] and
          "ARC1_PACKAGE_JULIA_COMPONENT_PASS" in logs["julia-direct-test-suite"]["output"],
          "G7 Julia direct-test log lacks sandbox, source-identity, or success markers")
    expected_testsets = tuple(adapter.REQUIRED_ARC1_TESTSETS)
    try:
        parsed_log_summary = adapter.parse_julia_test_output(
            logs["julia-direct-test-suite"]["output"],
            required_arc1_testsets=expected_testsets)
    except Exception as error:
        raise ReceiptError(f"G7 retained Julia log has no valid passing Test Summary evidence: {error}") from error
    summary = receipt.get("julia_test_summary")
    expected_sets = set(expected_testsets)
    _need(isinstance(summary, dict) and summary.get("required_arc1_testsets") == list(expected_testsets),
          "G7 Julia summary does not report the complete required Arc1 testset set")
    records = summary.get("summary_records")
    _need(isinstance(records, list), "G7 Julia testset summary is missing")
    _need(summary == parsed_log_summary,
          "G7 Julia receipt test summary differs from the hashed Julia log summaries")
    by_set = {row.get("testset"): row for row in records if isinstance(row, dict)}
    _need(set(by_set) >= expected_sets, "G7 Julia summary omits a required Arc1 testset")
    for name in expected_sets:
        row = by_set[name]
        _need(row.get("pass", 0) > 0 and row.get("total", 0) > 0 and
              all(row.get(key, 0) == 0 for key in ("fail", "error", "broken")),
              f"G7 Julia testset {name!r} lacks passing assertions or reports failures")
    component_receipts = receipt.get("component_receipts")
    _need(isinstance(component_receipts, dict) and set(component_receipts) == {"julia", "r", "docs"} and
          all(component_receipts[name].get("status") == "passed" for name in ("julia", "r", "docs")),
          "G7 component receipts are incomplete or not all passed")
    _need(component_receipts["julia"].get("test_summary") == summary,
          "G7 Julia component summary differs from the top-level summary")
    capture = _safe_directory(run_dir, "julia-test-sandbox", "G7 Julia test sandbox capture")
    captured_project = _hash_artifact(capture, "Project.toml", sandbox.get("project_sha256"),
                                      "G7 captured Julia sandbox Project.toml")
    captured_manifest = _hash_artifact(capture, "Manifest.toml", sandbox.get("manifest_sha256"),
                                       "G7 captured Julia sandbox Manifest.toml")
    capture_receipt = _safe_artifact(capture, "sha256.txt", "G7 Julia sandbox capture receipt")
    expected_capture = sandbox["project_sha256"] + "\n" + sandbox["manifest_sha256"] + "\n"
    _need(capture_receipt.read_text(encoding="ascii") == expected_capture,
          "G7 Julia sandbox capture receipt differs from reviewed pins")
    _need(component_receipts["julia"].get("test_sandbox") == {
              "project_sha256": sandbox["project_sha256"],
              "manifest_sha256": sandbox["manifest_sha256"], "capture_dir": str(capture)},
          "G7 Julia component sandbox metadata differs from retained capture")
    _need(component_receipts["julia"].get("test_sandbox_after_sha256") == {
              "project_sha256": sandbox["project_sha256"],
              "manifest_sha256": sandbox["manifest_sha256"]},
          "G7 Julia reviewed test sandbox changed during direct test execution")
    _need(component_receipts["julia"].get("test_sandbox_capture_after_sha256") == {
              "project_sha256": sandbox["project_sha256"],
              "manifest_sha256": sandbox["manifest_sha256"]},
          "G7 Julia retained test sandbox capture changed during direct test execution")
    driver = _safe_artifact(run_dir, "julia-test-driver.jl", "G7 Julia direct-test driver")
    driver_source = driver.read_text(encoding="utf-8")
    expected_driver = adapter.julia_test_driver_source(
        sandbox, capture, freeze_sha256=receipt["freeze_sha256"],
        expected_julia_executable=receipt["runtime_expected"]["julia_executable"],
        expected_julia_version=receipt["runtime_expected"]["julia"].removeprefix("julia version "),
        source_file_inventory=frozen_files["julia"])
    _need(driver_source == expected_driver,
          "G7 Julia direct-test driver differs from the current reviewed runner")
    _need(not any(operation in driver_source for operation in
                  ("Pkg.test", "Pkg.resolve", "Pkg.instantiate", "Pkg.add", "Pkg.update",
                   "Pkg.develop", "Pkg.rm", "Pkg.build", "Pkg.precompile")),
          "G7 Julia direct-test driver invokes package resolution or installation")
    driver_hash = sha256_file(driver)
    expected_driver_record = {"path": driver.name, "sha256": driver_hash}
    _need(receipt.get("julia_test_driver") == expected_driver_record and
          component_receipts["julia"].get("test_driver") == expected_driver_record,
          "G7 Julia direct-test driver is not bound to its retained hashes")
    preflight_log = logs["julia-direct-test-suite"]["output"]
    marker_values: dict[str, str] = {}
    for marker in ("ARC1_NO_INSTALL_PREFLIGHT_BEFORE_SHA256",
                   "ARC1_NO_INSTALL_PREFLIGHT_AFTER_SHA256",
                   "ARC1_NO_INSTALL_PREFLIGHT_CANONICAL_SHA256"):
        found = re.findall(rf"^{marker}=([0-9a-f]{{64}})$", preflight_log, flags=re.MULTILINE)
        _need(len(found) == 1, f"G7 Julia log must contain exactly one {marker} marker")
        marker_values[marker] = found[0]
    _need(preflight_log.count("ARC1_NO_INSTALL_PREFLIGHT_IDENTICAL") == 1,
          "G7 Julia log lacks one before/after no-install preflight identity marker")
    before_preflight = _safe_artifact(capture, "julia-noinstall-preflight-before.toml",
                                      "G7 before-test no-install preflight")
    after_preflight = _safe_artifact(capture, "julia-noinstall-preflight-after.toml",
                                     "G7 after-test no-install preflight")
    before_sha = sha256_file(before_preflight)
    after_sha = sha256_file(after_preflight)
    _need(before_sha == marker_values["ARC1_NO_INSTALL_PREFLIGHT_BEFORE_SHA256"] and
          after_sha == marker_values["ARC1_NO_INSTALL_PREFLIGHT_AFTER_SHA256"],
          "G7 retained no-install preflight hashes differ from the Julia test log")
    preflight_receipt = receipt.get("julia_noinstall_preflight")
    expected_preflight_receipt = {
        "schema": "arc1-julia-noinstall-preflight-v1", "status": "passed",
        "created_at_utc": None, "receipt_path": str(before_preflight), "receipt_sha256": before_sha,
        "post_test_receipt_path": str(after_preflight), "post_test_receipt_sha256": after_sha,
        "canonical_sha256": marker_values["ARC1_NO_INSTALL_PREFLIGHT_CANONICAL_SHA256"],
        "canonical_equal": True, "log_marker": "ARC1_NO_INSTALL_PREFLIGHT_IDENTICAL",
    }
    _need(isinstance(preflight_receipt, dict), "G7 top-level no-install preflight receipt is missing")
    expected_preflight_receipt["created_at_utc"] = preflight_receipt.get("created_at_utc")
    _need(preflight_receipt == expected_preflight_receipt and
          component_receipts["julia"].get("noinstall_preflight") == preflight_receipt,
          "G7 no-install preflight receipt pointers or component binding differ from retained evidence")
    julia_launcher = Path(receipt["runtime_expected"]["julia_executable"]).resolve()
    julia_version = receipt["runtime_expected"]["julia"].removeprefix("julia version ")
    try:
        host_identity = adapter._probe_julia_host_identity(
            julia_launcher, expected_version=julia_version)
    except (OSError, ValueError, RuntimeError) as error:
        raise ReceiptError(f"G7 pinned Julia host identity probe failed: {error}") from error
    expected_preflight = {
        "freeze_sha256": receipt["freeze_sha256"], "runner_sha256": receipt["runner_sha256"],
        "driver_sha256": driver_hash,
        "sandbox": {"project_path": str(Path(sandbox["project_path"]).resolve()),
                    "project_sha256": sandbox["project_sha256"],
                    "manifest_path": str(Path(sandbox["manifest_path"]).resolve()),
                    "manifest_sha256": sandbox["manifest_sha256"]},
        "source_root": str(adapter.JULIA_ROOT.resolve()),
        "source_files": dict(frozen_files["julia"]),
        "load_path": expected_julia_env["JULIA_LOAD_PATH"].split(os.pathsep),
        "depot_path": expected_julia_env["JULIA_DEPOT_PATH"].split(os.pathsep),
        "julia_executable": str(julia_launcher),
        "julia_launcher_sha256": sha256_file(julia_launcher),
        "julia_version": julia_version,
        "julia_runtime_executable": host_identity["julia_runtime_executable"],
        "julia_runtime_executable_sha256": host_identity["julia_runtime_executable_sha256"],
        "host_identity": host_identity,
    }
    before_report = _validate_retained_preflight_snapshot(
        before_preflight, before_sha, expected_preflight, adapter)
    after_report = _validate_retained_preflight_snapshot(
        after_preflight, after_sha, expected_preflight, adapter)
    _need(before_report.get("canonical_sha256") == marker_values["ARC1_NO_INSTALL_PREFLIGHT_CANONICAL_SHA256"] and
          after_report.get("canonical_sha256") == marker_values["ARC1_NO_INSTALL_PREFLIGHT_CANONICAL_SHA256"] and
          before_report.get("canonical_sha256") == after_report.get("canonical_sha256"),
          "G7 before/after no-install preflight reports do not share the logged canonical identity")
    before_substantive = {key: value for key, value in before_report.items()
                          if key not in {"created_at_utc", "canonical_sha256"}}
    after_substantive = {key: value for key, value in after_report.items()
                         if key not in {"created_at_utc", "canonical_sha256"}}
    _need(before_substantive == after_substantive,
          "G7 before/after no-install preflight substantive reports differ")
    _need(before_report.get("created_at_utc") == preflight_receipt.get("created_at_utc") and
          _canonical_preflight_sha256(before_preflight) == before_report.get("canonical_sha256") and
          _canonical_preflight_sha256(after_preflight) == after_report.get("canonical_sha256"),
          "G7 no-install preflight canonical digest or recorded timestamp is invalid")
    bootstrap_spec = freeze.get("julia_call_bootstrap")
    bootstrap_dir = _safe_directory(run_dir, "julia-call-bootstrap", "G7 JuliaCall bootstrap copy")
    bootstrap_hashes = {name: sha256_file(_safe_artifact(bootstrap_dir, name, f"G7 bootstrap {name}"))
                        for name in ("Project.toml", "Manifest.toml")}
    expected_bootstrap = {"Project.toml": bootstrap_spec["project_sha256"],
                          "Manifest.toml": bootstrap_spec["manifest_sha256"]}
    _need(bootstrap_hashes == expected_bootstrap and
          receipt.get("julia_call_bootstrap_run") == {"path": str(bootstrap_dir),
                                                      "initial_sha256": expected_bootstrap},
          "G7 JuliaCall bootstrap copy or receipt differs from the reviewed environment")
    for name, command_name, log_key, hash_key in (
        ("julia", "julia-direct-test-suite", "log", "log_sha256"),
        ("r", "r-arc1-mandatory-live", "live_log", "live_log_sha256"),
        ("docs", "julia-local-docs", "log", "log_sha256"),
    ):
        component = component_receipts[name]
        _need(component.get(log_key) == logs[command_name]["record"].get("log") and
              component.get(hash_key) == logs[command_name]["record"].get("log_sha256"),
              f"G7 {name} component log does not bind to its command record")

    live = logs["r-arc1-mandatory-live"]
    _need("ARC1_TESTTHAT_COUNTS " in live["output"], "G7 mandatory-live R log lacks the count marker")
    r_csv = _hash_artifact(run_dir, "arc1-live-results.csv", receipt.get("r_live_result_sha256", {}).get("csv"),
                           "G7 mandatory-live R CSV")
    _hash_artifact(run_dir, "arc1-live-results.rds", receipt.get("r_live_result_sha256", {}).get("rds"),
                   "G7 mandatory-live RDS")
    _parse_csv_results(r_csv, "G7 mandatory-live R CSV")
    check = logs["r-cmd-check"]
    _need("ARC1_PACKAGE_R_CHECK_COMPONENT_PASS" in check["output"], "G7 R CMD check log lacks its marker")
    check_meta = component_receipts["r"]
    check_log = _hash_artifact(run_dir, check_meta.get("check_log"), check_meta.get("check_log_sha256"),
                               "G7 R CMD check log")
    _need(sha256_file(_safe_artifact(run_dir, "r-check/hsquared.Rcheck/00check.log",
                                    "G7 R CMD check Status log")) == receipt.get("r_check_log_sha256"),
          "G7 R CMD check Status log hash differs from top-level receipt")
    # The package runner stores the actual R CMD check tree under this fixed path.
    status_log = _safe_artifact(run_dir, "r-check/hsquared.Rcheck/00check.log", "G7 R check Status log")
    _need("Status: OK" in status_log.read_text(encoding="utf-8", errors="replace").splitlines(),
          "G7 R CMD check did not retain exact Status: OK")
    result_path = _safe_artifact(run_dir, "r-check-result.json", "G7 R check result JSON")
    _need(sha256_file(result_path) == receipt.get("r_result_sha256") == check_meta.get("result_sha256"),
          "G7 R check result JSON hash differs from retained receipt")
    try:
        check_result = json.loads(result_path.read_text(encoding="utf-8"))
    except (UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise ReceiptError(f"G7 R check result JSON is invalid: {exc}") from exc
    _need(check_result == {"errors": 0, "warnings": 0, "notes": 0, "status_ok": True},
          "G7 R CMD check result does not have exact clean counts")
    _need(adapter.tree_hash(run_dir / "r-check") == receipt.get("r_check_tree_sha256") ==
          check_meta.get("check_tree_sha256"), "G7 R CMD check retained tree hash differs")

    docs = logs["julia-local-docs"]
    _need("ARC1_PACKAGE_DOCS_HTML_BUILT" in docs["output"] and
          "ARC1_PACKAGE_DOCS_COMPONENT_PASS" in docs["output"], "G7 docs log lacks HTML and success markers")
    docs_meta = component_receipts["docs"]
    docs_log = _hash_artifact(run_dir, docs_meta.get("log"), docs_meta.get("log_sha256"), "G7 docs log")
    _need(docs_log == docs["log"], "G7 docs component log does not match its command")
    script = _hash_artifact(run_dir, docs_meta.get("script"), docs_meta.get("script_sha256"), "G7 docs script")
    _need(script.name == "local-docs-make.jl", "G7 docs script path is unexpected")
    docs_source = (Path(adapter.JULIA_ROOT) / "docs" / "make.jl").read_text(encoding="utf-8")
    frontend_spec = freeze["docs_frontend"]
    expected_script = adapter.make_local_docs_script(
        docs_source, repo=Path(adapter.JULIA_ROOT), scratch_docs=run_dir / "scratch-docs",
        output_docs=run_dir / "scratch-docs", redirect_probe=run_dir / "legacy-redirect-contract",
        frontend=frontend_spec)
    _need(script.read_text(encoding="utf-8") == expected_script,
          "G7 executed docs script differs from a fresh pure derivation from frozen inputs")
    output_tree = _safe_directory(run_dir, "scratch-docs/build", "G7 rendered docs tree")
    _need(adapter.tree_hash(output_tree) == receipt.get("docs_output_tree_hash") ==
          docs_meta.get("output_tree_sha256"), "G7 rendered docs tree hash differs")
    pages = receipt.get("docs_rendered_status_pages")
    _need(isinstance(pages, list) and pages, "G7 receipt has no rendered status-page proof")
    page = _hash_artifact(output_tree, pages[0].get("path"), pages[0].get("sha256"), "G7 rendered status HTML")
    _need(page.name == "validation-status.html" and
          "Validation Status" in page.read_text(encoding="utf-8", errors="replace"),
          "G7 docs HTML output is absent or missing its expected page content")
    _need(receipt.get("docs_source_status_sha256") == frozen_files["julia"].get("docs/src/validation-status.md"),
          "G7 source status page identity differs from the frozen source")
    _need(receipt.get("docs_environment_after_sha256") == receipt.get("docs_environment_sha256"),
          "G7 docs environment changed during build")
    for filename, digest in receipt["docs_environment_sha256"].items():
        _hash_artifact(run_dir, f"docs-environment/{filename}", digest, f"G7 docs environment {filename}")
    frontend_expected = receipt.get("docs_frontend_expected")
    frontend_scratch = receipt.get("docs_frontend_scratch_sha256")
    frontend_fields = ("package_json_sha256", "package_lock_sha256", "node_modules_tree_sha256")
    frontend_identity = freeze.get("docs_frontend", {})
    frontend_frozen = {key: frontend_identity.get(key) for key in
                       (*frontend_fields, "node_version", "npm_version")}
    frontend_receipt = {key: frontend_expected.get(key) for key in
                        (*frontend_fields, "node_version", "npm_version")} \
        if isinstance(frontend_expected, dict) else None
    _need(frontend_frozen == frontend_receipt and isinstance(frontend_scratch, dict) and
          {key: frontend_expected.get(key) for key in frontend_fields} == frontend_scratch,
          "G7 scratch docs frontend differs from the reviewed frontend")
    scratch_docs = run_dir / "scratch-docs"
    for name, key in (("package.json", "package_json_sha256"),
                      ("package-lock.json", "package_lock_sha256")):
        _need(sha256_file(_safe_artifact(run_dir, f"scratch-docs/{name}", f"G7 scratch {name}")) ==
              frontend_scratch.get(key), f"G7 scratch {name} bytes differ from the reviewed frontend")
    _need(adapter.frontend_tree_hash(scratch_docs / "node_modules") ==
          frontend_scratch.get("node_modules_tree_sha256"),
          "G7 scratch node_modules tree differs from the reviewed frontend")


def verify_retained(gate: str, receipt_path: Path, receipt_sha256: str, freeze_path: Path,
                    freeze_sha256: str, *, adapter: Any | None = None,
                    artifact_kind: str | None = None) -> str:
    gate = gate.upper()
    _need(gate in {"G1", "G6", "G7"}, "supported gates are G1, G6, and G7")
    receipt = _load_json(receipt_path, receipt_sha256, "retained run receipt")
    _need(receipt.get("status") == "passed", "retained run did not finish with status=passed")
    schema = receipt.get("schema")
    inferred = "oracle" if schema == ORACLE_RUN_SCHEMA else "package" if schema == PACKAGE_RUN_SCHEMA else None
    artifact_kind = artifact_kind or inferred
    _need(artifact_kind in {"oracle", "package"} and inferred == artifact_kind,
          "receipt schema does not match a supported retained runner")
    if gate == "G1":
        _need(artifact_kind == "oracle" and receipt.get("gate") == "g1", "G1 requires a passed G1 oracle receipt")
    if gate == "G7":
        _need(artifact_kind == "package" and receipt.get("gate_selection") == "all",
              "G7 requires a passed all-components package receipt")
    if gate == "G6":
        _need((artifact_kind == "oracle" and receipt.get("gate") == "g6") or
              (artifact_kind == "package" and receipt.get("gate_selection") == "all"),
              "G6 requires a passed G6 oracle receipt or a passed all-components package receipt")

    adapter = adapter or _load_adapters(gate, artifact_kind)
    freeze = _load_json(freeze_path, freeze_sha256, "reviewed source freeze")
    evidence_root = getattr(adapter, "EVIDENCE_ROOT", getattr(adapter, "RUNS_ROOT", None))
    _need(evidence_root is not None and not _within(freeze_path, evidence_root),
          "reviewed freeze must be external to runner evidence")
    _validate_external_review(freeze, adapter, artifact_kind)
    freeze["_path"] = str(freeze_path)
    freeze["_sha256"] = freeze_sha256
    frozen_files = _inventory(adapter, freeze, gate, artifact_kind)
    if artifact_kind == "oracle":
        _need(_within(receipt_path, adapter.RUNS_ROOT), "oracle receipt is outside the retained runs directory")
        _need(receipt.get("run_id") == receipt_path.parent.name, "oracle receipt is not bound to its run directory")
        run_dir = receipt_path.parent.resolve()
        _verify_oracle(gate, receipt, run_dir, freeze, adapter, frozen_files)
    else:
        _need(_within(receipt_path, adapter.EVIDENCE_ROOT), "package receipt is outside the retained evidence directory")
        run_dir = receipt_path.parent.resolve()
        _verify_package(gate, receipt, run_dir, freeze, adapter, frozen_files)
    return {"G1": "ARC1_G1_RETAINED_RECEIPT_VERIFIED",
            "G6": "ARC1_G6_RETAINED_RECEIPT_VERIFIED",
            "G7": "ARC1_G7_RETAINED_RECEIPT_VERIFIED"}[gate]


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--gate", choices=("G1", "G6", "G7"), required=True)
    parser.add_argument("--receipt", type=Path, required=True)
    parser.add_argument("--receipt-sha256", required=True,
                        help="independently reviewed exact hash of the retained run.json")
    parser.add_argument("--freeze", type=Path, required=True,
                        help="absolute externally reviewed runner freeze")
    parser.add_argument("--freeze-sha256", required=True,
                        help="independently reviewed exact hash of the runner freeze")
    args = parser.parse_args(argv)
    try:
        marker = verify_retained(args.gate, args.receipt, args.receipt_sha256,
                                 args.freeze, args.freeze_sha256)
    except Exception as exc:
        print(f"ARC1_RETAINED_RECEIPT_REFUSED gate={args.gate}: {exc}", file=sys.stderr)
        return 1
    print(marker)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
