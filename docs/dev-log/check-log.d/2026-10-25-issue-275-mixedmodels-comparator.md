# 2026-10-25 issue 275: MixedModels.jl Julia-native comparator lane

Goal: add MixedModels.jl as an opt-in comparator on the shared Gaussian LMM surface (iid random
intercepts, REML), recording agreement and wall time, with the usual evidence discipline.

Commands (Totoro, worktree from `origin/main` at `f91337de`, Julia 1.12.7):

- `julia --project=<env developing HSquared> test/test_issue_275_mixedmodels_surface.jl`: red on
  main (the surface file does not exist), green on branch (35 passed).
- `HSQUARED_RUN_MIXEDMODELS=true OPENBLAS_NUM_THREADS=1 julia +1.12 --project=comparator/mixedmodels_lmm
  comparator/mixedmodels_lmm/run_mixedmodels_lmm.jl --reps 9`: 5/5 scenarios agree (variance
  relative difference at most 7.5e-7 against `1e-3`; fixed effects at most 1.1e-10 against
  `1e-6`); both engines converged, no singular fit. Receipts in
  `docs/dev-log/evidence/2026-10-25-mixedmodels-lmm/`.
- Without the environment variable the runner skips and exits 0 before importing MixedModels.

Claim boundary: agreement and wall time on the shared surface only, one machine, one run,
millisecond-scale timings. Not a speed or superiority claim, no pedigree or genomic coverage,
no capability-status change, no `covered` promotion.
