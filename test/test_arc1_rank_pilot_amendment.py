"""Tests for the separate, post-outcome G2/G3 pilot qualification policy."""
from __future__ import annotations

import importlib.util
import hashlib
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import arc1_gate_aggregate as gates
import arc1_manifest


def amended_policy(test: unittest.TestCase):
    spec = importlib.util.find_spec("arc1_rank_pilot_amendment")
    test.assertIsNotNone(spec, "versioned post-outcome pilot qualification policy is missing")
    if spec is None:
        return None
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def base_result(*, gate="G2", usable=24, selected_k1=0, references_ok=True):
    cells = []
    for cell in gates.required_cells(gate, "pilot"):
        k1 = selected_k1 if (cell["N"], cell["signal"]) == (80, "null") else 0
        cells.append({"cell": cell, "attempts": 30, "usable": usable,
            "selected_K1": k1, "references_required": 20,
            "references_passed": 20 if references_ok else 19})
    baseline_pass = all(row["usable"] >= 29 for row in cells)
    references_pass = all(row["references_required"] == row["references_passed"]
                          for row in cells)
    witness_pass = gate != "G2" or any(row["selected_K1"] for row in cells)
    return {"gate": gate, "phase": "pilot", "integrity": "PASS",
        "protocol_sha256": arc1_manifest.contract_sha256(), "cell_metrics": cells,
        "numerical_screen": "PASS" if baseline_pass else "HOLD",
        "selection_rule": "PASS", "reference_audits": "PASS" if references_pass else "HOLD",
        "ordinary_K1_witness": "PASS" if witness_pass else "HOLD",
        "pilot_qualification": "PASS" if baseline_pass and references_pass and witness_pass else "HOLD",
        "success_marker": None, "confirmation_allocation": "HOLD"}


class Arc1RankPilotAmendmentTests(unittest.TestCase):
    def test_frozen_experiment_manifest_still_requires_29_of_30(self):
        self.assertEqual(arc1_manifest.SCIENTIFIC_CONTRACT["rank_selection_gate"][
            "pilot_screen"]["numerical_eligibility_min"], 29)

    def test_24_of_30_is_labeled_post_outcome_and_preserves_frozen_result(self):
        amended = amended_policy(self).qualify_pilot_result(base_result(selected_k1=1))
        self.assertEqual(amended["numerical_screen"], "PASS")
        self.assertEqual(amended["frozen_v1_baseline"]["numerical_screen"], "HOLD")
        self.assertEqual(amended["pilot_qualification"], "PASS")
        self.assertEqual(amended["protocol_sha256"], arc1_manifest.contract_sha256())
        self.assertEqual(amended["qualification_policy"]["id"],
                         "arc1-g2-g3-pilot-24-of-30-postoutcome-v1")
        self.assertEqual(amended["qualification_interpretation"],
                         "post-outcome exploratory pilot feasibility only")
        self.assertEqual(len(amended["qualification_policy"]["sha256"]), 64)
        checker = ROOT / "tools/arc1_rank_pilot_amendment.py"
        self.assertEqual(amended["qualification_policy"]["qualification_checker_sha256"],
                         hashlib.sha256(checker.read_bytes()).hexdigest())
        self.assertEqual(amended["confirmation_allocation"], "HOLD")

    def test_23_of_30_holds_numerical_screen(self):
        source = base_result(selected_k1=1)
        source["cell_metrics"][0]["usable"] = 23
        result = amended_policy(self).qualify_pilot_result(source)
        self.assertEqual(result["numerical_screen"], "HOLD")
        self.assertEqual(result["pilot_qualification"], "HOLD")

    def test_attempt_denominator_cannot_be_reduced(self):
        source = base_result(selected_k1=1)
        source["cell_metrics"][0]["attempts"] = 29
        with self.assertRaisesRegex(ValueError, "all-attempt counts"):
            amended_policy(self).qualify_pilot_result(source)

    def test_reference_failure_still_holds_overall_qualification(self):
        result = amended_policy(self).qualify_pilot_result(
            base_result(selected_k1=1, references_ok=False))
        self.assertEqual(result["numerical_screen"], "PASS")
        self.assertEqual(result["reference_audits"], "HOLD")
        self.assertEqual(result["pilot_qualification"], "HOLD")
        self.assertIsNone(result["success_marker"])

    def test_amended_usability_does_not_override_g3_selection_rule(self):
        source = base_result(gate="G3")
        source["selection_rule"] = "HOLD"
        result = amended_policy(self).qualify_pilot_result(source)
        self.assertEqual(result["numerical_screen"], "PASS")
        self.assertEqual(result["selection_rule"], "HOLD")
        self.assertEqual(result["pilot_qualification"], "HOLD")

    def test_failed_attempts_are_not_counted_as_k0_and_rates_are_separate(self):
        result = amended_policy(self).qualify_pilot_result(
            base_result(selected_k1=6))
        null = next(row for row in result["cell_metrics"] if
                    row["cell"]["N"] == 80 and row["cell"]["signal"] == "null")
        self.assertEqual(null["selected_K0"], 18)
        self.assertEqual(null["selected_K1"], 6)
        self.assertEqual(null["unusable"], 6)
        self.assertEqual(null["K1_selection_all_attempt_rate"], 0.2)
        self.assertEqual(null["K1_selection_given_usable_rate"], 0.25)

    def test_amendment_is_limited_to_rank_pilots(self):
        result = base_result(gate="G3")
        result["phase"] = "confirmation"
        with self.assertRaisesRegex(ValueError, "only applies to G2/G3 pilot"):
            amended_policy(self).qualify_pilot_result(result)


if __name__ == "__main__":
    unittest.main()
