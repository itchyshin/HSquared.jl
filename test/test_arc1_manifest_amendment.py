from __future__ import annotations

import sys
import hashlib
import json
import shutil
import tempfile
from pathlib import Path
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import arc1_manifest


class FaRankDevelopmentAmendmentTests(unittest.TestCase):
    def test_development_allocation_has_separate_thirty_case_amendment(self):
        allocation = arc1_manifest.SCIENTIFIC_CONTRACT["allocation"]["fa_rank"]
        self.assertEqual(allocation["development"], 60)
        self.assertEqual(allocation["development_tranche"], {
            "historical_source_indices": [1, 30],
            "amended_source_indices": [31, 60],
        })

    def test_rank_rows_expand_without_changing_other_programmes(self):
        rows = list(arc1_manifest.outer_rows())
        rank_development = [row for row in rows
                            if row["programme"] == "fa_rank" and row["phase"] == "development"]
        self.assertEqual(len(rank_development), 9 * 60)
        for n in (80, 160, 320):
            for signal in arc1_manifest.FA_SIGNALS:
                indices = [row["outer"] for row in rank_development
                           if row["N"] == n and row["signal"] == signal]
                self.assertEqual(indices, list(range(1, 61)))
        for programme in ("repeatability", "fa_interval"):
            development = [row for row in rows
                           if row["programme"] == programme and row["phase"] == "development"]
            self.assertEqual(len(development), 9 * 30 if programme == "repeatability" else 3 * 30)

    def test_first_thirty_fa_rank_seeds_are_unchanged(self):
        csv_path = ROOT / "sim/arc1/manifests/arc1_outer_seeds.csv"
        original = {}
        import csv
        with csv_path.open(newline="", encoding="utf-8") as stream:
            for row in csv.DictReader(stream):
                if row["programme"] == "fa_rank" and row["phase"] == "development":
                    original[(int(row["N"]), row["signal"], int(row["outer"]))] = int(row["seed"])
        for key, seed in original.items():
            n, signal, outer = key
            self.assertEqual(seed, arc1_manifest.seed_for(
                "fa_rank", "development", n, signal, outer, 0, "data"))

    def test_historical_seed_collision_is_still_rejected(self):
        _, _, seed = next(arc1_manifest.iter_all_seed_records())
        audit = {"unique_integer_literals": [seed]}
        with patch.object(arc1_manifest, "historical_seed_audit", return_value=audit):
            with self.assertRaisesRegex(ValueError, f"historical seed-context literal {seed}"):
                arc1_manifest.validate(ROOT)

    def _outer33_fixture(self, root: Path) -> dict[str, object]:
        lane = root / "LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-development-nine-cell-admission-v17"
        source = ROOT / "LOOP/lanes/arc1-gaussian-reliability-20261002/evidence/g2-development-nine-cell-admission-v17"
        lane.mkdir(parents=True)
        for name in ("candidate.json", "source-lock.tsv", "independent-review-receipt-v17.json",
                     "owner-approval-v17-outer33.json", "totoro-current-state-preflight-v17.json",
                     "retained-attempt-outer33-v17-ingest.json", "0033.result.json"):
            shutil.copyfile(source / name, lane / name)
        log = root / "docs/dev-log/check-log.md"
        log.parent.mkdir(parents=True)
        shutil.copyfile(ROOT / "docs/dev-log/check-log.md", log)
        seed = 11447647806120141284
        audit = {"scanned_paths": [{"path": "docs/dev-log/check-log.md",
                                     "sha256": hashlib.sha256(log.read_bytes()).hexdigest()}],
                 "unique_integer_literals": [seed]}
        return {"lane": lane, "log": log, "audit": audit, "seed": seed}

    def test_exact_outer33_consumption_is_pinned_and_validate_accepts_only_that_key(self):
        audit = arc1_manifest.historical_seed_audit(ROOT)
        exceptions = audit["documented_allocated_seed_consumptions"]
        self.assertEqual(len(exceptions), 1)
        exception = exceptions[0]
        self.assertEqual(exception["key"], ["fa_rank", "development", 80, "null", 33, 0, "data"])
        self.assertEqual(exception["seed"], 11447647806120141284)
        self.assertEqual(exception["occurrence_count"], 1)
        self.assertEqual(exception["logged_occurrence"]["path"], "docs/dev-log/check-log.md")
        self.assertEqual(arc1_manifest.validate(ROOT)["unique_seeds"], 644750)

    def test_same_documented_seed_under_another_key_is_rejected(self):
        audit = arc1_manifest.historical_seed_audit(ROOT)
        other_key = ("fa_rank", "development", 80, "null", 34, 0, "data")
        with patch.object(arc1_manifest, "historical_seed_audit", return_value=audit), \
             patch.object(arc1_manifest, "iter_all_seed_records",
                          return_value=iter([("outer", other_key, 11447647806120141284)])):
            with self.assertRaisesRegex(ValueError, "historical seed-context literal 11447647806120141284"):
                arc1_manifest.validate(ROOT)

    def test_duplicate_or_relocated_log_occurrence_is_not_exempt(self):
        with tempfile.TemporaryDirectory(dir="/private/tmp") as temp:
            duplicate_root = Path(temp) / "duplicate"
            duplicate_root.mkdir()
            fixture = self._outer33_fixture(duplicate_root)
            log = fixture["log"]
            text = log.read_text(encoding="utf-8")
            line = next(row for row in text.splitlines() if str(fixture["seed"]) in row)
            audit = fixture["audit"]
            log.write_text(text + "\n" + line + "\n", encoding="utf-8")
            audit["scanned_paths"][0]["sha256"] = hashlib.sha256(log.read_bytes()).hexdigest()
            self.assertEqual(arc1_manifest._documented_consumed_seed_exceptions(duplicate_root, audit), [])

            # Start the relocation case from an otherwise valid one-occurrence fixture.
            relocated_root = Path(temp) / "relocated"
            relocated_root.mkdir()
            fixture = self._outer33_fixture(relocated_root)
            log = fixture["log"]
            audit = fixture["audit"]
            text = log.read_text(encoding="utf-8")
            line = next(row for row in text.splitlines() if str(fixture["seed"]) in row)
            moved = relocated_root / "docs/dev-log/other.md"
            moved.write_text(line + "\n", encoding="utf-8")
            audit["scanned_paths"].append({"path": "docs/dev-log/other.md",
                                           "sha256": hashlib.sha256(moved.read_bytes()).hexdigest()})
            self.assertEqual(arc1_manifest._documented_consumed_seed_exceptions(relocated_root, audit), [])

    def test_changed_context_hash_is_not_exempt(self):
        with tempfile.TemporaryDirectory(dir="/private/tmp") as temp:
            fixture = self._outer33_fixture(Path(temp))
            log = fixture["log"]
            log.write_text(log.read_text(encoding="utf-8").replace(
                "remain exactly one completed development observation",
                "remain one completed development observation"), encoding="utf-8")
            fixture["audit"]["scanned_paths"][0]["sha256"] = hashlib.sha256(log.read_bytes()).hexdigest()
            self.assertEqual(arc1_manifest._documented_consumed_seed_exceptions(
                Path(temp), fixture["audit"]), [])

    def test_changed_consumed_receipt_or_preallocation_audit_breaks_exception(self):
        with tempfile.TemporaryDirectory(dir="/private/tmp") as temp:
            fixture = self._outer33_fixture(Path(temp))
            lane = fixture["lane"]
            receipt = lane / "retained-attempt-outer33-v17-ingest.json"
            receipt.write_text(receipt.read_text() + " ", encoding="utf-8")
            self.assertEqual(arc1_manifest._documented_consumed_seed_exceptions(
                Path(temp), fixture["audit"]), [])
        with tempfile.TemporaryDirectory(dir="/private/tmp") as temp:
            fixture = self._outer33_fixture(Path(temp))
            candidate_path = fixture["lane"] / "candidate.json"
            candidate = json.loads(candidate_path.read_text())
            candidate["manifest_preflight"]["verified"]["historical_seed_audit"][
                "unique_integer_literals"].append(fixture["seed"])
            candidate_path.write_text(json.dumps(candidate), encoding="utf-8")
            self.assertEqual(arc1_manifest._documented_consumed_seed_exceptions(
                Path(temp), fixture["audit"]), [])


if __name__ == "__main__":
    unittest.main()
