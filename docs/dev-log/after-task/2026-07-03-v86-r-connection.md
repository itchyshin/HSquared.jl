# After-task — v0.8-V8.6: connect the matrix-free scale path to the R multi_effect surface (2026-07-03)

**Session:** Claude solo (Opus), autonomous. First CROSS-LANE slice after the R twin reopened —
wires the engine's new matrix-free / `:auto` multi-effect fit under the EXISTING R
`target="multi_effect"` `(1|g)` surface, so large R multi-effect models gain the scale path.
**Repos:** `HSquared.jl` (engine) + `hsquared` (R) — PAIRED PR.

## Headline

The matrix-free scale engine is now reachable from R, contract-preserving. **No covered-count
change on either lane** — this is an internal opt-in optimization (`engine_control
scale_method="auto"`), not a coverage move. Validated end-to-end through the live R↔Julia bridge.

## What landed

1. **Engine (contract-preserving):**
   - `fit_multi_effect_mc_reml(...; compute_loglik=true)` now returns `loglik` (via V8.1
     `matrix_free_reml_loglik`, stochastic) + `boundary` — making the matrix-free result
     shape-compatible with the payload-v2 bridge (`result_payload_v2` needs both).
   - `fit_multi_effect(...)` routes the matrix-free-only kwargs (`compute_loglik`, `slq_probes`,
     `slq_steps`, `shared_probes`) to the matrix-free branch only (the exact branch is unaffected).
   - `fit_payload_v2(payload; scale_method=:dense)` — NEW optional keyword. **Default `:dense` is
     byte-identical** (the payload-v2 parity tests pass → frozen contract preserved). `:auto`
     routes the `:multi_effect` dispatch through `fit_multi_effect(:auto)`: sparse-exact AI-REML
     (reduces exactly to the covered dense optimum) at validation scale, experimental matrix-free
     for large problems. Engine test: `:auto` routes + stays bridge-shape-compatible + `:bogus`
     rejected.

2. **R (`hsquared`):**
   - `hs_fit_julia_n_effect_payload(..., scale_method=c("dense","auto"))` threads the option to
     `HSquared.fit_payload_v2(...; scale_method=:...)`.
   - `hsquared.R` multi_effect dispatch reads `engine_control$scale_method` (default `"dense"`).
   - testthat live-bridge test: dense vs auto agree at validation scale (tolerance accommodates
     the dense-NelderMead convergence slack — `:auto`/sparse-exact is at least as accurate);
     invalid `scale_method` rejected.

3. **ROSE-PRINCIPLE FIX (pre-existing, unrelated):** the existing multi_effect live-bridge test
   called `random_effects(fit)` — a function that does not exist (the extractor is `ranef()`).
   It was masked in CI (the test `skip_if_not` skips without Julia) but fails locally with Julia.
   Fixed `random_effects` → `ranef` at `test-formula-animal.R:384`.

## Validation (live R↔Julia bridge)

On a well-identified fixture (200 animals, K=3) fit through R with both settings:
`max abs VC diff (dense vs auto) = 2.7e-5` — the covered result is preserved. (An 8-record K=3
fixture is under-identified and the two estimators land on different boundary optima — degeneracy,
not a bug; the proper-scale agreement is the real check.)

## Checks

- Engine `Pkg.test()` GREEN (new `scale_method` engine test; payload-v2 parity confirms `:dense`
  byte-identity; count 54 UNCHANGED). `docs/make.jl` GREEN.
- R `devtools::test()` GREEN (formula-animal live-bridge tests pass incl. the new scale_method
  test + the ranef fix).
- Honesty pins: engine rows 54 / covered 13 / `public_covered_count` 5 UNCHANGED; R covered claim
  UNCHANGED (validation-scale, exact path). The large-scale matrix-free path is opt-in experimental
  on BOTH lanes.
- Real `rose-systems-auditor`: <!-- ROSE_V86 -->

## Next (doc-25)

V8.3 (matrix-free intervals — unblocked by V8.1), then V8.4 (external comparator), V8.5 (APY), and
the v0.7 GPU stream (G-B/C/D/E).
