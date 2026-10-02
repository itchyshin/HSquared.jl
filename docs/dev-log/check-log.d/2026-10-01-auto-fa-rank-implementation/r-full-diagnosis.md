# R full-check diagnosis

The first full check failed. Its checker output abbreviated the middle of the check log, so a second unchanged-source check retained check_dir and the result object. This reproduced seven bridge failures, with zero R CMD check warnings or notes. The test subprocess activated ~/local-scratch/lanes/HSquared.jl-r-julia-parity-09, an older Julia checkout. Error messages show missing df payload fields and unsupported trait_names keywords there.

The mandatory automatic-rank live acceptance already bound HSQUARED_JULIA_PROJECT to the current managed Julia worktree and passed. The full R check omitted that binding and used the stale configured default. The repair is execution configuration only: set HSQUARED_JULIA_PROJECT to the exact current Julia worktree. No source or test is weakened, skipped or changed for this diagnosis. All failed logs and result values are retained under r-package-check-stale-default-project.

Estimate for corrected full check: three to eight minutes, single Julia and BLAS thread, fifteen-minute owned timeout. Outcome pending.
