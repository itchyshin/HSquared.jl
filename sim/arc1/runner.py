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
