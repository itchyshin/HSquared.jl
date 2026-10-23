# Non-Gaussian engine exact-current component review

Date: 2026-09-30  
Candidate: `codex/hsquared-fa-gllvm-20260927` at HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`  
Scope: read-only numerical review of the non-Gaussian objective, variational approximation, failure boundaries, and directly relevant tests. This is not whole-wave E1 signoff.

## Pinned files

| File | SHA-256 |
| --- | --- |
| `src/nongaussian.jl` | `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00` |
| `test/wave2_nongaussian_contracts.jl` | `c7a6cd8eba56cf54f4b0ffed629ba1b5a5dfbd5220f2d5d7d09e3ec1cebaad60` |
| `test/test_nongaussian_inner_convergence.jl` | `f405a75e14da1be035c9de29cc17accef4dbaedeeb740d0d96f7d44f401cb33c` |
| `test/runtests.jl` | `b4802d82a430abc10134485a21bf387d9497d72bb2643c25afbbb6ec0cdc4691` |
| `docs/design/genetic-gllvm-objective-contract.md` | `e19828a7d7480f47b0aac06f338e58357a58b4bcd3798b59d2967267848a0439` |
| `docs/dev-log/source-review/2026-09-27-wave2.md` | `f5da5f1a5147d682d426f31e36b98f3fa8c121bda6bc21e9ddc6168874f1ad56` |

## Review verdict

**Conditional PASS** for the repaired mathematical contracts described below. **HOLD** for whole-file/wave E1 closure. This was a static review only; the reviewer made no edits and ran no tests, simulations, or GPU work. The lane preflight found 11 other refs with `src/nongaussian.jl` work absent from this checkout. The review is limited to the pinned working-tree bytes and does not reconcile those refs.

Reviewer: Gauss numerical engineer role, GPT-6 Astra model, high reasoning effort.

## Confirmed contracts

- `src/nongaussian.jl:722-735` forms the integrated Laplace objective over fixed and genetic effects, including the flat fixed-effect measure, animal prior normalization, and final joint-Hessian determinant. This is not ordinary profiled non-Gaussian ML. Gaussian value and BLUP reductions are tested in `test/runtests.jl:8732-8740,8773-8787`.
- `src/nongaussian.jl:437-445,722-731` uses observed final beta-binomial curvature for the determinant after Fisher-scoring iterations. `test/wave2_nongaussian_contracts.jl:7-33,227-236` checks the joint Hessian and score derivative.
- The variational-approximation path labels its conditional ELBO and hybrid fixed-effect Laplace correction, applies the Gaussian mean-Hessian Schur complement, and requires inner covariance convergence (`src/nongaussian.jl:823-849,891-918,924-949`). Registered tests cover the Schur regression and distinguish zero mean score from incomplete covariance convergence (`test/wave2_nongaussian_contracts.jl:189-224`; `test/test_nongaussian_inner_convergence.jl:13-83`).
- The engine checks `Ainv` for finite values, relative symmetry, and positive definiteness before symmetrization (`src/multivariate.jl:287-309`). The contract requires a proper positive-definite prior; singular precision is unsupported. Ainv construction itself is outside this review.
- The path densifies design and precision inputs and forms a full inverse at the stated source locations. This is a dense validation-scale route; sparse-input acceptance tests do not establish sparse scaling.

## Findings to fix or carry

1. **P1, proper-integral guard is incomplete.** `src/nongaussian.jl:609-637` excludes general separation but does not cover negative-binomial all-zero or beta-binomial endpoint cases. The endpoint tests (`test/wave2_nongaussian_contracts.jl:36-67`) cover only enumerated families. The earlier Wave 2 packet carries separation but not these omitted cases. A converged local calculation does not establish existence of the flat-measure integral. Next check: deterministic separated-covariate and omitted-endpoint fixtures that reject or mark the objective unusable, with valid no-fixed-effect controls.
2. **P2, outer failure contract is inconsistent.** Gaussian and negative-binomial objectives pass inner NaNs or thrown inner failures to Optim (`src/nongaussian.jl:1306-1309,1327-1330`); selected scalar, ordinal, and Gamma routes guard some corresponding failures (`:1366-1375,1406-1414,1430-1437`). Variational Newton and covariance updates are undamped (`:800-808,902-904`). Existing inner-budget and profile-failure tests do not establish one consistent outer failure contract. Next check: deterministic difficult Poisson-VA and NB cases must return an explicit unusable fit or failure, never accept an invalid objective or leak an unexplained optimizer exception.
3. **P2, logistic covariance stationarity is unverified.** Fixed quadrature makes score/weight derivatives consistent in the mean, but the variance update uses expected curvature; that need not be the exact derivative of the finite quadrature ELBO with respect to variance. The registered finite-difference test differentiates only the mean (`test/runtests.jl:9295-9306`). Next check: finite-difference the ELBO variance derivative and quadrature-order sensitivity at moderate and large predictor variance for Bernoulli and binomial.
4. **Validation limit: dense scaling.** The dense route is documented. This review does not claim sparse scalability or inferential calibration.

Existing non-Gaussian quadrature gates use no fixed-effect columns (`test/runtests.jl:8850-8873,9308-9337`); they do not verify general integrated-fixed-effect accuracy, hybrid VA curvature, or interval calibration. The Poisson genetic GLLVM opt-in route remains the separately bounded, partial cell recorded in the twin gates.

## Disposition

Carry the findings above in E1 until fixed or explicitly resolved in the scope ledger. Do not promote a non-Gaussian family, claim whole-source signoff, or infer additional R bridge support from this component review.
