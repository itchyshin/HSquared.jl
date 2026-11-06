#!/usr/bin/env python3
"""Build a finite, hash-pinned seed-history inventory for Arc 1 diagnostics.

This tool reports only the explicitly supplied files. It does not certify that
all historical attempt stores have been found or searched.
"""
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import sys
import tomllib
from pathlib import Path
from typing import Any, Iterable

SCHEMA = "arc1-diagnostic-seed-history-v1"
AMENDMENT_ID = "2026-10-24-arc1-source-history-rebuild"
CELLS = [
    {"programme": "fa_rank", "phase": "pilot", "N": n, "signal": signal}
    for n in (80, 160, 320) for signal in ("null", "weak", "strong")
    if (n, signal) != (80, "null")
]
MAX_BYTES = 250_000_000
UINT64_MAX = 2**64 - 1
SEED_FIELDS = {"seed", "outer_seed", "bootstrap_seed"}
SEED_ARRAY_FIELDS = {"seeds", "bootstrap_seeds"}


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def canonical_sha256(value: Any) -> str:
    return sha256(json.dumps(value, sort_keys=True, separators=(",", ":"),
                            ensure_ascii=False, allow_nan=False).encode("utf-8"))


def _validate_seed(value: Any) -> int | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, int) and 0 <= value <= UINT64_MAX:
        return value
    if isinstance(value, str) and value.isdecimal():
        parsed = int(value)
        if parsed <= UINT64_MAX:
            return parsed
    if isinstance(value, str) and re.fullmatch(r"0[xX][0-9a-fA-F]{16}", value):
        return int(value, 16)
    return None


def _seed_values(value: Any, *, field: str, record: str,
                 errors: list[str]) -> Iterable[dict[str, Any]]:
    values = value if field in SEED_ARRAY_FIELDS and isinstance(value, list) else [value]
    if field in SEED_ARRAY_FIELDS and not isinstance(value, list):
        errors.append(f"{record}.{field} must be an array")
        return
    for index, item in enumerate(values):
        seed = _validate_seed(item)
        if seed is None:
            errors.append(f"{record}.{field}[{index}] is not a UInt64 seed")
            continue
        yield {"seed": seed, "record": f"{record}.{field}[{index}]",
               "consumed": True}


def _walk_seed_fields(value: Any, *, record: str = "$",
                      errors: list[str] | None = None) -> Iterable[dict[str, Any]]:
    """Collect recognized scalar and vector seed fields from structured records."""
    errors = errors if errors is not None else []
    if isinstance(value, dict):
        for key in sorted(SEED_FIELDS | SEED_ARRAY_FIELDS):
            if key in value:
                yield from _seed_values(value[key], field=key, record=record,
                                        errors=errors)
        for key, child in value.items():
            if isinstance(child, (dict, list)):
                yield from _walk_seed_fields(child, record=f"{record}.{key}",
                                             errors=errors)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from _walk_seed_fields(child, record=f"{record}[{index}]",
                                         errors=errors)


def _parse_record(path: Path, role: str) -> tuple[dict[str, Any], set[int]]:
    entry: dict[str, Any] = {"path": str(path), "role": role}
    seeds: set[int] = set()
    try:
        raw = path.read_bytes()
    except OSError as exc:
        entry.update(status="unreadable", error=f"{type(exc).__name__}: {exc}")
        return entry, seeds
    entry.update(bytes=len(raw), sha256=sha256(raw))
    if len(raw) > MAX_BYTES:
        entry.update(status="unparsed", error=f"file exceeds {MAX_BYTES} byte parser limit")
        return entry, seeds
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError as exc:
        entry.update(status="unparsed", error=f"invalid UTF-8: {exc}")
        return entry, seeds
    suffix = path.suffix.lower()
    try:
        if suffix in {".csv", ".tsv"}:
            delimiter = "\t" if suffix == ".tsv" else ","
            rows = list(csv.DictReader(text.splitlines(), delimiter=delimiter))
            if not rows:
                raise ValueError("CSV has no data rows")
            if rows and "seed" not in rows[0]:
                raise ValueError("CSV has no explicit seed column")
            if role == "allocation" and rows and not {"programme", "phase"}.issubset(rows[0]):
                raise ValueError("frozen allocation CSV requires programme and phase columns")
            for rownum, row in enumerate(rows, start=2):
                seed = _validate_seed(row.get("seed"))
                if seed is None:
                    raise ValueError(f"CSV row {rownum} has an invalid or missing seed")
                seeds.add(seed)
                entry.setdefault("seed_records", []).append(
                    {"seed": seed, "record": f"row:{rownum}", "consumed": True})
                if role == "allocation":
                    entry.setdefault("allocation_phases", set()).add(row.get("phase"))
        elif suffix in {".json", ".jsonl"}:
            if suffix == ".jsonl":
                parsed = [json.loads(line) for line in text.splitlines() if line.strip()]
            else:
                parsed = json.loads(text)
            parse_issues: list[str] = []
            found = list(_walk_seed_fields(parsed, errors=parse_issues))
            entry["seed_records"] = found
            seeds.update(item["seed"] for item in found)
            if parse_issues:
                raise ValueError("; ".join(parse_issues))
            if not found:
                raise ValueError("structured record has no recognized seed fields")
        elif suffix == ".toml":
            parsed = tomllib.loads(text)
            parse_issues = []
            found = list(_walk_seed_fields(parsed, errors=parse_issues))
            entry["seed_records"] = found
            seeds.update(item["seed"] for item in found)
            if parse_issues:
                raise ValueError("; ".join(parse_issues))
            if not found:
                raise ValueError("structured record has no recognized seed fields")
        else:
            raise ValueError(f"unsupported structured format: {suffix or '(no extension)'}")
    except (ValueError, csv.Error, json.JSONDecodeError) as exc:
        entry.update(status="unparsed", error=f"{type(exc).__name__}: {exc}")
        entry["seed_records"] = entry.get("seed_records", [])
        entry["seed_count"] = len(seeds)
        return entry, seeds
    entry["status"] = "parsed"
    entry["seed_count"] = len(seeds)
    if "allocation_phases" in entry:
        entry["allocation_phases"] = sorted(entry["allocation_phases"])
    return entry, seeds


def derive_seeds(amendment_sha256: str) -> list[dict[str, Any]]:
    """Deterministically derive one UInt64 seed per exact diagnostic cell."""
    result = []
    for cell in CELLS:
        label = "/".join((AMENDMENT_ID, amendment_sha256, cell["programme"],
                          cell["phase"], str(cell["N"]), cell["signal"], "outer=1"))
        seed = int.from_bytes(hashlib.sha256(label.encode("utf-8")).digest()[:8], "big")
        result.append({"cell": dict(cell), "outer": 1, "seed": seed,
                       "namespace": AMENDMENT_ID})
    return result


def build_report(*, amendment_path: Path, source_map_path: Path,
                 allocation_paths: list[Path], record_paths: list[Path],
                 missing_paths: list[Path] | None = None) -> dict[str, Any]:
    amendment_path = amendment_path.resolve()
    source_map_path = source_map_path.resolve()
    amendment_bytes = amendment_path.read_bytes()
    source_map_bytes = source_map_path.read_bytes()
    amendment_hash = sha256(amendment_bytes)
    try:
        source_map = json.loads(source_map_bytes)
    except json.JSONDecodeError as exc:
        raise ValueError("source map must be valid JSON") from exc
    root_raw = source_map.get("root") if isinstance(source_map, dict) else None
    if not isinstance(root_raw, str) or not root_raw.strip():
        raise ValueError("source map must declare its root directory")
    declared_root = Path(root_raw).expanduser()
    if not declared_root.is_absolute():
        declared_root = source_map_path.parent / declared_root
    root = declared_root.resolve(strict=True)
    if not root.is_dir():
        raise ValueError("source map root must be a directory")
    files = source_map.get("files") if isinstance(source_map, dict) else None
    if not isinstance(files, list) or not files:
        raise ValueError("source map must contain a nonempty files list")
    source_entries = []
    source_paths: set[Path] = set()
    for item in files:
        if not isinstance(item, dict) or not isinstance(item.get("path"), str) or not isinstance(item.get("sha256"), str):
            raise ValueError("source map entries require path and sha256")
        candidate = Path(item["path"]).expanduser()
        if not candidate.is_absolute():
            candidate = root / candidate
        path = candidate.resolve(strict=True)
        if not path.is_relative_to(root):
            raise ValueError(f"source map path escapes declared root: {path}")
        if path in source_paths:
            raise ValueError(f"duplicate source map path: {path}")
        source_paths.add(path)
        raw = path.read_bytes()
        actual = sha256(raw)
        if actual != item["sha256"]:
            raise ValueError(f"source map hash mismatch: {path}")
        source_entries.append({"path": str(path), "bytes": len(raw), "sha256": actual})

    if not allocation_paths:
        raise ValueError("at least one frozen allocation input is required")

    records = []
    consumed: set[int] = set()
    allocation_phases: set[str] = set()
    supplied = [(path, "allocation") for path in allocation_paths]
    supplied.extend((path, "attempt_record") for path in record_paths)
    seen: set[Path] = set()
    for path, role in supplied:
        resolved = path.expanduser().resolve()
        if resolved in seen:
            raise ValueError(f"duplicate supplied record path: {resolved}")
        seen.add(resolved)
        entry, seeds = _parse_record(resolved, role)
        if role == "allocation" and (entry["status"] != "parsed" or not seeds):
            raise ValueError(f"required frozen allocation is missing, unparsed, or seedless: {resolved}")
        if role == "allocation":
            allocation_phases.update(entry.get("allocation_phases", []))
        records.append(entry)
        consumed.update(seeds)
    required_phases = {"development", "pilot", "confirmation"}
    if not required_phases.issubset(allocation_phases):
        raise ValueError("frozen allocation inputs must cover development, pilot, and confirmation")
    missing = []
    for path in missing_paths or []:
        resolved = path.expanduser().resolve()
        missing.append({"path": str(resolved), "status": "missing_or_unavailable"})

    diagnostic = derive_seeds(amendment_hash)
    diagnostic_values = [item["seed"] for item in diagnostic]
    if len(set(diagnostic_values)) != 8:
        raise ValueError("diagnostic namespace produced duplicate seeds")
    collisions = sorted(set(diagnostic_values) & consumed)
    if collisions:
        raise ValueError(f"diagnostic seed collision in supplied scope: {collisions}")
    inv_body = {"schema": "arc1-diagnostic-history-inventory-v1",
                "records": records, "missing_or_unavailable": missing,
                "scope_statement": "Only explicitly supplied allocation and attempt-record files were inspected.",
                "exhaustive_history_claim": False}
    inv_body["inventory_sha256"] = canonical_sha256(inv_body)
    report = {
        "schema": SCHEMA,
        "status": "candidate_scoped_collision_check_passed",
        "seed_generator": {"path": str(Path(__file__).resolve()),
                           "sha256": sha256(Path(__file__).read_bytes())},
        "amendment": {"id": AMENDMENT_ID, "path": str(amendment_path),
                      "sha256": amendment_hash},
        "source_map": {"path": str(source_map_path), "root": str(root),
                       "sha256": sha256(source_map_bytes),
                       "files": source_entries,
                       "canonical_sha256": canonical_sha256(source_entries)},
        "history_inventory": inv_body,
        "history_scope": {"claim": "no_collision_among_extracted_seeds_pending_review",
                          "exhaustive": False,
                          "unreadable_count": sum(x["status"] == "unreadable" for x in records),
                          "unparsed_count": sum(x["status"] == "unparsed" for x in records),
                          "missing_or_unavailable_count": len(missing),
                          "independent_review_required": True},
        "diagnostic_seeds": diagnostic,
        "diagnostic_seed_sha256": canonical_sha256(diagnostic),
        "consumed_seed_count_in_supplied_scope": len(consumed),
        "collisions": [],
        "execution_authorized": False,
        "pilot_or_confirmation_authorized": False,
        "gate_credit": False,
    }
    report["report_sha256"] = canonical_sha256(report)
    return report


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--amendment", type=Path, required=True)
    parser.add_argument("--source-map", type=Path, required=True,
                        help="JSON object with files:[{path,sha256}, ...]")
    parser.add_argument("--allocation", type=Path, action="append", default=[])
    parser.add_argument("--record", type=Path, action="append", default=[])
    parser.add_argument("--missing", type=Path, action="append", default=[],
                        help="known unavailable path, retained as a coverage limitation")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args(argv)
    try:
        report = build_report(amendment_path=args.amendment,
                              source_map_path=args.source_map,
                              allocation_paths=args.allocation,
                              record_paths=args.record, missing_paths=args.missing)
        args.output.parent.mkdir(parents=True, exist_ok=True)
        with args.output.open("x", encoding="utf-8") as stream:
            json.dump(report, stream, sort_keys=True, indent=2)
            stream.write("\n")
    except (OSError, ValueError) as exc:
        print(f"arc1 diagnostic seed history: {exc}", file=sys.stderr)
        return 2
    print(json.dumps({"status": report["status"], "diagnostic_seed_sha256": report["diagnostic_seed_sha256"],
                      "record_count": len(report["history_inventory"]["records"]),
                      "unreadable_count": report["history_scope"]["unreadable_count"],
                      "unparsed_count": report["history_scope"]["unparsed_count"],
                      "exhaustive": False}, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
