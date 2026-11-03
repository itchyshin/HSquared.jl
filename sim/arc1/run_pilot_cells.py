#!/usr/bin/env python3
"""Plan or explicitly launch the eight remaining FA-rank pilot cells.

Planning validates source-bound per-cell admissions and never starts Julia.
Execution additionally requires a separate owner authorization bound to the
batch, paths, and measured pre-run receipt. Each admitted outer uses the
existing single-attempt runner with one Julia thread and one BLAS thread.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import importlib
import json
import math
import os
import signal
import subprocess
import sys
import tempfile
import threading
import time
from pathlib import Path
from typing import Any, Callable

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
ENGINE_ROOT = ROOT.resolve()
_ENGINE_IMPORT_PATHS: list[str] = []
manifest: Any
runner: Any


def configure_source_root(source_root: Path) -> None:
    """Load the runner and manifest from the explicitly selected engine tree."""
    global ENGINE_ROOT, manifest, runner, _ENGINE_IMPORT_PATHS
    root = source_root.expanduser().resolve()
    manifest_path = root / "tools/arc1_manifest.py"
    runner_path = root / "sim/arc1/runner.py"
    if (not manifest_path.is_file() or not runner_path.is_file() or
            not (root / "sim/arc1/run_cell.py").is_file()):
        raise ValueError("source root must contain the Arc 1 manifest, runner, and cell entry point")
    for name in ("runner", "arc1_manifest"):
        sys.modules.pop(name, None)
    if _ENGINE_IMPORT_PATHS:
        sys.path[:] = [entry for entry in sys.path if entry not in _ENGINE_IMPORT_PATHS]
    _ENGINE_IMPORT_PATHS = [str(root / "tools"), str(root / "sim/arc1")]
    sys.path[:0] = _ENGINE_IMPORT_PATHS
    importlib.invalidate_caches()
    loaded_manifest = importlib.import_module("arc1_manifest")
    loaded_runner = importlib.import_module("runner")
    if (Path(loaded_manifest.__file__).resolve() != manifest_path.resolve() or
            Path(loaded_runner.__file__).resolve() != runner_path.resolve() or
            getattr(loaded_runner, "manifest", None) is not loaded_manifest):
        raise RuntimeError("engine modules did not load from the selected source root")
    ENGINE_ROOT = root
    manifest = loaded_manifest
    runner = loaded_runner


configure_source_root(ROOT)

BATCH_SCHEMA = "arc1-fa-rank-eight-pilot-batch-v1"
PLAN_SCHEMA = "arc1-fa-rank-eight-pilot-plan-v1"
AUTHORIZATION_SCHEMA = "arc1-fa-rank-eight-pilot-execution-authorization-v1"
PRERUN_SCHEMA = "arc1-fa-rank-pilot-prerun-v1"
ATTEMPT_HISTORY_SCHEMA = "arc1-consumed-attempt-history-v1"
ATTEMPT_HISTORY_REVIEW_SCHEMA = "arc1-consumed-attempt-history-review-v1"
ATTEMPT_ROOT_INVENTORY_SCHEMA = "arc1-retained-attempt-root-inventory-v1"
ATTEMPT_HISTORY_SCOPE = "all-retained-arc1-attempt-records"
EXECUTION_SCOPE = "all-eight-unrun-fa-rank-pilot-cells"
OWNER_APPROVAL_TEXT = "I approve execution of all eight FA-rank pilot cells bound by this plan."
ESTIMATION_METHOD = "per-cell maximum successful attempt time x 30; Graham list-scheduling bound using admitted workers"
JULIA_THREADS = 1
BLAS_THREADS = 1
MAX_CELL_WORKERS = 4
ALLOWED_OUTPUT_ROOT_ENV = "HSQ_ARC1_ALLOWED_OUTPUT_ROOT"
_CHILDREN_LOCK = threading.Lock()
_CHILDREN: dict[int, subprocess.Popen[str]] = {}
_CANCEL = threading.Event()


def cell_key(cell: dict[str, Any]) -> tuple[str, str, int, str]:
    return (cell.get("programme"), cell.get("phase"), cell.get("N"), cell.get("signal"))


def required_cells() -> list[dict[str, Any]]:
    """The eight cells left after the consumed N80/null pilot cell."""
    return [
        {"programme": "fa_rank", "phase": "pilot", "N": n, "signal": signal}
        for n in (80, 160, 320)
        for signal in ("null", "weak", "strong")
        if (n, signal) != (80, "null")
    ]


def _canonical_sha256(value: Any) -> str:
    payload = json.dumps(value, sort_keys=True, separators=(",", ":"),
                         ensure_ascii=False, allow_nan=False).encode("utf-8")
    return hashlib.sha256(payload).hexdigest()


def _validate_output_root(output_root: Path) -> Path:
    """Keep result files in scratch/evidence roots, never inside a checkout."""
    output = output_root.expanduser().resolve()
    allowed_roots = {Path(tempfile.gettempdir()).resolve(), Path("/private/tmp").resolve()}
    configured = os.environ.get(ALLOWED_OUTPUT_ROOT_ENV)
    if configured:
        configured_root = Path(configured).expanduser()
        if not configured_root.is_absolute() or not configured_root.is_dir():
            raise ValueError(f"{ALLOWED_OUTPUT_ROOT_ENV} must name an existing absolute directory")
        allowed_roots.add(configured_root.resolve())
    if not any(output == root or output.is_relative_to(root) for root in allowed_roots):
        raise ValueError(f"result root must be beneath a temp directory, /private/tmp, or {ALLOWED_OUTPUT_ROOT_ENV}")
    for ancestor in (output, *output.parents):
        if os.path.lexists(ancestor / ".git"):
            raise ValueError(f"result root is inside a Git checkout: {ancestor}")
    return output


def validate_batch(batch: dict[str, Any], *, source_root: Path,
                   verify_admission: Callable[..., None] | None = None) -> dict[str, Any]:
    """Validate the exact eight-cell allocation without starting any process."""
    if batch.get("schema") != BATCH_SCHEMA:
        raise ValueError(f"batch schema must be {BATCH_SCHEMA}")
    jobs = batch.get("jobs")
    if not isinstance(jobs, list) or len(jobs) != 8:
        raise ValueError("batch must contain the exact eight unrun FA-rank pilot cells")
    attempt_history = batch.get("consumed_attempt_history")
    consumed_seeds = _load_consumed_attempt_history(attempt_history)
    expected = {cell_key(cell): cell for cell in required_cells()}
    seen: set[tuple[str, str, int, str]] = set()
    allocated_seeds: set[int] = set()
    validated: list[dict[str, Any]] = []
    root = source_root.resolve()
    check = verify_admission or manifest.verify_run_admission
    for job in jobs:
        if not isinstance(job, dict) or not isinstance(job.get("cell"), dict):
            raise ValueError("each batch job must pin a cell")
        cell = job["cell"]
        key = cell_key(cell)
        if key not in expected or cell != expected[key] or key in seen:
            raise ValueError("batch must contain the exact eight unrun FA-rank pilot cells once each")
        seen.add(key)
        admission = job.get("admission")
        admission_path_raw = job.get("admission_path")
        if not isinstance(admission, dict) or not isinstance(admission_path_raw, str) or not admission_path_raw:
            raise ValueError("each cell requires an embedded admission and its retained JSON path")
        admission_path = Path(admission_path_raw).expanduser().resolve()
        if not admission_path.is_file():
            raise ValueError(f"admission file is missing: {admission_path}")
        on_disk = json.loads(admission_path.read_text(encoding="utf-8"))
        if on_disk != admission:
            raise ValueError("embedded admission differs from the retained admission file")
        if admission.get("schema") != "arc1-run-admission-v2" or admission.get("cell") != cell:
            raise ValueError("cell admission schema or cell identity differs from the batch")
        if admission.get("single_attempt_review_scope") is not None:
            raise ValueError("single-attempt review scope is incompatible with the full pilot batch")
        if admission.get("status") != "admitted_before_execution":
            raise ValueError("cell admission is not marked admitted before execution")
        if admission.get("planned_attempts") != 30:
            raise ValueError("each pilot cell admission must contain all 30 planned attempts")
        seeds = admission.get("expected_outer_seeds")
        if (not isinstance(seeds, list) or len(seeds) != 30 or
                any(type(seed) is not int or not 0 <= seed < 2**64 for seed in seeds) or
                len(set(seeds)) != 30):
            raise ValueError("each cell must retain 30 distinct UInt64 outer seeds")
        if any(seed in consumed_seeds for seed in seeds):
            raise ValueError("admitted outer seed already appears in reviewed Arc 1 history")
        if allocated_seeds.intersection(seeds):
            raise ValueError("outer seed allocation is duplicated across pilot cells")
        allocated_seeds.update(seeds)
        if admission.get("threads") != {"julia": JULIA_THREADS, "blas": BLAS_THREADS}:
            raise ValueError("each admission must pin Julia and BLAS to one thread")
        if admission.get("thread_environment") != {
                "JULIA_NUM_THREADS": "1", "OPENBLAS_NUM_THREADS": "1"}:
            raise ValueError("each admission must pin the one-thread environment")
        if admission.get("julia_version") != "1.10.0":
            raise ValueError("each admission must pin Julia 1.10.0")
        check(root, admission, julia_version="1.10.0",
              julia_threads=JULIA_THREADS, blas_threads=BLAS_THREADS)
        validated.append({"cell": dict(cell), "admission_path": str(admission_path),
                          "admission_sha256": _canonical_sha256(admission),
                          "threads": {"julia": JULIA_THREADS, "blas": BLAS_THREADS},
                          "admission": admission})
    if seen != set(expected):
        raise ValueError("batch must contain the exact eight unrun FA-rank pilot cells")
    source_locks = [item["admission"].get("source_sha256") for item in validated]
    if (any(not isinstance(lock, dict) or not lock for lock in source_locks) or
            len({_canonical_sha256(lock) for lock in source_locks}) != 1):
        raise ValueError("all eight admissions must share one complete source lock")
    source_lock_sha256 = _canonical_sha256(source_locks[0])
    return {"schema": BATCH_SCHEMA, "jobs": validated, "planned_attempts": 240,
            "julia_threads_per_job": JULIA_THREADS,
            "blas_threads_per_job": BLAS_THREADS,
            "maximum_concurrent_cell_workers": MAX_CELL_WORKERS,
            "source_lock_sha256": source_lock_sha256,
            "consumed_attempt_history": dict(attempt_history)}


def make_plan(batch: dict[str, Any], *, source_root: Path,
              output_root: Path,
              verify_admission: Callable[..., None] | None = None) -> dict[str, Any]:
    source = source_root.resolve()
    output = output_root.expanduser().resolve()
    if source != ENGINE_ROOT:
        raise ValueError("source root differs from the engine modules loaded by this launcher")
    if source == output or source.is_relative_to(output) or output.is_relative_to(source):
        raise ValueError("source and result roots must be disjoint")
    output = _validate_output_root(output)
    validated = validate_batch(batch, source_root=source,
                               verify_admission=verify_admission)
    source_lock_sha256 = validated["source_lock_sha256"]
    jobs = []
    for item in validated["jobs"]:
        cell = item["cell"]
        jobs.append({"cell": cell, "admission_path": item["admission_path"],
                     "admission_sha256": item["admission_sha256"],
                     "source_lock_sha256": source_lock_sha256,
                     "expected_outer_seeds": item["admission"]["expected_outer_seeds"],
                     "output_dir": str(runner.cell_output_dir(output, cell)),
                     "outers": list(range(1, 31)), "threads": {"julia": 1, "blas": 1}})
    plan = {"schema": PLAN_SCHEMA, "scope": EXECUTION_SCOPE,
            "batch_sha256": _canonical_sha256(batch),
            "source_lock_sha256": source_lock_sha256,
            "consumed_attempt_history": validated["consumed_attempt_history"],
            "source_root": str(source), "output_root": str(output),
            "launcher_sha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            "jobs": jobs, "planned_cells": 8, "planned_attempts": 240,
            "maximum_concurrent_cell_workers": MAX_CELL_WORKERS,
            "julia_threads_per_job": 1, "blas_threads_per_job": 1,
            "execution_started": False}
    plan["plan_sha256"] = _canonical_sha256(plan)
    return plan


def execution_authorized(auth: dict[str, Any] | None, plan: dict[str, Any]) -> bool:
    """Require owner authorization bound to a measured, plan-matched pre-run."""
    if not isinstance(auth, dict) or not isinstance(plan, dict):
        return False
    digest = auth.get("pre_run_receipt_sha256")
    valid_digest = (isinstance(digest, str) and len(digest) == 64 and
                    all(char in "0123456789abcdef" for char in digest))
    estimate = auth.get("estimated_total_seconds")
    approved = auth.get("owner_approved_total_seconds")
    plan_body = {key: value for key, value in plan.items() if key != "plan_sha256"}
    plan_digest_matches = plan.get("plan_sha256") == _canonical_sha256(plan_body)
    receipt_path = auth.get("pre_run_receipt_path")
    try:
        receipt_file = Path(receipt_path).expanduser() if isinstance(receipt_path, str) else None
        receipt_bytes = (receipt_file.read_bytes()
                         if receipt_file is not None and receipt_file.is_absolute() else None)
        receipt_matches = bool(receipt_bytes is not None and
                               hashlib.sha256(receipt_bytes).hexdigest() == digest)
        receipt = json.loads(receipt_bytes) if receipt_matches else None
    except (OSError, json.JSONDecodeError, UnicodeDecodeError):
        receipt_matches, receipt = False, None
    receipt_estimate = (_measured_prerun_estimate(receipt, plan)
                        if isinstance(receipt, dict) else None)
    return bool(
        plan_digest_matches and _plan_contract_valid(plan) and
        receipt_matches and receipt_estimate is not None and
        receipt.get("schema") == PRERUN_SCHEMA and
        receipt.get("status") == "complete" and
        receipt.get("plan_sha256") == plan.get("plan_sha256") and
        receipt.get("batch_sha256") == plan.get("batch_sha256") and
        receipt.get("source_root") == plan.get("source_root") and
        receipt.get("output_root") == plan.get("output_root") and
        receipt.get("estimation_method") == ESTIMATION_METHOD and
        receipt.get("estimated_total_seconds") == receipt_estimate and
        auth.get("schema") == AUTHORIZATION_SCHEMA and
        auth.get("scope") == EXECUTION_SCOPE and
        auth.get("approval") == OWNER_APPROVAL_TEXT and
        auth.get("plan_sha256") == plan.get("plan_sha256") and
        auth.get("batch_sha256") == plan.get("batch_sha256") and
        auth.get("source_root") == plan.get("source_root") and
        auth.get("output_root") == plan.get("output_root") and
        auth.get("approved_by_owner") is True and valid_digest and receipt_matches and
        type(estimate) in (int, float) and estimate > 0 and
        math.isfinite(float(estimate)) and type(approved) in (int, float) and
        math.isfinite(float(approved)) and approved >= estimate and
        estimate == receipt_estimate)


def _load_verified_admission(job: dict[str, Any]) -> dict[str, Any]:
    path = Path(job["admission_path"])
    admission = json.loads(path.read_text(encoding="utf-8"))
    if _canonical_sha256(admission) != job["admission_sha256"]:
        raise ValueError("admission changed after the plan was created")
    manifest.verify_run_admission(ENGINE_ROOT, admission, julia_version="1.10.0",
                                  julia_threads=JULIA_THREADS, blas_threads=BLAS_THREADS)
    if (admission.get("schema") != "arc1-run-admission-v2" or
            admission.get("cell") != job.get("cell") or
            admission.get("planned_attempts") != 30 or
            admission.get("expected_outer_seeds") != job.get("expected_outer_seeds")):
        raise ValueError("admission contents differ from the planned cell and seed allocation")
    return admission


def _plan_contract_valid(plan: dict[str, Any]) -> bool:
    """Reject hand-built or stale plans before considering execution approval."""
    output_raw = plan.get("output_root")
    source_raw = plan.get("source_root")
    jobs = plan.get("jobs")
    if (plan.get("schema") != PLAN_SCHEMA or plan.get("scope") != EXECUTION_SCOPE or
            source_raw != str(ENGINE_ROOT) or not isinstance(output_raw, str) or
            not Path(output_raw).is_absolute() or
            plan.get("planned_cells") != 8 or plan.get("planned_attempts") != 240 or
            plan.get("maximum_concurrent_cell_workers") != MAX_CELL_WORKERS or
            plan.get("julia_threads_per_job") != 1 or plan.get("blas_threads_per_job") != 1 or
            plan.get("launcher_sha256") != hashlib.sha256(Path(__file__).read_bytes()).hexdigest() or
            not _is_sha256(plan.get("batch_sha256")) or
            not _is_sha256(plan.get("source_lock_sha256")) or
            not isinstance(jobs, list) or len(jobs) != 8):
        return False
    try:
        output = _validate_output_root(Path(output_raw))
    except (OSError, TypeError, ValueError):
        return False
    source = Path(source_raw).resolve()
    if (str(output) != output_raw or
            source == output or source.is_relative_to(output) or output.is_relative_to(source)):
        return False
    expected = {cell_key(cell): cell for cell in required_cells()}
    seen: set[tuple[str, str, int, str]] = set()
    allocated_seeds: set[int] = set()
    try:
        consumed_seeds = _load_consumed_attempt_history(
            plan.get("consumed_attempt_history"))
    except (OSError, TypeError, ValueError):
        return False
    for job in jobs:
        if not isinstance(job, dict) or not isinstance(job.get("cell"), dict):
            return False
        cell = job["cell"]
        key = cell_key(cell)
        seeds = job.get("expected_outer_seeds")
        admission_path = job.get("admission_path")
        if (key not in expected or cell != expected[key] or key in seen or
                not isinstance(seeds, list) or len(seeds) != 30 or
                any(type(seed) is not int or not 0 <= seed < 2**64 for seed in seeds) or
                len(set(seeds)) != 30 or
                not _is_sha256(job.get("admission_sha256")) or
                job.get("source_lock_sha256") != plan.get("source_lock_sha256") or
                not isinstance(admission_path, str) or not Path(admission_path).is_absolute() or
                job.get("outers") != list(range(1, 31)) or
                job.get("threads") != {"julia": 1, "blas": 1} or
                job.get("output_dir") != str(runner.cell_output_dir(output, cell))):
            return False
        if consumed_seeds.intersection(seeds) or allocated_seeds.intersection(seeds):
            return False
        allocated_seeds.update(seeds)
        try:
            admission = _load_verified_admission(job)
            source_hashes = admission.get("source_sha256")
            if (not isinstance(source_hashes, dict) or not source_hashes or
                    _canonical_sha256(source_hashes) != plan["source_lock_sha256"]):
                return False
        except Exception:
            return False
        seen.add(key)
    return seen == set(expected)


def _is_sha256(value: Any) -> bool:
    return isinstance(value, str) and len(value) == 64 and all(
        char in "0123456789abcdef" for char in value)


def _load_consumed_attempt_history(reference: Any) -> set[int]:
    """Load a hash-pinned attempt history and independently reviewed root inventory."""
    if not isinstance(reference, dict):
        raise ValueError("a reviewed complete consumed-attempt history is required")
    history_path_raw = reference.get("history_path")
    review_path_raw = reference.get("review_path")
    history_sha = reference.get("history_sha256")
    review_sha = reference.get("review_sha256")
    if (not isinstance(history_path_raw, str) or not Path(history_path_raw).is_absolute() or
            not isinstance(review_path_raw, str) or not Path(review_path_raw).is_absolute() or
            not _is_sha256(history_sha) or not _is_sha256(review_sha)):
        raise ValueError("attempt history and review must be absolute, hash-pinned files")
    history_path = Path(history_path_raw)
    review_path = Path(review_path_raw)
    try:
        history_bytes = history_path.read_bytes()
        review_bytes = review_path.read_bytes()
        history = json.loads(history_bytes)
        review = json.loads(review_bytes)
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError("attempt history or review receipt is unreadable") from error
    if (hashlib.sha256(history_bytes).hexdigest() != history_sha or
            hashlib.sha256(review_bytes).hexdigest() != review_sha):
        raise ValueError("attempt history or review hash mismatch")
    if (not isinstance(history, dict) or
            history.get("schema") != ATTEMPT_HISTORY_SCHEMA or
            history.get("scope") != ATTEMPT_HISTORY_SCOPE or
            history.get("status") != "complete"):
        raise ValueError("attempt history scope or status is incomplete")
    attempts = history.get("attempts")
    sources = history.get("sources")
    inventory_path_raw = history.get("root_inventory_path")
    inventory_sha = history.get("root_inventory_sha256")
    if (not isinstance(attempts, list) or not attempts or
            not isinstance(sources, dict) or not sources or
            not isinstance(inventory_path_raw, str) or
            not Path(inventory_path_raw).is_absolute() or not _is_sha256(inventory_sha)):
        raise ValueError("attempt history lacks attempts, source pins, or root inventory")
    source_payloads: dict[str, bytes] = {}
    for source_path_raw, source_sha in sources.items():
        if (not isinstance(source_path_raw, str) or not Path(source_path_raw).is_absolute() or
                not _is_sha256(source_sha)):
            raise ValueError("attempt history source map is malformed")
        try:
            source_bytes = Path(source_path_raw).read_bytes()
        except OSError as error:
            raise ValueError("attempt history source is unreadable") from error
        actual_sha = hashlib.sha256(source_bytes).hexdigest()
        if actual_sha != source_sha:
            raise ValueError("attempt history source hash mismatch")
        source_payloads[source_path_raw] = source_bytes
    try:
        inventory_bytes = Path(inventory_path_raw).read_bytes()
        inventory = json.loads(inventory_bytes)
    except (OSError, json.JSONDecodeError) as error:
        raise ValueError("retained attempt root inventory is unreadable") from error
    if hashlib.sha256(inventory_bytes).hexdigest() != inventory_sha:
        raise ValueError("retained attempt root inventory hash mismatch")
    if (not isinstance(inventory, dict) or
            inventory.get("schema") != ATTEMPT_ROOT_INVENTORY_SCHEMA or
            inventory.get("scope") != ATTEMPT_HISTORY_SCOPE or
            inventory.get("status") != "complete"):
        raise ValueError("retained attempt root inventory is not complete")
    inventory_body = {key: value for key, value in inventory.items()
                      if key != "inventory_sha256"}
    if inventory.get("inventory_sha256") != _canonical_sha256(inventory_body):
        raise ValueError("retained attempt root inventory canonical hash mismatch")
    roots = inventory.get("roots")
    root_ids: set[str] = set()
    listed_records: dict[str, dict[str, str]] = {}
    if not isinstance(roots, list) or not roots:
        raise ValueError("retained attempt root inventory is empty")
    for root in roots:
        if (not isinstance(root, dict) or
                not isinstance(root.get("root_id"), str) or not root["root_id"].strip() or
                root["root_id"] in root_ids or
                not isinstance(root.get("path"), str) or not Path(root["path"]).is_absolute() or
                not Path(root["path"]).is_dir() or
                not isinstance(root.get("listing_path"), str) or
                not Path(root["listing_path"]).is_absolute() or
                root.get("status") != "complete" or
                not _is_sha256(root.get("listing_sha256")) or
                sources.get(root["listing_path"]) != root.get("listing_sha256") or
                type(root.get("record_count")) is not int or root["record_count"] < 0 or
                type(root.get("unreadable_count")) is not int or root["unreadable_count"] != 0 or
                type(root.get("unparsed_count")) is not int or root["unparsed_count"] != 0):
            raise ValueError("root inventory contains an incomplete or malformed scan")
        try:
            listing = json.loads(source_payloads[root["listing_path"]])
        except (KeyError, json.JSONDecodeError, UnicodeDecodeError) as error:
            raise ValueError("retained attempt root listing is unreadable") from error
        entries = listing.get("entries") if isinstance(listing, dict) else None
        if (not isinstance(listing, dict) or
                listing.get("schema") != "arc1-retained-attempt-root-listing-v1" or
                listing.get("root_id") != root["root_id"] or
                listing.get("root_path") != root["path"] or
                listing.get("enumeration_complete") is not True or
                not isinstance(entries, list) or len(entries) != root["record_count"]):
            raise ValueError("retained attempt root listing is incomplete or misbound")
        entry_paths: set[str] = set()
        entry_hashes: dict[str, str] = {}
        for entry in entries:
            if (not isinstance(entry, dict) or
                    not isinstance(entry.get("path"), str) or
                    not Path(entry["path"]).is_absolute() or
                    entry["path"] in entry_paths or
                    not _is_sha256(entry.get("sha256")) or
                    sources.get(entry["path"]) != entry.get("sha256")):
                raise ValueError("retained attempt root listing contains an unpinned entry")
            if not Path(entry["path"]).resolve().is_relative_to(Path(root["path"]).resolve()):
                raise ValueError("retained attempt root listing contains a path outside its root")
            entry_paths.add(entry["path"])
            entry_hashes[entry["path"]] = entry["sha256"]
        listed_records[root["root_id"]] = entry_hashes
        root_ids.add(root["root_id"])
    review_matches = (
        isinstance(review, dict) and
        review.get("schema") == ATTEMPT_HISTORY_REVIEW_SCHEMA and
        review.get("status") == "complete" and
        review.get("scope") == ATTEMPT_HISTORY_SCOPE and
        review.get("history_sha256") == history_sha and
        review.get("root_inventory_sha256") == inventory_sha and
        isinstance(review.get("reviewer"), str) and bool(review["reviewer"].strip()) and
        isinstance(review.get("reviewed_at_utc"), str) and bool(review["reviewed_at_utc"].strip()) and
        review.get("independent") is True and review.get("scope_complete") is True and
        type(review.get("attempt_count")) is int and review["attempt_count"] == len(attempts) and
        type(review.get("root_count")) is int and review["root_count"] == len(roots) and
        type(review.get("source_count")) is int and review["source_count"] == len(sources))
    if not review_matches:
        raise ValueError("attempt history lacks independent review of the complete root inventory")
    consumed: set[int] = set()
    for attempt in attempts:
        if (not isinstance(attempt, dict) or
                not isinstance(attempt.get("programme"), str) or not attempt["programme"].strip() or
                not isinstance(attempt.get("phase"), str) or not attempt["phase"].strip() or
                type(attempt.get("N")) is not int or attempt["N"] <= 0 or
                not isinstance(attempt.get("signal"), str) or not attempt["signal"].strip() or
                type(attempt.get("outer")) is not int or attempt["outer"] < 1 or
                type(attempt.get("seed")) is not int or not 0 <= attempt["seed"] < 2**64 or
                not isinstance(attempt.get("status"), str) or not attempt["status"].strip() or
                attempt.get("consumed") is not True or
                attempt.get("root_id") not in root_ids or
                not isinstance(attempt.get("source_path"), str) or
                not Path(attempt["source_path"]).is_absolute() or
                not _is_sha256(attempt.get("source_sha256")) or
                sources.get(attempt["source_path"]) != attempt["source_sha256"] or
                listed_records[attempt["root_id"]].get(attempt["source_path"]) !=
                attempt["source_sha256"]):
            raise ValueError("each retained attempt must be consumed and linked to a scanned root")
        consumed.add(attempt["seed"])
        try:
            source_record = json.loads(source_payloads[attempt["source_path"]])
        except (KeyError, json.JSONDecodeError) as error:
            raise ValueError("retained attempt source record is unreadable") from error
        identity_fields = ("programme", "phase", "N", "signal", "outer", "seed",
                           "status", "consumed")
        if (not isinstance(source_record, dict) or
                any(type(source_record.get(field)) is not type(attempt[field]) or
                    source_record[field] != attempt[field]
                    for field in identity_fields)):
            raise ValueError("attempt history identity differs from its retained source record")
    return consumed


def _measured_prerun_estimate(receipt: dict[str, Any], plan: dict[str, Any]) -> int | None:
    """Validate one successful timed attempt per admitted cell and size the batch."""
    jobs = plan.get("jobs")
    attempts = receipt.get("attempts")
    workers = plan.get("maximum_concurrent_cell_workers")
    if (not isinstance(jobs, list) or len(jobs) != 8 or
            not isinstance(attempts, list) or len(attempts) != 8 or
            type(workers) is not int or not 1 <= workers <= MAX_CELL_WORKERS):
        return None
    jobs_by_key = {cell_key(job.get("cell", {})): job for job in jobs
                   if isinstance(job, dict) and isinstance(job.get("cell"), dict)}
    if len(jobs_by_key) != 8 or set(jobs_by_key) != {cell_key(cell) for cell in required_cells()}:
        return None
    seconds_by_cell: dict[tuple[str, str, int, str], float] = {}
    for row in attempts:
        if not isinstance(row, dict) or not isinstance(row.get("cell"), dict):
            return None
        key = cell_key(row["cell"])
        job = jobs_by_key.get(key)
        outer = row.get("outer")
        elapsed = row.get("elapsed_seconds")
        if (job is None or key in seconds_by_cell or type(outer) is not int or
                not isinstance(job.get("expected_outer_seeds"), list) or
                len(job["expected_outer_seeds"]) != 30 or
                not isinstance(job.get("admission_sha256"), str) or
                not 1 <= outer <= 30 or row.get("seed") != job["expected_outer_seeds"][outer - 1] or
                row.get("admission_sha256") != job["admission_sha256"] or
                row.get("status") != "child_complete" or row.get("success") is not True or
                row.get("returncode") != 0 or type(elapsed) not in (int, float) or
                not math.isfinite(float(elapsed)) or elapsed <= 0):
            return None
        result_path = Path(job["output_dir"]) / "attempts" / f"{outer:04d}.result.json"
        try:
            result_bytes = result_path.read_bytes()
            result = json.loads(result_bytes)
            admission = _load_verified_admission(job)
            child_elapsed = result.get("child_elapsed_seconds") if isinstance(result, dict) else None
            runner_elapsed = result.get("elapsed_seconds") if isinstance(result, dict) else None
            if (not _is_sha256(row.get("runner_result_sha256")) or
                    hashlib.sha256(result_bytes).hexdigest() != row["runner_result_sha256"] or
                    not isinstance(result, dict) or result.get("outer") != outer or
                    result.get("seed") != row["seed"] or
                    result.get("admission_sha256") != job["admission_sha256"] or
                    result.get("status") != "ok" or result.get("success") is not True or
                    not isinstance(result.get("execution_identity"), dict) or
                    type(child_elapsed) not in (int, float) or
                    not math.isfinite(float(child_elapsed)) or child_elapsed <= 0 or
                    type(runner_elapsed) not in (int, float) or
                    not math.isfinite(float(runner_elapsed)) or runner_elapsed <= 0):
                return None
            manifest.verify_execution_identity(ENGINE_ROOT, admission, result["execution_identity"])

            # The launcher measures the full wrapper process; the runner and Julia
            # measure nested intervals. Bind the receipt to the parent record and
            # validate inner durations independently instead of equating clocks.
            launcher_path = (_attempt_record_dir(Path(job["output_dir"])) /
                             f"{outer:04d}.result.json")
            launcher_bytes = launcher_path.read_bytes()
            launcher_result = json.loads(launcher_bytes)
            if (not _is_sha256(row.get("launcher_result_sha256")) or
                    hashlib.sha256(launcher_bytes).hexdigest() != row["launcher_result_sha256"] or
                    not isinstance(launcher_result, dict) or
                    launcher_result.get("outer") != outer or
                    launcher_result.get("seed") != row["seed"] or
                    launcher_result.get("admission_sha256") != job["admission_sha256"] or
                    launcher_result.get("plan_sha256") != plan.get("plan_sha256") or
                    launcher_result.get("batch_sha256") != plan.get("batch_sha256") or
                    launcher_result.get("launcher_sha256") != plan.get("launcher_sha256") or
                    launcher_result.get("status") != "child_complete" or
                    launcher_result.get("success") is not True or
                    launcher_result.get("returncode") != 0 or
                    type(launcher_result.get("elapsed_seconds")) not in (int, float) or
                    not math.isfinite(float(launcher_result["elapsed_seconds"])) or
                    launcher_result["elapsed_seconds"] <= 0 or
                    not math.isclose(float(launcher_result["elapsed_seconds"]), float(elapsed),
                                     rel_tol=0.0, abs_tol=1e-9)):
                return None
        except Exception:
            return None
        seconds_by_cell[key] = float(elapsed)
    if set(seconds_by_cell) != set(jobs_by_key):
        return None
    job_seconds = [30.0 * seconds_by_cell[cell_key(job["cell"])] for job in jobs]
    projected = sum(job_seconds) / workers + ((workers - 1) / workers) * max(job_seconds)
    return math.ceil(projected)


def child_environment(base: dict[str, str]) -> dict[str, str]:
    env = dict(base)
    env.update({"JULIA_NUM_THREADS": "1", "OPENBLAS_NUM_THREADS": "1",
                "OMP_NUM_THREADS": "1", "MKL_NUM_THREADS": "1",
                "BLIS_NUM_THREADS": "1", "VECLIB_MAXIMUM_THREADS": "1"})
    return env


def child_command(*, julia: str, source_root: Path, output_root: Path,
                  admission_path: Path, outer: int, timeout: float = 3600.0) -> list[str]:
    return [sys.executable, str(source_root / "sim/arc1/run_cell.py"),
            "--source-root", str(source_root), "--output-root", str(output_root),
            "--admission", str(admission_path), "--outer", str(outer),
            "--julia", julia, "--julia-threads=1", "--blas-threads=1",
            "--timeout", str(timeout)]


def _atomic_json(path: Path, value: dict[str, Any], *, refuse_existing: bool = False) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(path.name + f".{os.getpid()}.tmp")
    temporary.write_text(json.dumps(value, sort_keys=True, allow_nan=False) + "\n",
                         encoding="utf-8")
    try:
        if refuse_existing:
            os.link(temporary, path)
        else:
            os.replace(temporary, path)
    except FileExistsError as error:
        raise FileExistsError(f"refusing to replace durable launcher record: {path}") from error
    finally:
        temporary.unlink(missing_ok=True)


def _attempt_record_dir(output_dir: Path) -> Path:
    return output_dir / "launcher-attempts"


def _verify_retained_record(path: Path, *, outer: int, seed: int,
                            admission_sha256: str) -> dict[str, Any]:
    row = json.loads(path.read_text(encoding="utf-8"))
    if (row.get("outer") != outer or row.get("seed") != seed or
            row.get("admission_sha256") != admission_sha256):
        raise ValueError(f"retained outer {outer} record differs from the admitted seed partition")
    return row


def _resume_launcher_attempt_is_verified(job: dict[str, Any], launcher_record: dict[str, Any],
                                         *, outer: int, seed: int, plan_sha256: str,
                                         batch_sha256: str, launcher_sha256: str) -> bool:
    """Accept a retained success only when launcher and runner evidence agree."""
    try:
        output_dir = Path(job["output_dir"])
        runner_path = output_dir / "attempts" / f"{outer:04d}.result.json"
        runner_bytes = runner_path.read_bytes()
        runner_record = json.loads(runner_bytes)
        admission = _load_verified_admission(job)
        launcher_elapsed = launcher_record.get("elapsed_seconds")
        runner_elapsed = runner_record.get("elapsed_seconds")
        child_elapsed = runner_record.get("child_elapsed_seconds")
        valid = bool(
            launcher_record.get("plan_sha256") == plan_sha256 and
            launcher_record.get("batch_sha256") == batch_sha256 and
            launcher_record.get("launcher_sha256") == launcher_sha256 and
            type(launcher_elapsed) in (int, float) and
            math.isfinite(float(launcher_elapsed)) and launcher_elapsed > 0 and
            _is_sha256(launcher_record.get("runner_result_sha256")) and
            hashlib.sha256(runner_bytes).hexdigest() == launcher_record["runner_result_sha256"] and
            runner_record.get("outer") == outer and runner_record.get("seed") == seed and
            runner_record.get("admission_sha256") == job["admission_sha256"] and
            runner_record.get("status") == "ok" and runner_record.get("success") is True and
            type(runner_elapsed) in (int, float) and math.isfinite(float(runner_elapsed)) and
            runner_elapsed > 0 and type(child_elapsed) in (int, float) and
            math.isfinite(float(child_elapsed)) and child_elapsed > 0 and
            isinstance(runner_record.get("execution_identity"), dict)
        )
        if not valid:
            return False
        manifest.verify_execution_identity(ENGINE_ROOT, admission, runner_record["execution_identity"])
        return True
    except Exception:
        return False


def _terminate_process_group(process: subprocess.Popen[str], *, grace_seconds: float = 2.0) -> None:
    """Stop a wrapper and any Julia descendants in its isolated process group."""
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    try:
        process.wait(timeout=grace_seconds)
    except subprocess.TimeoutExpired:
        pass
    deadline = time.monotonic() + grace_seconds
    while time.monotonic() < deadline:
        try:
            os.killpg(process.pid, 0)
        except ProcessLookupError:
            break
        time.sleep(0.05)
    else:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    if process.poll() is None:
        process.wait()


def _run_child(command: list[str], *, env: dict[str, str], timeout: float) -> subprocess.CompletedProcess[str]:
    """Run an isolated process group and kill descendants on timeout or interruption."""
    with _CHILDREN_LOCK:
        if _CANCEL.is_set():
            raise InterruptedError("pilot batch cancellation requested before child launch")
        process = subprocess.Popen(command, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                   text=True, encoding="utf-8", errors="replace",
                                   start_new_session=True)
        _CHILDREN[process.pid] = process
    try:
        stdout, stderr = process.communicate(timeout=timeout)
    except BaseException:
        _terminate_process_group(process)
        process.communicate()
        raise
    finally:
        with _CHILDREN_LOCK:
            _CHILDREN.pop(process.pid, None)
    return subprocess.CompletedProcess(command, process.returncode, stdout, stderr)


def _cancel_children(signum: int, _frame: Any) -> None:
    _CANCEL.set()
    with _CHILDREN_LOCK:
        children = list(_CHILDREN.values())
    for process in children:
        _terminate_process_group(process)
    raise KeyboardInterrupt(f"launcher received signal {signum}")


def _execute_cell(job: dict[str, Any], *, source_root: Path, julia: str,
                  output_root: Path, timeout: float, plan_sha256: str,
                  batch_sha256: str, launcher_sha256: str) -> dict[str, Any]:
    output_dir = Path(job["output_dir"])
    record_dir = _attempt_record_dir(output_dir)
    run_records = []
    admission_path = Path(job["admission_path"])
    for outer in job["outers"]:
        if _CANCEL.is_set():
            raise InterruptedError("pilot batch cancellation requested; no later outer was launched")
        final_record = record_dir / f"{outer:04d}.result.json"
        start_record = record_dir / f"{outer:04d}.started.json"
        runner_result = output_dir / "attempts" / f"{outer:04d}.result.json"
        runner_started = output_dir / "attempts" / f"{outer:04d}.started.json"
        seed = job["expected_outer_seeds"][outer - 1]
        if final_record.exists():
            prior = _verify_retained_record(final_record, outer=outer, seed=seed,
                                            admission_sha256=job["admission_sha256"])
            terminal = (prior.get("status") == "child_complete" and
                        prior.get("success") is True and prior.get("returncode") == 0 and
                        _resume_launcher_attempt_is_verified(
                            job, prior, outer=outer, seed=seed,
                            plan_sha256=plan_sha256, batch_sha256=batch_sha256,
                            launcher_sha256=launcher_sha256))
            run_records.append({"outer": outer,
                                "status": "already_recorded" if terminal else "launcher_error_requires_reconciliation",
                                "success": prior.get("success"), "terminal": terminal,
                                "launched": False})
            if not terminal:
                break
            continue
        if runner_result.exists():
            try:
                prior = _verify_retained_record(runner_result, outer=outer, seed=seed,
                                                admission_sha256=job["admission_sha256"])
            except Exception:
                prior = {}
            run_records.append({"outer": outer, "status": "runner_result_requires_reconciliation",
                                "success": prior.get("success"), "terminal": False,
                                "launched": False})
            break
        if start_record.exists() or runner_started.exists():
            if start_record.exists():
                _verify_retained_record(start_record, outer=outer, seed=seed,
                                        admission_sha256=job["admission_sha256"])
            if runner_started.exists():
                _verify_retained_record(runner_started, outer=outer, seed=seed,
                                        admission_sha256=job["admission_sha256"])
            run_records.append({"outer": outer, "status": "started_requires_reconciliation",
                                "terminal": False, "launched": False})
            break
        current_admission = json.loads(admission_path.read_text(encoding="utf-8"))
        if _canonical_sha256(current_admission) != job["admission_sha256"]:
            raise ValueError("cell admission changed after plan creation; refusing to launch")
        _atomic_json(start_record, {"outer": outer, "status": "launcher_started",
                                    "seed": seed,
                                    "admission_sha256": job["admission_sha256"]},
                     refuse_existing=True)
        command = child_command(julia=julia, source_root=source_root,
                                output_root=output_root,
                                admission_path=Path(job["admission_path"]), outer=outer,
                                timeout=timeout)
        child_started = time.monotonic()
        try:
            completed = _run_child(command, env=child_environment(os.environ.copy()),
                                   timeout=timeout + 60.0)
            elapsed = time.monotonic() - child_started
            runner_result_sha256 = None
            if completed.returncode == 0:
                if not runner_result.is_file():
                    raise RuntimeError("child exited zero without a retained runner result")
                runner_result_sha256 = hashlib.sha256(runner_result.read_bytes()).hexdigest()
                candidate = {
                    "outer": outer, "status": "child_complete", "seed": seed,
                    "admission_sha256": job["admission_sha256"],
                    "plan_sha256": plan_sha256, "batch_sha256": batch_sha256,
                    "launcher_sha256": launcher_sha256,
                    "runner_result_sha256": runner_result_sha256,
                    "elapsed_seconds": elapsed, "success": True, "returncode": 0,
                }
                if not _resume_launcher_attempt_is_verified(
                        job, candidate, outer=outer, seed=seed,
                        plan_sha256=plan_sha256, batch_sha256=batch_sha256,
                        launcher_sha256=launcher_sha256):
                    raise RuntimeError("child exited zero but its runner result failed verification")
            result = {"outer": outer, "status": "child_complete",
                      "seed": seed, "admission_sha256": job["admission_sha256"],
                      "plan_sha256": plan_sha256, "batch_sha256": batch_sha256,
                      "launcher_sha256": launcher_sha256,
                      "runner_result_sha256": runner_result_sha256,
                      "elapsed_seconds": elapsed,
                      "success": completed.returncode == 0,
                      "returncode": completed.returncode,
                      "stdout": completed.stdout, "stderr": completed.stderr}
        except Exception as error:
            result = {"outer": outer, "status": "launcher_error", "success": False,
                      "seed": seed, "admission_sha256": job["admission_sha256"],
                      "failure_reason": f"{type(error).__name__}: {error}"}
        _atomic_json(final_record, result, refuse_existing=True)
        run_records.append({"outer": outer, "status": result["status"],
                            "success": result.get("success"),
                            "terminal": result["status"] == "child_complete",
                            "launched": True})
        if result["status"] == "launcher_error" or result.get("success") is not True:
            break
    return {"cell": job["cell"], "attempts": run_records,
            "planned_attempts": len(job["outers"]),
            "terminal_attempts": sum(row.get("terminal") is True for row in run_records),
            "all_attempts_terminal": (len(run_records) == len(job["outers"]) and
                                      all(row.get("terminal") is True for row in run_records)),
            "gate_result": "not_evaluated"}


def execute_plan(plan: dict[str, Any], *, authorization: dict[str, Any],
                 julia: str = "julia", timeout: float = 3600.0,
                 max_workers: int = MAX_CELL_WORKERS) -> list[dict[str, Any]]:
    if not execution_authorized(authorization, plan):
        raise PermissionError("execution authorization is missing or not bound to this measured plan")
    if not math.isfinite(timeout) or timeout <= 0:
        raise ValueError("per-attempt timeout must be positive and finite")
    if max_workers != MAX_CELL_WORKERS:
        raise ValueError("this batch is admitted for exactly four one-thread cell workers")
    _CANCEL.clear()
    previous_handlers = {}
    if threading.current_thread() is threading.main_thread():
        for signum in (signal.SIGINT, signal.SIGTERM):
            previous_handlers[signum] = signal.getsignal(signum)
            signal.signal(signum, _cancel_children)
    source_root = Path(plan["source_root"])
    output_root = Path(plan["output_root"])
    results = []
    try:
        with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_CELL_WORKERS) as pool:
            futures = [pool.submit(_execute_cell, job, source_root=source_root,
                                   output_root=output_root, julia=julia, timeout=timeout,
                                   plan_sha256=plan["plan_sha256"],
                                   batch_sha256=plan["batch_sha256"],
                                   launcher_sha256=plan["launcher_sha256"])
                       for job in plan["jobs"]]
            for future in futures:
                results.append(future.result())
    finally:
        for signum, handler in previous_handlers.items():
            signal.signal(signum, handler)
    return results


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--batch", type=Path, required=True,
                        help="JSON batch with eight source-bound cell admissions")
    parser.add_argument("--source-root", type=Path, default=ROOT)
    parser.add_argument("--output-root", type=Path, required=True)
    parser.add_argument("--plan-output", type=Path, required=True)
    parser.add_argument("--julia", default="julia")
    parser.add_argument("--timeout", type=float, default=3600.0)
    parser.add_argument("--execute", action="store_true",
                        help="execute only with a separate measured-pre-run authorization")
    parser.add_argument("--authorization", type=Path,
                        help="owner authorization bound to this exact plan and pre-run receipt")
    args = parser.parse_args()
    try:
        configure_source_root(args.source_root)
        batch = json.loads(args.batch.read_text(encoding="utf-8"))
        plan = make_plan(batch, source_root=args.source_root, output_root=args.output_root)
        plan_path = args.plan_output.expanduser().resolve()
        if not plan_path.is_relative_to(args.output_root.expanduser().resolve()):
            raise ValueError("plan output must be retained beneath the disjoint result root")
        if plan_path.exists():
            if not args.execute:
                raise FileExistsError(f"refusing to replace existing plan: {plan_path}")
            retained_plan = json.loads(plan_path.read_text(encoding="utf-8"))
            if retained_plan != plan:
                raise ValueError("retained plan differs from current admissions or source")
            plan = retained_plan
        else:
            _atomic_json(plan_path, plan, refuse_existing=True)
        if not args.execute:
            print(json.dumps({"status": "plan_validated_no_fits_started",
                              "plan_path": str(plan_path),
                              "plan_sha256": plan["plan_sha256"]}, sort_keys=True))
            return 0
        if args.authorization is None:
            raise PermissionError("--execute requires --authorization from a separate owner approval")
        authorization = json.loads(args.authorization.read_text(encoding="utf-8"))
        results = execute_plan(plan, authorization=authorization, julia=args.julia,
                               timeout=args.timeout)
        terminal = all(result["all_attempts_terminal"] for result in results)
        print(json.dumps({"status": "attempts_terminal_gate_unassessed" if terminal
                          else "held_for_reconciliation",
                          "gate_result": "not_evaluated", "results": results},
                         sort_keys=True, allow_nan=False))
        return 0 if terminal else 2
    except Exception as error:
        print(json.dumps({"status": "launcher_rejected", "error_type": type(error).__name__,
                          "failure_reason": str(error)}, sort_keys=True), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
