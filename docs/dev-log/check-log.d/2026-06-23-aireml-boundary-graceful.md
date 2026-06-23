# Check log — fit_ai_reml graceful σ²→0 boundary (flaky CI fix)

**2026-06-23 · follow-up to F3 (spawned task `task_acb7fb81`).**

## Symptom

`@testset "Phase 2 single-step fitting (public Hinv + fit)"` (`test/runtests.jl`)
intermittently FAILED CI on Julia 1.10: "Error During Test / Got exception outside of a
@test — `fit_ai_reml could not keep variance components positive; try a different start`".
Passed on #179/#180, errored on #181 with byte-identical code → FP/environment-sensitive.

## Root cause (systematic debugging, Phase 1)

The single-step fixture (`y=[10,12,11,9,13]`, 5 animals, 5 random + 1 fixed) has **no
genetic signal** → its REML optimum is at the **σ²a→0 boundary**. As AI-REML drives σ²a
toward 0, the FINITE Newton step grows large relative to the tiny σ²a; even 60 step-halvings
cannot bring `a_new = sigma_a2 + step/2⁶⁰` back positive (`step/2⁶⁰` still exceeds the tiny
σ²a), so the throw fires. NOT a NaN step (first hypothesis, disproved by re-running) and NOT
caused by F1/F3. **Reproduced deterministically:** `fit_ai_reml` on a constant-`y` spec
(no signal) throws on the Mac too; the same single-step fixture throws at 5000 iterations.
On a Mac with the default 100-iter cap it grinds to σ²a≈1e-13 (`converged=false`); Linux CI
reaches the boundary sooner and throws — hence the flake.

## Fix (root cause, not symptom)

`src/likelihood.jl` (`fit_ai_reml`): replace the boundary **throw** with a graceful
**break** — when 60 halvings cannot keep σ positive, STOP at the current finite, positive σ
with `converged=false` (the V1-REML #6 boundary contract: "finite positive ... never NaN").
Plus an `all(isfinite, step) || break` guard (defense-in-depth for a truly NaN/Inf step from
a degenerate AI matrix). A finite step can never wrongly trigger the old throw, and no test
asserted that throw (the only `@test_throws` on `fit_ai_reml` are `ArgumentError` on invalid
input), so this is safe.

## Evidence

- **Deterministic reproduction → graceful:** the constant-`y` / `n3-const` / `antisignal` /
  single-step-at-5000-iters specs all threw pre-fix and now return finite positive σ with
  `converged=false`; a non-degenerate spec still converges in 3 iters (unchanged).
- **New regression testset** `"fit_ai_reml graceful σ²→0 boundary (no throw on degenerate
  spec)"` (6 assertions) — both fixtures threw deterministically pre-fix.
- **Full `Pkg.test()` green** (`JULIA_EXIT=0`, "Testing HSquared tests passed"): the flaky
  single-step testset is now 11/11 deterministic; #6 boundary hardening 7/7 + 14/14 (the
  graceful break is contract-compliant); the new testset 6/6.
- Capability-status (AI-REML row) + validation-debt (V1-REML #6) boundary clauses updated.

## Boundary / honesty

- Behavior change is on the existing experimental AI-REML path: the σ²→0 boundary now ALWAYS
  returns a finite positive optimum with `converged=false` (never throws). Nothing promoted
  to `covered`. Not a recovery/accuracy claim — the degenerate optimum is genuinely at the
  boundary (the data has no genetic signal).
