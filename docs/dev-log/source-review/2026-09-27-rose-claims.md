# Rose claim-versus-evidence audit: FA and genetic GLLVM candidate

Date: 2026-09-27. Scope: the uncommitted twin candidates on `codex/hsquared-fa-gllvm-20260927`, especially Julia `validation_status()` and capability/debt rows, generated status page, R public status and articles, focused tests, and source-review packets. Numerical signoff remains with the source-review waves and final tests.

## Verdict: CLEAN-WITH-LIMITATIONS for bounded public wording

The bounded capability language is supported: R exposes an **experimental, partial** four-trait, rank-one Gaussian pedigree FA expert-control fit and an **experimental, partial** three-trait, rank-two Poisson-log pedigree genetic GLLVM expert-control fit. Julia's historical `V4-FA` **covered** engine row is limited to its stated T=4/K=1 validation cell; it does not promote the R route. Julia `V6-GGLLVM-LAPLACE` remains **partial**. The GLLVM output is link-scale trait conditional modes and an integrated Laplace objective, not factor scores, posterior means, ordinary non-Gaussian ML, or REML. Neither route earns a broad family, rank-selection, interval, or production claim. `public_covered_count` remains **7** in both twins.

The R evidence counts are reconciled: **50** FA parity checks and **49** GLLVM parity checks. Final programme signoff remains blocked by incomplete final-candidate verification and the source-review holds below.

## Evidence checked

- FA: local identifiability/scale checks **15/15** and an independent dense Cholesky REML *objective* oracle **7/7**. A later independent base-R BFGS same-model fit agrees on one near-boundary fixture (`docs/dev-log/scout/2026-09-27-fa-same-model-reference.md`); an interior and external-package fitted comparison remain open. The historical S4 FA gate passed **8/10** selected seeds; the broader Phase 4B calibration did not pass. The R live same-input FA parity receipt is **50 passed** for fitted quantities (`hsquared/docs/dev-log/check-log.md`, 2026-09-27 entry).
- GLLVM: the selected Poisson T=3/K=2 pedigree cell converged from the default and three ordinary starts with objective spread below `1e-5`; the R live 12-animal same-input parity receipt is **49 checks**. An external same-objective comparator remains open.
- Wave 2 repairs: beta-binomial Fisher information remains the *working* scoring weight; the final Laplace determinant uses observed joint curvature and refuses a non-positive-definite Hessian. With integrated fixed effects, the historical numeric `elbo` field is a hybrid variational-plus-Laplace value without a general lower-bound guarantee. Focused Julia wave-2 tests passed **183/183**. R user-facing labels and the relevant help/article text were corrected; focused R non-Gaussian tests passed **186**, with **7 skips** (five live-Julia and two legacy), no failures or warnings.
- Julia `validation_status()` generated **56** rows; status-page regeneration was idempotent **5/5**. `git diff --check` passed in both worktrees. The Rose wording changes made no covered-status flip.

## Open gates

The final content-matched Julia `Pkg.test()` and Documenter build passed locally (`/private/tmp/hsq-fa-gllvm-pkg-test-20260927-final-exact.log`, `/private/tmp/hsq-fa-gllvm-docs-20260927-final-exact.log`); this is not CI proof. The R final local check returned zero errors, warnings, and notes (`/private/tmp/hsquared-fa-gllvm-rcmdcheck-20260927-final-current.log`). Current CI and final commit review remain open. Source-review waves 1–4 retain **HOLD** dispositions despite focused repairs; their remaining findings need independent integration and panel disposition. FA still needs an interior and external-package fitted comparator; GLLVM lacks an external same-objective comparator and broad recovery/calibration. No interval calibration, automatic rank choice, missing-record, or broader-family claim follows from the selected cells. No GPU or release action was audited here.
