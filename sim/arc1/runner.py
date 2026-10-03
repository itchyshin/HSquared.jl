#!/usr/bin/env python3
"""Fail-closed cell admission and immutable per-attempt evidence storage.

This module does not start a campaign by itself. A caller must provide the
already-admitted cell and an executor; studies remain blocked until review.
"""
from __future__ import annotations

import json
import os
import tempfile
import hashlib
import fcntl
import socket
from pathlib import Path
from typing import Callable, Any

import arc1_manifest as manifest


class StoreBusyError(RuntimeError):
    """Another live worker owns this cell's evidence directory."""


def cell_output_dir(output_root: Path, cell: dict[str, Any]) -> Path:
    """Return a collision-resistant per-cell output path beneath output_root."""
    parts = (str(cell["programme"]), str(cell["phase"]), f"N{int(cell['N'])}", str(cell["signal"]))
    if any(not part or part in {".", ".."} or "/" in part or "\\" in part for part in parts):
        raise ValueError("cell labels must be safe path components")
    return output_root.resolve().joinpath(*parts)


def _write_new_json(path: Path, value: dict[str, Any]) -> None:
    """Durably write one JSON document and publish it without replacing a prior file."""
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    temp = Path(name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            json.dump(value, stream, sort_keys=True, separators=(",", ":"))
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
        # link() is atomic and fails if the destination already exists.
        os.link(temp, path)
        temp.unlink()
        directory_fd = os.open(path.parent, os.O_RDONLY)
        try:
            os.fsync(directory_fd)
        finally:
            os.close(directory_fd)
    finally:
        if temp.exists():
            temp.unlink()


class Arc1AttemptStore:
    """Per-cell write-once records, protected by one live-owner lock."""

    def __init__(self, source_root: Path, output_dir: Path, admission: dict[str, Any], *,
                 julia_version: str, julia_threads: int, blas_threads: int):
        self.source_root = source_root.resolve()
        self.output_dir = output_dir.resolve()
        if (self.output_dir == self.source_root or self.output_dir.is_relative_to(self.source_root) or
                self.source_root.is_relative_to(self.output_dir)):
            raise ValueError("source root and per-cell output directory must be disjoint")
        self.admission = admission
        manifest.verify_run_admission(self.source_root, admission, julia_version=julia_version,
                                      julia_threads=julia_threads, blas_threads=blas_threads)
        manifest.validate_candidate_manifest(self.source_root)
        if admission.get("cell") is None or cell_output_dir(self.output_dir.parents[3], admission["cell"]) != self.output_dir:
            raise ValueError("output directory must be the canonical directory for this cell")
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.lock_path = self.output_dir / ".worker.lock"
        self._lock_stream = self.lock_path.open("a+")
        try:
            fcntl.flock(self._lock_stream.fileno(), fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as error:
            self._lock_stream.close()
            raise StoreBusyError("another live worker owns this cell output directory") from error
        self._active: set[int] = set()
        self._executing: set[int] = set()
        self.directory = self.output_dir / "attempts"
        self.admission_path = self.output_dir / "run-admission.json"
        try:
            self.directory.mkdir(parents=True, exist_ok=True)
            if self.admission_path.exists():
                stored = json.loads(self.admission_path.read_text(encoding="utf-8"))
                if stored != admission:
                    raise ValueError("resume admission differs from the durable original admission")
            else:
                _write_new_json(self.admission_path, admission)
            self.admission_sha256 = hashlib.sha256(
                json.dumps(admission, sort_keys=True, separators=(",", ":")).encode("utf-8")).hexdigest()
        except BaseException:
            fcntl.flock(self._lock_stream.fileno(), fcntl.LOCK_UN)
            self._lock_stream.close()
            raise

    def _path(self, outer: int, state: str) -> Path:
        return self.directory / f"{outer:04d}.{state}.json"

    def begin(self, outer: int) -> dict[str, Any]:
        manifest.verify_run_admission(self.source_root, self.admission,
                                      julia_version=self.admission["julia_version"],
                                      julia_threads=self.admission["threads"]["julia"],
                                      blas_threads=self.admission["threads"]["blas"])
        manifest.validate_candidate_manifest(self.source_root)
        seeds = self.admission["expected_outer_seeds"]
        if type(outer) is not int or not 1 <= outer <= len(seeds):
            raise ValueError("outer index is outside the admitted attempt partition")
        seed = seeds[outer - 1]
        done = self._path(outer, "result")
        if done.exists():
            row = json.loads(done.read_text(encoding="utf-8"))
            if (row.get("seed") != seed or row.get("outer") != outer or
                    row.get("admission_sha256") != self.admission_sha256):
                raise ValueError("existing attempt result differs from admitted seed partition")
            return row
        started = self._path(outer, "started")
        if started.exists():
            start_row = json.loads(started.read_text(encoding="utf-8"))
            if (start_row.get("seed") != seed or start_row.get("outer") != outer or
                    start_row.get("admission_sha256") != self.admission_sha256):
                raise ValueError("existing attempt start differs from admitted seed partition")
            return {"outer": outer, "seed": seed, "status": "started",
                    "success": None, "admission_sha256": self.admission_sha256,
                    "owner_pid": start_row.get("owner_pid")}
        _write_new_json(started, {"outer": outer, "seed": seed, "status": "started",
                                  "admission_sha256": self.admission_sha256,
                                  "owner_pid": os.getpid(), "owner_host": socket.gethostname()})
        self._active.add(outer)
        return {"outer": outer, "seed": seed, "status": "started"}

    def finish(self, outer: int, result: dict[str, Any]) -> dict[str, Any]:
        manifest.verify_run_admission(self.source_root, self.admission,
                                      julia_version=self.admission["julia_version"],
                                      julia_threads=self.admission["threads"]["julia"],
                                      blas_threads=self.admission["threads"]["blas"])
        manifest.validate_candidate_manifest(self.source_root)
        start_path, done_path = self._path(outer, "started"), self._path(outer, "result")
        if not start_path.exists():
            raise ValueError("attempt must have a durable start record before completion")
        start = json.loads(start_path.read_text(encoding="utf-8"))
        if start.get("admission_sha256") != self.admission_sha256:
            raise ValueError("attempt start belongs to a different admission")
        if "outer" in result and result["outer"] != outer:
            raise ValueError("executor returned a different outer index than the admitted attempt")
        if "seed" in result and result["seed"] != start["seed"]:
            raise ValueError("executor returned a different UInt64 seed than the admitted attempt")
        exact_seed = str(start["seed"])
        for key in ("seed_string", "exact_seed_string"):
            if key in result and result[key] != exact_seed:
                raise ValueError(f"executor returned a mismatched {key} for the admitted attempt")
        row = dict(result, outer=outer, seed=start["seed"])
        row["admission_sha256"] = self.admission_sha256
        if not isinstance(row.get("status"), str) or not row["status"]:
            raise ValueError("attempt outcome must retain a status")
        if row.get("success") is False and not row.get("failure_reason"):
            row["failure_reason"] = "attempt failed without a more specific retained reason"
        if row.get("success") is True:
            manifest.verify_execution_identity(self.source_root, self.admission,
                                                row.get("execution_identity"))
        _write_new_json(done_path, row)
        self._active.discard(outer)
        return row

    def rows(self) -> list[dict[str, Any]]:
        count = int(self.admission["planned_attempts"])
        rows = []
        for outer in range(1, count + 1):
            result = self._path(outer, "result")
            if result.exists():
                rows.append(json.loads(result.read_text(encoding="utf-8")))
            else:
                started = self._path(outer, "started")
                if started.exists():
                    rows.append(json.loads(started.read_text(encoding="utf-8")))
        return rows

    def recover_orphans(self) -> list[dict[str, Any]]:
        """Explicitly finalize only attempts whose recorded owner is no longer alive."""
        recovered = []
        for outer in range(1, int(self.admission["planned_attempts"]) + 1):
            started, result = self._path(outer, "started"), self._path(outer, "result")
            if not started.exists() or result.exists() or outer in self._active:
                continue
            row = json.loads(started.read_text(encoding="utf-8"))
            if row.get("owner_host") != socket.gethostname():
                raise StoreBusyError("cannot prove liveness for an attempt owned by another host")
            pid = row.get("owner_pid")
            if type(pid) is not int or _pid_is_alive(pid):
                raise StoreBusyError("attempt owner may still be alive; refusing orphan recovery")
            interrupted = {"outer": outer, "seed": row["seed"], "status": "interrupted",
                           "success": False, "failure_reason": "recorded owner process is no longer alive",
                           "admission_sha256": self.admission_sha256,
                           "owner_pid": pid, "owner_host": row.get("owner_host")}
            _write_new_json(result, interrupted)
            recovered.append(interrupted)
        return recovered

    def close(self) -> None:
        if self._active:
            raise StoreBusyError("cannot release cell ownership while this store has active attempts")
        if not self._lock_stream.closed:
            fcntl.flock(self._lock_stream.fileno(), fcntl.LOCK_UN)
            self._lock_stream.close()

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.close()


def _pid_is_alive(pid: int) -> bool:
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def execute_one(store: Arc1AttemptStore, outer: int,
                executor: Callable[[int, int], dict[str, Any]]) -> dict[str, Any]:
    """Execute once; retain ordinary errors and interrupts as failed outcomes."""
    if outer in store._executing:
        raise StoreBusyError("attempt is already executing in this worker")
    admitted = store.begin(outer)
    if admitted["status"] != "started" or outer not in store._active:
        return admitted
    store._executing.add(outer)
    try:
        result = executor(outer, admitted["seed"])
        if not isinstance(result, dict):
            raise TypeError("attempt executor must return a result mapping")
    except KeyboardInterrupt:
        result = {"status": "interrupted", "success": False,
                  "failure_reason": "KeyboardInterrupt during attempt"}
    except BaseException as error:
        result = {"status": "error", "success": False,
                  "failure_reason": f"{type(error).__name__}: {error}"}
    try:
        return store.finish(outer, result)
    finally:
        store._executing.discard(outer)


def assemble_cell_receipt(rows: list[dict[str, Any]], admission: dict[str, Any], *,
                          source_root: Path, artifact_root: Path) -> dict[str, Any]:
    """Flatten durable attempt-store rows into the checker’s canonical cell receipt.

    Every result artifact is re-hashed from disk here. The original nested row is
    retained verbatim so this view never replaces the lossless executor record.
    """
    cell = admission.get("cell")
    planned = admission.get("planned_attempts")
    seeds = admission.get("expected_outer_seeds")
    source_hashes = admission.get("source_sha256")
    if (not isinstance(cell, dict) or not isinstance(planned, int) or
            not isinstance(seeds, list) or len(seeds) != planned or
            not isinstance(source_hashes, dict) or not source_hashes):
        raise ValueError("admission lacks the canonical cell, seed, or source pins")
    if len(rows) != planned:
        raise ValueError("stored rows do not cover every planned outer attempt")
    source_root = source_root.resolve()
    artifact_root = artifact_root.resolve()
    attempts = []
    for index, (stored, seed) in enumerate(zip(rows, seeds), start=1):
        if stored.get("outer") != index or stored.get("seed") != seed:
            raise ValueError("stored attempt rows differ from canonical outer ordering/seeds")
        executor_payload = (stored if stored.get("schema") == "arc1-attempt-result-v1"
                            else stored.get("result"))
        executor_payload = executor_payload if isinstance(executor_payload, dict) else {}
        nested = executor_payload.get("result")
        result = nested if isinstance(nested, dict) else executor_payload
        identity = stored.get("execution_identity") or executor_payload.get("execution_identity")
        if identity is not None:
            manifest.verify_execution_identity(source_root, admission, identity)
        artifact_path = (stored.get("full_result_path") or stored.get("artifact_path") or
                         executor_payload.get("artifact_path"))
        artifact_sha = (stored.get("full_result_sha256") or stored.get("artifact_sha256") or
                        executor_payload.get("artifact_sha256"))
        if artifact_path is not None:
            artifact = Path(artifact_path).resolve()
            if not artifact.is_relative_to(artifact_root) or not artifact.is_file():
                raise ValueError("stored full-result artifact is missing or outside the cell output")
            actual = hashlib.sha256(artifact.read_bytes()).hexdigest()
            if actual != artifact_sha:
                raise ValueError("stored full-result artifact hash differs from its durable row")
        elif stored.get("success") is True:
            raise ValueError("successful attempt lacks a retained full-result artifact")
        summary_path = executor_payload.get("receipt_summary_path")
        summary_sha = executor_payload.get("receipt_summary_sha256")
        has_summary_claim = summary_path is not None or summary_sha is not None
        if executor_payload.get("schema") == "arc1-attempt-result-v1" and stored.get("success") is True:
            if not has_summary_claim or not isinstance(summary_path, str) or not isinstance(summary_sha, str):
                raise ValueError("successful Julia attempt lacks a bound canonical receipt summary")
        if has_summary_claim:
            if not isinstance(summary_path, str) or not isinstance(summary_sha, str):
                raise ValueError("retained Julia summary has incomplete path/hash metadata")
            summary_file = Path(summary_path).resolve()
            if not summary_file.is_relative_to(artifact_root) or not summary_file.is_file():
                raise ValueError("canonical receipt summary is missing or outside the cell output")
            summary_bytes = summary_file.read_bytes()
            if hashlib.sha256(summary_bytes).hexdigest() != summary_sha:
                raise ValueError("canonical receipt summary bytes differ from the Julia-pinned SHA-256")
            if json.loads(summary_bytes.decode("utf-8")) != result:
                raise ValueError("canonical receipt summary differs from the retained Julia result mapping")
        attempt_id = f"{cell['programme']}:{cell['phase']}:N{cell['N']}:{cell['signal']}:{index:04d}"
        attempt = {"attempt_id": attempt_id, "outer": index, "seed": seed,
                   "status": stored.get("status", "interrupted"),
                   "success": stored.get("success") is True,
                   "failure_reason": stored.get("failure_reason") or
                       (None if stored.get("success") is True else "attempt did not produce a completed result"),
                   "stored_row": stored, "artifact_path": str(artifact_path) if artifact_path else None,
                   "artifact_sha256": artifact_sha,
                   "receipt_summary_path": summary_path,
                   "receipt_summary_sha256": summary_sha,
                   "execution_identity": identity}
        for name in ("rank_candidates", "eligible", "both_candidates_available", "selection_status",
                     "selection_reason", "selected_rank", "guard_results", "starts_planned", "starts_attempted",
                     "selector_attempts", "reference_audit", "outer_selection", "bootstrap",
                     "profile_method", "profile_lr_cutoff", "profile_intervals", "point_estimates",
                     "point_fit_status", "point_fit_not_optimal", "point_loglik",
                     "max_constrained_loglik", "point_identity", "reference_point_identity",
                     "source_identity", "reference_source_identity",
                     "point_fit_diagnostic_identity", "profile_method_version",
                     "requested_profile_method_version", "profile_method_version_mismatch",
                     "target_diagnostics_identity", "data_identity_method",
                     "semantic_data_identity_sha256", "selection", "candidate_summary"):
            if name in result:
                attempt[name] = result[name]
        if "data_identity_sha256" in stored:
            attempt["data_identity_sha256"] = stored["data_identity_sha256"]
        if "semantic_data_identity_sha256" in stored:
            attempt["semantic_data_identity_sha256"] = stored["semantic_data_identity_sha256"]
        elif "semantic_data_identity_sha256" in executor_payload:
            attempt["semantic_data_identity_sha256"] = executor_payload["semantic_data_identity_sha256"]
        if "data_identity_method" in executor_payload:
            attempt["data_identity_method"] = executor_payload["data_identity_method"]
        programme = cell["programme"]
        failure = attempt["failure_reason"] or "attempt did not produce a completed result"
        if programme == "fa_interval":
            planned_inner = admission.get("expected_bootstrap_seeds", {}).get(str(index), [])
            attempt["planned_inner_seeds"] = planned_inner
            attempt["planned_inner_seed_strings"] = [str(seed) for seed in planned_inner]
        if programme == "fa_rank" and "rank_candidates" not in attempt:
            attempt.update(eligible=False, both_candidates_available=False,
                           selection_status="not_run", selection_reason=failure,
                           selected_rank=None,
                           rank_candidates={label: {"parameter_count": q, "aic_penalty": 2 * q,
                               "available": False, "status": "not_run", "raw_loglik": None,
                               "score": None, "error_reason": failure}
                               for label, q in (("K0", 14), ("K1", 18))},
                           guard_results={"schedule_complete": False, "better_unaccepted": None,
                               "nonnested": None, "nesting_witness": {"status": "not_evaluated",
                               "discrepancy": None, "tolerance": 1e-8}})
        if programme == "fa_interval" and "outer_selection" not in attempt:
            phase = cell["phase"]
            primary = 19 if phase == "development" else 199 if phase == "pilot" else 499
            attempt["outer_selection"] = {"eligible": False, "both_candidates_available": False,
                "selection_status": "not_run", "selected_rank": None,
                "selection_reason": failure,
                "rank_candidates": {label: {"parameter_count": q, "aic_penalty": 2 * q,
                    "available": False, "status": "not_run", "raw_loglik": None,
                    "score": None, "error_reason": failure}
                    for label, q in (("K0", 14), ("K1", 18))},
                "guard_results": {"schedule_complete": False, "better_unaccepted": None,
                    "nonnested": None, "nesting_witness": {"status": "not_evaluated",
                    "discrepancy": None, "tolerance": 1e-8}}}
            attempt["bootstrap"] = {"stage": "not_started", "requested_B": primary,
                "refusal_status": failure, "inner_attempts": [], "usable_inner": 0,
                "intervals": {f"h2_{i}": {"formed": False, "segments": [],
                    "status": "outer_fit_failed", "refusal_status": failure,
                    "formula": f"G_{i}{i}/(G_{i}{i}+R_{i}{i})"} for i in range(1, 5)}}
        if programme in {"repeatability", "boundary"} and "profile_intervals" not in attempt:
            truths = ({"Va": 0.0, "Vpe": 0.3, "Ve": 0.7, "h2": 0.0, "t": 0.3}
                      if cell["signal"] == "Va_zero" else
                      {"Va": 0.3, "Vpe": 0.0, "Ve": 0.7, "h2": 0.3, "t": 0.3}
                      if cell["signal"] == "Vpe_zero" else None)
            if truths is None:
                values = manifest.REPEATABILITY_TRUTHS[cell["signal"]]
                va, vpe, ve = values
                total = va + vpe + ve
                truths = {"Va": va, "Vpe": vpe, "Ve": ve, "h2": va / total,
                          "t": (va + vpe) / total}
            formulas = {"Va": "Va", "Vpe": "Vpe", "Ve": "Ve",
                        "h2": "Va/(Va+Vpe+Ve)", "t": "(Va+Vpe)/(Va+Vpe+Ve)"}
            attempt.update(profile_method="profile_likelihood_ratio",
                profile_lr_cutoff=3.841458820694124,
                profile_intervals={key: {"formed": False, "segments": [],
                    "status": "outer_fit_failed", "refusal_status": failure,
                    "formula": formulas[key]} for key in truths},
                point_fit_status="not_run", point_fit_not_optimal=None,
                point_loglik=None, max_constrained_loglik=None, point_estimates=None,
                point_identity=None, reference_point_identity=None,
                source_identity=None, reference_source_identity=None,
                point_fit_diagnostic_identity=None, profile_method_version=None,
                requested_profile_method_version=admission.get("profile_method_version"),
                target_diagnostics_identity=None)
        attempts.append(attempt)
    return {"schema": "arc1-attempt-receipt-v1", **cell,
            "protocol_sha256": admission.get("protocol_sha256"),
            "source_hashes": source_hashes, "planned_attempts": planned,
            "attempts": attempts}
