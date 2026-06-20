# 2026-06-20 Genetic-GLLVM REML recovery: rank-2 broadening (#50)

- **Goal:** broaden the genetic-GLLVM recovery study (#106) from rank-1 to a genuine
  rank-2 structure with NON-degenerate genetic correlations (the rank-1 case forces
  `±1` correlations, so it could not test correlation recovery).
- **Active lenses:** Curie (simulation) + Fisher (estimand) + Kirkpatrick (correlations) +
  Rose (claims).
- **What landed:** `sim/phase6_gllvm_recovery.jl` refactored to a two-scenario runner
  (`_scenario`) + an off-diagonal genetic-correlation-error metric; opt-in, outside CI.
- **RESULT (ran):** Scenario A (rank-1, q=240): 5/5, mean `rel(G_lat)=0.091`. Scenario B
  (rank-2, non-degenerate ρ, q=120): 5/5, mean `rel(G_lat)=0.205`, **genetic
  correlations `mean|Δρ|=0.089`**. Graceful degradation as the structure hardens.
- **Docs:** recovery-checkpoint note updated (both scenarios); capability-status +
  `V6-GGLLVM-REML` validation-debt + `validation_status()` rows EXTENDED (rank-2 +
  correlation recovery; "still needs" narrowed to FA/Bernoulli/Binomial/larger-q); no new
  row (stays 41). `validation_status()` loads, 41 rows.
- **Honest status:** two POSITIVE Poisson scenarios; NOT FA/Bernoulli/Binomial/comparator.
  `partial` stays; nothing covered.
- **Rose audit:** CLEAN (inline). Results recorded verbatim; scope honestly bounded; not
  promoted; no inflated row. Suite unaffected (harness outside `test/`).
