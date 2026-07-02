# After-task — Generality-gap ultraplan: N-effect covered + Phase 0 (S0) + Phase 1 public flip (2026-07-01)

One autonomous session executing the cross-twin **"Closing the mixed-model generality
gap"** ultraplan (`hsquared` × `HSquared.jl`). Three landings, each full-DoD, real-Rose-audited,
merged to `main` on green CI in both lanes.

## What landed

### 1. `V3-NEFFECT-REML` engine `partial → covered` (PR #230, `HSquared.jl`)
Arbitrary-N independent-random-effect REML (`fit_multi_effect_reml`, Phase 2 P2.1) flipped
to **covered** (experimental, validation-scale, opt-in) via the doc-16 substitutable gate:
- **Leg 1 — pre-declared 48-seed bias/MCSE recovery gate PASSED.** Predeclaration committed
  `68cc7acc` BEFORE the run; K=3 non-confounded (animal-A + two pedigree-independent
  environmental factors); 48/48 converged, all four `|bias| ≤ 2·MCSE` (σa² 0.34·MCSE the
  largest). A confounded v1 design was WITHDRAWN pre-run (design correction, not a relaxation).
- **Leg 2 — `sommer` 4.4.5 same-estimand REML comparator AGREE** (max rel.diff 8.09e-5).
- Real `rose-systems-auditor` independently reproduced BOTH legs → PROMOTE. `status_cache`
  covered 10→11, partial 38→37; row count 52 unchanged; `public_covered_count` **unchanged at 1**
  (engine-covered ≠ R-public-covered; no R surface).

### 2. Phase 0 / S0 — payload-v2 multi-block bridge contract FROZEN (PRs #231 / #115)
The single upfront blocker for every R-lane vertical. Contract-only; `public_covered_count`
stayed 1.
- Reconciled the DRAFT schema with the LIVE `bridge-payload.R` contract (Hopper subagent) →
  frozen `docs/design/21-payload-v2-multiblock-schema.md`: an ordered `random_effects` block
  list (pedigree/iid/coefcov/correlated) + fixed-effect block + v0.1 back-compat alias.
- Julia parser (`src/bridge_payload_v2.jl`: `parse_payload_v2`/`fit_payload_v2`/`result_payload_v2`,
  reusing existing estimators — no new numerics) + R emitter (`hs_build_bridge_payload` →
  additive `payload_version=2L`).
- Cross-lane parity: R-emitted payloads round-trip **byte-identically** (3 fixtures,
  max_abs=max_rel=0.0); v0.1 fast-path `===` bit-identical.
- Key honest fences (Hopper + Rose): `maternal_genetic()` stays INDEPENDENT (routes to
  two-effect, NOT the correlated 2×2-G slot); `coefcov` result shape deferred to Phase 3
  P3.0; frozen slots marked not-live. Real Rose audit → PROMOTE-WITH-CHANGES (JSON3 → test-only
  dep; schema self-contradiction fixes; all applied).

### 3. Phase 1 — FIRST public-covered model beyond v0.1: `public_covered_count` 1 → 2 (PRs #232 / #116)
The opt-in **common-environment two-effect animal model** (`engine="julia", target="two_effect"`;
NOT the default `engine="fit"` path) is now public-covered.
- **J1** — new engine `two_effect_ratio_interval`: asymptotic delta-method logit CI for h²
  (ratio1) and c²/m² (ratio2) from a finite-difference observed-information Hessian, mirroring
  `heritability_interval`; boundary-flagged (σ→0 → NaN, no spurious CI); reduces to
  `heritability_interval` at σ2²=0. NOT coverage-calibrated (house caveat verbatim).
- **R surface** — exported `common_env_proportion()`/`maternal_proportion()` + `_interval()`
  accessors; `heritability_interval()` now resolves for a two-effect fit; Falconer fences (c²/m²
  is a variance ratio, not a heritability); comparator vignette (`sommer` agreement + cited
  blupf90/gate) + reproducible live-parity record.
- **Evidence:** live R↔engine parity EXACT (max diff 0 on VC/h²/c²/intervals, common-env +
  maternal legs); `sommer` `vsr(id,Gu=A)+vsr(litter)` cross-check ~2e-5; engine `V3-TWOEFFECT-REML`
  covered (48-seed gate + blupf90+, cited not re-run).
- **Scope (Rose-adjudicated):** ONLY the common-environment / c² leg flips (matches the engine's
  covered scope = animal-A + common-env-I). The **maternal** leg (A2=pedigree) stays experimental
  — same estimator, exact parity, but a harder direct-maternal-correlated identifiability problem;
  its own recovery gate + comparator are owed.
- Real Rose pre-public audit → PROMOTE-WITH-CHANGES; all applied, incl. 3 `public_covered_count`
  pin sites Rose's spec missed (I verified all 5: comment, cache-rewrite literal, status.json
  emission, honesty_assert, log line). A follow-up fix (`532d51d`) resolved a non-ASCII WARNING
  (two em-dashes I added to R status strings) caught by R CMD check — merged only after BOTH
  lanes' CI went green (paired-PR discipline).

## Honesty pins (all HOLD)
- `public_covered_count` = **2** on `main` (v0.1 Gaussian default + opt-in common-env two-effect);
  pinned consistently at all 5 sites in `status_cache.json` + `gen_status_json.jl`.
- Engine `validation_status()` row count **52 UNCHANGED**; engine covered-count unchanged by the
  Phase 1 flip (V3-TWOEFFECT-REML was already engine-covered — Phase 1 is a public-surface flip).
- v0.1 default path untouched. All intervals asymptotic/delta-method, NOT coverage-calibrated.
- Every covered/public claim carries its scope fence; no calibrated-coverage claim anywhere.

## Method
Ran under the `ultra-plan` house method: decompose → parallel self-contained sub-agents →
verify (real Rose audits + CI) → consolidate. ~15 sub-agents across the session (spec-freeze,
parser, emitter, parity, 3 Rose audits, scoping, J1, R surface, live parity). Model-tier
economics honored (Opus for Rose/gates/contract design + novel numerics; Sonnet for
spec-bounded impl/parity/docs).

## Next (parallel streams now unblocked by S0)
- **Phase 4** — direct-maternal 2×2 G toward covered (engine `fit_direct_maternal_reml` exists,
  `partial`): pre-declared gate on a confounding-breaking design + BLUPF90 AIREMLF90 2×2-G
  comparator (verify it parameterizes direct-maternal correctly; WOMBAT not installed) + R
  surface. Highest-difficulty (Fable-tier gate design).
- **Phase 3** — random regression k=2 toward covered (`fit_random_regression_reml`, `partial`),
  after the P3.0 convention lock (raw/correlated `(x|g)` vs Legendre `rr()`); sommer `leg()`
  comparator.
- **Phase 5** — sparse AI-REML N-component (scale) after Phase 2; measure-first, no perf claim
  without a pre-declared benchmark.
- Owed on Phase 1: a COVERAGE-CALIBRATED two-effect ratio interval (the asymptotic one exists);
  the maternal-A2 recovery gate + comparator (to eventually cover the maternal leg).

START HERE for the next session: this report + `docs/design/21-payload-v2-multiblock-schema.md`
(frozen bridge contract) + the ultraplan (`~/.claude/plans/declarative-dancing-hinton.md`).
