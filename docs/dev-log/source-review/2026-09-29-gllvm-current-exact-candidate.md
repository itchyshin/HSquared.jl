# Scoped current-candidate GLLVM objective and bridge review

Date: 2026-09-29. This is a bounded review of the current dirty Julia and R
candidates. It supplements, and does not replace, the older Wave 3 and GLLVM
foundation review packets.

## Pinned state

- Julia branch `codex/hsquared-fa-gllvm-20260927`, HEAD
  `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`.
- Julia `src/genetic_gllvm.jl` SHA-256
  `0727459d2f163835519ae8cf8481d2439b90ba5065cfc8d74ad2c0c08736d2ca`.
- Julia objective contract SHA-256
  `e19828a7d7480f47b0aac06f338e58357a58b4bcd3798b59d2967267848a0439`.
- Julia trait-effects test after adding the design-basis regression SHA-256
  `a5c68350b2778e069e9c0b2d4cb1542a40b33e406e621bed5495863f4418698b`.
- Matched R branch `codex/hsquared-fa-gllvm-20260927`, HEAD
  `fa98c262eb21694d672e671c9672491ce3369cec`.
- R bridge SHA-256
  `329a2ff527b4e03b0b18f7bbf249eb59c19264fad245fc98e75d5c5251dab9fb`;
  focused R test SHA-256
  `16d62082886f4bf8daf50db69a729c248b6a4c0c422a0f538e4e447f574f5b90`.

## Reviewed contracts

Noether reviewed the symbolic objective and selected Julia source spans at
`src/genetic_gllvm.jl:157-180,253-299,325-428,510-517,537-552,560-670`.
The predictor, trait-major response stacking, factor-major mode vector, prior
precision, joint observed-Hessian Laplace correction, and reported fixed-plus-
genetic-effect integrated objective agree with
`docs/design/genetic-gllvm-objective-contract.md:7-21`. The source requires a
full-rank fixed-effect design. The reported q-by-T trait modes reconstruct as
`F*Λ' + D`, with the FA-specific term on its documented scale. Factor scores
and loadings remain rotation-dependent.

The Gaussian objective reduction is consistent with multivariate REML for the
tested covariance and fixed-effect cases. Before this slice, reviewed
comparisons used an intercept-only fixed-effect design. A new regression now
checks a full-rank two-column design with a nonidentity pedigree and verifies
both direct Gaussian reduction and the documented flat-measure coordinate
shift `-T*log(abs(det(C)))` after replacing `X` by `X*C`.

Hopper reviewed the current R bridge and test contract. The bounded adapter
reorders rows to normalized pedigree IDs, preserves the three trait labels,
returns link-scale conditional modes and fit diagnostics, and compares the R
result with a direct same-input Julia fit. The audited route remains limited to
Poisson-log, T=3, K=2, pure-low-rank covariance, complete balanced records, a
pedigree animal effect, and trait intercepts.

## Checks run

- Julia command
  `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia julia --project=. --startup-file=no test/genetic_gllvm_trait_effects.jl`
  passed 73/73 assertions. The new multi-column reduction test passed 6/6.
- Full Julia `Pkg.test()` exited 0 and ended with
  `Testing HSquared tests passed`. It emitted the existing project/manifest
  mismatch warning; no `Pkg.resolve()` or update was run.
- Live R command
  `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 JULIA_DEPOT_PATH=/private/tmp/hsquared-fa-gllvm-depot:/Users/z3437171/.julia HSQUARED_JULIA_PROJECT=/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl HSQUARED_JULIA_TESTS=true Rscript --vanilla -e 'devtools::test(filter = "gllvm-optin")'`
  passed 87/87, with zero failures, warnings, or skips. This included live
  direct R-Julia parity and the trait-order comparison.
- `git diff --check -- test/genetic_gllvm_trait_effects.jl` passed.

Reviewers did not run these checks; they are the current-turn execution
receipts. The GLLVM route remains experimental and partial. This review does
not establish population recovery, a same-objective external comparator,
non-Gaussian uniqueness, broad inference, GPU behavior, whole-file E1 signoff,
or release readiness. GLLVM FA continues to use `ψ=exp(θ)` while Gaussian FA
uses its documented positive floor; cross-route feasible sets therefore differ
near zero.

## Disposition

Scoped PASS for the reviewed objective, trait-effect reconstruction, current
bounded bridge payload, live parity, and Gaussian fixed-effect-basis reduction.
No whole-file, A2, E1, or V3 signoff is implied. The prior
`docs/dev-log/source-review/2026-09-29-gllvm-foundation-followup.md` records an
older source hash and is not evidence for this current source snapshot.
