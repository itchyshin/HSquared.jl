# Genomic endpoint roundoff repair: independent review

## 1. Verdict

Bounded PASS for the frozen precision-fallback delta. Independent baseline reproduction fails with the targeted refusal reason; proposed source passes 166 assertions. Hosted platform replay remains required to close the observed CI regression.

## 2. Scope and independence

Reviewer is independent of this proposal's author and acknowledges prior likelihood ingress/identity authorship. Read only the declared source delta and its neighboring contract, verified artifact pins and original tests, and ran isolated tiny checks. Root owns live integration, registration, and CI.

## 3. Exact pins

Baseline likelihood: d77e6565e574ce428371fb86f8322d12edc977ead5f05093d24c4204ef85e935.

Proposed source: 9e4b7b422f0ba6daac41b39aadf2172b56fc1879b91563ca40d2df9e374d9f11.

Patch: bf5046c5617225ccc0f24009c7f0044b6f9fcd2ccfcb86001dd0d7d5b50c1bee.

Packaged regression: 7c2623319bbef4fa8520588283790ba30e6ff3f0456fa318776271eb9f9cdc09.

Author receipt: 69d009aa0819db9958423c58f89520167dd439207506bcb495b151c7169d2eed.

All were independently measured. Owned replay: `/private/tmp/hsq-endpoint-independent-replay-20261001`.

## 4. Estimand and arithmetic audit

The context overload evaluates the same profiled Gaussian REML formula, with the same rounded eigenvalues, y, fixed design, degrees of freedom, and determinant terms. The ratio retains BigFloat only for a BigFloat eigen context. The 32-epsilon threshold selects recomputation and does not relax the sign rule. Any positive recomputed difference still refuses the endpoint. The existing four-argument strict helper remains unchanged.

## 5. Scientific and compatibility preservation

KKT signs, grid/refinement acceptance, ordinary tie rules, numerical epsilon, typed failure handling, component representability, and result constructors remain unchanged. Original source inventory differs only in likelihood.jl. The original 71-assertion doc46 block is an exact contiguous match to current runtests; the original 28-assertion near-endpoint file is byte-identical. Exact original specification identity is independently checked.

## 6. Red-before evidence

An owned baseline package at the exact d77 pin evaluates the equivalent lower fixture scaled by 0.2. It returns boundary_unresolved with reason endpoint_adjacent_candidate_beats_endpoint; the desired original endpoint assertion fails with Julia exit one. This independently confirms the source mechanism. The author's 20 real old-source failures are distinct from the 19 expected missing-overload errors in the frozen new test. The original hosted log does not expose its refusal reason, so that exact hosted branch remains an inference.

## 7. Green-after evidence

Independent ARM Julia1.10.0 replay: 166/166 in 11.87 seconds, comprising 52 new assertions, 71 unchanged original boundary assertions, 28 unchanged near-endpoint assertions, and 15 reviewer controls. Runtime estimate was under one minute; Julia/BLAS/OMP were capped at one with a 60-second timeout. The author also reports 151/151 on Intel Julia1.10.12; that second author run was not independently repeated here.

## 8. Independent challenges

A separate dense high-precision determinant/quadratic expression provides signed comparisons for an arbitrary two-column fixed design. Lower and upper comparisons retain signs after an invertible fixed-basis change, response scaling, and observation permutation. Nonfinite response, nonfinite eigenvalue, and rank-deficient context return unresolved comparison. The original boundary specification identity, exact scientific ratio zero, numerical ratio 1e-7, and unchanged caller BigFloat256 precision pass.

## 9. Retained failures and registration

The first reviewer script passed all 151 frozen assertions, then failed parsing the reviewer's additional numeric literal. That script/log/result are retained; correcting only the owned probe yielded 166 passes. No proposed source or original assertion changed. Parent should register the new fixture in a namespace to avoid its global boundary_fixture helper colliding with other tests.

## 10. Remaining limits and next action

This review does NOT cover PCG repair, a full package rerun, hosted acceptance, eigendecomposition accuracy under poor conditioning, interval-arithmetic sign proofs, recovery/calibration, R parity, or public capability changes. Caller precision below 128 bits fails closed; finite precision cannot resolve every arbitrarily small change. Integrate the exact reviewed delta, preserve the original tests, then rerun affected hosted jobs and refresh exact-current evidence.

## 11. Memory receipt and Golden Set

Memory receipt: current source, original assertions, exact author artifacts, and independent calculations establish this verdict. Golden Set: original scientific endpoint and genuine near-endpoint improvement refusals remain intact, including positive gains below the ordinary tie tolerance and Float64 objective resolution.

## 12. Preservation and final disposition

All reviewer writes are confined to scratch; no live source, runner, gate, public surface, or Git state changed. Earlier diagnosis/report is preserved. SHA inventory, red/green logs, timings, and absolute-path slopcheck accompany the review. Bounded numerical-source approval is PASS at the exact proposal pin above.
