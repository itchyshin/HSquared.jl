from __future__ import annotations

import csv
import hashlib
import json
import os
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
import sys
sys.path.insert(0, str(ROOT / "tools"))
from arc1_diagnostic_seed_history import (
    AMENDMENT_ID,
    CELLS,
    build_report,
    canonical_sha256,
    derive_seeds,
)


class DiagnosticSeedHistoryTests(unittest.TestCase):
    def setUp(self) -> None:
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.amendment = self.root / "amendment.md"
        self.amendment.write_text("reviewed candidate amendment\n", encoding="utf-8")
        self.source = self.root / "engine.jl"
        self.source.write_text("module Engine end\n", encoding="utf-8")
        self.allocation = self.root / "allocations.csv"
        self.write_allocation([5])
        self.source_map = self.root / "source-map.json"
        self.write_source_map()

    def tearDown(self) -> None:
        self.tmp.cleanup()

    def write_source_map(self) -> None:
        payload = {"root": str(self.root), "files": [{"path": "engine.jl",
                              "sha256": hashlib.sha256(self.source.read_bytes()).hexdigest()}]}
        self.source_map.write_text(json.dumps(payload), encoding="utf-8")

    def write_allocation(self, seeds):
        with self.allocation.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=["programme", "phase", "seed"])
            writer.writeheader()
            base = list(seeds)
            for index, phase in enumerate(("development", "pilot", "confirmation")):
                for seed in base:
                    writer.writerow({"programme": "fa_rank", "phase": phase,
                                     "seed": (seed + index) % (2**64)})

    def build(self, allocations=(), records=(), missing=()):
        return build_report(amendment_path=self.amendment,
                            source_map_path=self.source_map,
                            allocation_paths=list(allocations) or [self.allocation],
                            record_paths=list(records), missing_paths=list(missing))

    def test_deterministic_eight_seed_partition_is_pilot_only_and_unapproved(self) -> None:
        report = self.build()
        self.assertEqual(len(report["diagnostic_seeds"]), 8)
        self.assertEqual([item["cell"] for item in report["diagnostic_seeds"]], CELLS)
        self.assertEqual(len({item["seed"] for item in report["diagnostic_seeds"]}), 8)
        self.assertTrue(all(item["outer"] == 1 and item["namespace"] == AMENDMENT_ID
                            for item in report["diagnostic_seeds"]))
        self.assertEqual(report, self.build())
        self.assertFalse(report["history_scope"]["exhaustive"])
        self.assertEqual(report["history_scope"]["claim"],
                         "no_collision_among_extracted_seeds_pending_review")
        self.assertTrue(report["history_scope"]["independent_review_required"])
        self.assertFalse(report["execution_authorized"])
        self.assertFalse(report["pilot_or_confirmation_authorized"])
        self.assertFalse(report["gate_credit"])

    def test_rejects_collision_with_any_supplied_allocation_seed(self) -> None:
        seed = derive_seeds(hashlib.sha256(self.amendment.read_bytes()).hexdigest())[0]["seed"]
        self.write_allocation([seed])
        with self.assertRaisesRegex(ValueError, "diagnostic seed collision"):
            self.build()

    def test_rejects_source_map_drift(self) -> None:
        self.source.write_text("changed engine bytes\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "source map hash mismatch"):
            self.build()

    def test_records_unreadable_unparsed_and_unavailable_coverage(self) -> None:
        unreadable = self.root / "gone.json"
        malformed = self.root / "broken.json"
        malformed.write_text("{not-json", encoding="utf-8")
        unavailable = self.root / "remote-archive.tar"
        report = self.build(records=[unreadable, malformed], missing=[unavailable])
        self.assertEqual(report["history_scope"]["unreadable_count"], 1)
        self.assertEqual(report["history_scope"]["unparsed_count"], 1)
        self.assertEqual(report["history_scope"]["missing_or_unavailable_count"], 1)
        statuses = {entry["path"]: entry["status"]
                    for entry in report["history_inventory"]["records"]}
        self.assertEqual(statuses[str(unreadable.resolve())], "unreadable")
        self.assertEqual(statuses[str(malformed.resolve())], "unparsed")
        self.assertEqual(report["history_inventory"]["missing_or_unavailable"][0]["status"],
                         "missing_or_unavailable")
        self.assertFalse(report["history_inventory"]["exhaustive_history_claim"])

    def test_hashes_bind_inventory_and_seed_partition(self) -> None:
        report = self.build()
        inventory = report["history_inventory"]
        expected_inventory = {key: value for key, value in inventory.items()
                              if key != "inventory_sha256"}
        self.assertEqual(inventory["inventory_sha256"], canonical_sha256(expected_inventory))
        body = {key: value for key, value in report.items() if key != "report_sha256"}
        self.assertEqual(report["report_sha256"], canonical_sha256(body))
        self.assertEqual(report["diagnostic_seed_sha256"],
                         canonical_sha256(report["diagnostic_seeds"]))
        self.assertEqual(report["seed_generator"]["sha256"],
                         hashlib.sha256(Path(report["seed_generator"]["path"]).read_bytes()).hexdigest())

    def test_relative_source_paths_resolve_under_declared_root_from_other_cwd(self) -> None:
        cwd = Path.cwd()
        try:
            os.chdir(self.root.parent)
            report = self.build()
        finally:
            os.chdir(cwd)
        self.assertEqual(report["source_map"]["root"], str(self.root.resolve()))
        self.assertEqual(report["source_map"]["files"][0]["path"], str(self.source.resolve()))

    def test_source_map_rejects_duplicate_and_symlink_escape_paths(self) -> None:
        outside = self.root.parent / f"{self.root.name}-outside.jl"
        outside.write_text("outside\n", encoding="utf-8")
        symlink = self.root / "escape.jl"
        try:
            symlink.symlink_to(outside)
            payload = {"root": str(self.root), "files": [
                {"path": "escape.jl", "sha256": hashlib.sha256(outside.read_bytes()).hexdigest()}]}
            self.source_map.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "escapes declared root"):
                self.build()
            payload["files"] = [
                {"path": "engine.jl", "sha256": hashlib.sha256(self.source.read_bytes()).hexdigest()},
                {"path": str(self.source), "sha256": hashlib.sha256(self.source.read_bytes()).hexdigest()}]
            self.source_map.write_text(json.dumps(payload), encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "duplicate source map path"):
                self.build()
        finally:
            outside.unlink(missing_ok=True)

    def test_extracts_known_scalar_and_array_seed_fields(self) -> None:
        path = self.root / "attempts.json"
        path.write_text(json.dumps({"attempts": [
            {"outer_seed": 11}, {"bootstrap_seed": "12"},
            {"seeds": [13, 14]}, {"bootstrap_seeds": [15, "16"]}]}), encoding="utf-8")
        report = self.build(records=[path])
        item = next(entry for entry in report["history_inventory"]["records"]
                    if entry["path"] == str(path.resolve()))
        self.assertEqual(item["status"], "parsed")
        self.assertEqual({record["seed"] for record in item["seed_records"]},
                         {11, 12, 13, 14, 15, 16})

    def test_invalid_or_unknown_history_schema_stays_unparsed(self) -> None:
        invalid = self.root / "invalid-seed.json"
        invalid.write_text('{"outer_seed": "not-a-number", "seed": 999}', encoding="utf-8")
        unknown = self.root / "unknown.json"
        unknown.write_text('{"attempt_id": "a1", "state": "finished"}', encoding="utf-8")
        report = self.build(records=[invalid, unknown])
        states = {Path(entry["path"]).name: entry["status"]
                  for entry in report["history_inventory"]["records"]}
        self.assertEqual({key: value for key, value in states.items() if key != "allocations.csv"},
                         {"invalid-seed.json": "unparsed", "unknown.json": "unparsed"})
        self.assertEqual(report["history_scope"]["unparsed_count"], 2)

    def test_valid_seed_survives_later_invalid_nested_seed_and_still_collides(self) -> None:
        generated = derive_seeds(hashlib.sha256(self.amendment.read_bytes()).hexdigest())[0]["seed"]
        path = self.root / "mixed-attempts.json"
        path.write_text(json.dumps({"attempts": [
            {"outer_seed": generated},
            {"nested": {"bootstrap_seeds": ["malformed", 123]}}]}), encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "diagnostic seed collision"):
            self.build(records=[path])

    def test_toml_seed_fields_are_extracted_for_collision_checks(self) -> None:
        generated = derive_seeds(hashlib.sha256(self.amendment.read_bytes()).hexdigest())[2]["seed"]
        path = self.root / "attempt-summary.toml"
        path.write_text(f'seed = "{generated}"\nstatus = "failed"\n', encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "diagnostic seed collision"):
            self.build(records=[path])

    def test_tsv_explicit_seed_column_is_extracted_for_collision_checks(self) -> None:
        generated = derive_seeds(hashlib.sha256(self.amendment.read_bytes()).hexdigest())[4]["seed"]
        path = self.root / "attempts.tsv"
        path.write_text(f"attempt\tseed\tstatus\n1\t{generated}\tfailed\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "diagnostic seed collision"):
            self.build(records=[path])

    def test_invalid_nested_sibling_marks_unparsed_but_keeps_valid_seed(self) -> None:
        path = self.root / "mixed-attempts.json"
        path.write_text('{"attempts":[{"outer_seed":123},{"nested":{"seed":"bad"}}]}',
                        encoding="utf-8")
        report = self.build(records=[path])
        entry = next(item for item in report["history_inventory"]["records"]
                     if item["path"] == str(path.resolve()))
        self.assertEqual(entry["status"], "unparsed")
        self.assertEqual([item["seed"] for item in entry["seed_records"]], [123])
        self.assertEqual(report["consumed_seed_count_in_supplied_scope"], 4)

    def test_required_allocation_set_cannot_be_empty_or_unparsed(self) -> None:
        with self.assertRaisesRegex(ValueError, "at least one frozen allocation"):
            build_report(amendment_path=self.amendment, source_map_path=self.source_map,
                         allocation_paths=[], record_paths=[])
        broken = self.root / "broken-allocation.csv"
        broken.write_text("programme,phase\nfa_rank,development\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "required frozen allocation"):
            self.build(allocations=[broken])

    def test_required_allocation_phases_must_all_be_present(self) -> None:
        partial = self.root / "partial.csv"
        partial.write_text("programme,phase,seed\nfa_rank,development,5\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "cover development, pilot, and confirmation"):
            self.build(allocations=[partial])


if __name__ == "__main__":
    unittest.main()
