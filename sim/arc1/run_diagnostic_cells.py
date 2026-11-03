#!/usr/bin/env python3
"""Plan or execute the eight separately admitted Arc 1 diagnostic attempts.

Planning is the default. Execution requires an independently reviewed admission
and uses the native Julia attempt entrypoint directly; it does not call the
canonical pilot launcher or confer pilot, confirmation, parity, or gate credit.
"""
from __future__ import annotations

import argparse
import concurrent.futures
import datetime as dt
import fcntl
import hashlib
import importlib.util
import json
import os
import signal
import subprocess
import sys
import threading
import time
from pathlib import Path
from typing import Any, Callable

SCHEMA = "arc1-diagnostic-execution-admission-v1"
HISTORY_SCHEMA = "arc1-diagnostic-seed-history-v1"
AMENDMENT_ID = "2026-10-24-arc1-source-history-rebuild"
RESERVATION_ROOT = (Path.home() / "hsq_work" / "arc1-diagnostic-reservations" / AMENDMENT_ID).resolve()
MAX_CONCURRENCY = 4
MAX_TIMEOUT_SECONDS = 3 * 60 * 60
UINT64_MAX = 2**64 - 1
CELLS = [
    {"programme": "fa_rank", "phase": "pilot", "N": n, "signal": signal_name}
    for n in (80, 160, 320) for signal_name in ("null", "weak", "strong")
    if (n, signal_name) != (80, "null")
]
REQUIRED_NATIVE_FILES = {
    "Project.toml", "Manifest.toml", "src/HSquared.jl",
    "tools/arc1_manifest.py",
    "sim/arc1/execute_attempt.jl", "sim/arc1/execution_identity.jl",
    "sim/arc1/independent_dgp.jl", "sim/arc1/engine_io.jl",
    "sim/arc1/reference.jl",
}
_ACTIVE_LOCK = threading.Lock()
_ACTIVE_PGIDS: set[int] = set()
_STOP_REQUESTED = threading.Event()


def canonical_bytes(value: Any) -> bytes:
    return json.dumps(value, sort_keys=True, separators=(",", ":"),
                      ensure_ascii=False, allow_nan=False).encode("utf-8")


def canonical_sha256(value: Any) -> str:
    return hashlib.sha256(canonical_bytes(value)).hexdigest()


def sha256_file(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _read_json(path: Path, label: str) -> dict[str, Any]:
    try:
        value = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise ValueError(f"cannot read {label}: {path}: {exc}") from exc
    if not isinstance(value, dict):
        raise ValueError(f"{label} must be a JSON object")
    return value


def _sha(value: Any, field: str) -> str:
    if not isinstance(value, str) or len(value) != 64 or any(c not in "0123456789abcdef" for c in value):
        raise ValueError(f"{field} must be a lowercase SHA-256")
    return value


def _safe_descendant(path: Path, root: Path, label: str) -> Path:
    resolved = path.resolve(strict=True)
    if not resolved.is_relative_to(root):
        raise ValueError(f"{label} escapes the pinned Julia source root: {path}")
    return resolved


def _source_inventory(source_root: Path, source_map_path: Path,
                      source_map: dict[str, Any], history: dict[str, Any]) -> tuple[dict[str, str], dict[str, str]]:
    if Path(source_map.get("root", "")).expanduser().resolve() != source_root:
        raise ValueError("source-map root differs from the reviewed diagnostic source root")
    files = source_map.get("files")
    if not isinstance(files, list) or not files:
        raise ValueError("source map must contain a nonempty files list")
    source_hashes: dict[str, str] = {}
    normalized_entries = []
    for entry in files:
        if not isinstance(entry, dict) or not isinstance(entry.get("path"), str):
            raise ValueError("source map file entries require absolute paths and SHA-256 values")
        expected = _sha(entry.get("sha256"), "source-map file sha256")
        file_path = Path(entry["path"])
        if not file_path.is_absolute():
            file_path = source_root / file_path
        resolved = _safe_descendant(file_path, source_root, "source file")
        relative = resolved.relative_to(source_root).as_posix()
        if relative in source_hashes:
            raise ValueError(f"duplicate source-map path: {relative}")
        actual = sha256_file(resolved)
        if actual != expected:
            raise ValueError(f"source drift: {relative}")
        if relative.startswith("R/") or relative.endswith(".R") or relative == "DESCRIPTION":
            raise ValueError(f"diagnostic source map unexpectedly includes paired R source: {relative}")
        source_hashes[relative] = actual
        normalized_entries.append({"path": str(resolved), "bytes": resolved.stat().st_size,
                                  "sha256": actual})
    if not REQUIRED_NATIVE_FILES.issubset(source_hashes):
        missing = sorted(REQUIRED_NATIVE_FILES - source_hashes.keys())
        raise ValueError(f"source map omits required native Julia files: {missing}")
    source_module = (source_root / "src/HSquared.jl").read_text(encoding="utf-8")
    import re
    includes = re.findall(r'^\s*include\("([^"/]+)"\)', source_module, flags=re.MULTILINE)
    required_includes = {f"src/{name}" for name in includes}
    if not required_includes.issubset(source_hashes):
        missing = sorted(required_includes - source_hashes.keys())
        raise ValueError(f"source map omits Julia engine includes: {missing}")
    canonical_inventory = canonical_sha256(normalized_entries)
    if history.get("source_map", {}).get("canonical_sha256") != canonical_inventory:
        raise ValueError("history report source-map inventory differs from the current source map")
    if history.get("source_map", {}).get("files") != normalized_entries:
        raise ValueError("history report source file identities differ from the current source map")
    environment_hashes = {key: source_hashes[key] for key in ("Project.toml", "Manifest.toml")}
    return source_hashes, environment_hashes


def _validate_report(history_path: Path, source_map_path: Path, amendment_path: Path,
                     admission: dict[str, Any], source_root: Path) -> tuple[dict[str, Any], list[dict[str, Any]], dict[str, str], dict[str, str]]:
    if admission.get("schema") != SCHEMA:
        raise ValueError("unsupported diagnostic execution admission schema")
    if admission.get("amendment_id") != AMENDMENT_ID:
        raise ValueError("diagnostic admission names a different amendment")
    amendment_hash = _sha(admission.get("amendment_sha256"), "amendment_sha256")
    source_map_hash = _sha(admission.get("source_map_sha256"), "source_map_sha256")
    history_hash = _sha(admission.get("history_report_sha256"), "history_report_sha256")
    if sha256_file(amendment_path) != amendment_hash:
        raise ValueError("amendment source changed after admission")
    if sha256_file(source_map_path) != source_map_hash:
        raise ValueError("source map changed after admission")
    if sha256_file(history_path) != history_hash:
        raise ValueError("seed-history report changed after admission")

    source_map = _read_json(source_map_path, "source map")
    history = _read_json(history_path, "seed-history report")
    history_core = dict(history)
    recorded_history_hash = _sha(history_core.pop("report_sha256", None), "report_sha256")
    if canonical_sha256(history_core) != recorded_history_hash:
        raise ValueError("seed-history report self-hash is invalid")
    if history.get("schema") != HISTORY_SCHEMA or history.get("status") != "candidate_scoped_collision_check_passed":
        raise ValueError("seed-history report is not a valid scoped diagnostic inventory")
    if history.get("execution_authorized") is not False or history.get("pilot_or_confirmation_authorized") is not False or history.get("gate_credit") is not False:
        raise ValueError("seed-history report must remain diagnostic-only and carry no gate credit")
    if history.get("history_scope", {}).get("exhaustive") is not False or history.get("history_scope", {}).get("independent_review_required") is not True:
        raise ValueError("seed-history report must disclose finite history scope and require review")
    if history.get("history_scope", {}).get("claim") != "no_collision_among_extracted_seeds_pending_review":
        raise ValueError("seed-history report has an unsupported collision-scope claim")
    if history.get("amendment", {}).get("id") != AMENDMENT_ID:
        raise ValueError("seed-history report names a different amendment")
    if Path(history.get("amendment", {}).get("path", "")).resolve() != amendment_path:
        raise ValueError("seed-history report names a different amendment path")
    if history.get("amendment", {}).get("sha256") != amendment_hash:
        raise ValueError("seed-history report is bound to another amendment")
    if history.get("source_map", {}).get("sha256") != source_map_hash:
        raise ValueError("seed-history report is bound to another source map")
    if Path(history.get("source_map", {}).get("path", "")).resolve() != source_map_path:
        raise ValueError("seed-history report names a different source map path")
    if history.get("history_inventory", {}).get("exhaustive_history_claim") is not False:
        raise ValueError("history inventory makes an unsupported exhaustive-history claim")
    inventory_core = dict(history["history_inventory"])
    inventory_hash = _sha(inventory_core.pop("inventory_sha256", None), "history_inventory.inventory_sha256")
    if canonical_sha256(inventory_core) != inventory_hash or admission.get("history_inventory_sha256") != inventory_hash:
        raise ValueError("history inventory digest differs from the reviewed admission")
    records = history["history_inventory"].get("records")
    if not isinstance(records, list):
        raise ValueError("history inventory records must be an explicit list")
    for record in records:
        if not isinstance(record, dict) or not isinstance(record.get("path"), str):
            raise ValueError("history inventory entries require explicit paths")
        record_path = Path(record["path"]).expanduser().resolve()
        status = record.get("status")
        if status in {"parsed", "unparsed"}:
            if not record_path.is_file() or sha256_file(record_path) != _sha(record.get("sha256"), "history record sha256"):
                raise ValueError(f"historical record changed or disappeared after inventory: {record_path}")
        elif status == "unreadable" and record_path.exists():
            raise ValueError(f"previously unreadable historical record is now present; rebuild its inventory: {record_path}")
        elif status not in {"unreadable", "parsed", "unparsed"}:
            raise ValueError("history inventory has an unsupported record status")
    unavailable = history["history_inventory"].get("missing_or_unavailable", [])
    if not isinstance(unavailable, list):
        raise ValueError("history inventory missing-path list is malformed")
    for entry in unavailable:
        if not isinstance(entry, dict) or not isinstance(entry.get("path"), str):
            raise ValueError("history missing-path entries require explicit paths")
        if Path(entry["path"]).expanduser().exists():
            raise ValueError(f"previously unavailable historical path now exists; rebuild its inventory: {entry['path']}")
    parsed_allocations = [record for record in records if isinstance(record, dict) and
                          record.get("role") == "allocation" and record.get("status") == "parsed" and
                          isinstance(record.get("seed_records"), list) and record["seed_records"]]
    if not parsed_allocations:
        raise ValueError("history inventory requires at least one successfully parsed allocation")
    extracted_seeds = set()
    for record in records:
        if not isinstance(record, dict) or record.get("status") not in {"parsed", "unparsed"}:
            continue
        seed_records = record.get("seed_records", [])
        if not isinstance(seed_records, list):
            raise ValueError("parsed history record has malformed seed_records")
        for seed_record in seed_records:
            seed = seed_record.get("seed") if isinstance(seed_record, dict) else None
            if type(seed) is not int or not 0 <= seed <= UINT64_MAX:
                raise ValueError("parsed history record contains a malformed seed")
            extracted_seeds.add(seed)
    if history.get("consumed_seed_count_in_supplied_scope") != len(extracted_seeds):
        raise ValueError("history report consumed-seed count differs from parsed records")
    collisions = sorted(extracted_seeds & {row.get("seed") for row in history.get("diagnostic_seeds", [])
                                            if isinstance(row, dict)})
    if collisions or history.get("collisions") != []:
        raise ValueError(f"diagnostic seed collision in the reviewed history scope: {collisions}")

    seeds = history.get("diagnostic_seeds")
    if not isinstance(seeds, list) or len(seeds) != 8 or canonical_sha256(seeds) != _sha(
            history.get("diagnostic_seed_sha256"), "diagnostic_seed_sha256"):
        raise ValueError("diagnostic history must pin exactly eight seeds")
    if canonical_sha256(seeds) != admission.get("diagnostic_seed_sha256"):
        raise ValueError("admission diagnostic seed digest differs from the history report")
    normalized = []
    seen_cells = set()
    seen_seeds = set()
    for seed_row, expected_cell in zip(seeds, CELLS):
        if not isinstance(seed_row, dict) or seed_row.get("cell") != expected_cell or seed_row.get("outer") != 1:
            raise ValueError("diagnostic seed rows do not match the exact eight-cell schedule")
        seed = seed_row.get("seed")
        if type(seed) is not int or not 0 <= seed <= UINT64_MAX:
            raise ValueError("diagnostic seeds must be UInt64 integers")
        if seed_row.get("namespace") != AMENDMENT_ID:
            raise ValueError("diagnostic seed row uses an unreviewed namespace")
        label = "/".join((AMENDMENT_ID, amendment_hash, expected_cell["programme"],
                          expected_cell["phase"], str(expected_cell["N"]),
                          expected_cell["signal"], "outer=1"))
        derived = int.from_bytes(hashlib.sha256(label.encode("utf-8")).digest()[:8], "big")
        if seed != derived:
            raise ValueError("diagnostic seed differs from the amendment-pinned seed generator")
        key = canonical_sha256(expected_cell)
        if key in seen_cells or seed in seen_seeds:
            raise ValueError("duplicate diagnostic cell or seed")
        seen_cells.add(key)
        seen_seeds.add(seed)
        normalized.append({"cell": expected_cell, "outer": 1, "seed": seed})
    if len(seen_cells) != 8:
        raise ValueError("diagnostic schedule does not contain eight unique cells")
    if admission.get("source_map_canonical_sha256") != history.get("source_map", {}).get("canonical_sha256"):
        raise ValueError("admission source-map canonical digest differs from the history report")
    generator = history.get("seed_generator")
    if not isinstance(generator, dict) or not isinstance(generator.get("path"), str):
        raise ValueError("seed-history report lacks the exact seed-generator source pin")
    generator_path = Path(generator["path"]).expanduser().resolve(strict=True)
    generator_hash = _sha(generator.get("sha256"), "seed_generator.sha256")
    if sha256_file(generator_path) != generator_hash or admission.get("seed_generator_sha256") != generator_hash:
        raise ValueError("seed generator changed after diagnostic admission")
    source_hashes, environment_hashes = _source_inventory(source_root, source_map_path, source_map, history)
    manifest_path = source_root / "tools/arc1_manifest.py"
    spec = importlib.util.spec_from_file_location("arc1_diagnostic_pinned_manifest", manifest_path)
    if spec is None or spec.loader is None:
        raise ValueError("cannot load the pinned Arc1 protocol module")
    pinned_manifest = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(pinned_manifest)
    protocol_hash = pinned_manifest.contract_sha256()
    if admission.get("protocol_sha256") != protocol_hash:
        raise ValueError("admission protocol hash differs from the pinned Julia source tree")
    return history, normalized, source_hashes, environment_hashes


def _admission_core(admission: dict[str, Any]) -> dict[str, Any]:
    return {key: value for key, value in admission.items() if key != "review_receipt"}


def _validate_review(admission: dict[str, Any], history: dict[str, Any]) -> tuple[str, Path]:
    receipt_info = admission.get("review_receipt")
    if not isinstance(receipt_info, dict):
        raise ValueError("diagnostic admission lacks an independent review receipt")
    receipt_path = Path(receipt_info.get("path", "")).expanduser().resolve(strict=True)
    receipt_hash = _sha(receipt_info.get("sha256"), "review_receipt.sha256")
    if sha256_file(receipt_path) != receipt_hash:
        raise ValueError("independent review receipt bytes changed")
    receipt = _read_json(receipt_path, "independent review receipt")
    if receipt.get("schema") != "arc1-diagnostic-execution-review-v1" or receipt.get("status") != "reviewed":
        raise ValueError("independent review receipt is missing or not approved")
    if not isinstance(receipt.get("reviewer"), str) or not receipt["reviewer"].strip() or not isinstance(receipt.get("reviewed_at_utc"), str):
        raise ValueError("independent review receipt lacks reviewer identity or date")
    if receipt.get("admission_core_sha256") != canonical_sha256(_admission_core(admission)):
        raise ValueError("independent review receipt does not pin this admission")
    for field, expected in (("amendment_sha256", admission.get("amendment_sha256")),
                            ("source_map_sha256", admission.get("source_map_sha256")),
                            ("history_report_sha256", admission.get("history_report_sha256")),
                            ("diagnostic_seed_sha256", history.get("diagnostic_seed_sha256")),
                            ("history_inventory_sha256", history.get("history_inventory", {}).get("inventory_sha256")),
                            ("seed_generator_sha256", history.get("seed_generator", {}).get("sha256")),
                            ("julia_sha256", admission.get("julia_sha256")),
                            ("runtime_inventory_sha256", admission.get("runtime_inventory_sha256")),
                            ("launcher_sha256", admission.get("launcher_sha256")),
                            ("runtime_estimate_seconds", admission.get("runtime_estimate_seconds")),
                            ("timeout_seconds", admission.get("timeout_seconds")),
                            ("output_root", admission.get("output_root")),
                            ("reference_schedule", admission.get("reference_schedule"))):
        if receipt.get(field) != expected:
            raise ValueError(f"review receipt does not pin {field}")
    return receipt_hash, receipt_path


def build_plan(admission_path: Path, *, check_output: bool = True) -> dict[str, Any]:
    admission_path = admission_path.expanduser().resolve(strict=True)
    admission = _read_json(admission_path, "diagnostic admission")
    required = ("amendment_path", "source_map_path", "history_report_path", "source_root",
                "output_root", "reservation_root", "julia", "julia_version", "timeout_seconds",
                "runtime_estimate_seconds", "concurrency", "threads", "run_kind", "diagnostic_seed_sha256",
                "source_map_canonical_sha256", "source_map_sha256", "history_report_sha256",
                "amendment_sha256", "seed_generator_sha256", "launcher_path", "launcher_sha256",
                "julia_sha256", "runtime_files", "runtime_inventory_sha256",
                "reference_schedule",
                "execution_authorized", "pilot_or_confirmation_authorized",
                "gate_credit", "review_receipt")
    missing = [key for key in required if key not in admission]
    if missing:
        raise ValueError(f"diagnostic admission lacks required pins: {missing}")
    if admission.get("run_kind") != "diagnostic_only" or admission.get("pilot_or_confirmation_authorized") is not False or admission.get("gate_credit") is not False:
        raise ValueError("diagnostic route refuses pilot/confirmation authority or gate credit")
    if admission.get("reference_schedule") != "full_expanded_pilot_outer1_reference":
        raise ValueError("diagnostic admission must retain the full expanded outer-1 reference schedule")
    if admission.get("julia_version") != "1.10.0":
        raise ValueError("diagnostic admission must pin Julia 1.10.0")
    if admission.get("threads") != {"julia": 1, "blas": 1}:
        raise ValueError("diagnostic jobs require one Julia and one BLAS thread")
    concurrency = admission.get("concurrency")
    if type(concurrency) is not int or not 1 <= concurrency <= MAX_CONCURRENCY:
        raise ValueError("diagnostic concurrency must be between one and four")
    timeout = admission.get("timeout_seconds")
    if type(timeout) not in (int, float) or isinstance(timeout, bool) or not 1 <= timeout <= MAX_TIMEOUT_SECONDS:
        raise ValueError("diagnostic timeout must be finite and at most three hours")
    estimate = admission.get("runtime_estimate_seconds")
    if type(estimate) not in (int, float) or isinstance(estimate, bool) or not 1 <= estimate <= timeout:
        raise ValueError("admission must pin a positive runtime estimate no greater than the timeout")

    source_root = Path(admission["source_root"]).expanduser().resolve(strict=True)
    amendment_path = Path(admission["amendment_path"]).expanduser().resolve(strict=True)
    source_map_path = Path(admission["source_map_path"]).expanduser().resolve(strict=True)
    history_path = Path(admission["history_report_path"]).expanduser().resolve(strict=True)
    output_root = Path(admission["output_root"]).expanduser().resolve()
    reservation_root = Path(admission["reservation_root"]).expanduser().resolve()
    if reservation_root != RESERVATION_ROOT:
        raise ValueError("reservation ledger must use the amendment-bound canonical root")
    if output_root == source_root or output_root.is_relative_to(source_root) or source_root.is_relative_to(output_root):
        raise ValueError("diagnostic outputs must be disjoint from the pinned Julia source root")
    if reservation_root == source_root or reservation_root.is_relative_to(source_root) or source_root.is_relative_to(reservation_root):
        raise ValueError("reservation ledger must be outside the pinned Julia source root")
    if check_output and output_root.exists():
        raise ValueError("diagnostic output root already exists; attempts cannot be retried under another output")
    if type(admission.get("execution_authorized")) is not bool:
        raise ValueError("execution_authorized must be an explicit Boolean")

    history, seeds, source_hashes, environment_hashes = _validate_report(
        history_path, source_map_path, amendment_path, admission, source_root)
    _validate_review(admission, history)
    executable = Path(admission["julia"]).expanduser().resolve(strict=True)
    if not executable.is_file() or not os.access(executable, os.X_OK):
        raise ValueError("pinned Julia runtime is not an executable file")
    julia_hash = _sha(admission.get("julia_sha256"), "julia_sha256")
    if sha256_file(executable) != julia_hash:
        raise ValueError("Julia executable changed after independent review")
    runtime_files = admission.get("runtime_files")
    if not isinstance(runtime_files, list) or not runtime_files:
        raise ValueError("admission must pin the Julia executable and runtime libraries")
    runtime_identity = []
    seen_runtime = set()
    for item in runtime_files:
        if not isinstance(item, dict) or item.get("role") not in {"executable", "library"} or not isinstance(item.get("path"), str):
            raise ValueError("runtime file inventory entries need path and executable/library role")
        path = Path(item["path"]).expanduser().resolve(strict=True)
        digest = _sha(item.get("sha256"), "runtime file sha256")
        if path in seen_runtime or sha256_file(path) != digest:
            raise ValueError(f"Julia runtime file identity changed or is duplicated: {path}")
        seen_runtime.add(path)
        runtime_identity.append({"path": str(path), "role": item["role"], "sha256": digest})
    if str(executable) not in {item["path"] for item in runtime_identity if item["role"] == "executable"}:
        raise ValueError("runtime file inventory omits the pinned Julia executable")
    if not any(item["role"] == "library" for item in runtime_identity):
        raise ValueError("runtime file inventory omits Julia shared libraries")
    runtime_identity.sort(key=lambda item: item["path"])
    runtime_hash = canonical_sha256(runtime_identity)
    if admission.get("runtime_inventory_sha256") != runtime_hash:
        raise ValueError("Julia runtime inventory digest differs from admission")
    if next((item["sha256"] for item in runtime_identity if item["path"] == str(executable)), None) != julia_hash:
        raise ValueError("Julia executable hash differs from its runtime inventory entry")
    launcher_path = Path(admission["launcher_path"]).expanduser().resolve(strict=True)
    if launcher_path != Path(__file__).resolve():
        raise ValueError("admission pins a different diagnostic launcher")
    launcher_hash = _sha(admission.get("launcher_sha256"), "launcher_sha256")
    if sha256_file(launcher_path) != launcher_hash:
        raise ValueError("diagnostic launcher changed after independent review")
    if admission.get("execution_authorized") is True and history.get("execution_authorized") is not False:
        raise ValueError("seed-history report cannot authorize its own execution")
    jobs = []
    for row in seeds:
        cell = row["cell"]
        safe = f"fa_rank/pilot/N{cell['N']}/{cell['signal']}"
        cell_dir = output_root / safe
        jobs.append({**row, "output_dir": cell_dir,
                     "config_path": cell_dir / "outer-0001.input.toml",
                     "artifact_path": cell_dir / "outer-0001.full.jls",
                     "log_path": cell_dir / "outer-0001.julia.log"})
    return {"admission": admission, "admission_path": admission_path,
            "admission_core_sha256": canonical_sha256(_admission_core(admission)),
            "history": history, "source_root": source_root, "source_hashes": source_hashes,
            "environment_hashes": environment_hashes, "output_root": output_root,
            "reservation_root": reservation_root, "julia": str(executable), "julia_sha256": julia_hash,
            "runtime_identity": runtime_identity, "runtime_inventory_sha256": runtime_hash,
            "launcher_path": launcher_path, "launcher_sha256": launcher_hash,
            "timeout_seconds": float(timeout), "runtime_estimate_seconds": float(estimate),
            "concurrency": concurrency, "jobs": jobs}


def _julia_version(executable: str, run: Callable[..., Any] = subprocess.run) -> str:
    completed = run([executable, "--startup-file=no", "--version"], capture_output=True,
                    text=True, timeout=10, check=True)
    text = completed.stdout + completed.stderr
    if "1.10.0" not in text:
        raise ValueError(f"Julia executable does not report the pinned 1.10.0 version: {text.strip()}")
    return "1.10.0"


def _exclusive_json(path: Path, value: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    flags = os.O_WRONLY | os.O_CREAT | os.O_EXCL
    fd = os.open(path, flags, 0o600)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as stream:
            json.dump(value, stream, sort_keys=True, separators=(",", ":"), allow_nan=False)
            stream.write("\n")
            stream.flush()
            os.fsync(stream.fileno())
    except BaseException:
        # The created reservation is deliberately retained as a consumed attempt.
        raise


def reserve_batch(plan: dict[str, Any]) -> None:
    """Consume all eight seeds in a shared, admission-independent ledger before dispatch."""
    root: Path = plan["reservation_root"]
    root.mkdir(parents=True, exist_ok=True)
    lock_path = root / ".arc1-diagnostic-ledger.lock"
    with lock_path.open("a+") as lock:
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
        try:
            for job in plan["jobs"]:
                seed = job["seed"]
                receipt = {"schema": "arc1-diagnostic-seed-reservation-v1",
                           "seed": seed, "cell": job["cell"], "outer": 1,
                           "admission_core_sha256": plan["admission_core_sha256"],
                           "status": "consumed_before_dispatch",
                           "history_report_sha256": plan["admission"]["history_report_sha256"]}
                _exclusive_json(root / f"seed-{seed}.json", receipt)
        finally:
            fcntl.flock(lock.fileno(), fcntl.LOCK_UN)


def _toml_quote(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def write_julia_config(plan: dict[str, Any], job: dict[str, Any]) -> None:
    job["output_dir"].mkdir(parents=True, exist_ok=True)
    if job["config_path"].exists():
        raise FileExistsError(f"refusing to replace diagnostic input config: {job['config_path']}")
    cell = job["cell"]
    source_root = plan["source_root"]
    lines = ["mode = \"diagnostic\"",
             f"source_root = {_toml_quote(str(source_root))}",
             f"attempt_output = {_toml_quote(str(job['output_dir']))}",
             f"artifact_path = {_toml_quote(str(job['artifact_path']))}",
             "outer = 1", f"seed = {_toml_quote(str(job['seed']))}",
             "blas_threads = 1", "profile_method_version = \"\"",
             f"protocol_sha256 = {_toml_quote(str(plan['admission'].get('protocol_sha256', '')))}",
             "bootstrap_seeds = []", "", "[cell]"]
    for key in ("programme", "phase", "signal"):
        lines.append(f"{key} = {_toml_quote(cell[key])}")
    lines.append(f"N = {cell['N']}")
    lines.extend(["", "[engine_hashes]"])
    for name, digest in sorted(plan["source_hashes"].items()):
        if name.startswith("src/"):
            lines.append(f"{_toml_quote(name)} = {_toml_quote(digest)}")
    lines.extend(["", "[environment_hashes]"])
    for name, digest in sorted(plan["environment_hashes"].items()):
        lines.append(f"{_toml_quote(name)} = {_toml_quote(digest)}")
    lines.extend(["", "[source_hashes]"])
    for name, digest in sorted(plan["source_hashes"].items()):
        lines.append(f"{_toml_quote(name)} = {_toml_quote(digest)}")
    with job["config_path"].open("x", encoding="utf-8") as stream:
        stream.write("\n".join(lines) + "\n")
        stream.flush()
        os.fsync(stream.fileno())


def _revalidate_plan(plan: dict[str, Any]) -> dict[str, Any]:
    fresh = build_plan(plan["admission_path"], check_output=False)
    if fresh["admission_core_sha256"] != plan["admission_core_sha256"]:
        raise ValueError("reviewed diagnostic admission changed after planning")
    return fresh


def _write_result(plan: dict[str, Any], job: dict[str, Any], result: dict[str, Any]) -> None:
    result_path = job["output_dir"] / "outer-0001.diagnostic-result.json"
    job["output_dir"].mkdir(parents=True, exist_ok=True)
    row = {"admission_core_sha256": plan["admission_core_sha256"],
           "history_report_sha256": plan["admission"]["history_report_sha256"],
           "source_map_sha256": plan["admission"]["source_map_sha256"],
           "runtime_inventory_sha256": plan["runtime_inventory_sha256"],
           "launcher_sha256": plan["launcher_sha256"],
           "reference_schedule": plan["admission"]["reference_schedule"],
           "paired_R_source_resolved": False, "gate_credit": False,
           "pilot_or_confirmation_credit": False, **result}
    _exclusive_json(result_path, row)


def _group_exists(pgid: int) -> bool:
    try:
        os.killpg(pgid, 0)
        return True
    except ProcessLookupError:
        return False
    except PermissionError:
        return True


def _stop_group(process: subprocess.Popen[str], grace: float = 3.0) -> None:
    try:
        os.killpg(process.pid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    deadline = time.monotonic() + grace
    while time.monotonic() < deadline:
        process.poll()
        if not _group_exists(process.pid):
            return
        time.sleep(0.02)
    if _group_exists(process.pid):
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    process.wait(timeout=grace)
    deadline = time.monotonic() + grace
    while _group_exists(process.pid) and time.monotonic() < deadline:
        time.sleep(0.02)
    if _group_exists(process.pid):
        raise RuntimeError("diagnostic Julia process group survived SIGKILL")


def _launch_one(plan: dict[str, Any], job: dict[str, Any],
                popen: Callable[..., subprocess.Popen[str]] = subprocess.Popen) -> dict[str, Any]:
    if _STOP_REQUESTED.is_set():
        result = {"schema": "arc1-diagnostic-result-v1", "cell": job["cell"],
                  "outer": 1, "seed": job["seed"], "success": False,
                  "status": "not_started_after_interrupt", "gate_credit": False,
                  "pilot_or_confirmation_credit": False}
        _write_result(plan, job, result)
        return result
    plan = _revalidate_plan(plan)
    write_julia_config(plan, job)
    command = [plan["julia"], "--startup-file=no", "--threads=1",
               f"--project={plan['source_root']}",
               str(plan["source_root"] / "sim/arc1/execute_attempt.jl"),
               str(job["config_path"])]
    env = dict(os.environ)
    env["JULIA_NUM_THREADS"] = "1"
    env["OPENBLAS_NUM_THREADS"] = "1"
    _exclusive_json(job["output_dir"] / "outer-0001.diagnostic-start.json", {
        "schema": "arc1-diagnostic-start-v1", "cell": job["cell"], "outer": 1,
        "seed": job["seed"], "command": command,
        "command_sha256": canonical_sha256(command),
        "admission_core_sha256": plan["admission_core_sha256"],
        "source_map_sha256": plan["admission"]["source_map_sha256"],
        "history_report_sha256": plan["admission"]["history_report_sha256"],
        "runtime_inventory_sha256": plan["runtime_inventory_sha256"],
        "runtime_estimate_seconds": plan["runtime_estimate_seconds"],
        "timeout_seconds": plan["timeout_seconds"],
        "started_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "reference_schedule": plan["admission"]["reference_schedule"],
    })
    started = time.monotonic()
    plan = _revalidate_plan(plan)
    process = popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True,
                    encoding="utf-8", errors="replace", env=env, start_new_session=True)
    with _ACTIVE_LOCK:
        _ACTIVE_PGIDS.add(process.pid)
        if _STOP_REQUESTED.is_set():
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
    deadline = started + plan["runtime_estimate_seconds"]
    status = "child_result"
    try:
        while True:
            if _STOP_REQUESTED.is_set():
                _stop_group(process)
                status = "interrupted"
                break
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                _stop_group(process)
                status = "runtime_estimate_exceeded"
                break
            try:
                stdout, stderr = process.communicate(timeout=min(0.25, remaining))
                break
            except subprocess.TimeoutExpired:
                continue
        if process.poll() is None:
            _stop_group(process)
        stdout, stderr = process.communicate()
        if _STOP_REQUESTED.is_set() and status == "child_result":
            status = "interrupted"
    except BaseException:
        # Any failure after spawn owns the complete process group. A failure in
        # communicate(), logging, or signal handling must not orphan Julia or
        # its workers; terminate descendants before reporting launcher_error.
        try:
            if process.poll() is None or _group_exists(process.pid):
                _stop_group(process)
        finally:
            for stream in (getattr(process, "stdout", None), getattr(process, "stderr", None)):
                if stream is not None:
                    stream.close()
        raise
    finally:
        with _ACTIVE_LOCK:
            _ACTIVE_PGIDS.discard(process.pid)
    elapsed = time.monotonic() - started
    job["log_path"].write_text("--- stdout ---\n" + (stdout or "") + "\n--- stderr ---\n" + (stderr or ""), encoding="utf-8")
    payload = None
    for line in reversed((stdout or "").splitlines()):
        try:
            candidate = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(candidate, dict) and candidate.get("schema") == "arc1-attempt-result-v1":
            payload = candidate
            break
    result = {"schema": "arc1-diagnostic-result-v1", "cell": job["cell"],
              "outer": 1, "seed": job["seed"], "status": status,
              "elapsed_seconds": elapsed, "child_exit_code": process.returncode,
              "success": bool(payload and payload.get("success") is True and process.returncode == 0),
              "gate_credit": False, "pilot_or_confirmation_credit": False,
              "stdout": stdout or "", "stderr": stderr or "", "child_receipt": payload}
    _write_result(plan, job, result)
    return result


def execute_plan(plan: dict[str, Any], *, popen: Callable[..., subprocess.Popen[str]] = subprocess.Popen,
                 version_probe: Callable[[str], str] | None = None) -> list[dict[str, Any]]:
    if plan["admission"].get("execution_authorized") is not True:
        raise ValueError("execution requires execution_authorized=true in the reviewed admission")
    if plan["output_root"].exists():
        raise ValueError("diagnostic output root already exists; refusing all retries")
    plan = _revalidate_plan(plan)
    probe = version_probe or _julia_version
    if probe(plan["julia"]) != "1.10.0":
        raise ValueError("Julia version differs from the reviewed admission")
    if plan["output_root"].exists():
        raise ValueError("diagnostic output root already exists; refusing all retries")
    plan["output_root"].mkdir(parents=True, exist_ok=False)
    _exclusive_json(plan["output_root"] / "diagnostic-admission.json", {
        "schema": "arc1-diagnostic-run-admission-v1",
        "admission_core_sha256": plan["admission_core_sha256"],
        "history_report_sha256": plan["admission"]["history_report_sha256"],
        "source_map_sha256": plan["admission"]["source_map_sha256"],
        "diagnostic_seed_sha256": plan["admission"]["diagnostic_seed_sha256"],
        "runtime_inventory_sha256": plan["runtime_inventory_sha256"],
        "launcher_sha256": plan["launcher_sha256"],
        "reference_schedule": plan["admission"]["reference_schedule"],
        "history_exhaustive": False, "paired_R_source_resolved": False,
        "gate_credit": False,
    })
    _STOP_REQUESTED.clear()
    reserve_batch(plan)
    results: list[dict[str, Any]] = []
    previous_handlers = {sig: signal.getsignal(sig) for sig in (signal.SIGINT, signal.SIGTERM)}

    def request_stop(signum, _frame):
        _STOP_REQUESTED.set()
        with _ACTIVE_LOCK:
            active = tuple(_ACTIVE_PGIDS)
        for pgid in active:
            try:
                os.killpg(pgid, signal.SIGTERM)
            except ProcessLookupError:
                pass

    for sig in previous_handlers:
        signal.signal(sig, request_stop)
    try:
        stop_after_estimate = False
        with concurrent.futures.ThreadPoolExecutor(max_workers=plan["concurrency"]) as pool:
            for offset in range(0, len(plan["jobs"]), plan["concurrency"]):
                wave = plan["jobs"][offset:offset + plan["concurrency"]]
                skip_status = ("not_started_after_runtime_estimate_exceeded" if stop_after_estimate else
                               "not_started_after_interrupt" if _STOP_REQUESTED.is_set() else None)
                if skip_status is not None:
                    for job in wave:
                        skipped = {"schema": "arc1-diagnostic-result-v1", "cell": job["cell"],
                                   "outer": 1, "seed": job["seed"], "success": False,
                                   "status": skip_status, "gate_credit": False,
                                   "pilot_or_confirmation_credit": False}
                        _write_result(plan, job, skipped)
                        results.append(skipped)
                    continue
                future_jobs = {pool.submit(_launch_one, plan, job, popen): job for job in wave}
                for future in concurrent.futures.as_completed(future_jobs):
                    job = future_jobs[future]
                    try:
                        result = future.result()
                        results.append(result)
                        stop_after_estimate |= result.get("status") == "runtime_estimate_exceeded"
                    except BaseException as exc:
                        failure = {"schema": "arc1-diagnostic-result-v1", "cell": job["cell"],
                                   "outer": 1, "seed": job["seed"], "success": False,
                                   "status": "launcher_error", "failure_reason": f"{type(exc).__name__}: {exc}",
                                   "gate_credit": False, "pilot_or_confirmation_credit": False}
                        result_path = job["output_dir"] / "outer-0001.diagnostic-result.json"
                        if not result_path.exists():
                            _write_result(plan, job, failure)
                        results.append(failure)
    finally:
        for sig, handler in previous_handlers.items():
            signal.signal(sig, handler)
    return sorted(results, key=lambda row: CELLS.index(row["cell"]))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--admission", required=True, type=Path)
    parser.add_argument("--execute", action="store_true", help="execute only after independent review")
    args = parser.parse_args(argv)
    try:
        plan = build_plan(args.admission)
        summary = {"status": "plan_only", "job_count": len(plan["jobs"]),
                   "cells": [{"cell": row["cell"], "outer": row["outer"], "seed": row["seed"]}
                             for row in plan["jobs"]],
                   "threads": plan["admission"]["threads"],
                   "concurrency": plan["concurrency"],
                   "timeout_seconds": plan["timeout_seconds"],
                   "runtime_estimate_seconds": plan["runtime_estimate_seconds"],
                   "admission_core_sha256": plan["admission_core_sha256"],
                   "history_exhaustive": False, "paired_R_source_resolved": False,
                   "gate_credit": False}
        if args.execute:
            results = execute_plan(plan)
            summary.update(status="completed_with_diagnostic_records", results=results,
                           success_count=sum(row.get("success") is True for row in results))
        print(json.dumps(summary, sort_keys=True, allow_nan=False))
        return 0 if not args.execute or all(row.get("success") is True for row in summary.get("results", [])) else 2
    except BaseException as exc:
        print(json.dumps({"status": "refused", "error_type": type(exc).__name__,
                          "error": str(exc)}, sort_keys=True), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
