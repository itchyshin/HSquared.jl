# After-task — fit_ai_reml graceful σ²→0 boundary (flaky CI fix) — 2026-06-23

## Task goal

Spawned follow-up (`task_acb7fb81`) to fix a flaky CI failure: the single-step fitting test
(`test/runtests.jl`, "Phase 2 single-step fitting (public Hinv + fit)") intermittently
errored on Julia 1.10 with `fit_ai_reml could not keep variance components positive`. `[JL]`
engine-only; existing experimental AI-REML path; no `covered` promotion.

## Root cause (systematic debugging)

Followed the four-phase discipline. Phase 1 disproved the obvious "NaN step" hypothesis by
re-running after the first fix (cases still threw → the step is FINITE). The real cause: the
single-step fixture `y=[10,12,11,9,13]` (5 animals, over-parameterised, no genetic signal)
has its REML optimum at the **σ²a→0 boundary**. Near σ²a≈0, the finite Newton step is large
relative to the tiny σ²a, so even 60 step-halvings cannot keep `a_new > 0` → the throw fires.
Reproduced DETERMINISTICALLY (constant-`y` and several degenerate specs throw on the Mac too;
the original fixture throws at 5000 iterations). The flake = a Mac grinds to the 100-iter cap
(σ²a≈1e-13, `converged=false`) while Linux CI reaches the boundary in fewer iters and throws.
Confirmed NOT caused by F1 (bit-exact inbreeding) or F3 (its convergence check is after the
step-halving).

## Files changed

- `src/likelihood.jl` (`fit_ai_reml`): replaced the boundary **throw** with a graceful
  **break** (stop at the current finite, positive σ with `converged=false`); added an
  `all(isfinite, step) || break` guard as defense-in-depth for a degenerate (NaN/Inf) step.
- `test/runtests.jl`: new testset `"fit_ai_reml graceful σ²→0 boundary (no throw on
  degenerate spec)"` (6 assertions, two fixtures that threw deterministically pre-fix).
- `docs/design/capability-status.md` (AI-REML row) + `docs/design/validation-debt-register.md`
  (V1-REML #6 boundary clause): updated to "always returns finite positive, `converged=false`,
  never throws at the boundary".

## Checks run and exact outcomes

- Deterministic reproduction → graceful: constant-`y`, `n3-const`, `antisignal`, and the
  single-step fixture at 5000 iters all threw pre-fix and now return finite positive σ with
  `converged=false`; the non-degenerate `n2-signal` still converges in 3 iters (unchanged).
- The actual single-step test path verified directly: `fit_single_step_reml` vs
  `fit_ai_reml` (G=A22 reduction) now both return `converged=false` with σ²a/σ²e/loglik all
  matching (rtol 1e-5/1e-6) — the test passes deterministically.
- **Full `Pkg.test()` green** (thread-capped, julia 1.10.10, `JULIA_EXIT=0`, "Testing
  HSquared tests passed"): single-step testset 11/11; #6 boundary hardening 7/7 + 14/14
  (graceful break is contract-compliant); new graceful-boundary testset 6/6.
- `docs/make.jl`: not re-run (function-body change + dev-log/design-row docs; no public
  API/docstring change). CI Documenter will confirm.
- Real `rose-systems-auditor`: __PENDING__ (next).

## Public claim audit (Rose)

- Behavior change on the experimental AI-REML path only; nothing promoted to `covered`. The
  boundary now ALWAYS returns finite positive σ with `converged=false` (contract-compliant —
  the V1-REML #6 "finite positive OR documented error" becomes "finite positive"). NO
  recovery/accuracy claim: the degenerate optimum is genuinely at the boundary (no signal).

## What did not go smoothly

- First fix (an `isfinite(step)` guard) was based on a WRONG hypothesis (NaN step). Re-running
  the deterministic reproduction showed the cases still threw → the step is finite, and a
  tiny σ + large finite step is the real mechanism. Corrected to the halving-exhausted
  graceful break (kept the isfinite guard as defense-in-depth). The systematic-debugging
  "verify before continuing" loop caught the wrong hypothesis before it shipped.

## Next actions

1. Real `rose-systems-auditor` over the branch; commit; PR; self-merge on green CI.
2. (Optional follow-up, not this slice) proper boundary-aware step-length control in
   `fit_ai_reml` (cap the step so σ stays positive and keep iterating) — B5 convergence
   hardening; the graceful break is sufficient for correctness.
