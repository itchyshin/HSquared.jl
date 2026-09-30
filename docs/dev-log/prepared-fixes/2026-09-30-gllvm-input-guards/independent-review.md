# Independent isolated GLLVM input-guard review

Date: 2026-09-30. Reviewer: Curie. The reviewed files are in /private/tmp/hsq-gllvm-input-fix-20260930. No live candidate source, primary driver, repository state, or biological campaign was changed.

## Verdict

PASS for C1 and the enumerated basic C4 guards in this isolated patch. C4 remains partial. C2, C3, C5, broader family support, inference, recovery, and integration remain HOLD or carried. This verdict does not certify the full GLLVM engine or authorize capability promotion.

## Guard placement and preservation

Patched src/genetic_gllvm.jl:158-176 rejects nonfinite or nonpositive tolerance, negative maxiter, nonfinite Y/X, wrong family-vector length or members, and nonfinite/nonpositive Gaussian residual variance. Both entry points call it before mode work or outer optimization (lines 241-246 and 622-630). Initial loadings are checked for finiteness at lines 634-644; FA uniqueness has length, finiteness, and positivity guards at lines 669-677, before optimize.

The patch preserves the integer signatures and maxiter=0 diagnostic behavior. Only genetic_gllvm.jl differs between frozen and scratch source trees. Its changes add ingress guards and retain the existing objective, scoring, initialization values, optimizer, and result construction. Shared GaussianResponse construction is unchanged. Numerical Y/X conversion returns new Float64 matrices with the same values for the tested inputs.

test/gllvm_input_guard_regression.jl:10-24 exercises both entry points for five bad tolerances and negative maxiter, plus the valid zero-cap diagnostic. Lines 27-51 exercise invalid numeric inputs, Gaussian variance, family-vector membership/length, initial loadings, and uniqueness. Running the negative cases with zero caps catches a missing ingress guard without needing long optimization. Lines 54-61 pin scalar/per-trait Gaussian equality. Lines 64-120 preserve the existing one-step Gaussian reduction and multi-column fixed-effect coordinate-shift checks against the multivariate REML evaluator. These checks would detect a change in objective normalization or fixed-effect handling.

## Independent execution and exact pins

Estimated before execution: under one minute. I independently ran the standalone test with OPENBLAS_NUM_THREADS=1, JULIA_NUM_THREADS=1, and the specified scratch/shared depot. Result: 50/50 PASS, exit 0, test execution 0.7 seconds. Log: /private/tmp/hsq-gllvm-input-fix-independent-green-20260930.log. The supplied red-all.log records 25 passes, 25 failures, and zero errors before the guards, so the negatives distinguish the old behavior.

Every artifact in sha256-inventory.json independently matched. Source comparison confirmed only genetic_gllvm.jl changed. Before/after patch, test, and patched-source hashes matched these pins:

- Frozen source tree: d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a
- Frozen genetic_gllvm.jl: 0727459d2f163835519ae8cf8481d2439b90ba5065cfc8d74ad2c0c08736d2ca
- Patched source tree: 570123ce873c76a7e015ff6a3fa26359d4bee9f460f1c0b53a8d86beaff6689a
- Patched genetic_gllvm.jl: 44e871db58417273e04d4e76b00db6d81edb28e6fddef21505e9248af0fd0a15
- Patch: b3dd47ab24c491ec4e727cb3a36b2d5aa89a5dfc1bc3bb35092853029fff9ef1
- Regression test: 59d254178a426bd58a6bf7ea58d416bc517acc8e9505622bea297007858a7edf

## Remaining gaps and landing checks

C2 proper-integral validity, C3 per-record binomial dispatch, and C5 descriptor metadata are unchanged. Membership in ResponseFamily does not prove that every subtype has executable per-trait dispatch. Empty trait matrices, arbitrary conversion failures, other family parameter guards, missing/unbalanced responses, and full-suite coverage remain outside this closure. The positive tests exercise marginal Gaussian evaluation; they do not establish preservation of every optimized fit or non-Gaussian route.

When the parent lands this patch after the freeze, include the standalone regression in the package runner, record fresh source pins, and run the relevant integrated tests. Keep C4 partial and update only the enumerated C1/C4 findings. No additional simulation is needed to validate these ingress guards.

Graft callers and the finite-matrix/family-constructor query were consulted; cache refresh was unavailable, so current scratch numbered source supplied coordinates. Graft reported 128,384 tokens saved for this review.
