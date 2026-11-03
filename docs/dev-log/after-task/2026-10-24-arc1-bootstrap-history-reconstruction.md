# Arc 1 diagnostic bootstrap history reconstruction

## 1. Goal

Resolve the seed-history question raised by two retained FA-interval diagnostic run summaries, then determine whether that evidence admits the candidate pilot batch.

## 2. Implemented

Packaged the exact retained history archive, candidate batch, diagnostic seed list, and historical seed implementation in a reproducible evidence bundle. Recomputed all 20 bootstrap seeds for diagnostic outers 2 and 14, derived their two outer-data seeds, and compared all 22 identities with the candidate batch's 240 outer seeds.

The bounded reconstruction passed with zero overlap. The candidate batch remains inadmissible because the available evidence does not establish a complete retained-root inventory.

## 3a. Decisions and Rejected Alternatives

Count the 22 reconstructed seeds as consumed diagnostic work. Preserve the failed outer-2 bootstrap attempts in the run summary. Treat the two summary files as duplicate evidence for diagnostic outers 2 and 14; their hashes are identical. Keep the zero-overlap result scoped to these records.

The candidate batch pins the same seed-derivation helper hash used in the reconstruction. Its `sim/arc1/execute_attempt.jl` hash differs from the run's recorded hash, so this evidence verifies seed identities and collision status only. It does not establish matching model-execution source.

## 4. Files Touched

- `docs/dev-log/after-task/2026-10-24-arc1-bootstrap-history-reconstruction.tar.gz`
- `docs/dev-log/after-task/2026-10-24-arc1-bootstrap-history-reconstruction.json`
- `docs/dev-log/after-task/2026-10-24-arc1-bootstrap-history-reconstruction.md`

All changes are additive evidence in this worktree. The recovery tree, Dropbox checkouts, protected gates, freeze, checkpoint, coordination board, and AGENTS.md were not edited. No commit or push was made.

## 5. Checks Run

- Verified the reproduction bundle members and every embedded input hash.
- Recomputed the 20 bootstrap seeds from the embedded historical `tools/arc1_manifest.py`; all match the retained seed list and ordered-seed hash `1455741d28a11ce9370ecbbe6f5eac22fbe0a6a073a625f3c30865b41352a4a6`.
- Derived outer-data seeds `9348221611535869429` and `615821728690168049` for outers 2 and 14.
- Verified the candidate batch has 240 unique outer seeds and no overlap with the reconstructed 22 seeds.
- Verified both archived run-summary copies against their manifest hashes and the completed diagnostic status. Outer 2 had 7/10 usable bootstrap samples and was refused; outer 14 had 10/10 and formed.
- Independent review passed at this bounded reconstruction scope. It did not verify binary fit results or exhaustive historical coverage.
- No fits, seed reruns, SSH sessions, or reference-grid reruns were started.

## 6. Tests of the Tests

The reconstruction was checked against the separately retained seed list, the exact historical source bytes, both raw run summaries, and the candidate's explicit seed allocations. The independent reviewer separately recomputed the seed values and candidate overlap. No synthetic or checker-corruption test was added in this evidence-only slice.

## 7a. Issue Ledger

The history admission blocker remains open. The history archive does not enumerate every retained attempt root, and source-map references to omitted historical payloads cannot be followed from this evidence bundle. The candidate still lacks the complete, independently reviewed consumed-attempt history required by `sim/arc1/run_pilot_cells.py`.

## 8. Consistency Audit

G0 and G1 retain their recorded status. G2 through G8 remain open. `public_covered_count` remains 7 and v7 remains HOLD. The eight-fit diagnostic pre-run remains diagnostic-only and earns no pilot or confirmation credit.

## 9. What Did Not Go Smoothly

The retained seed-list JSON has a stale `NOT STARTED` execution field alongside completed status and outcomes. The two completed run summaries and their retained results support the bounded reconstruction; the stale field is explicitly recorded in the evidence qualifications. The two run-summary files are identical copies.

## 10. Known Residuals

This work accounts for two diagnostic outers only. The recorded run and candidate `execute_attempt.jl` hashes differ, so model-execution source parity remains unverified. This work does not establish exhaustive seed-history coverage, verify binary fit results, satisfy the pilot admission contract, or close an Arc 1 gate. The broader Julia and R validation work remains open.

## 11. Team Learning

Seed derivation summaries can describe consumed work without storing seed literals. Admission evidence must follow deterministic references to the exact historical implementation, account for both outer-data and nested bootstrap seeds, and keep coverage limits visible.

## 12. Cross-Product Coverage

This is seed-history evidence for two diagnostic FA-interval outers. It does NOT cover Julia or R capability parity, interval calibration, rank-selection performance, full Arc 1 completion, or release readiness.
