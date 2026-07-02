# After-task — Phase 4: direct–maternal 2×2 G_dm covered + R public (2026-07-02)

The generality-gap ultraplan's **Phase 4 headline**: the FIRST correlated random-effect
structure promoted to covered. `fit_direct_maternal_reml` — the 2×2 `G_dm` Willham
direct–maternal estimator — satisfies both doc-16 covered legs. `public_covered_count`
**4 → 5**; engine covered 12 → 13. Both twin CIs green; paired-PR discipline maintained.

HSquared.jl merge commit `e34a1ef8` (PR #238); hsquared merge commit `7e848ee` (PR #120).

## What landed

### Engine (HSquared.jl): `V4-DIRECT-MATERNAL` `partial → covered` (PR #238)

`fit_direct_maternal_reml` (`src/likelihood.jl:1311`) fits the correlated `[a_d; a_m]`
2×2 `G_dm` over a single pedigree `A` plus a homogeneous residual σ²e. The covered flip
(`f8959fb8`) promotes this from `partial` with the following evidence chain:

- Docstrings on `fit_direct_maternal_reml` and `maternal_genetic()` updated from
  EXPERIMENTAL / "no gate yet" to COVERED at validation scale with correct citations.
- Rose stale-status corrections (`d8ea337f`): 3 self-contradictions (stale
  EXPERIMENTAL in docstrings) and sibling field-6/field-7 contradictions fixed.
- `status_cache.json`, `gen_status_json.jl`, `docs/design/capability-status.md`,
  `docs/design/validation-debt-register.md` updated in lockstep (`f8959fb8`).

### Comparator (`sommer` 4.4.5 `covm()`, PR #238 commit `14e3e028`)

`comparator/run_sommer_dm.R` fits the same model via the IGE pattern
`random = ~ covm(vsm(ism(animal),Gu=A), vsm(ism(dam_id),Gu=A))`, `rcov = ~units`.
**Critical construction note:** the k=2 RR comparator used `usm(leg())` because both
basis functions load on the record's OWN id. Here the maternal coefficient loads on the
DAM's id (`Z_m` = record→dam), not the animal's own incidence matrix. Using `usm(leg())`
would fit the wrong model. `covm()` with two different `ism()` arguments handles distinct
incidence matrices over the same `A` — exactly `G_dm`. Column identification was
verified explicitly (not correlation-only) before recording agreement.

Agreement (seed 20264000): σ²_ad 4.2e-3, σ²_am 2.8e-3, σ_dm 1.1e-2, σ²e 2.2e-3
relative difference. The larger residual for σ_dm (~1e-2 vs the RR/N-effect ~1e-5) is
expected for a correlated off-diagonal entry and remains well inside same-estimand
agreement.

### Recovery gate (pre-declared, commit `76f6c67e`, run in PR #238)

Predeclaration committed BEFORE the run; harness `sim/phase4_direct_maternal_recovery_gate.jl`
byte-identical pre/post (`git diff 76f6c67e HEAD -- sim/...` empty → no relaxation).

**DGP:** confound-breaking design — the load-bearing design point for direct–maternal
identifiability. 4 overlapping generations; dams with their own records PLUS ≥8 recorded
offspring; 90 qualifying identifying dams; n=960 records; q=996 pedigree animals. Truth:
σ²_ad=1.0, σ²_am=0.5, σ_dm≈−0.2121 (r_am=−0.3), σ²e=1.0. Plus a negative-control
cell (σ_dm=0 reduction test). Seeds fixed in the predeclaration; cold start.

**Result: 48/48 converged; all four |bias|≤2·MCSE:**

| component | bias/MCSE | interpretation |
| --- | --- | --- |
| σ²_ad | 0.13 | negligible |
| σ²_am | 1.65 | largest (within gate; no detectable bias) |
| σ_dm  | 0.72 | within gate |
| σ²e   | 0.24 | negligible |

Additional diagnostics: EBV accuracy direct 0.667, maternal 0.759; max condition number
157.17 (well-conditioned across all 48 seeds); max |r_am| 0.80225 (no seed rode the ±1
boundary); mean walltime ~62 s/seed. r_am reported (not gated): mean −0.266 vs truth −0.30.

### R twin (hsquared, PR #120)

- `target="direct_maternal"` surface: `maternal_genetic()` stub wired to
  `fit_direct_maternal_reml` via the bridge.
- Labelled-triple `heritability()` returns (direct h², m², Willham total h²_T).
- Corrected phenotypic variance denominator: `σ_P = σ²_ad + σ²_am + σ_dm + σ²e`
  (Willham — the covariance term contributes to total phenotypic variance).
- `total_heritability()` extractor.
- Live R↔engine parity verified.

## Evidence chain

Full evidence document: `docs/dev-log/recovery-checkpoints/2026-07-01-direct-maternal-covered-evidence.md`.

1. Predeclaration `76f6c67e` — DGP + seeds fixed BEFORE the run.
2. Gate PASS — 48/48 converged, all four |bias|≤2·MCSE (see table above).
3. `sommer covm()` comparator AGREE — ≤1.1e-2 relative, absolute variance entries (not
   correlation-only); `covm()` vs `usm(leg())` construction trap documented.
4. Engine G1 reduction — σ_dm=0 collapses to the two-independent-effect model (~1e-9).
5. Engine G2 oracle — full 2×2 G_dm with negative off-diagonal matches marginal-GLS
   oracle for β and both BLUP vectors (~1e-9, observed ~1e-15).

## Rose audit

Real Fable `rose-systems-auditor` → **PROMOTE-WITH-CHANGES**. Required changes (all applied
before merge, commit `d8ea337f`):

1. `src/likelihood.jl`: `fit_direct_maternal_reml` docstring updated from EXPERIMENTAL /
   "no R surface, no external comparator, no pre-declared recovery gate yet" to COVERED
   (validation-scale, opt-in), citing the R surface, `sommer covm()` comparator, and
   48-seed gate.
2. `src/planned_terms.jl`: `maternal_genetic()` docstring notes the capability IS covered
   via `fit_direct_maternal_reml` / `target="direct_maternal"`; the stub is the formula-
   reservation marker only.
3. `docs/dev-log/recovery-checkpoints/2026-07-01-direct-maternal-covered-evidence.md`:
   harness-header note added — the illustrative header comments (NOFF=6, 3-gen example)
   are superseded by the locked constants at L88–94 and the predeclaration doc; the
   harness itself remains byte-identical to `76f6c67e`.

## Honesty pins (all HOLD)

- `public_covered_count` = **5** (v0.1 Gaussian + Phase 1 common-env two-effect + Phase
  2-R arbitrary `(1|g)` + Phase 3 RR k=2 + Phase 4 direct–maternal 2×2 G_dm), pinned
  consistently at all 5 sites (`status_cache.json` + `gen_status_json.jl`).
- Engine `validation_status()` row count **52 UNCHANGED** (covered 12→**13**, partial
  36→35).
- `V4-DIRECT-MATERNAL` covered claim is SCOPED: validation-scale dense n≤~1000, opt-in
  NOT the public default `engine="fit"` path; direct h² ≠ total h² (Willham); negative
  r_am real/expected; |r_am|→1 covered only on well-conditioned identified designs
  (max cond 157, max |r_am| 0.80 in the gate); single A (not maternal-A2 generalization).
- v0.1 default path and all other existing covered rows untouched.

## R-CMD-check non-ASCII lesson (SECOND occurrence — DoD recommendation)

Non-ASCII em-dashes in 4 R string literals caused an R-CMD-check WARNING that was
**invisible to `devtools::test` locally**. The fix was ASCII-izing those 4 strings
before merge. This is the SECOND occurrence (Phase 1 was the first; each time caught
by CI, not pre-push local checks).

**Recommendation for R-lane DoD:** add "run `R CMD check` locally for R branches
(not just `devtools::test`)" as an explicit DoD step. `devtools::test` does NOT catch
non-ASCII in runtime strings; `R CMD check` does. The pattern: an em-dash used in a
human-readable status label triggers the warning even if the string is only printed,
not parsed. The fix is always the same (ASCII hyphen or spelled-out word), so catching
it locally saves a CI round-trip.

## Session arc — generality-gap ultraplan (complete)

`public_covered_count` **1 → 5** across the programme:

| Phase | Capability | public count |
| --- | --- | --- |
| v0.1 (pre-existing) | Univariate Gaussian animal model | 1 |
| Phase 1 | Common-environment two-effect model (`target="two_effect"`) | 2 |
| Phase 2-R | Arbitrary-N independent `(1|g)` (`target="multi_effect"`) | 3 |
| Phase 3 | Random regression k=2 (`target="random_regression"`) | 4 |
| **Phase 4** | **Direct–maternal 2×2 G_dm (`target="direct_maternal"`)** | **5** |

Foundation: Phase 0 (S0) payload-v2 bridge contract (PRs #231/#115).

## Next

- **Phase 5** — sparse AI-REML N-effect scale. Measure-first (profile the sparse
  factorization before any performance claim); no perf claim without a pre-declared
  benchmark. `V3-NEFFECT-REML` is already engine-covered; Phase 5 is the scale
  demonstration.
- **Standing debt (does NOT block Phase 5):** BLUPF90 AIREMLF90 2×2-G optional 2nd-
  lineage comparator (banked as OPTIONAL in the covered claim; owed but not blocking);
  broader-DGP / larger-than-dense-scale direct–maternal recovery; maternal-A2
  generalization (separate relationship matrix per leg — harder identifiability problem).
- **R-lane DoD:** add `R CMD check` as a required pre-push step (see above).

START HERE next session: this report +
`docs/dev-log/recovery-checkpoints/2026-07-01-direct-maternal-covered-evidence.md`.
