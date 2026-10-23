# GLLVM record-family boundary and descriptor guards: isolated receipt

Date: 2026-09-30. Owner: Gauss numerical lane. Status: isolated repair and focused checks complete; parent review and integration pending.

## 1. Goal

Dispose of GLLVM-C3, accepted varying-trial binomial input that lacks record dispatch, and GLLVM-C5, malformed synthetic descriptor metadata. Keep the frozen candidate and bounded R Poisson T=3,K=2 route unchanged.

## 2. Implemented

C3 uses an explicit support boundary. `_check_gllvm_record_family` rejects `BinomialVectorResponse` both as a scalar family and anywhere in a per-trait family vector. The marginal and fitter call it as their first statement, before conversion, precision validation, mode work, or optimization. The error and both source docstrings direct callers to the standalone scalar animal-model path for varying trials. This is rejection of unsupported input, not new per-record GLLVM support.

C5 validates `genetic_gllvm_descriptors(result::NamedTuple)` before descriptor arithmetic: G passes existing covariance validation; K is a non-Bool integer in 1:T, matching the multivariate structured-fit producer; supplied loading metadata is a finite T×K matrix; uniqueness has length T, finite nonnegative entries, and does not exceed diag(G). FA requires uniqueness. Low-rank accepts nothing or a zero vector. Optional absent loading metadata remains allowed. Descriptors still use only G and uniqueness; raw loading orientation does not affect their values.

The supplied-loading descriptor method remains unchanged. Its existing constructor checks enforce finite loadings, matching uniqueness length, and positive supplied FA uniqueness. Its wider K>T support remains available, distinct from the multivariate-result overload's producer contract.

## 3a. Decisions and Rejected Alternatives

The existing capability rows describe scalar response families or one family per trait. They do not promise varying trial counts within a trait. A bounded rejection fence avoids extending every score, weight, observed-curvature, log-likelihood, and backtracking dispatch loop. `BinomialVectorResponse.n_trials::Vector{Int}` and `_fam_record` at nongaussian 184 remain the standalone route.

No comparison with a particular loading orientation is used for descriptor computation. Loading metadata is checked only for shape and finiteness. This bounded repair does not certify arbitrary synthetic G against the full supplied loading decomposition.

## 4. Files Touched

Only `/private/tmp/hsq-gllvm-descriptor-record-fix-20260930/` was written: project/source copy without Git directories or campaign artifacts; isolated genetic_gllvm.jl; new regression file; logs; unified patch; inventory; receipt. No live candidate, primary driver, repository test entry point, R twin, or other lane's files were changed.

Frozen genetic_gllvm SHA-256: `0727459d2f163835519ae8cf8481d2439b90ba5065cfc8d74ad2c0c08736d2ca`.

Isolated genetic_gllvm SHA-256: `7cf01057c9a101e64f50f476eda10c17b47dddb04b090b416810467eeba453c9`.

Frozen source tree: `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`.

Isolated source tree: `017d3dd68d08158e849b585405bed15c7c9ff71f800e3f3d9e7c32bc5a4862f8`.

Patch SHA-256: `737bd4156a4ac8186ea49c9af1eb6ddc0275c68a1a7f3801d0fc6301e6ae680d`.

Test SHA-256: `9932c6e4a91a065c519a41d66f11aadf4d829d2f8eb75329f9f5b6635ccbbd36`.

The inventory pins Project/Manifest and every run log. The source-tree algorithm is sorted src-relative UTF-8 path, NUL, file bytes, NUL. Only src/genetic_gllvm.jl differs. Parent-authorized HEAD is 9c10f09c1bdc7f7ab19cb07c339d1dc83179f429; source pin remains frozen.

## 5. Checks Run

Estimate before runtime: under two minutes, deterministic tiny inputs, one Julia thread, one BLAS thread, no GPU. Launch: `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`; Julia 1.10.0. From the isolated root: `julia --project=. test/gllvm_descriptor_record_regression.jl`.

Red frozen source: 16 passed / 23 failed / 0 errors, exit 1, 5.9 seconds. First green: 39/39, exit 0, 5.1 seconds. Final exact source/test: 50/50, exit 0, 7.2 seconds. No statistical optimizer, fit, score, mode, or Hessian solve ran. Calls to the fitter reject at its first statement. These probes supply rank=0 as a fallback so that a regressed family fence would fail the message check and stop at the existing rank guard, before any optimizer call. Supported marginal controls invoke the real shared proper-integral guard, then a test-only sentinel stops execution before mode work; guard/precision validation may perform their existing matrix checks. Temporary dispatch is deleted in finally and generic dispatch restoration is asserted.

`git apply --numstat` parses 50 additions / 5 deletions in genetic_gllvm.jl and 111 additions in the regression file. Graft caller/literal queries preceded source reads and edits; total reported context savings 862,985 tokens. Final prose check: zero hits.

## 6. Tests of the Tests

All 23 baseline failures target the defects: four record-family boundary checks and 19 synthetic metadata checks. An outer testset retains both groups after failures. The final file adds 11 retained-contract and entry controls after the red run: four fitter-entry rejection checks, standalone count/record mapping, pure low-rank descriptor controls including K>T, and a T=3,K=2 Poisson kernel guard-path control. Mixed-family rejection includes a valid Gaussian first trait and a varying-trial second trait.

## 7a. Issue Ledger

| Finding | Disposition |
| --- | --- |
| C3 varying-trial binomial dispatch gap | Isolated explicit rejection fence before mode/optimizer; support remains standalone |
| C5 malformed uniqueness/rank/loading metadata | Isolated validation guards; red/green descriptor evidence |
| C1 and basic C4 input guards | Separate prepared patch; not stacked here |
| C2 endpoint guards | Separate nongaussian patch; general separation remains carried |
| General separation and outer failure handling | Carried; no closure claimed |

## 8. Consistency Audit

Inclusive changed source spans in the isolated file: descriptor documentation 77–80; NamedTuple descriptor 84–128; family fence 175–182; marginal boundary documentation/call 257–265; fitter boundary documentation/call 638–649. Base reviewed component coordinates remain 81–98, 219–429, 597–682; earlier full-file review at the exact base hash is reused.

The descriptor overload is fed by multivariate structured-fit metadata, whose rank validator at multivariate 663–664 already requires 1:T. GLLVM fitting calls the unchanged supplied-loading descriptor at base 662–663, and the Gaussian MME wrapper calls it at base 139. The new record-family helper is called only by the GLLVM marginal and fitter. Scalar/binomial count validators, record mapping, and standalone fitting source remain identical to the frozen tree.

Merge dependency: C1/basic C4 and this patch both edit genetic_gllvm.jl near the numerical error types and both function entries. Parent should retain both helpers and both entry calls when resolving overlap. This patch has no dependency on C1 to pass its own checks and does not replace its finite-data/tolerance/initial-value guards. The nongaussian endpoint patch is a separate file and is not included here. Run the focused regression files against the parent's combined source after integration.

## 9. What Did Not Go Smoothly

The first red run stopped after its first failing testset; grouping the tests under an outer testset produced complete red evidence without running numerical modes. One edit script caught a mismatched fitter default (maxiter=200) before writing source; the subsequent unchanged-source run was discarded. The context graph correctly warns that ambiguous descriptor overloads have incomplete caller edges, so an exhaustive literal query supplied the missing references.

## 10. Known Residuals

This slice does NOT cover general design separation, outer parameter-failure handling, arbitrary synthetic decomposition certification, broad family support, missing/unbalanced records, recovery, inference, calibration, or capability promotion. It does not add varying-trial GLLVM dispatch. No optimizer run, statistical fit, known-truth campaign, package-wide test suite, GPU work, or R bridge execution was needed.

## 11. Team Learning

A shared early support fence can reject unsupported family objects uniformly in scalar and per-trait-vector entry points. Descriptor validation can check metadata while keeping outputs defined by the rotation-invariant covariance. Test-only sentinels verify the supported entry path without invoking numerical fitting.

Memory receipt: no durable memory edits; technical evidence is the frozen source, reused exact review, and scratch logs. Preflight was completed; the owned lane is this scratch directory, while the parent retains the source freeze and primary-run ownership.

## 12. Cross-Product Coverage

Golden Set: varying-trial binomial scalar/trait vectors, mixed Gaussian/varying-trial vector, retained common-trial binomial and Poisson paths, T=3,K=2 Poisson guard control, malformed synthetic uniqueness/rank/loading metadata, rotated loading metadata, optional absent loadings, FA zero uniqueness, pure low-rank uniqueness and wider supplied-loading K>T controls.

Parent next action: review patch/receipt, integrate after freeze, reconcile both genetic_gllvm entry guards with C1/basic C4, wire the new regression test into the chosen test entry point, and run the combined focused checks. No public status row is promoted by this receipt.
