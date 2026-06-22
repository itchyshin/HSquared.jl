# V4-MV-REML pre-declared recovery confirmation — 48-seed cold-start — 2026-06-22

Executes the recovery gate **pre-registered** in
`docs/dev-log/decisions/2026-06-22-mv-reml-substitutable-gate.md` (committed
`a7b1f9ad`, before this run). This is path (b) of the substitutable covered gate.

## Run

- Harness: `sim/phase4_multivariate_reml_recovery.jl`, **cold-start** (no truth
  warm-start), 5000 iterations.
- Design (harness default): half-sib 8×16×56, 3 records/animal → q=80, n=240, t=2.
  Truth `G=[1 .35; .35 .7]`, `R=[.8 .2; .2 .55]`.
- 48 fresh seeds 20260616–20260663. Thread-capped (`OPENBLAS=OMP=VECLIB=2`,
  `JULIA_NUM_THREADS=1`). Log: `/tmp/mvreml_recovery_48.log`.

Reproduce:

    SEEDS=$(seq -f "%.0f" 20260616 20260663 | paste -sd, -)
    env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 \
      julia --project=. sim/phase4_multivariate_reml_recovery.jl \
      --cold-start=true --seeds="$SEEDS"

(First attempt aborted on arg-parse: macOS `seq` without `-f "%.0f"` emits
scientific notation the harness rejects — zero fits ran, no results seen, so the
pre-registration is intact.)

## Result — aggregate Monte Carlo recovery (m = 48)

| param | true | mean | bias | MCSE | \|bias\| ≤ 2·MCSE |
| --- | --- | --- | --- | --- | --- |
| G[1,1] | 1.0000 | 0.9429 | −0.0571 | 0.0363 | yes (1.57·MCSE) |
| G[1,2] | 0.3500 | 0.3290 | −0.0210 | 0.0242 | yes |
| G[2,2] | 0.7000 | 0.7066 | +0.0066 | 0.0202 | yes |
| R[1,1] | 0.8000 | 0.7883 | −0.0117 | 0.0134 | yes |
| R[1,2] | 0.2000 | 0.2051 | +0.0051 | 0.0067 | yes |
| R[2,2] | 0.5500 | 0.5426 | −0.0074 | 0.0082 | yes |

- EBV accuracy: trait 1 mean 0.8927 (sd 0.0317), trait 2 mean 0.9056 (sd 0.0270).
- Convergence: 48/48. Per-seed Frobenius gate (the OLD gate): 25/48 = 0.521
  (Wilson 95% [0.383, 0.655]) — as expected, `G` per-replicate sampling variance,
  not a defect; the harness still exits 1 on it.

## Verdict against the pre-declared gate

| criterion | required | observed | pass |
| --- | --- | --- | --- |
| 1 convergence | 48/48 | 48/48 | ✅ |
| 2 \|bias\| ≤ 2·MCSE, all 6 | all | all 6 yes | ✅ |
| 3 EBV accuracy mean | ≥ 0.85 | 0.893 / 0.906 | ✅ |
| 4 G-entry MCSE | ≤ 0.045 | 0.036 / 0.024 / 0.020 | ✅ |

**The pre-declared recovery gate PASSES.** Combined with the banked legs (sommer
same-estimand REML parity ≤ 8e-5, MCMCglmm cross-class agreement, Mrode 5.1 MME
anchor), the doc-33 **substitutable covered gate is now met** via path (b).

## Honest caveats (must survive into any covered wording)

- **`G[1,1]` is the weak axis:** −5.7% (1.57·MCSE) below truth — within the
  pre-declared 2·MCSE gate but the largest standardized residual. The power floor
  (MCSE 0.036) means a genetic-variance bias above ≈0.073 (7.3%) would be
  detectable; the observed −0.057 is below that, so "**no detectable bias**" is
  honest — **never "unbiased."** This downward pull on the genetic variance is
  consistent with REML finite-sample behavior at q=80/n=240 (sommer, same
  estimand, agrees to ≤8e-5 on the fixture, so it is not engine-specific).
- Cold-start; warm-start at truth gives the same optimum (prior checkpoint). This
  characterises this design only — not a global convergence guarantee, not a
  deep-inbreeding / high-condition claim.

## Next (does NOT auto-promote)

`partial → covered` still requires: the doc-33 rec-3 honesty fixes (sommer
in-suite skip-guarded test or reworded row; no "unbiased" wording) + a Rose
claim-vs-evidence audit + the maintainer's explicit sign-off.
