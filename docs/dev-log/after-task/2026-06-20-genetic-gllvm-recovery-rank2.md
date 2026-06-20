# After-task — Genetic-GLLVM REML recovery: rank-2 broadening (#50)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/genetic-gllvm-recovery-rank2`. Broadens the genetic-GLLVM recovery study (#106)
from rank-1 to a genuine rank-2, non-degenerate-correlation scenario.

## Summary

Extended `sim/phase6_gllvm_recovery.jl` to a two-scenario harness and RAN it:

- **Scenario A — rank-1** (`Λ=[1.0,0.7,0.5]`, `K=1`, `q=240`): 5/5, mean
  `rel(G_lat) = 0.091` (the #106 baseline).
- **Scenario B — rank-2, NON-degenerate ρ** (`Λ=[1 0; 0.5 0.8; 0.3 0.9]`, `K=2`,
  `q=120`): 5/5, mean `rel(G_lat) = 0.205` AND **genetic correlations recovered to
  `mean|Δρ| = 0.089`**.

Rank-1 could not test correlation recovery (rank-1 ⇒ `±1` correlations by
construction); rank-2 finally does, and the estimator recovers the genetic correlation
structure well, with `G_lat` Frobenius error degrading gracefully as the structure
hardens / `q` shrinks.

## Definition of Done

- implementation — `sim/phase6_gllvm_recovery.jl` refactored to a `_scenario` runner
  with the rank-1 + rank-2 scenarios and an off-diagonal genetic-correlation-error
  metric; opt-in, outside CI.
- run + evidence — the recovery-checkpoint note
  (`docs/dev-log/recovery-checkpoints/2026-06-20-genetic-gllvm-reml-recovery.md`)
  updated with both scenarios' executed results.
- documentation — capability-status + `V6-GGLLVM-REML` validation-debt +
  `validation_status()` rows EXTENDED with the rank-2 + correlation-recovery evidence;
  the "still needs" narrowed to FA(+Ψ)/Bernoulli/Binomial/larger-`q`. No new validation
  row; stays 41 rows.
- check-log — `docs/dev-log/check-log.d/2026-06-20-genetic-gllvm-recovery-rank2.md`.
- after-task — this file.
- Rose audit — inline: CLEAN (both scenarios' results recorded verbatim; scope honestly
  bounded — Poisson-only, balanced, no FA/Bernoulli/comparator; status `partial`, not
  promoted; no inflated row).
- clean local checks — `validation_status()` loads (41 rows); the committed suite is
  unaffected (harness outside `test/`).

## Claim boundary

Two POSITIVE Poisson recovery scenarios (rank-1 + rank-2 incl. correlation recovery);
not FA(+Ψ)/Bernoulli/Binomial, not larger-`q` calibration, not external-comparator
parity. `GLLVM-style animal models` stays `planned`; nothing covered.

## Next

FA(+Ψ) and Bernoulli/Binomial recovery; larger-`q` rank-2 to tighten the correlation
error; a fitted-object/EBV extractor; per-trait families; the external comparator; the
R `gllvm()` bridge (gated on #50).
