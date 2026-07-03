# Check-log — v0.8-V8.6 R connection (2026-07-03)

**Slice:** connect the matrix-free scale path to the R `target="multi_effect"` surface via
`fit_payload_v2(...; scale_method=:auto)` + R `engine_control scale_method="auto"`. Paired PRs:
engine #251 (`feat/2026-07-03-v86-r-matfree-connect`) / hsquared #122
(`feat/2026-07-03-v86-scale-method-connect`).

## Evidence

- **Engine `Pkg.test()` GREEN** — full suite passed; `validation_status()` count **54** UNCHANGED
  (covered 13, covered_external 3, partial 37, planned 1; `public_covered_count` 5). New engine
  test "(c) three independent blocks": `scale_method=:auto` routes + returns `loglik`+`boundary` +
  `result_payload_v2` marshals 3 blocks + `:bogus` throws.
- **Frozen contract byte-identical** — the P0.5 payload-v2 parity testsets report `max_abs = 0.0`,
  `max_rel = 0.0`, `sigma_a2_identical = true`; the "(c)" testset parity-checks the default
  (`:dense`) fit against a direct `fit_multi_effect_reml` at `atol = 1e-10`. Default resolves to
  `:dense` when `scale_method` absent (R `hs_engine_control_value(..., "scale_method", "dense")`).
- **`docs/make.jl` GREEN.**
- **R `devtools::test(filter="formula-animal")` GREEN** — the new `scale_method="auto"` live-bridge
  test passes; the pre-existing `random_effects`→`ranef` latent bug (masked by `skip_if_not` in CI)
  fixed.
- **Live R↔Julia bridge** (200-animal K=3 fixture): dense vs auto agree to **max abs VC diff
  2.7e-5** at validation scale (`:auto` picks the sparse-exact AI-REML, which reduces to the
  covered dense result).
- **Real `rose-systems-auditor` (Opus)** over both lanes → **PROMOTE-WITH-CHANGES**: contract
  byte-identity + pins + no-overclaim independently reproduced; 2 required doc-hygiene fixes (this
  check-log entry + the doc-25 V8.6 status) applied.

## Honesty

No covered flip either lane; the large-scale matrix-free path is opt-in EXPERIMENTAL on both
lanes. The R covered claim (validation-scale, exact) is unchanged.
