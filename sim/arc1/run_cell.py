#!/usr/bin/env python3
"""Launch exactly one admitted Arc1 outer attempt in an isolated Julia process."""
from __future__ import annotations

import argparse
import json
import os
import re
import signal
import subprocess
import sys
import threading
import time
from pathlib import Path
from typing import Any

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(ROOT / "tools"))
sys.path.insert(0, str(HERE))

import arc1_manifest as manifest
import runner


def _toml_string(value: str) -> str:
    # JSON basic-string escapes are a subset of TOML's basic-string escapes.
    return json.dumps(value, ensure_ascii=False)


def _toml_input(path: Path, *, mode: str, source_root: Path, attempt_output: Path,
                artifact_path: Path, cell: dict[str, Any], outer: int, seed: int,
                bootstrap_seeds: list[int], admission: dict[str, Any], blas_threads: int) -> None:
    lines = ["mode = " + _toml_string(mode),
             "source_root = " + _toml_string(str(source_root.resolve())),
             "attempt_output = " + _toml_string(str(attempt_output.resolve())),
             "artifact_path = " + _toml_string(str(artifact_path.resolve())),
             f"outer = {outer}", f"seed = {_toml_string(str(seed))}",
             f"blas_threads = {blas_threads}",
             "protocol_sha256 = " + _toml_string(str(admission["protocol_sha256"])),
             "bootstrap_seeds = [" + ", ".join(_toml_string(str(x)) for x in bootstrap_seeds) + "]", "",
             "[cell]"]
    for name in ("programme", "phase", "signal"):
        lines.append(f"{name} = {_toml_string(str(cell[name]))}")
    lines.append(f"N = {int(cell['N'])}")
    lines.extend(["", "[engine_hashes]"])
    for name, digest in sorted(admission["source_sha256"].items()):
        if name.startswith("src/"):
            lines.append(f"{_toml_string(name)} = {_toml_string(digest)}")
    lines.extend(["", "[environment_hashes]"])
    for name, digest in sorted(admission["environment_sha256"].items()):
        lines.append(f"{_toml_string(name)} = {_toml_string(digest)}")
    lines.extend(["", "[source_hashes]"])
    for name, digest in sorted(admission["source_sha256"].items()):
        lines.append(f"{_toml_string(name)} = {_toml_string(digest)}")
    lines.append("")
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        raise FileExistsError(f"refusing to replace Julia input: {path}")
    path.write_text("\n".join(lines), encoding="utf-8")


def _stop_process_group(process: subprocess.Popen[str], *, first_signal: int = signal.SIGTERM,
                        grace_seconds: float = 5.0) -> None:
    if process.poll() is not None:
        return
    try:
        os.killpg(process.pid, first_signal)
    except ProcessLookupError:
        return
    try:
        process.wait(timeout=grace_seconds)
    except subprocess.TimeoutExpired:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        process.wait()


class _Arc1ParentSignal(BaseException):
    def __init__(self, signum: int):
        self.signum = signum


def _raise_arc1_signal(signum: int, _frame) -> None:
    raise _Arc1ParentSignal(signum)


def launch_julia_attempt(command: list[str], *, env: dict[str, str], timeout_seconds: float,
                         log_path: Path) -> dict[str, Any]:
    """Run a fresh Julia process, retain its streams, and never leave its group behind."""
    started = time.monotonic()
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               text=True, encoding="utf-8", errors="replace", env=env,
                               start_new_session=True)
    previous_sigterm = None
    if threading.current_thread() is threading.main_thread():
        previous_sigterm = signal.getsignal(signal.SIGTERM)
        signal.signal(signal.SIGTERM, _raise_arc1_signal)
    try:
        stdout, stderr = process.communicate(timeout=timeout_seconds)
    except subprocess.TimeoutExpired:
        _stop_process_group(process)
        stdout, stderr = process.communicate()
        elapsed = time.monotonic() - started
        _write_log(log_path, stdout, stderr)
        return {"success": False, "status": "timeout", "failure_reason":
                f"Julia attempt exceeded {timeout_seconds:g} seconds", "elapsed_seconds": elapsed,
                "child_exit_code": process.returncode, "stdout": stdout, "stderr": stderr}
    except KeyboardInterrupt:
        _stop_process_group(process, first_signal=signal.SIGINT)
        stdout, stderr = process.communicate()
        _write_log(log_path, stdout, stderr)
        raise
    except _Arc1ParentSignal as interrupted:
        _stop_process_group(process, first_signal=interrupted.signum)
        stdout, stderr = process.communicate()
        elapsed = time.monotonic() - started
        _write_log(log_path, stdout, stderr)
        return {"success": False, "status": "interrupted",
                "failure_reason": f"launcher received signal {interrupted.signum}",
                "signal": interrupted.signum, "elapsed_seconds": elapsed,
                "child_exit_code": process.returncode, "stdout": stdout, "stderr": stderr}
    finally:
        if previous_sigterm is not None:
            signal.signal(signal.SIGTERM, previous_sigterm)
    elapsed = time.monotonic() - started
    _write_log(log_path, stdout, stderr)
    payload = None
    for line in reversed(stdout.splitlines()):
        try:
            candidate = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(candidate, dict) and candidate.get("schema") == "arc1-attempt-result-v1":
            payload = candidate
            break
    if payload is None:
        return {"success": False, "status": "child_error", "failure_reason":
                f"Julia child exited {process.returncode} without a machine-readable result",
                "elapsed_seconds": elapsed, "child_exit_code": process.returncode,
                "stdout": stdout, "stderr": stderr}
    payload["child_exit_code"] = process.returncode
    payload["child_elapsed_seconds"] = elapsed
    payload["julia_log_path"] = str(log_path)
    if process.returncode != 0 and payload.get("success") is True:
        payload.update(success=False, status="child_error",
                       failure_reason=f"Julia child exited {process.returncode} after a success payload")
    return payload


def _write_log(path: Path, stdout: str, stderr: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    content = "--- stdout ---\n" + stdout + "\n--- stderr ---\n" + stderr
    path.write_text(content, encoding="utf-8")


def _atomic_error(path: Path, error: BaseException) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp = path.with_name(path.name + f".{os.getpid()}.tmp")
    temp.write_text(json.dumps({"schema": "arc1-admission-error-v1",
                                "error_type": type(error).__name__,
                                "error": str(error)}, sort_keys=True) + "\n", encoding="utf-8")
    os.replace(temp, path)


def _julia_version(executable: str) -> str:
    completed = subprocess.run([executable, "--version"], check=True, capture_output=True,
                               text=True, timeout=10)
    match = re.search(r"([0-9]+\.[0-9]+\.[0-9]+)", completed.stdout + completed.stderr)
    if not match:
        raise ValueError("could not parse Julia version")
    return match.group(1)


def execute_cli(args: argparse.Namespace) -> dict[str, Any]:
    source_root = args.source_root.resolve()
    output_root = args.output_root.resolve()
    if source_root == output_root or source_root.is_relative_to(output_root) or output_root.is_relative_to(source_root):
        raise ValueError("source and result roots must be disjoint")
    admission = json.loads(args.admission.read_text(encoding="utf-8"))
    julia_version = _julia_version(args.julia)
    cell = admission.get("cell")
    if not isinstance(cell, dict):
        raise ValueError("admission lacks a cell pin")
    outdir = runner.cell_output_dir(output_root, cell)
    try:
        store = runner.Arc1AttemptStore(source_root, outdir, admission,
                                       julia_version=julia_version,
                                       julia_threads=args.julia_threads,
                                       blas_threads=args.blas_threads)
    except BaseException as error:
        _atomic_error(output_root / "admission-rejected.json", error)
        raise
    with store:
        outer = args.outer
        if type(outer) is not int or not 1 <= outer <= admission["planned_attempts"]:
            raise ValueError("--outer is outside the admitted attempt allocation")
        seeds = admission["expected_outer_seeds"]
        bootstrap_map = admission.get("expected_bootstrap_seeds", {})
        bootstrap_seeds = bootstrap_map.get(str(outer), [])
        attempt_dir = store.directory
        input_path = attempt_dir / f"{outer:04d}.input.toml"
        artifact_path = attempt_dir / f"{outer:04d}.full.jls"
        log_path = attempt_dir / f"{outer:04d}.julia.log"

        def executor(_outer: int, seed: int) -> dict[str, Any]:
            _toml_input(input_path, mode="study", source_root=source_root,
                        attempt_output=attempt_dir, artifact_path=artifact_path,
                        cell=cell, outer=_outer, seed=seed,
                        bootstrap_seeds=bootstrap_seeds, admission=admission,
                        blas_threads=args.blas_threads)
            env = dict(os.environ)
            env["JULIA_NUM_THREADS"] = str(args.julia_threads)
            env["OPENBLAS_NUM_THREADS"] = str(args.blas_threads)
            command = [args.julia, "--startup-file=no", f"--threads={args.julia_threads}",
                       f"--project={source_root}", str(source_root / "sim/arc1/execute_attempt.jl"),
                       str(input_path)]
            result = launch_julia_attempt(command, env=env, timeout_seconds=args.timeout,
                                          log_path=log_path)
            _check_returned_attempt_identity(result, _outer, seed)
            result.setdefault("outer", _outer)
            result.setdefault("seed", seed)
            result.setdefault("exact_seed_string", str(seed))
            result["julia_log_sha256"] = __import__("hashlib").sha256(log_path.read_bytes()).hexdigest()
            if artifact_path.is_file():
                result["full_result_path"] = str(artifact_path)
                result["full_result_sha256"] = __import__("hashlib").sha256(artifact_path.read_bytes()).hexdigest()
            return result

        return runner.execute_one(store, outer, executor)


def _check_returned_attempt_identity(result: dict[str, Any], outer: int, seed: int) -> None:
    """Reject child identity mismatches before adding request-side fallback fields."""
    returned_outer = result.get("outer")
    if returned_outer is not None and (type(returned_outer) is not int or returned_outer != outer):
        raise ValueError(f"Julia child returned outer {returned_outer!r}; requested {outer}")
    for field in ("seed",):
        returned = result.get(field)
        if returned is not None and (type(returned) is not int or returned != seed):
            raise ValueError(f"Julia child returned {field} {returned!r}; requested {seed}")
    for field in ("seed_string", "exact_seed_string"):
        returned = result.get(field)
        if returned is not None and returned != str(seed):
            raise ValueError(f"Julia child returned {field} {returned!r}; requested {seed}")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source-root", type=Path, default=ROOT)
    parser.add_argument("--output-root", type=Path, required=True)
    parser.add_argument("--admission", type=Path, required=True)
    parser.add_argument("--outer", type=int, required=True, help="one canonical 1-based outer attempt")
    parser.add_argument("--julia", default="julia")
    parser.add_argument("--julia-threads", type=int, default=4)
    parser.add_argument("--blas-threads", type=int, default=1)
    parser.add_argument("--timeout", type=float, default=3600.0)
    args = parser.parse_args()
    try:
        result = execute_cli(args)
    except BaseException as error:
        print(json.dumps({"success": False, "status": "admission_error",
                          "error_type": type(error).__name__, "failure_reason": str(error)},
                         sort_keys=True), file=sys.stderr)
        return 2
    print(json.dumps(result, sort_keys=True, allow_nan=False))
    return 0 if result.get("success") is True else 2


if __name__ == "__main__":
    raise SystemExit(main())
