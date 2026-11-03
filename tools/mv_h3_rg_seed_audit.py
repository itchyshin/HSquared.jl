#!/usr/bin/env python3
"""Read-only H3 RG seed-exclusion inventory; never allocates or runs seeds."""
from __future__ import annotations

import argparse
import csv
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
from datetime import datetime, timezone
from typing import Any, Iterable

SCHEMA = "mv-h3-rg-seed-exclusion-audit-v1"
REQUIRED_SOURCE_PATHS = (
    "docs/dev-log/recovery-checkpoints/2026-09-03-c1-ext-h1-h3-ademp-predeclaration.md",
    "sim/phase1_interval_coverage_ext.jl",
    "sim/phase1_c1_rerun_interval_coverage.jl",
    "sim/mv_h3_rg_screen_20261004.jl",
    "test/test_mv_h3_rg_screen_contract.jl",
)
PREDECLARATION = REQUIRED_SOURCE_PATHS[0]
CAMPAIGN_DRIVER = REQUIRED_SOURCE_PATHS[1]
SCREEN_TEST = REQUIRED_SOURCE_PATHS[4]
SEARCH_ROOTS = ("sim/", "test/", "docs/dev-log/", "docs/design/")
TEXT_SUFFIXES = {".jl", ".r", ".py", ".sh", ".sbatch", ".md", ".txt", ".csv", ".tsv", ".json", ".toml", ".yaml", ".yml"}
PATH_HINTS = ("h3", "seed", "manifest", "result", "interval", "coverage", "c1")
H3_MARKER = re.compile(r"\bh3[_ -]?rg\b|\bgenetic_correlation_interval\b|\bH3[- ]rg\b", re.I)
SEED_CONTEXT = re.compile(r"seed|rng|mersennetwister|predecl", re.I)
INTEGER = re.compile(r"(?<![\w.])(?:0[xX][0-9a-fA-F_]+|\d[\d_]*)(?![\w]|\.\d)")


def _run(root: Path, args: list[str], *, check: bool = True) -> bytes:
    proc = subprocess.run(["git", *args], cwd=root, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if check and proc.returncode:
        raise RuntimeError(f"git {' '.join(args)} failed ({proc.returncode}): {proc.stderr.decode('utf-8', 'replace').strip()}")
    return proc.stdout


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def _ref_inventory(root: Path) -> list[dict[str, str]]:
    raw = _run(root, ["for-each-ref", "--format=%(refname)%09%(objectname)"])
    refs = []
    for line in raw.decode("utf-8", "replace").splitlines():
        name, oid = line.split("\t", 1)
        refs.append({"ref": name, "object": oid})
    return refs


def _worktree_inventory(root: Path) -> list[dict[str, Any]]:
    raw = _run(root, ["worktree", "list", "--porcelain", "-z"])
    rows = []
    for block in raw.split(b"\0\0"):
        fields = [field.decode("utf-8", "replace") for field in block.split(b"\0") if field]
        if not fields:
            continue
        row: dict[str, Any] = {}
        for field in fields:
            key, _, value = field.partition(" ")
            if key == "worktree":
                row["path"] = value
            elif key == "HEAD":
                row["head"] = value
            elif key == "branch":
                row["branch"] = value
            elif key in {"detached", "bare", "locked", "prunable"}:
                row[key] = value or True
        rows.append(row)
    return rows


def _porcelain_entries(root: Path) -> list[tuple[str, str]]:
    raw = _run(root, ["status", "--porcelain=v1", "-z", "--untracked-files=all", "--ignored=matching"])
    entries: list[tuple[str, str]] = []
    parts = raw.split(b"\0")
    i = 0
    while i < len(parts) and parts[i]:
        token = parts[i].decode("utf-8", "surrogateescape")
        status = token[:2]
        path = token[3:] if len(token) > 3 else ""
        entries.append((status, path))
        i += 1
        if "R" in status or "C" in status:
            i += 1
    return entries


def _candidate_path(path: str) -> bool:
    if path in REQUIRED_SOURCE_PATHS:
        return True
    lower = path.lower()
    return lower.startswith(SEARCH_ROOTS) and Path(lower).suffix in TEXT_SUFFIXES and any(hint in lower for hint in PATH_HINTS)


def _has_h3_marker(path: str, raw: bytes) -> bool:
    if path in REQUIRED_SOURCE_PATHS:
        return True
    if b"\0" in raw:
        return False
    text = raw.decode("utf-8", "replace")
    return bool(H3_MARKER.search(text))


def _seed_literals(text: str) -> list[str]:
    values: set[str] = set()
    for line in text.splitlines():
        if SEED_CONTEXT.search(line):
            for value in INTEGER.findall(line):
                values.add(value.replace("_", ""))
    return sorted(values, key=lambda x: (len(x), x))


def _attempt_rows(path: str, raw: bytes) -> list[dict[str, Any]]:
    suffix = Path(path).suffix.lower()
    if suffix not in {".csv", ".tsv"}:
        return []
    lower_path = path.lower()
    # Fixture/input-declaration tables describe planned or test data; they do
    # not establish that a fit was executed, even if they carry a seed column.
    if "/fixtures/" in f"/{lower_path}" or "declaration" in Path(lower_path).name:
        return []
    result_path = any(token in f"/{lower_path}/" for token in ("/results/", "/outputs/", "/drac/"))
    if not result_path:
        return []
    try:
        text = raw.decode("utf-8-sig")
        rows = csv.DictReader(io.StringIO(text), delimiter="\t" if suffix == ".tsv" else ",")
    except (UnicodeDecodeError, csv.Error):
        return []
    attempts = []
    for number, row in enumerate(rows, start=2):
        normalized = {str(k).strip().lower(): (v or "").strip() for k, v in row.items() if k is not None}
        campaign = normalized.get("campaign", "").strip(":").lower()
        if campaign != "h3_rg":
            continue
        if not any(key in normalized for key in ("fit_success", "fit_converged", "interval_success", "failure_reason")):
            continue
        seed = normalized.get("seed")
        if not seed or not seed.isdigit():
            continue
        attempts.append({"row": number, "campaign": campaign or "path-tagged-h3-rg", "seed_literal": seed,
                         "record_type": "retained_attempt_row_claim", "execution_independently_verified": False,
                         "status_fields": {key: normalized[key] for key in ("fit_success", "interval_success", "fit_converged", "failure_reason") if key in normalized}})
    return attempts


def _tree_paths(root: Path, commit: str) -> dict[str, str]:
    raw = _run(root, ["ls-tree", "-r", "-z", "--full-tree", commit], check=False)
    if not raw:
        return {}
    result: dict[str, str] = {}
    for record in raw.split(b"\0"):
        if not record:
            continue
        metadata, path_b = record.split(b"\t", 1)
        fields = metadata.split()
        if len(fields) == 3 and fields[1] == b"blob":
            result[path_b.decode("utf-8", "surrogateescape")] = fields[2].decode("ascii")
    return result


def _object_bytes(root: Path, oid: str, cache: dict[str, bytes]) -> bytes:
    if oid not in cache:
        cache[oid] = _run(root, ["cat-file", "blob", oid])
    return cache[oid]


def _worktree_file_record(wt: dict[str, Any], status: str, rel: str) -> dict[str, Any]:
    path = Path(wt["path"]) / rel
    record: dict[str, Any] = {"worktree": wt["path"], "ref": wt.get("branch"), "head": wt.get("head"),
                              "status": status, "path": rel, "candidate": _candidate_path(rel)}
    try:
        if path.is_file():
            record.update({"kind": "file", "bytes": path.stat().st_size, "sha256": sha256_file(path)})
        elif path.is_dir():
            record.update({"kind": "directory", "sha256": None})
        else:
            record.update({"kind": "missing", "sha256": None})
    except OSError as error:
        record.update({"kind": "unreadable", "sha256": None, "error": str(error)})
    return record


def _inventory_gap(expected: Iterable[str], observed: Iterable[str]) -> list[str]:
    return sorted(set(expected) - set(observed))


def audit_repository(root: str | Path, *, observed_refs: Iterable[str] | None = None,
                     observed_worktrees: Iterable[str] | None = None,
                     declared_sources: Iterable[str] = REQUIRED_SOURCE_PATHS) -> dict[str, Any]:
    root = Path(root).resolve()
    if not (root / ".git").exists() and not (root / ".git").is_file():
        raise ValueError(f"not a Git worktree: {root}")
    refs = _ref_inventory(root)
    worktrees = _worktree_inventory(root)
    ref_names = [row["ref"] for row in refs]
    wt_paths = [str(Path(row["path"]).resolve()) for row in worktrees]
    unresolved: list[dict[str, str]] = []
    if observed_refs is not None:
        for missing in _inventory_gap(ref_names, observed_refs):
            unresolved.append({"kind": "omitted_ref", "identity": missing})
    if observed_worktrees is not None:
        for missing in _inventory_gap(wt_paths, (str(Path(p).resolve()) for p in observed_worktrees)):
            unresolved.append({"kind": "omitted_worktree", "identity": missing})
    for missing in _inventory_gap(REQUIRED_SOURCE_PATHS, declared_sources):
        unresolved.append({"kind": "omitted_required_source", "identity": missing})

    remote_names = _run(root, ["remote"], check=False).decode("utf-8", "replace").splitlines()
    for remote in remote_names:
        unresolved.append({"kind": "remote_host_not_queried", "identity": remote})
    unresolved.append({"kind": "out_of_root_historical_result_stores", "identity": "not globally inventoried"})
    unresolved.append({"kind": "sister_R_doc34", "identity": "cited by predeclaration; outside this repository and not inventoried"})

    source_records: list[dict[str, Any]] = []
    tracked_artifacts: list[dict[str, Any]] = []
    predeclarations: list[dict[str, Any]] = []
    literal_inventory: list[dict[str, Any]] = []
    retained_attempt_rows: list[dict[str, Any]] = []
    tree_cache: dict[str, dict[str, str]] = {}
    blob_cache: dict[str, bytes] = {}
    tree_errors: list[dict[str, str]] = []
    selected_sources = set(REQUIRED_SOURCE_PATHS)
    for ref in refs:
        commit = _run(root, ["rev-parse", "--verify", f"{ref['ref']}^{{commit}}"], check=False).decode().strip()
        if not commit:
            tree_errors.append({"ref": ref["ref"], "error": "reference has no readable commit"})
            unresolved.append({"kind": "missing_ref_object", "identity": ref["ref"]})
            continue
        if commit not in tree_cache:
            tree_cache[commit] = _tree_paths(root, commit)
        tree = tree_cache[commit]
        for path in sorted(selected_sources):
            oid = tree.get(path)
            source_records.append({"ref": ref["ref"], "ref_object": ref["object"], "commit": commit,
                                   "path": path, "present": oid is not None,
                                   "git_blob": oid, "sha256": sha256_bytes(_object_bytes(root, oid, blob_cache)) if oid else None,
                                   "classification": "predeclaration" if path == PREDECLARATION else
                                       "h3_screen_test_fixture_source" if path == SCREEN_TEST else
                                       "h3_campaign_or_contract_source"})
            if oid and path != PREDECLARATION:
                raw = _object_bytes(root, oid, blob_cache)
                literals = _seed_literals(raw.decode("utf-8", "replace"))
                if literals:
                    literal_inventory.append({"ref": ref["ref"], "path": path, "sha256": sha256_bytes(raw),
                        "classification": "test_fixture_or_source_literal_not_execution",
                        "seed_context_integer_literals": literals})
        for path, oid in tree.items():
            if not _candidate_path(path) or path in selected_sources:
                continue
            raw = _object_bytes(root, oid, blob_cache)
            if not _has_h3_marker(path, raw):
                continue
            text = raw.decode("utf-8", "replace")
            digest = sha256_bytes(raw)
            attempts = _attempt_rows(path, raw)
            literals = _seed_literals(text)
            if literals:
                literal_inventory.append({"ref": ref["ref"], "path": path, "sha256": digest,
                    "classification": "predeclared_or_source_literal_not_execution" if path.startswith(("sim/", "test/", "docs/")) else "unclassified_literal",
                    "seed_context_integer_literals": literals})
            is_candidate_result = (path.lower().endswith((".csv", ".tsv", ".json")) and
                                   ("/results/" in f"/{path.lower()}/" or "/outputs/" in f"/{path.lower()}/"))
            if H3_MARKER.search(text):
                tracked_artifacts.append({"ref": ref["ref"], "ref_object": ref["object"], "path": path,
                    "sha256": digest, "bytes": len(raw), "classification":
                        "tracked_h3_seed_manifest_or_result_candidate" if is_candidate_result else "tracked_h3_interval_or_seed_source",
                    "retained_attempt_rows": len(attempts)})
                for attempt in attempts:
                    retained_attempt_rows.append({"ref": ref["ref"], "path": path, "sha256": digest, **attempt})
        pre_oid = tree.get(PREDECLARATION)
        if pre_oid:
            raw = _object_bytes(root, pre_oid, blob_cache)
            text = raw.decode("utf-8", "replace")
            relevant_lines = [line.strip() for line in text.splitlines()
                              if re.search(r"master seed|rep seed|seed stride|screening:|confirm:", line, re.I)]
            predeclarations.append({"ref": ref["ref"], "path": PREDECLARATION, "sha256": sha256_bytes(raw),
                "status": "predeclared_not_execution_evidence", "seed_design_lines": relevant_lines,
                "seed_context_integer_literals": _seed_literals(text)})

    for error in tree_errors:
        unresolved.append({"kind": "ref_tree_unavailable", "identity": error["ref"]})
    pinned_paths_present = {row["path"] for row in source_records if row["present"]}
    for required in REQUIRED_SOURCE_PATHS:
        present_on_disk = any((Path(wt["path"]) / required).is_file()
                              for wt in worktrees if Path(wt["path"]).exists())
        if required not in pinned_paths_present and not present_on_disk:
            unresolved.append({"kind": "required_source_missing_everywhere", "identity": required})
    # Every current worktree contributes status, dirty/untracked hashes, and compact ignored-directory entries.
    worktree_rows: list[dict[str, Any]] = []
    worktree_file_rows: list[dict[str, Any]] = []
    for wt in worktrees:
        path = Path(wt["path"])
        row = dict(wt)
        row["path"] = str(path)
        if not path.exists():
            row["accessible"] = False
            unresolved.append({"kind": "inaccessible_worktree", "identity": str(path)})
            worktree_rows.append(row)
            continue
        row["accessible"] = True
        try:
            entries = _porcelain_entries(path)
            row["status_entry_count"] = len(entries)
            for status, rel in entries:
                file_row = _worktree_file_record(wt, status, rel)
                worktree_file_rows.append(file_row)
                if status == "!!":
                    unresolved.append({"kind": "ignored_inventory_not_descended", "identity": f"{path}/{rel}"})
                elif status == "??" and not file_row.get("sha256"):
                    unresolved.append({"kind": "unhashed_untracked_candidate", "identity": f"{path}/{rel}"})
        except (RuntimeError, OSError) as error:
            row["accessible"] = False
            unresolved.append({"kind": "worktree_status_unavailable", "identity": f"{path}: {error}"})
        worktree_rows.append(row)

    # Current and dirty working files are listed separately from retained results.
    current_candidates = []
    for record in worktree_file_rows:
        if record.get("worktree") == str(root) and (record.get("candidate") or record.get("status") in {"??", "!!"}):
            current_candidates.append(record)

    audit = {
        "schema": SCHEMA,
        "purpose": "exclusion inventory only; not seed allocation, execution authorization, or freshness proof",
        "root": str(root),
        "generated_utc": datetime.now(timezone.utc).isoformat(),
        "freshness_verified": False,
        "execution_authorized": False,
        "seed_allocation_performed": False,
        "simulation_or_fit_performed": False,
        "required_sources": list(REQUIRED_SOURCE_PATHS),
        "ref_count": len(refs), "refs": refs,
        "worktree_count": len(worktrees), "worktrees": worktree_rows,
        "ref_source_inventory": source_records,
        "predeclarations": predeclarations,
        "seed_literal_inventory": literal_inventory,
        "tracked_h3_artifact_candidates": tracked_artifacts,
        "retained_attempt_rows": retained_attempt_rows,
        "current_worktree_candidate_and_untracked_inventory": current_candidates,
        "worktree_status_inventory": worktree_file_rows,
        "remote_names_not_queried": remote_names,
        "unresolved_sources": unresolved,
        "interpretation": {
            "predeclared_seed_literals_are_not_executed_attempts": True,
            "retained_attempt_rows_are_artifact_claims_not_independent_execution_proof": True,
            "fixture_seed_literals_are_not_executed_attempts": True,
            "freshness_is_false_until_external_hosts_and_out_of_root_stores_are_checked": True,
        },
    }
    audit["inventory_sha256"] = sha256_bytes(json.dumps(audit, sort_keys=True, separators=(",", ":")).encode())
    return audit


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--output", type=Path, help="optional JSON path; default prints to stdout")
    args = parser.parse_args(argv)
    report = audit_repository(args.root)
    text = json.dumps(report, indent=2, sort_keys=True) + "\n"
    if args.output:
        args.output.write_text(text, encoding="utf-8")
    else:
        sys.stdout.write(text)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
