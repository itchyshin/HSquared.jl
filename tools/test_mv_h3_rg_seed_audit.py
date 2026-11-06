#!/usr/bin/env python3
"""Adversarial, seed-free tests for the H3 RG exclusion inventory."""
from __future__ import annotations

import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

MODULE_PATH = Path(__file__).with_name("mv_h3_rg_seed_audit.py")
SPEC = importlib.util.spec_from_file_location("mv_h3_rg_seed_audit", MODULE_PATH)
audit = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(audit)


def git(root: Path, *args: str) -> str:
    return subprocess.run(["git", *args], cwd=root, check=True, text=True,
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE).stdout.strip()


class H3RGSeedAuditTests(unittest.TestCase):
    def make_repo(self, root: Path) -> None:
        git(root, "init", "-q", "-b", "main")
        git(root, "config", "user.email", "audit@example.invalid")
        git(root, "config", "user.name", "Audit Fixture")
        for path in audit.REQUIRED_SOURCE_PATHS:
            target = root / path
            target.parent.mkdir(parents=True, exist_ok=True)
            if path == audit.PREDECLARATION:
                target.write_text("""# H3-rg predeclaration
Master seed default: 20260903.
Rep seed: master + 1_000_003*campaign_index + 10_007*cell_index + rep.
Confirm array not armed; confirm not run.
""", encoding="utf-8")
            elif path == audit.CAMPAIGN_DRIVER:
                target.write_text("""# H3-rg driver; source definition only
EXT_SEED = 20260903
_rep_seed(master, campaign_index, cell_index, rep) = master + 1_000_003*campaign_index + 10_007*cell_index + rep
""", encoding="utf-8")
            elif path == audit.SCREEN_TEST:
                target.write_text("""# H3-rg callback fixture; not an executed attempt
fixture_seeds = [1, 2, 3]
""", encoding="utf-8")
            else:
                target.write_text("# C1 seed source for interval campaign\n", encoding="utf-8")
        (root / "sim" / "unrelated_seed_example.jl").write_text(
            "SMOKE_SEED = 777777 # unrelated package smoke\n", encoding="utf-8")
        results = root / "sim" / "drac" / "results" / "h3_rg_smoke.tsv"
        results.parent.mkdir(parents=True, exist_ok=True)
        results.write_text("campaign\tseed\tfit_success\tinterval_success\n"
                           "h3_rg\t51003\ttrue\ttrue\n", encoding="utf-8")
        declaration = root / "sim" / "fixtures" / "h1-c1-input-declaration.tsv"
        declaration.parent.mkdir(parents=True, exist_ok=True)
        declaration.write_text("campaign\tseed\testimand\nh1_two\t21270914\tratio1\n",
                               encoding="utf-8")
        git(root, "add", ".")
        git(root, "commit", "-qm", "historical H3 audit fixture")
        git(root, "branch", "archive/predecl")
        git(root, "remote", "add", "origin", "https://example.invalid/hsquared.git")

    def test_predeclaration_fixtures_and_attempt_records_are_separate(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_repo(root)
            report = audit.audit_repository(root)
            self.assertEqual(report["schema"], audit.SCHEMA)
            self.assertFalse(report["freshness_verified"])
            self.assertFalse(report["seed_allocation_performed"])
            self.assertFalse(report["simulation_or_fit_performed"])
            self.assertIn("refs/heads/main", {r["ref"] for r in report["refs"]})
            self.assertIn("refs/heads/archive/predecl", {r["ref"] for r in report["refs"]})
            self.assertTrue(any(row["path"] == audit.PREDECLARATION and
                                row["status"] == "predeclared_not_execution_evidence"
                                for row in report["predeclarations"]))
            predecl = next(row for row in report["predeclarations"] if row["ref"] == "refs/heads/main")
            self.assertIn("20260903", predecl["seed_context_integer_literals"])
            self.assertTrue(any(row["path"] == audit.SCREEN_TEST and
                                row["classification"] == "test_fixture_or_source_literal_not_execution"
                                for row in report["seed_literal_inventory"]))
            attempts = [row for row in report["retained_attempt_rows"] if row["ref"] == "refs/heads/main"]
            self.assertEqual(len(attempts), 1)
            attempt = attempts[0]
            self.assertEqual(attempt["seed_literal"], "51003")
            self.assertFalse(attempt["execution_independently_verified"])
            self.assertFalse(any(row["path"] == "sim/fixtures/h1-c1-input-declaration.tsv"
                                 for row in report["retained_attempt_rows"]))
            self.assertNotIn("777777", {n for row in report["seed_literal_inventory"]
                                        for n in row["seed_context_integer_literals"]})
            self.assertIn("remote_host_not_queried", {row["kind"] for row in report["unresolved_sources"]})
            self.assertIn("out_of_root_historical_result_stores", {row["kind"] for row in report["unresolved_sources"]})
            self.assertIn("sister_R_doc34", {row["kind"] for row in report["unresolved_sources"]})

    def test_dirty_untracked_candidate_and_changed_bytes_are_hashed(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_repo(root)
            changed_file = root / audit.CAMPAIGN_DRIVER
            first = audit.audit_repository(root)
            first_hash = next(row["sha256"] for row in first["ref_source_inventory"]
                              if row["ref"] == "refs/heads/main" and row["path"] == audit.CAMPAIGN_DRIVER)
            changed_file.write_text(changed_file.read_text(encoding="utf-8") + "# altered bytes\n", encoding="utf-8")
            candidate = root / "sim" / "h3_rg_new_seed_candidate.tsv"
            candidate.write_text("not allocated; candidate only\n", encoding="utf-8")
            second = audit.audit_repository(root)
            current = next(row for row in second["worktree_status_inventory"]
                           if row["path"] == audit.CAMPAIGN_DRIVER)
            self.assertEqual(current["status"], " M")
            self.assertNotEqual(first_hash, current["sha256"])
            candidate_row = next(row for row in second["current_worktree_candidate_and_untracked_inventory"]
                                 if row["path"] == "sim/h3_rg_new_seed_candidate.tsv")
            self.assertEqual(candidate_row["status"], "??")
            self.assertIsNotNone(candidate_row["sha256"])

    def test_omitted_ref_worktree_and_declared_source_are_reported(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_repo(root)
            refs = audit._ref_inventory(root)
            worktrees = audit._worktree_inventory(root)
            report = audit.audit_repository(root,
                observed_refs=[refs[0]["ref"]], observed_worktrees=[],
                declared_sources=audit.REQUIRED_SOURCE_PATHS[:-1])
            gaps = {(row["kind"], row["identity"]) for row in report["unresolved_sources"]}
            self.assertIn(("omitted_ref", next(ref["ref"] for ref in refs if ref["ref"] != refs[0]["ref"])), gaps)
            self.assertTrue(any(kind == "omitted_worktree" for kind, _ in gaps))
            self.assertIn(("omitted_required_source", audit.REQUIRED_SOURCE_PATHS[-1]), gaps)
            self.assertEqual(len(worktrees), report["worktree_count"])

    def test_required_source_missing_from_every_ref_is_unresolved(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_repo(root)
            git(root, "rm", "-q", audit.PREDECLARATION)
            git(root, "commit", "-qm", "remove required predeclaration")
            git(root, "branch", "-Dq", "archive/predecl")
            report = audit.audit_repository(root)
            self.assertIn(("required_source_missing_everywhere", audit.PREDECLARATION),
                          {(row["kind"], row["identity"]) for row in report["unresolved_sources"]})


if __name__ == "__main__":
    unittest.main(verbosity=2)
