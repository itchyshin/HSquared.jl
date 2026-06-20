# 2026-06-20 Genetic-GLLVM REML known-truth recovery study (#50)

- **Goal:** the missing validation for the genetic-GLLVM REML — an opt-in known-truth
  recovery harness (every `V6-GGLLVM-*` row listed it as "still needs").
- **Active lenses:** Curie (simulation design) + Fisher (estimand/recovery) + Rose (claims).
- **What landed:** `sim/phase6_gllvm_recovery.jl` (opt-in, outside CI) + the executed
  recovery-checkpoint note `docs/dev-log/recovery-checkpoints/2026-06-20-genetic-gllvm-reml-recovery.md`.
- **DGP:** half-sib pedigree (`q=240`), rank-1 Poisson genetic GLLVM, `Λ=[1.0,0.7,0.5]`
  (`T=3,K=1`), `μ=1.0`, Knuth Poisson sampler. Estimand: rotation-invariant `G_lat=ΛΛ'`.
- **RESULT (ran):** 5/5 seeds converged; mean `‖Ĝ−G‖_F/‖G‖_F = 0.091` (range 0.019–0.18;
  loose gate ≤ 0.45); per-trait variances track truth. **The estimator recovers the
  rank-1 Poisson `G_lat` well.**
- **Honest scope:** POSITIVE but ONE setup (rank-1 / Poisson / balanced / q=240); NOT
  broad multi-rank/family/FA calibration, no external comparator; recovery on `G_lat`
  (rank-1 ⇒ ±1 correlations by construction).
- **Docs:** capability-status + `V6-GGLLVM-REML` validation-debt + `validation_status()`
  rows EXTENDED with the recovery evidence + adjusted "still needs" (BROAD calibration +
  comparator); no new row (stays 41). `validation_status()` loads, 41 rows.
- **Honest status:** strengthens `V6-GGLLVM-REML` (first recovery study, positive); NOT
  promoted — `partial` stays. Nothing covered.
- **Rose audit:** CLEAN (inline). Executed result recorded verbatim; scope honestly
  bounded; status not promoted; no inflated row.
