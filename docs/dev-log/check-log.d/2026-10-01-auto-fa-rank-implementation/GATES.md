# Gates: complete paired automatic FA rank implementation

OWNS: src/**, test/**, docs/design/auto-fa-rank*, docs/dev-log/**, LOOP/lanes/auto-fa-rank-implementation-20261001/**

Scope: complete approved bounded experimental Julia/R implementation; no reliability or release claim.

- [x] G1: Independent O1-O10 numerical and policy witnesses pass.
  CHECK: env JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. test/auto_fa_rank_acceptance.jl
  EXPECT: AUTO_FA_ENGINE_ACCEPTANCE_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl; path=692d5958748b/8 entries; output=automatic FA selector public shape and refusal contract |    8      8  0.0s | AUTO_FA_ENGINE_ACCEPTANCE_PASS

- [x] G2: Established fixed-rank regressions remain compatible.
  CHECK: env JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using HSquared, Test, LinearAlgebra, SparseArrays; include("test/test_multivariate_fa_multistart.jl"); include("test/multivariate_contract_regression.jl"); println("AUTO_FA_FIXED_COMPATIBILITY_PASS")'
  EXPECT: AUTO_FA_FIXED_COMPATIBILITY_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl; path=692d5958748b/8 entries; output=Multivariate bounded contracts |  107    107  4.0s | AUTO_FA_FIXED_COMPATIBILITY_PASS

- [x] G3: R expert-control and complete object/transport tests pass.
  CHECK: env PATH=/Users/z3437171/.juliaup/bin:/Users/z3437171/miniconda3/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::test(filter="auto-fa-rank", stop_on_failure=TRUE); cat("AUTO_FA_R_ACCEPTANCE_PASS\n")'
  CWD: /private/tmp/hsquared-auto-fa-r-20261001
  EXPECT: AUTO_FA_R_ACCEPTANCE_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/hsquared-auto-fa-r-20261001; path=692d5958748b/8 entries; output=What you may report is listed on Can I fit and report this? -- not in validation_status(). Intervals are not coverage-calibrated. | See https://itchyshin.github.io/hsquared/articles/current-limits.html

- [x] G4: Required live ordinary-start Julia/R parity and interruption pass without skips.
  CHECK: env PATH=/Users/z3437171/.juliaup/bin:/Users/z3437171/miniconda3/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 HSQUARED_AUTO_FA_REQUIRE_LIVE=true HSQUARED_JULIA_PROJECT=/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl Rscript -e 'devtools::test(filter="auto-fa-rank", stop_on_failure=TRUE); cat("AUTO_FA_LIVE_TWIN_PASS\n")'
  CWD: /private/tmp/hsquared-auto-fa-r-20261001
  EXPECT: AUTO_FA_LIVE_TWIN_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/hsquared-auto-fa-r-20261001; path=692d5958748b/8 entries; output=Activating project at `~/.codex/worktrees/b9ae/HSquared.jl` | Julia exit.

- [x] G5: Current Julia full package tests pass.
  CHECK: env JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using Pkg; Pkg.test(); println("AUTO_FA_JULIA_FULL_PASS")'
  EXPECT: AUTO_FA_JULIA_FULL_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl; path=692d5958748b/8 entries; output=PCG verifies true residual before stopping |   31     31  0.8s | Testing HSquared tests passed

- [x] G6: R package check has no errors or warnings.
  CHECK: env PATH=/Users/z3437171/.juliaup/bin:/Users/z3437171/miniconda3/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin JULIA_DEPOT_PATH=/private/tmp/hsq-julia-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 HSQUARED_JULIA_PROJECT=/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl Rscript -e 'x <- devtools::check(document=FALSE, cran=FALSE, error_on="never", check_dir="/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl/.unlazy/auto-fa-rank-implementation-20261001/r-package-check"); dput(list(errors=x$errors, warnings=x$warnings, notes=x$notes), file="/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl/.unlazy/auto-fa-rank-implementation-20261001/r-package-check-result.R"); stopifnot(length(x$errors)==0L, length(x$warnings)==0L); cat("AUTO_FA_R_FULL_PASS\n")'
  CWD: /private/tmp/hsquared-auto-fa-r-20261001
  EXPECT: AUTO_FA_R_FULL_PASS
  EVIDENCE: exit=0; shell=/bin/sh; cwd=/private/tmp/hsquared-auto-fa-r-20261001; path=692d5958748b/8 entries; output=running command ''quarto' -V' had status 1 | AUTO_FA_R_FULL_PASS

- [ ] G7: Fresh independent numerical, bridge and claim reviewers accept the exact current sources.
  EVIDENCE: pending

- [ ] G8: Documentation, capability/debt boundaries, after-task validation, source-pinned receipts, local commits and final replay are complete.
  EVIDENCE: pending
