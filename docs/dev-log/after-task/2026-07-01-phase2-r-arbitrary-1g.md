# After-task — Phase 2-R: arbitrary `(1|g)` random effects to the R public surface (2026-07-01)

The generality-gap ultraplan's **headline** slice: a user can now write
`hsquared(y ~ animal(1|id, pedigree=ped) + (1|nest) + (1|year), control=hs_control(engine="julia",
engine_control=list(target="multi_effect")))` and get a validated multi-effect fit —
per-component variances + animal-block h² + intervals. `public_covered_count` **2 → 3**
across both twins. Proven Phase-1 loop; real-Rose-audited; both-lane CI green.

## What landed (4 PRs, atomic pair for the flip)

- **HSquared.jl #234** + **hsquared #117** (the paired public flip). Preceded by the engine
  interval (`beca24e1`), the R core (`cf4aab9`), and the interval+parity+vignette (`21d0a3d`).

### Engine
- **`multi_effect_ratio_interval`** — generalizes `two_effect_ratio_interval` (J1) to K
  components: delta-method logit CI for each `ratio_i = σ_i²/(Σσ²+σe²)` from the FD-Hessian of
  the multi-effect REML loglik; boundary-flagged (σ→0 → NaN, sub-block info); reduces to
  `two_effect_ratio_interval` at K=2 (rtol 1e-6) and `heritability_interval` at K=1. Refactor:
  `_ratio_delta_ci` (dimension-agnostic) + `_reml_fd_information` shared by both. Asymptotic /
  NOT coverage-calibrated. 47 tests.

### R (`hsquared`)
- **Grammar** (`model-spec.R`): accept bare `(1|g)` intercepts (`hs_is_one` guard); **reject**
  `(x|g)` slopes AND `(x||g)` correlated (`hs_is_double_bar_expr`); iid effects held in a LIST
  (fixes the string-keyed collision so multiple `(1|g)` coexist); scope fences (requires
  `animal()`; rejects genomic/single-step/metafounder/RR/multivariate).
- **Emitter** (`bridge-payload.R`): loop → N iid blocks. **Dispatch** (`hsquared.R` +
  `julia-bridge.R`): `multi_effect` target + `hs_fit_julia_n_effect_payload` →
  `parse/fit/result_payload_v2`. **Normalizer** `hs_normalize_n_effect_result` (h² = animal
  block only; Falconer-fenced `variance_ratios`). **Interval passthrough**
  `hs_attach_n_effect_intervals` (`heritability_interval()` resolves for K≥3 = animal ratio;
  per-component `variance_ratio_intervals`; NaN→NA). Extractors inherited unchanged (shape-driven).
- Comparator vignette (`multi-effect-comparator.Rmd`) + reproducible parity record.

## Evidence
- **Live R↔engine parity EXACT (max diff 0)** on a K=3 fixture, TWO independent checks: (1) R
  fit vs direct engine on the marshalled payload; (2) R fit vs an independent native-Julia rebuild
  (verifies the JuliaCall N-block marshalling — sparse-CSC assign + Dict construction).
- Live K≥3 test 96/0/0; `test-common-env` 59/0/0 (no regression).
- `sommer` same-estimand cross-check ~1.5e-2 (AI vs EM, n=40, 3 components — honest, not machine
  precision, not a small-sample accuracy claim).
- Engine `V3-NEFFECT-REML` covered (pre-declared 48-seed gate + `sommer` 8.09e-5), cited not re-run.

## Honesty pins (all HOLD)
- `public_covered_count` = **3** (v0.1 Gaussian default + common-env two-effect + arbitrary-N
  `(1|g)`), pinned consistently at all 5 sites (`status_cache.json` + `gen_status_json.jl`).
- Engine `validation_status()` row count **52 UNCHANGED**; engine covered-count unchanged (this is
  a **public-surface** flip — `V3-NEFFECT-REML` was already engine-covered).
- **Scope:** INDEPENDENT iid + animal-A only, Gaussian, REML, validation-scale. Animal ratio =
  narrow-sense h²; other blocks = variance-explained proportions, NOT heritabilities (Falconer).
  Intervals asymptotic/delta-method, NOT coverage-calibrated. NOT correlated (direct–maternal),
  NOT random-regression, NOT non-Gaussian, NOT random slopes — those stay planned/experimental.
  The `maternal_genetic()` leg (A2=pedigree) stays experimental. v0.1 default path untouched.
- Real `rose-systems-auditor` pre-public audit → PROMOTE-WITH-CHANGES; all applied (5 pin sites;
  stale-string fixes: formula-status "intervals not available"→available, vignette "stays 1"→3rd
  model, extractors/Rd stopped mislabeling the covered rows as partial).

## Process notes
- CI caught two things before merge (paired-PR discipline — merge only when BOTH lanes green): a
  **Julia-1.11/1.12 version-fragile boundary test** (fixed to a contract-based assertion, verified
  on 1.10 AND 1.12) and, on the R side this time, a clean R CMD check (proactive ASCII pre-check
  after Phase 1's non-ASCII stumble). One subagent over-delegated to its own explorers and paused;
  resumed via SendMessage.

## Session arc (generality gap)
`public_covered_count` **1 → 3** in one session: v0.1 Gaussian (pre-existing) → **Phase 1**
common-env two-effect/c² → **Phase 2-R** arbitrary-N `(1|g)`. Foundation: Phase 0 (S0) payload-v2
bridge; Phase 2 engine `V3-NEFFECT-REML` covered.

## Next (remaining ultraplan)
- **Phase 3** — random regression k=2 → covered (after the P3.0 `(x|g)` raw/correlated vs `rr()`
  Legendre convention lock; `sommer leg()` comparator). Random slopes are the next generality rung.
- **Phase 4** — direct–maternal 2×2 G → covered (engine `partial`; Fable-tier gate design +
  BLUPF90 AIREMLF90 2×2-G comparator — verify it parameterizes direct-maternal; WOMBAT not installed).
- **Phase 5** — sparse AI-REML N-component (scale; measure-first, no perf claim without a
  pre-declared benchmark).
- Owed on Phase 2-R: a coverage-CALIBRATED N-component interval (the asymptotic one exists).

START HERE next session: this report + the ultraplan (`~/.claude/plans/declarative-dancing-hinton.md`)
+ `docs/design/21-payload-v2-multiblock-schema.md` (frozen bridge contract).
