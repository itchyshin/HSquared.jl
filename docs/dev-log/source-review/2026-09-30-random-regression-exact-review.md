# E1 exact-current random-regression source review, 2026-09-30

## 1. Goal

Complete the residual source review of `src/random_regression.jl` at the frozen candidate. Reviewer: Gauss numerical engine lens. No additional agents were spawned.

Verdict: **full-file source coverage is accounted for, 1–533; full-file approval remains HOLD**. The exact-current optimizer component remains approved within its existing scope. The descriptor findings below require repair or explicit accepted limitations; covered-cell status is unchanged.

## 2. Implemented

Created this scratch review receipt. No source, tests, repository reports, status rows, gate ledgers, driver, or Git state were changed.

Candidate `/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl`, branch `codex/hsquared-fa-gllvm-20260927`, HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16`, dirty working tree.

| Source or test | SHA-256 |
|---|---|
| `src/random_regression.jl` | `761151eb0297bece4c859db8a504a244a26510d320f123f85a9a9295621e7a5c` |
| `src/evolvability.jl` | `fd49987ee69c1f9b6e3335bdb6e4f8c73b6f0cdab3da4b7263cf4e87b6577ff3` |
| `src/multivariate.jl` | `fc41aefefb61b2cc915d4f802b0017dc4daea5daa795a9d3421854e9c4958670` |
| `test/wave2_precision_contracts.jl` | `ca13fb83ac9d35abcd08a4115e78b229c57283a512da19e0b1f3d88dbf0c0719` |
| `test/runtests.jl` | `b2d77c7f0937f5fcf0ed8ec32913c816b2c942f27c83825c8424107a5bc58b24` |

Review receipts used:

- `docs/dev-log/source-review/2026-09-29-optimizer-covariance-boundaries.md`, SHA `b34767c9457316ac8279cbe2233f7745d2f7a6a842b21cda56dbc83ebfcfabf6`.
- `docs/dev-log/source-review/2026-09-29-wave2-random-regression-followup.md`, SHA `edd94f036e05dc99492e2f0a8a929c035d4d2b529d6b70854218d532df913fac`.
- `docs/dev-log/source-review/2026-09-30-e1-current-coverage-reconciliation.md`, random-regression subsection.

## 3a. Decisions and Rejected Alternatives

Reused the exact-current optimizer/covariance review's finite proposal and final-point approval, mapped to current inclusive spans `496–511,516–521` (22 lines). Its receipt names the component without numbered ranges; these coordinates identify the actual proposal closure and post-fit decoded-parameter guards. The reused finite-start/covariance proof was not repeated.

Fresh residual spans reviewed:

| Inclusive span | Contract |
|---|---|
| 1–277 | scope/units, normalized Legendre basis, standardization, supplied descriptors, eigenfunctions, plotting payloads, design-order convention |
| 278–370 | record/animal/coefficient design, supplied MME and input/ID/precision/residual guards |
| 371–495 | dense covariance factorization, REML and GLS/BLUP helpers, fitter input/default/start construction |
| 512–515 | optimizer initialization and selected parameter extraction |
| 522–533 | final GLS/BLUP call, fitted output fields and diagnostics |

These residual spans contain 511 lines. Together with the reused 22 lines, the union is exactly 1–533 with no gap or overlap. Coverage records inspection; it does not approve every accepted input or numerical scale.

Historical ID/finite-Z/residual approval pins `e282760b…`, rather than the current bytes. This task reattests its named contracts directly at the current source: `156–164` for descriptor residuals; `323–343,360–362` for supplied MME; `457–490,492–493,527` for the fitter. IDs are checked before solve/optimization, finite Z is checked before W construction, supplied and explicit starting residuals are finite positive, and explicit starting covariance is checked before W construction and Ainv inversion. The old receipt contains no archived e282 source bytes, so the current contracts were reinspected directly; no byte-identical old-to-new diff is claimed.

The diff against HEAD shows unchanged descriptor algebra apart from the residual guard, plus the historical input/status repairs and the current optimizer guards. Original Wave-2 whole-file HOLD and its algebra remain history; corrected covariance/precision and ID findings have the current dispositions above.

## 4. Files Touched

Only `/private/tmp/e1-random-regression-exact-review-20260930.md` was created. Other lanes' dirty source and tests were preserved.

## 5. Checks Run

Graft query/skeleton preceded source inspection. Cache refresh failed with EPERM and graph coordinates were stale; the review used numbered current source. Earlier lane preflight for this candidate was completed and showed active validator and pedigree-test leases; this task performed no overlapping writes.

Relevant test source was inspected at `test/runtests.jl:9871–9993,10035–10185` and `test/wave2_precision_contracts.jl:1–112`. Tests cover basis normalization, spectral reconstruction, descriptor shapes, independent supplied-MME GLS ordering, k=1 scalar reduction, fitter objective oracle, fitted MME consistency, and malformed IDs/precision/Z/residual/start guards. These test assertions were not rerun. The historical focused 105/105 receipt retains its original scope.

Before the runtime probe, the estimate was under one minute. The probe loaded the frozen project with one Julia thread and one BLAS thread and used only descriptor calls. It completed within that estimate. No optimizer, fitted model, simulation, GPU, remote compute, package update, or full test suite ran.

Command environment:

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia julia --project=/Users/z3437171/.codex/worktrees/hsquared-fa-gllvm-foundations/HSquared.jl --startup-file=no -
```

Exact calls and observed values:

```julia
standardize_covariate([0.0, 1.0]; lower=-Inf, upper=Inf)
# [NaN, NaN]
standardize_covariate([0.0, 1e308])
# [-1.0, Inf]
standardize_covariate([10.0, 20.0, 30.0])
# [-1.0, 0.0, 1.0]
rr_heritability(reshape([1.6e308], 1, 1), 1.2e308, [0.0]).values
# [0.0], whereas 0.8 / (0.8 + 1.2) == 0.4
rr_genetic_covariance_surface(reshape([1.6e308], 1, 1), [0.0]).values
# [8.000000000000001e307;;]
rr_eigenfunctions(Matrix(Diagonal([1e308, 1e308])), [0.0]).variance_explained
# [0.0, 0.0], whereas the two shares are 0.5 each
rr_heritability(reshape([1.6], 1, 1), 1.2, [0.0]).values
# [0.4000000000000001]
```

The target SHA was checked before review and again after source/test inspection. Closeout matched the target and whole frozen source tree `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`. The coverage union check returned 22 reused lines, 511 fresh lines, zero gaps, and zero overlaps. The prose checker passed; final tool output records its result.

## 6. Tests of the Tests

No mutation tests were run. The independent supplied-MME oracle constructs W directly instead of calling `_rr_random_design`, and uses unequal diagonal/off-diagonal coefficient covariance, so it tests the coefficient ordering. The normal descriptor controls above distinguish the confirmed extreme-input failures from ordinary behavior.

Required regressions: reject infinite standardization bounds; preserve finite endpoint/midpoint maps at large finite scales; verify heritability and eigenvalue shares under multiplication of all relevant variances by a common large finite scale. Add deliberate rank-deficient and nearly-collinear fixed-design tests with explicit error/conditioning expectations; no recovery campaign is needed to test these contracts.

## 7a. Issue Ledger

RR-C1, P2: standardization admits nonfinite bounds and can overflow at finite endpoints. At `74–77`, only a's finiteness and `upper > lower` are checked. Infinite bounds pass and return NaNs. Even `[0,1e308]` has a representable finite range, but the factor `2*(a-lower)` overflows before division, returning an infinite upper endpoint. Validate finite bounds and use a scaled affine calculation, or reject an unrepresentable transform explicitly. This is confirmed by descriptor-only runtime.

RR-C2, P2: descriptor ratios silently change under large finite scaling. `rr_heritability` at `164` sums two finite variances into infinity, returning 0 when the true ratio is representable and equals 0.4. `rr_eigenfunctions` at `200–201` sums finite eigenvalues into infinity and returns all-zero explained-variance shares. Shared PSD/PCA guards correctly accept the finite inputs; they do not protect these sums. Use stable ratio normalization or explicit failure. This is confirmed by descriptor-only runtime and propagates to plot-data helpers at `226–246`.

RR-C3, validation requirement: fixed-effect rank and conditioning. The fitter checks `p < n` at `464` but does not explicitly check full column rank before optimization. REML and GLS use Cholesky of `X'V^-1X` at `383,395`; rank-deficient X therefore reaches numerical failure, and the proposal closure can turn that into an all-Inf optimizer rather than an early input error. Supplied MME likewise relies on the solve at `354`. Final coefficients have no explicit finite-value check. Source inspection establishes the ingress/diagnostic limitation. No bad fitted result was measured.

Historical W2-03 covariance/precision admission: FIXED and reattested. Historical W2-07 RR ID count and residual admission: FIXED and reattested. Exact-current optimizer/covariance proposal and post-fit boundaries: approved component reused. No broader historical or programme gate is closed by this receipt.

## 8. Consistency Audit

The normalized-Legendre convention is coherent: k counts coefficients, phi0 squared is 1/2, and the k=1 reduction uses `K_g=2*sigma_a2`. W places animal a's coefficient c in column `(a-1)k+c`; `Ainv ⊗ inv(K_g)` and GLS reshape match this ordering. Supplied MME requires PD K_g; descriptors allow PSD, and the internal marginal GLS formula remains algebraically defined at singular K_g. The log-Cholesky fitter's feasible set remains PD.

The full REML determinant/residual expression includes the `(n-p)*log(2pi)` constant and uses supplied/model-aligned matrices. Reused oracle/reduction evidence supports those valid-input identities. Comparing fixed-effect REML values across different fixed-effect designs still requires the usual restricted-likelihood coordinate/design qualifications.

Heritability units and the permanent-environment denominator caveat remain visible at `144–154`. Covariance/eigenfunctions refer to the supplied normalized basis; repeated eigenvalues identify eigenspaces. Public descriptor wrappers carry supplied-status flags. Current fitted output stores k but omits basis bounds/convention provenance, so callers must retain the basis map themselves.

## 9. What Did Not Go Smoothly

Graft cache coordinates were stale, requiring exact numbered-source reads. The historical input receipt's source hash differs; its named contracts were reattested directly instead of presenting it as current whole-file approval.

## 10. Known Residuals

Dense execution remains fenced: Z and Phi are materialized, W is dense `n × qk`, supplied MME materializes the Kronecker precision into the coefficient matrix, and REML inverts dense Ainv and forms dense `A ⊗ K_g` and V. No dense-cell budget is enforced. Sparse pedigree input does not establish sparse execution.

Near-zero residual variance, ill-conditioned fixed/basis design, high-order coefficients, and large finite default phenotypic-scale calculations remain numerical validation limits. Optimizer convergence alone does not establish a global maximum or calibrated inference. The existing covered k=2 cell, broader-order experimental boundary, permanent-environment omission, and comparator/calibration limits remain as recorded in the capability/convention ledgers.

## 11. Team Learning

Finite covariance and positive residual guards do not make downstream arithmetic safe: bounded ratios can be wrong after an overflowing sum. Descriptor-scale tests should verify invariance of ratios under a common finite rescaling and verify raw-covariate endpoint maps separately from basis recurrence tests.

Memory receipt: current source and repository receipts supplied all numerical conclusions. Earlier routing retained exact-cell evidence, twin boundaries, and shared-lane preservation. Golden Set: no broader campaign was run for this bounded source/descriptor review. No memory was updated.

## 12. Cross-Product Coverage

This receipt accounts for exact-current random-regression source inspection and the specified descriptor arithmetic probes. It does NOT cover whole-file numerical approval, whole-wave E1, broader-order recovery, general R bridge providers, permanent-environment or heterogeneous-residual fitters, curve PEV, uncertainty calibration, GPU execution, sparse scaling, capability promotion, or release readiness. Parent should carry RR-C1/RR-C2 and the rank/conditioning requirements into its E1 ledger while retaining the current component approvals.
