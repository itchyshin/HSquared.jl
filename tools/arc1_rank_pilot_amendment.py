"""Apply the owner-approved, post-outcome 24/30 screen to verified G2/G3 pilot receipts.

The frozen experiment protocol and the ordinary gate aggregator remain unchanged. This
sidecar first runs the frozen receipt, source, protocol, and reference checks, then
adds a separately identified exploratory qualification result.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

import arc1_gate_aggregate as frozen_gates
import arc1_manifest as manifest


ROOT = Path(__file__).resolve().parents[1]
POLICY_ID = "arc1-g2-g3-pilot-24-of-30-postoutcome-v1"
DECISION_RECORD = "docs/dev-log/decisions/2026-10-22-g2-pilot-24-of-30-amendment.md"
DECISION_RECORD_SHA256 = "fedad641f229a6152f07107fb32f672870a2456b05e4d1783293358e936d58cc"
MINIMUM_USABLE = 24
DENOMINATOR = 30


def _policy_metadata() -> dict[str, Any]:
    decision_path = ROOT / DECISION_RECORD
    if not decision_path.is_file():
        raise ValueError("approved pilot-threshold decision record is missing")
    decision_sha256 = hashlib.sha256(decision_path.read_bytes()).hexdigest()
    if decision_sha256 != DECISION_RECORD_SHA256:
        raise ValueError("pilot-threshold decision record changed after review")
    frozen_minimum = manifest.SCIENTIFIC_CONTRACT["rank_selection_gate"][
        "pilot_screen"]["numerical_eligibility_min"]
    if frozen_minimum != 29:
        raise ValueError("frozen experiment protocol changed; review the amendment against its new parent")
    checker_sha256 = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    return {
        "schema": "arc1-rank-pilot-qualification-policy-v1",
        "id": POLICY_ID,
        "decision_record": DECISION_RECORD,
        "decision_record_sha256": decision_sha256,
        "qualification_checker": "tools/arc1_rank_pilot_amendment.py",
        "qualification_checker_sha256": checker_sha256,
        "parent_experiment_protocol_sha256": manifest.contract_sha256(),
        "scope": {"gates": ["G2", "G3"], "phase": "pilot"},
        "numerical_eligibility_minimum": MINIMUM_USABLE,
        "denominator": DENOMINATOR,
        "failure_replacement": False,
        "interpretation": "post-outcome exploratory pilot feasibility only",
        "confirmation_eligibility_bound_unchanged": 0.90,
    }


def _policy_sha256(policy: dict[str, Any]) -> str:
    canonical = json.dumps(policy, sort_keys=True, separators=(",", ":"),
                           ensure_ascii=False).encode("utf-8")
    return hashlib.sha256(canonical).hexdigest()


def qualify_pilot_result(frozen_result: dict[str, Any]) -> dict[str, Any]:
    """Apply the separate pilot screen to a result from the frozen gate aggregator."""
    if (not isinstance(frozen_result, dict) or
            frozen_result.get("gate") not in {"G2", "G3"} or
            frozen_result.get("phase") != "pilot"):
        raise ValueError("the amendment only applies to G2/G3 pilot results")
    if (frozen_result.get("integrity") != "PASS" or
            frozen_result.get("protocol_sha256") != manifest.contract_sha256()):
        raise ValueError("the frozen experiment receipt/protocol verification has not passed")

    expected = {frozen_gates._cell_key(cell)
                for cell in frozen_gates.required_cells(frozen_result["gate"], "pilot")}
    metrics = frozen_result.get("cell_metrics")
    if not isinstance(metrics, list) or len(metrics) != len(expected):
        raise ValueError("the frozen result does not contain exactly the required pilot cells")

    seen: set[tuple[Any, ...]] = set()
    amended_metrics = []
    numerical_ok = True
    reference_rows_ok = True
    reasons: list[str] = []
    for metric in metrics:
        if not isinstance(metric, dict) or not isinstance(metric.get("cell"), dict):
            raise ValueError("pilot cell metric is malformed")
        key = frozen_gates._cell_key(metric["cell"])
        if key not in expected or key in seen:
            raise ValueError("pilot result contains an unexpected or duplicate cell")
        seen.add(key)
        row = dict(metric)
        attempts = row.get("attempts")
        usable = row.get("usable")
        selected_k1 = row.get("selected_K1")
        if (any(not isinstance(value, int) or isinstance(value, bool)
                for value in (attempts, usable, selected_k1)) or
                attempts != DENOMINATOR or not 0 <= usable <= attempts or
                not 0 <= selected_k1 <= usable):
            raise ValueError("pilot counts must be integer all-attempt counts with usable K1 selections")
        if usable < MINIMUM_USABLE:
            numerical_ok = False
            reasons.append(f"{key}:usable={usable} below amended minimum {MINIMUM_USABLE}")
        required = row.get("references_required")
        passed = row.get("references_passed")
        if (not isinstance(required, int) or isinstance(required, bool) or
                not isinstance(passed, int) or isinstance(passed, bool) or
                required < 0 or passed < 0 or passed > required):
            raise ValueError("pilot reference-audit counts are malformed")
        if required != passed:
            reference_rows_ok = False
        row["selected_K0"] = usable - selected_k1
        row["unusable"] = attempts - usable
        row["K1_selection_all_attempt_rate"] = selected_k1 / attempts
        row["K1_selection_given_usable_rate"] = selected_k1 / usable if usable else None
        row["K0_selection_given_usable_rate"] = (usable - selected_k1) / usable if usable else None
        amended_metrics.append(row)
    if seen != expected:
        raise ValueError("pilot result is missing one or more required cells")

    references_ok = (frozen_result.get("reference_audits") == "PASS" and reference_rows_ok)
    selection_ok = frozen_result.get("selection_rule") == "PASS"
    witness_ok = (frozen_result.get("ordinary_K1_witness") == "PASS"
                  if frozen_result["gate"] == "G2" else True)
    if not references_ok:
        reasons.append("one or more required expanded-reference audits remain unresolved")
    if not selection_ok:
        reasons.append("the frozen pilot selection rule is not met")
    if not witness_ok:
        reasons.append("G2 lacks a usable ordinary K1 witness")

    policy = _policy_metadata()
    result = dict(frozen_result)
    result["cell_metrics"] = amended_metrics
    result["frozen_v1_baseline"] = {
        "numerical_screen": frozen_result.get("numerical_screen"),
        "pilot_qualification": frozen_result.get("pilot_qualification"),
        "numerical_eligibility_minimum": manifest.SCIENTIFIC_CONTRACT[
            "rank_selection_gate"]["pilot_screen"]["numerical_eligibility_min"],
        "denominator": DENOMINATOR,
    }
    result["qualification_policy"] = {**policy, "sha256": _policy_sha256(policy)}
    result["qualification_interpretation"] = policy["interpretation"]
    result["numerical_screen"] = "PASS" if numerical_ok else "HOLD"
    qualified = numerical_ok and references_ok and selection_ok and witness_ok
    result["pilot_qualification"] = "PASS" if qualified else "HOLD"
    result["qualification_failure_reasons"] = reasons
    result["success_marker"] = (
        f"{frozen_result['gate']}_PILOT_QUALIFIED_POSTOUTCOME_24_OF_30_V1"
        if qualified else None)
    result["confirmation_allocation"] = "HOLD"
    result["confirmation_admission_compatible"] = False
    return result


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("gate", choices=("G2", "G3"))
    parser.add_argument("bundle", type=Path, help="JSON with a `receipts` array")
    parser.add_argument("--pins", required=True, type=Path,
                        help="separate trusted JSON mapping cells to independent verifier pins")
    args = parser.parse_args()
    frozen_result = frozen_gates.aggregate_gate_files(args.gate, "pilot", args.bundle, args.pins)
    result = qualify_pilot_result(frozen_result)
    print(json.dumps(result, sort_keys=True))
    if result["pilot_qualification"] != "PASS":
        raise SystemExit(2)


if __name__ == "__main__":
    main()
