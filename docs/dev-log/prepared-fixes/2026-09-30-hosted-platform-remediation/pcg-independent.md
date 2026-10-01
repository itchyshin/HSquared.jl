# PCG true-residual stopping repair: independent review

## 1. Verdict

Bounded PASS for the frozen PCG stopping/restart delta. Original matrix-free CI assertions pass independently on ARM Julia1.13.1; Intel Julia1.10.12 passes the targeted kernel and independent controls. The separate Intel original-fit replay timed out and remains explicitly incomplete. Hosted current-head acceptance remains required.

## 2. Scope and independence

Reviewer did not author this proposal and previously reviewed adjacent iterative finite guards. Graft callers/source context preceded source inspection. Only the minimal _pcg_solve delta, its return/refusal contracts, fixed witness, original CI fixture, and public finite guards were exercised. Root owns live integration, registration, and CI.

## 3. Exact pins

Baseline iterative source: 91317fe23ab913767b3f4ed44f74b69b9d5e0f5a5ce46fa09ed442047f361769.

Proposed source: e1b50131c5e38b59a200925e0ff2f2377fecc7c5e4f0c63a90fe33261dbf2133.

Patch: 7485c2bca5b4ea6036af1d4081d1854321bf44bf687c452e82cba45aff44413e.

Frozen new regression: 7d2ba4868e9202c04217cd0f53e3245ecf25201107d7cc48364cc4f67f6e280a.

All supplied pins were independently measured. Owned replay: `/private/tmp/hsq-pcg-independent-review-20261001`.

## 4. Numerical delta audit

The recurrence residual remains an inexpensive candidate stopping signal. Before stopping, the solver evaluates b-Cx and applies the unchanged requested tolerance to its norm ratio. A failed tentative stop replaces r with that true residual, recomputes its preconditioned direction/inner product, and continues the same bounded for loop. Current x is retained. Iterations never reset or exceed maxiter. The final reported true-residual calculation and downstream convergence rejection remain unchanged.

## 5. Exact scope preservation

Reversing only the declared comment and stopping block restores the entire baseline file byte for byte. All functions following _pcg_solve are unchanged. The copied original CI assertion block is an exact contiguous match to runtests after removing its import/BLAS wrapper. No requested tolerance, RNG/probe, estimator, numerical target, default budget, preconditioner, scientific convergence label, or other numerical body changed. No new matrix assembly or factorization is introduced.

## 6. Independent red and green mechanism

On ARM Julia1.13.1, the exact old helper stops at iteration 41/240 with independently recomputed residual 1.4491059939112126e-9 against 1e-9. The proposal continues to iteration 53 with residual 8.306968845015103e-10. Budgets 41,42,52 exhaust honestly above tolerance; budget 53 and 240 return the successful iteration 53. Relative residual need not decrease monotonically, and no best-iterate guarantee is claimed.

On ARM Julia1.10.0 the old witness already reaches tolerance at iteration 40. This difference is retained; baseline failure is runtime-dependent. The patched witness also succeeds on Intel Julia1.10.12/OpenBLAS0.3.23.

## 7. Independent replay totals

Each run was estimated under two minutes, capped at 120 seconds, with Julia/BLAS/OMP one thread.

| Runtime | Independent checks | Elapsed |
| --- | --- | --- |
| Intel Julia1.10.12 | 31 frozen kernel +24 reviewer controls =55 PASS | 61.35 s cold load |
| ARM Julia1.10.0 | 31+24+15 budget checks +105 original public finite guards =175 PASS | 17.80 s |
| ARM Julia1.13.1 | 31+24+15 budget checks +9 unchanged original CI assertions =79 PASS | 39.09 s |

These are 309 passing assertion executions across three runtimes, with repeated controls explicitly counted per runtime. The original matrix-free CI testset alone took 25.1 seconds on ARM1.13.1.

## 8. Refusal and tiny controls

Independent probes verify exact one-step solves for ordinary, 1e-100, and 1e-160 right-hand sides; zero iteration diagnostic metadata; honest one-step starvation and downstream refusal; underflow outside supported dot-product range; nonfinite RHS/preconditioner; negative preconditioner; and exact reported residual at returned x. Original zero RHS, sparse/dense preconditioned reductions, non-SPD/nonfinite operator, and public malformed-input controls remain green. Genuine exhausted budgets never receive a successful label.

## 9. Retained incomplete attempts

Intel original nine-assertion fit replay was terminated at the 120-second cap without a test summary. Its empty log and timeout result remain retained; it is not classified as a numerical assertion failure or a passing gate. The first latest-runtime launch used a nonexistent bin path before Julia started; the installed app-bundle path was then used. Both the prelaunch failure and correction are recorded. No assertion or proposed source was changed.

## 10. Remaining limits and next action

This review does NOT cover broad PCG performance, guarantees for arbitrary conditioning or tolerances, MC calibration, a full package rerun, hosted CI, the endpoint precision delta, or public capability promotion. Residual replacement adds an operator evaluation at tentative convergence and may still exhaust the budget or refuse unsupported arithmetic. Integrate the exact reviewed source/test, preserve original assertions, then renew affected hosted jobs and exact-current evidence. The unfinished Intel fit check remains unfinished.

## 11. Memory receipt and Golden Set

Memory receipt: current source, exact supplied artifacts, deterministic operator checks, and original assertions establish the verdict. Golden Set: original scientific tolerance, strict true-residual refusal, zero/tiny valid controls, finite/range guards, and original nine-assertion matrix-free fixture remain unchanged.

## 12. Preservation and final disposition

All reviewer writes are confined to owned scratch. No live source, runner, gate, campaign, public surface, or Git state changed. Timing/result logs, exact delta reversal proof, pin verification, SHA inventory, and absolute-path slopcheck accompany this report. Bounded source-contract approval is PASS at the exact proposal pin; hosted/full-programme acceptance remains separate.
