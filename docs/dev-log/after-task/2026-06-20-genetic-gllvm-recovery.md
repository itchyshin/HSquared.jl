# After-task — Genetic-GLLVM REML known-truth recovery study (#50)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/genetic-gllvm-recovery`. The missing validation for the genetic-GLLVM REML —
an opt-in known-truth recovery harness, the item every `V6-GGLLVM-*` row listed as
"still needs".

## Summary

Added `sim/phase6_gllvm_recovery.jl` (opt-in, outside CI) and RAN it: a rank-1 Poisson
genetic-GLLVM DGP (`Λ = [1.0, 0.7, 0.5]`, `T=3`, `K=1`, `q=240`, `μ=1.0`) → fit with
`fit_gllvm_laplace_reml` → measure recovery of the rotation-invariant `G_lat = ΛΛ'`.

**Result: 5/5 predeclared seeds converged, mean relative Frobenius error
`‖Ĝ−G‖/‖G‖ = 0.091`** (range 0.019–0.18; loose gate ≤ 0.45), per-trait variances
tracking truth. The estimator **recovers the rank-1 Poisson `G_lat` well** — genuine
known-truth recovery evidence, recorded in
`docs/dev-log/recovery-checkpoints/2026-06-20-genetic-gllvm-reml-recovery.md`.

## Honest framing

POSITIVE but ONE setup — rank-1 / Poisson / balanced / `q=240`. **NOT** a broad
multi-rank / multi-family / FA(+Ψ) calibration, **NOT** an external comparator. Recovery
is on `G_lat` (loadings rotation-nonidentified); with rank-1 truth the genetic
correlations are `±1` by construction. So this strengthens `V6-GGLLVM-REML`'s evidence
(first recovery study, positive) but does **not** promote it to `covered` (which still
needs broad calibration + an external comparator).

## Definition of Done

- implementation — `sim/phase6_gllvm_recovery.jl` (opt-in harness; reuses the
  `sim/phase6_poisson_recovery.jl` half-sib pedigree + Knuth Poisson sampler patterns).
- run + evidence — recovery-checkpoint note (the table above) with the executed result.
- documentation — capability-status + `V6-GGLLVM-REML` validation-debt +
  `validation_status()` rows EXTENDED with the recovery evidence and the adjusted
  "still needs" (now BROAD calibration + comparator; the recovery study exists). No new
  validation row; `validation_status()` stays 41 rows.
- check-log — `docs/dev-log/check-log.d/2026-06-20-genetic-gllvm-recovery.md`.
- after-task — this file.
- Rose audit — inline (below).
- clean local checks — `validation_status()` loads (41 rows); the committed suite is
  unaffected (the harness is outside `test/`, RNG-free suite preserved).

## Rose audit (claim-vs-evidence)

Rose-lens audit (inline). **CLEAN.** The recovery claim is backed by an EXECUTED run
recorded verbatim (per-seed table + mean); the framing is scrupulously honest about
scope (one setup, rank-1/Poisson/balanced, recovery on `G_lat`, `±1` correlations by
construction, not broad, no comparator); the status row stays `partial` (not promoted).
No new validation row inflated. Nothing covered.

## Claim boundary

A first POSITIVE known-truth recovery study for the genetic-GLLVM REML, rank-1 Poisson
only; not broad calibration, not external-comparator parity. `GLLVM-style animal
models` stays `planned`; nothing covered.

## Next

Broaden the recovery study (higher ranks, FA(+Ψ), Bernoulli/Binomial, smaller `q`); a
fitted-object/EBV extractor + payload; per-trait families; unbalanced records; the
external GLLVM.jl/gllvmTMB comparator; the R `gllvm()` bridge (gated on #50).
