# Isolated PCG true-residual stopping repair

Date: 2026-09-30. Author: actual GPT-6.1 Sol, High effort. Numerical/source review lenses: Gauss/Noether/Curie. This is an author proposal, not independent approval. Ownership is this scratch packet, copied source and one targeted regression. No live source, runner, gates or protected file was edited; no campaign, GPU or public mutation occurred. Parent owns integration and renewed hosted checks.

## Diagnosis

Public baseline Julia commit `73ace301a7e79e922d911345f5033c72968e2ecd`, iterative source `91317fe23ab913767b3f4ed44f74b69b9d5e0f5a5ce46fa09ed442047f361769`.

Hosted Julia 1.13.1 Linux failed the unchanged matrix-free fit fixture at `test/runtests.jl:3737/3742`. Its trace solve returned true residual `1.0000000513789172e-9` against requested `1e-9`; `_require_pcg_convergence` correctly refused. Log: `/private/tmp/hsq-final-integrated-checks-20260930/julia-candidate-ci-failures.log`, lines 1650 onward. Windows/genomic boundary failures belong to another lane.

The source breaks its iteration loop on the recursively updated residual, then computes `norm(b-C*x)/norm(b)` after leaving the loop. Roundoff can therefore cause an early exit with unused budget and an insufficient true residual. Graft identified `_pcg_solve` and its exact callers: assembled/matrix-free standalone solves, MC block traces, likelihood and information RHS solves. Downstream convergence refusal is correct and remains unchanged.

A bounded tiny SPD diagnostic reproduced the mechanism on local Julia 1.13.1. The fixed 12-by-12 matrix has condition number about `1e8`. Original PCG stopped at iteration 41 of 240 with true residual `1.4491059939112126e-9` against `1e-9`. The regression checks the independently recomputed true residual, requested tolerance, budget, valid SPD/dense-solve controls and genuine failure behavior. Red: **28 PASS, 2 FAIL, 1 ERROR**. A cold-load diagnostic and kernel checks were estimated under 30 seconds; the kernel's reported test time was 5.3 seconds. Logs and literal fixture are retained.

## Narrow change

When the recursive residual first reaches tolerance, verify `b-C*x` before breaking. If the true residual does not satisfy tolerance, replace the residual with `b-C*x`, apply the existing preconditioner, and restart PCG from that direction using the remaining iterations in the same `1:maxiter` loop. True-residual and preconditioned-residual finite checks preserve arithmetic refusals. Return the existing final true-residual calculation and tuple unchanged.

No tolerance, fit convergence label, iteration budget, default, estimator, RNG/probe, operator, preconditioner or downstream `_require_pcg_convergence` rule is changed. Non-SPD and nonfinite products still throw. A finite unsolved system exhausts its budget and remains unconverged/refused by fit consumers. The helper comment documents the stopping/restart behavior. The only changed function is `_pcg_solve`.

## Green and neighbor evidence

All launches use one Julia/BLAS thread. Green kernel budget: 60 seconds; unchanged fit plus existing neighbors: 120 seconds, enforced by the owned process-group wrapper.

- Julia 1.13.1 new regression: **31/31 PASS**, reported test time 3.8 seconds.
- Julia 1.10.0 new regression: **31/31 PASS**, owned wall time 7.39 seconds, test time 2.7 seconds.
- Julia 1.13.1 unchanged CI fit: **9/9 PASS**. This uses the exact original testset, copied without changed assertions; it includes the original 300/40/500-probe fits and recovery comparisons. The testset took 25.8 seconds.
- Existing iterative finite contracts: **105/105 PASS**.
- Existing Wave 1 numerical contracts: **167/167 PASS**, plus unchanged neighboring matrix controls **16+8+5+4+4 PASS**.
- Total integration controls: **318/318 PASS**, owned elapsed 48.31 seconds, exit 0, under estimate. With the new kernel regression this is **349 passing assertions** on Julia 1.13.1, plus the 31-assertion Julia 1.10.0 replay.

The fixed SPD witness now stops at iteration 53 with true residual `8.306968845015103e-10`, satisfying the original `1e-9` within the original 240-iteration budget. The one-iteration starvation, downstream refusal, zero RHS, non-SPD/nonfinite operator and ordinary diagonal/sparse preconditioned controls all pass. No full package suite was run here. Local ARM 1.13.1 evidence does not claim the hosted Linux x86 job has passed; renewed hosted CI is required after integration.

## Exact proposal

- Prepared source: `e1b50131c5e38b59a200925e0ff2f2377fecc7c5e4f0c63a90fe33261dbf2133`.
- Patch: `7485c2bca5b4ea6036af1d4081d1854321bf44bf687c452e82cba45aff44413e`.
- New regression: `7d2ba4868e9202c04217cd0f53e3245ecf25201107d7cc48364cc4f67f6e280a`.

`iterative-pcg.patch` contains only the helper/comment change and new `test/pcg_true_residual_regression.jl`. `pins.json` records the baseline, prepared source, patch, regression, unchanged testset/neighbor drivers, environment and retained logs. `git apply --check` passes against the live unchanged iterative baseline. Patch replay into the owned `replay/` produces these exact source/test pins. Parent must register the new test in its real test namespace and obtain independent review before live integration.

## Limits and next step

Residual replacement is bounded by existing iterations; ill-conditioned systems may still fail to achieve a requested tolerance. True-residual verification adds an operator application at tentative convergence, in addition to the existing final diagnostic application. No performance or large-scale accuracy claim is made. This repair cannot close hosted acceptance until an independent reviewer approves its delta, affected source-bound local checks are renewed, and actual current-head CI passes. Existing programme scope, immutable campaigns and scientific carries remain unchanged.

Memory receipt: existing lane ownership and frozen-campaign boundaries only; current source, logs and deterministic regression establish this finding. Golden Set: valid ordinary SPD, zero RHS, preconditioned sparse/dense answers and honest budget/refusal controls were retained. No em dash is used in this report. Graft was used before source changes; its reported savings include 224,915 tokens for the exhaustive PCG query and 18,529 for exact callers, plus the earlier context query.
