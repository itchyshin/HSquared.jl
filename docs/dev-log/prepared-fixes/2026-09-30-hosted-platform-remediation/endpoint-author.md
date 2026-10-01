# Genomic endpoint cancellation repair: author evidence

Date: 2026-10-01. Actual model/effort: Astra high. Author proposal; independent review and hosted confirmation remain required.

## 1. Goal

Diagnose and repair the current candidate's lower-boundary failure while retaining the original scientific boundary, convergence, and compatibility assertions. Parent owns live integration and CI. All work here is isolated under `/private/tmp/hsq-genomic-endpoint-roundoff-fix-20261001`.

Candidate HEAD: `73ace301a7e79e922d911345f5033c72968e2ecd`. Baseline likelihood SHA-256: `d77e6565e574ce428371fb86f8322d12edc977ead5f05093d24c4204ef85e935`.

## 2. Implemented

The strict comparison of two independently rounded Float64 profile likelihoods can turn a negative, second-order change near a stationary endpoint into a positive change. The new context-aware overload re-evaluates close comparisons using BigFloat arithmetic on the same eigen context. A comparison is close when its absolute gap is at most `32*eps(Float64)*max(1,abs(candidate),abs(endpoint))`. The threshold triggers more accurate arithmetic; it does not alter acceptance. Any positive re-evaluated gain still blocks endpoint acceptance. The original four-argument strict helper is unchanged.

The generic profile evaluator retains a BigFloat ratio when given a BigFloat eigen context; normal Float64 evaluations are unchanged. The classifier calls the new overload only for an endpoint-adjacent refined candidate. It preserves all grid, refinement, KKT, tie, component, and convergence rules. Failed precision evaluation returns `endpoint_comparison_failed` and unresolved status.

The routine never changes process-wide MPFR precision. It requires the caller's current BigFloat precision to be at least 128 bits for the fallback; the tested default is 256 bits. This avoids changing precision while another Julia thread may be using BigFloat.

## 3a. Decisions and Rejected Alternatives

Rejected enlarging the scientific likelihood tie tolerance: the existing three-record anisotropic regression deliberately detects real improvements below that tolerance. Rejected forcing a boundary classification from a small gradient alone. Rejected weakening or skipping the original doc-46 assertions. Rejected making a process-wide precision change within the fitting routine.

For the paired lower fixture, `X'H^-1 y=0`. With `h_i=1+r(lambda_i-1)` and `S(r)=sum(1/h_i)`, the independent exact profile difference is

```text
delta ell(r) = -[n log(S(r)/n) + sum(log(h_i))]/2.
```

Its derivative at zero is zero. The leading difference is negative and quadratic for this nonconstant diagonal kernel. Scaling y changes the absolute likelihood by a constant and cannot change this difference or the optimum.

## 4. Files Touched

Proposed patch contains only:

- `src/likelihood.jl`: one new helper overload, one type-preserving ratio line, one adjacent comparison caller block.
- `test/wave4_genomic_endpoint_roundoff.jl`: 52 focused assertions and a deterministic fixture.
- `docs/design/59-v07-genomic-boundary-score-amendment.md`: explanation of cancellation resolution and its limits.

No live file, original test, runner, frozen design-46 seal, campaign, or acceptance manifest was edited. Proposed registration: include `wave4_genomic_endpoint_roundoff.jl` beside the existing `wave4_genomic_boundary_near_endpoint.jl` include. Registration is left to the parent.

## 5. Checks Run

Every Julia run was estimated before launch, used Julia/BLAS1, and had a subprocess timeout. No full package test, campaign, GPU work, or new simulated data.

| Check | Result | Time / timeout |
| --- | --- | --- |
| Intel Julia 1.10.12 baseline three original fixtures | All three happened to pass; lower refined gain rounded to zero | 35.15 s / 120 s |
| ARM Julia 1.10.12 scale/ratio diagnostic | Positive rounded gains on equivalent lower fixtures | 16.86 s / 120 s |
| Frozen new regression against baseline | 13 pass, 20 fail, 19 errors, 52 total | 23.85 s / 120 s |
| First implementation test | Reserved formula-term namespace collision; retained | 19.61 s / 120 s |
| Corrected implementation, Julia 1.10.0 ARM | 52 new + 71 original doc46 + 28 original near-endpoint = 151 pass | 26.90 s / 120 s |
| Final packaged test, Julia 1.10.12 Intel | Same 151 pass, OpenBLAS 0.3.23, BigFloat256 | 41.43 s / 120 s |
| Baseline mechanism reproduction | Exact rejection reason and independent signed gap recorded | 18.02 s / 60 s |
| Patch replay | All three proposed files reproduce tested bytes | Static |
| Exact unchanged-region check | Removing only the declared source delta restores the whole baseline byte for byte | Static |
| Original-test preservation | Original doc46 block and near-endpoint file match live bytes exactly | Static |

Baseline mechanism at response scale 0.2 returns `boundary_unresolved`, reason `endpoint_adjacent_candidate_beats_endpoint`. At r=1e-10 its Float64 gain is +1.3322676295501878e-14, but the independent 256-bit paired-data identity gives -1.2952302628664683e-19. At original response scale 1.0, the same ratio gives +7.105427357601002e-15 despite the same negative mathematical gap. On this Mac the original optimizer selects another ratio whose rounded gap is zero, explaining why the complete original local fixture passes.

The original Windows CI log does not print the unresolved reason or the selected ratio. This packet establishes the source defect and an equivalent local reproduction. Attribution of that exact hosted branch remains an inference until hosted replay. The parent also reports the same lower assertion failure on Linux1.10 and Windowslatest; those reports are not a substitute for new hosted evidence.

## 6. Tests of the Tests

The 20 baseline failures demonstrate the existing full-profile behavior on equivalent scaled fixtures. The 19 baseline errors concern the new context overload, absent before implementation; they are not counted as independent old-source failures. Regression assertions were frozen before source changes. Packaging only inlines the identical fixture; `verification.json` proves the assertion body was preserved.

Independent controls use the paired-data identity above, without the general profile evaluator or optimizer. Genuine positive gains are tested at r=1e-10 and r=1e-16, including a gain below one Float64 ULP of the absolute objective. Reflecting K and transforming y tests the upper endpoint. Existing small-positive scalar helper assertions and the anisotropic three-record counterexample all remain green. Low caller BigFloat precision returns an unresolved comparison instead of inventing a sign.

## 7a. Issue Ledger

- Confirmed and repaired: cancellation can falsely reject the stationary lower endpoint.
- Preserved: true endpoint-adjacent improvement remains unresolved, including improvements below the ordinary tie tolerance and below Float64 absolute-objective resolution.
- Pending: independent source/test review, live integration, exact-current full package and hosted replay.
- Separate parent-owned issue: Linuxlatest PCG actual-residual failure; this patch does not touch iterative solvers.

## 8. Consistency Audit

Original scalar strict comparison, KKT signs, boundary epsilon, grid step, refinement tolerance and success guard, classification tie tolerance, endpoint numerical representation, and all fit constructors are unchanged. The new calculation operates on the same rounded eigen context. It cannot establish the accuracy of an ill-conditioned eigendecomposition. No API, convergence meaning, capability status, public covered count, or broad calibration claim changes.

## 9. What Did Not Go Smoothly

The first Intel executable path omitted the Julia app bundle and failed before Julia launched; the correct installed path was discovered and used. The first implementation used unqualified `precision`, which resolves to HSquared's reserved formula term; qualifying `Base.precision` fixed this namespace error. The failed log is retained. No assertion was changed to accommodate it. The original unscaled fixture passes on both local runtimes, so hosted arithmetic is not claimed to have been reproduced exactly.

## 10. Known Residuals

Default BigFloat256 is tested; lower-than-128 caller precision fails closed. Higher precision evaluates the existing numerical eigen context and does not remove eigendecomposition, conditioning, optimizer, or model-identification uncertainty. Finite precision still limits arbitrarily small signed differences; no interval-arithmetic proof is claimed. No broad boundary recovery, coverage, R-oracle, performance, or release conclusion follows. The original historical campaign remains historical evidence for its own source.

## 11. Team Learning

A strict scientific sign rule can require more accurate arithmetic than two rounded absolute objectives provide. Preserve the sign rule and improve its calculation. Scaling-invariant fixtures and an independent closed-form likelihood difference exposed the defect without a new campaign. Graft supplied context before source reads; reported savings total about 458,146 tokens across the three context calls.

## 12. Cross-Product Coverage

This packet covers the bounded genomic closed-boundary comparison only. It does NOT cover the concurrent PCG repair, full package/platform acceptance, R bridge parity, campaign recovery, general boundary calibration, release, or any independent approval of my earlier profile/PEV or iterative work.

## Exact proposal pins

- Source: `9e4b7b422f0ba6daac41b39aadf2172b56fc1879b91563ca40d2df9e374d9f11`.
- Patch `endpoint-roundoff.patch`: `bf5046c5617225ccc0f24009c7f0044b6f9fcd2ccfcb86001dd0d7d5b50c1bee`.
- Packaged test: `7c2623319bbef4fa8520588283790ba30e6ff3f0456fa318776271eb9f9cdc09`.
- Original frozen regression before fixture inlining: `8f492d721cb32a008e4824e58cbeebe4ad5e2a36d6e0e5d94c3b2cfa6a1a02f4`.

All artifact pins are recorded in `SHA256SUMS`; replay and preservation evidence is in `verification.json`. Raw red/green logs and timing JSON files are retained in this directory.
