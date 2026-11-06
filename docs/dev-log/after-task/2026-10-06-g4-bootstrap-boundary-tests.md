## 1. Goal

Test the frozen 99% usable-replicate formation threshold at the actual Arc 1 FA bootstrap stream sizes.

## 2. Implemented

Added deterministic tests for B=199, 499, and 999. Each size is checked at the exact required usable count and one below it. The assertions cover interval formation, ordered finite endpoints, failure counts, rank-frequency totals among usable replicates, and retention of all planned attempts.

## 3a. Decisions and Rejected Alternatives

The implementation remains unchanged because it already uses `ceil(0.99 * B)` and preserves the fixed attempt denominator. The added boundary cases verify those rules directly. No calibration claim or interval-method change is made.

## 4. Files Touched

- `test/arc1_bootstrap.jl`
- `LOOP/lanes/arc1-gaussian-reliability-20261002/checkpoint.md`
- `docs/dev-log/after-task/2026-10-06-g4-bootstrap-boundary-tests.md`

## 5. Checks Run

- `julia --startup-file=no --project=. test/arc1_bootstrap.jl` first stopped during package loading because the shared Julia depot could not create a compiled-cache lock. No tests ran in that attempt.
- Rerun with `JULIA_DEPOT_PATH=/private/tmp/arc1-g4-bootstrap-boundary-depot-20261006:/Users/z3437171/.julia`, `JULIA_NUM_THREADS=1`, and `OPENBLAS_NUM_THREADS=1`: exit 0; all four bootstrap testsets passed, 293/293 assertions.
- `node ~/shinichi-brain/skills/unlazy/scripts/gate-check.mjs --status --scope arc1-gaussian-reliability`: G4 remains unmet pending interval-calibration evidence; G2, G3, G5, and G8 also remain unmet.
- Report structure passed. The complete after-task validator exited 1 because Arc 1, automatic-FA-rank implementation, and H2 non-GPU acceptance ledgers remain open.
- Naturalness check: 0 findings. `git diff --check`: passed.

## 6. Tests of the Tests

Each of the three frozen stream sizes has two cases: exactly the required usable count forms intervals; one fewer refuses formation and leaves endpoints missing. A hard-coded expected threshold catches an off-by-one change. The synthetic failures remain in the requested-count denominator.

## 7a. Issue Ledger

Resolved: no direct tests covered the 99% formation boundary at B=199/499/999. Deferred: G4 pilot and confirmation calibration, held until the frozen prerequisites qualify.

## 8. Consistency Audit

Checked the bootstrap summary logic, selector callback path, fixed-attempt handling, failure ledger, interval ordering, rank-frequency diagnostics, and frozen G4 design. No source implementation or R contract changed.

## 9. What Did Not Go Smoothly

The initial focused Julia command targeted the shared read-only compiled depot and stopped with a permission error. Using an isolated scratch-first depot allowed the same focused test file to complete.

## 10. Known Residuals

This verifies a formation-rule boundary only. It does not show that any required target or cell reaches the formation rate or coverage criteria. G4 stays open, as do G2, G3, G5, and G8.

## 11. Team Learning

Memory receipt: the current repository instructions, checkpoint, and frozen Arc 1 design were consulted. `route.py` reports no LOAD-FIRST manifest for this worktree path. Golden Set: not run because only deterministic test coverage changed.

## 12. Cross-Product Coverage

Covers: Julia's internal Arc 1 FA-bootstrap summary formation rule at the three frozen stream sizes.

Does NOT cover: R access or parity, scientific interval calibration, confirmation evidence, repeatability profiles, or any broader HSquared gate.

## Naturalness assessment

Style rating: 1/10, moderate confidence. The record states the tested boundary and its scientific limits directly. Scientific, factual, and reference checks: pass for this deterministic test-only change. No external references were used.
