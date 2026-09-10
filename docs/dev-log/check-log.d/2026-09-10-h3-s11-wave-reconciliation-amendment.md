# H3 S11 wave-reconciliation amendment — 2026-09-10

## Scope

Source-inert control repair only. The first retained `r_g` scheduler wave contains
tasks 1–1000, while the original reconciler accepted only the full 1–2000 cell.
It therefore failed after all 1,000 receipts and sidecar hashes had already been
retained. No fixture, seed, interval construction, estimator, bridge, public API,
capability status, or release field changed.

## Amendment

`h3_replacement_s11_reconcile()` now accepts a bounded contiguous task range.
Only a full 1–2000 cell can apply the 1,800-success floor and issue a coverage
classification. A partial wave is labelled `partial_wave`, remains
`claim_eligible=false`, and is limited to receipt/failure-retention validation.
The manifest now governs the reconciler SHA-256 as well as the driver, sbatch,
pre-run sbatch, and lockfile.

## Evidence

- Red test: partial-wave call failed with unsupported `task_start` / `task_end`
  keywords before implementation.
- Green focused reconciliation test: 7/7 assertions, including partial-wave and
  retained-failure checks.
- Range mutation check: invalid task range rejected.
- Manifest test: 3/3 assertions; validator and mutation controls passed.
- Full local `Pkg.test()` was run after the amendment.
- Remote wave `2783399`: 1,000 completed tasks, 1,000 non-empty receipts,
  1,000 SHA-256 sidecars verified, contiguous seeds
  `202609110001`–`202609111000`, and no active-array stderr logs.

## Boundaries

The failed reconciliation job `2788208` is retained as evidence of the original
control mismatch. It is not a scientific replicate failure and did not write to
the receipt directory. Successor waves remain held until the amended source is
sealed, transferred, and the repaired one-thread reconciliation is green.
