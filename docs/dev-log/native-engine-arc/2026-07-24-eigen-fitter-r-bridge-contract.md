# R-bridge contract + coordination handoff — eigen-once single-effect REML (`fit_eigen_reml`)

**2026-07-24 · Julia engine lane (HSquared.jl) → hsquared R lane · CROSS-LANE COORDINATION (not an R edit)**

> This lane (HSquared.jl) implemented the Julia engine fitter. Per `AGENTS.md` the Julia lane does **not**
> edit the `hsquared` R repo — the R wrapper is the R twin session's work. This doc is the contract + brief so
> the R lane can expose the fitter. Durable coordination: mirror this as a comment on the ledger issues
> (Julia #5/#6 ↔ R #2/#5). **Nothing here moves `public_covered_count` (stays 5); the R exposure is opt-in,
> experimental, and does NOT change any covered claim.**

## What landed on the Julia side (this lane)

- **`fit_eigen_reml(spec; max_dense_n = 20_000)`** — exported. Estimates `(σ²a, σ²e)` of the standard **`Z=I`**
  Gaussian animal model by the EMMA/GEMMA canonical transformation: eigendecompose `A = Ainv⁻¹` **once**
  (dense `O(n³)`, variance-independent), rotate `y`/`X`, then a 1-D optimisation over the variance ratio via
  the already-validated `_genomic_profile_reml` evaluator. No repeated MME factorization, no selected inverse.
- **Returns the standard `AnimalModelFit`** (same object as `fit_ai_reml`), with `target = :eigen_reml`,
  `variance_components_source = :estimated_eigen_reml`. All standard extractors work
  (`fixed_effects`, `breeding_values`, `heritability`, PEV, reliability), because they operate on
  `spec + variance_components`, not on stored internals.
- **Correctness-gated in-CI**: recovers `fit_ai_reml`'s `(σ²a, σ²e)` to ~1e-6 (`test/runtests.jl`).
- **Preconditions (throw `ArgumentError`)**: `Z ≠ I` → "use fit_ai_reml"; `n > max_dense_n`; non-PD `Ainv`;
  `method ≠ :REML`.
- **When it wins** (off-CI, `bench_eigen.jl`): fill-in-INDEPENDENT; **6.95× over sparse AI-REML at high-fill-in
  random n=10000** (25.4s vs 176.9s); LOSES on well-structured or large pedigrees (dense `n³`/memory).

## The R-bridge contract (what the R lane needs to do)

1. **Routing.** Add an opt-in method selector that dispatches to `fit_eigen_reml`. Recommended R surface:
   `heritability(..., engine = "julia", method = "eigen")` (or `target = "eigen"`), mirroring how the R twin
   already opts into `target = "sparse_reml"` / `"henderson_mme"`. Default stays the current path — **eigen is
   opt-in.**
2. **Payload.** The Julia return is a standard `AnimalModelFit`, so the **existing `result_payload(fit)`
   normalizer already covers it** — no new payload shape. **ONE mapping to add on both sides:** the method /
   target string for `:eigen_reml` (Julia `target` symbol ↔ R method label, e.g. `"eigen_reml"` / `"eigen"`),
   analogous to the existing `:sparse_reml`/`:ai_reml` ↔ R string map. Verify `result_payload` on an eigen fit
   round-trips (it should; flagged as the one thing to check).
3. **Precondition surfacing.** The Julia side throws a clear `ArgumentError` for `Z ≠ I` and large `n`. The R
   wrapper should either (a) let that error propagate with a readable message, or (b) pre-check and route to
   the sparse path. For the standard `animal ~ (1|id)` one-record-per-animal model, `Z = I` holds.
4. **Docs / fence.** Mark it **experimental** in the R docs; state it is a speed path for moderate-`n`,
   high-fill-in / dense-genomic-`G` single-effect models, `Z=I`-only, and that it returns the identical
   estimates as the default fitter (it is a *faster route to the same answer*, not a different estimand).
   **Do not present it as covered or as the default.**

## What is NOT in scope here (deferred, owner/lane-gated)

- `:auto` dispatch (eigen-vs-sparse by `n`/fill-in heuristic) — Julia-side follow-up (validation-debt
  `V1-EIGEN-REML`).
- Promotion partial → covered: a pre-declared multi-seed recovery gate + an external same-estimand comparator
  (ASReml/blupf90) + a Rose audit. Until then it stays experimental on BOTH lanes.
- Multi-effect (`K≥2`): the eigen trick diagonalizes ONE variance ratio only — it does **not** generalize to
  several random effects. Keep it single-effect.

## Coordination checklist for the R lane

- [ ] add the `method="eigen"` opt-in route → `fit_eigen_reml`
- [ ] add the `:eigen_reml` ↔ R method-string mapping in the payload normalizer; verify round-trip
- [ ] surface the `Z=I` / large-`n` preconditions readably
- [ ] R docs: experimental, opt-in, same-answer-faster-route, not covered, not default
- [ ] R twin: confirm `public_covered_count` unchanged (5)

> Related: `docs/design/capability-status.md` (Eigen-once row) · `docs/design/validation-debt-register.md`
> (`V1-EIGEN-REML`) · `docs/dev-log/native-engine-arc/2026-07-24-ai-reml-convergence-findings.md` (benchmarks).
