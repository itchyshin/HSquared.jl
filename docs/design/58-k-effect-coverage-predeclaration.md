# 58 — K-effect / summed-ratio interval coverage predeclaration (#366)

Status: **FROZEN 2026-09-24** (G0 Ada defaults; owner go-ahead).  
Issue: https://github.com/itchyshin/HSquared.jl/issues/366  
Lane: `cursor/coverage-366-20260924` @ `~/local-scratch/lanes/HSquared.jl-coverage-366`  
Ultra-plan: `~/local-scratch/hsquared-366-coverage-calibration-plan.md`

This document freezes estimands, DGP, seeds, success criteria, and claim fences
**before** any official replicate. It does **not** authorize a capability flip.

## Fences (non-negotiable)

- Packages stay experimental **0.9.0**.
- `public_covered_count` **stays 7**.
- This study **banks evidence** and may name a claim class. It does **not** flip
  `partial` → `covered`. Any flip is a **separate owner ticket** after
  Standard-Tier gate + Darwin/Boole/Rose.
- ASReml agreement is **not** a covered leg.
- Claim vocabulary: bank-only + Layer-B **directional-conservative** ceiling.
  Do **not** claim nominal ~95% calibration unless a later owner-authorized
  band analysis says so.

## Routes in scope

**Sparse K-effect only** (`fit_multi_effect(...; method = :auto)` plus
`multi_effect_variance_component_standard_errors`,
`multi_effect_ratio_standard_errors`,
`multi_effect_sum_ratio_interval` / `multi_effect_uncertainty`).

No dense `fit_repeatability_reml` / dense `repeatability_interval` arm in the
smoke or main table (dense remains a correctness anchor from #352, not a
coverage arm).

## Estimands (per replicate, vs simulation truth)

| Label | Estimand | Interval |
| --- | --- | --- |
| VC-a | `σ²a` | Wald: `hat ± z_{1-α/2} · SE` from `multi_effect_variance_component_standard_errors` |
| VC-pe | `σ²pe` | same |
| VC-e | `σ²e` | same |
| h2 | `σ²a / (σ²a+σ²pe+σ²e)` | logit delta via `multi_effect_sum_ratio_interval(...; which = 1:1)` |
| t | `(σ²a+σ²pe)/(σ²a+σ²pe+σ²e)` | logit delta via `multi_effect_sum_ratio_interval(...; which = 1:2)` |

Also record per replicate: fit converged?, SE/covariance refused?, interval
`boundary`?, covered? (NA when refused).

Level: **0.95** throughout.

## DGP

Univariate Gaussian **repeatability**: animal + permanent environment + residual;
≥2 records per recorded individual.

- Pedigree: half-sib (`_halfsib_pedigree` as in phase-3 harnesses).
- Recorded animals: offspring only; PE shared across records of the same individual.
- Family: gaussian; REML; sparse multi-effect AI-REML via `fit_multi_effect(:auto)`.
- Design (smoke and provisional main rung):
  - `nsire=15`, `ndam=30`, `noffspring=200`, `records=2`
  - → 245 pedigree rows, 400 observations (Totoro-class).

### Truth cells

| Cell | `(Va, Vpe, Ve)` | h2 | t | Role |
| --- | --- | --- | --- | --- |
| interior | `(0.3, 0.2, 0.5)` | 0.3 | 0.5 | smoke + main |
| low_pe | `(0.3, 0.05, 0.65)` | 0.3 | 0.35 | main only |
| near_pe | `(0.3, 0.01, 0.69)` | 0.3 | 0.31 | main only; expect refusals |
| near_va | `(0.01, 0.3, 0.69)` | 0.01 | 0.31 | main only; expect refusals |

Smoke runs **interior only**.

## n / seeds / MCSE

| Tier | N per cell | Host | Notes |
| --- | --- | --- | --- |
| Smoke | **50** | **Totoro** (≤16 cores; `OPENBLAS_NUM_THREADS=1`) | unlocks harness; not claim-grade |
| Main (triage) | 500 | ask **"Totoro or DRAC?"** after smoke | only if owner chooses triage |
| Main (Layer-B-class) | 2000 | ask again; usually **DRAC** array | only after owner yes |

Seeds are frozen in
`docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-seeds.txt`
**before** the first official replicate. Base seed `20260924000`; smoke uses the
first 50 integers `20260924001`…`20260924050`. Main cells reuse contiguous
blocks from the same file (no redraw).

Report empirical coverage `p̂` and MCSE `sqrt(p̂(1−p̂)/N_eval)` where `N_eval`
counts replicates with a formed interval (refusals reported separately).

## Success criteria (what the study reports — not auto-flip)

| Outcome class | Meaning |
| --- | --- |
| **Banks evidence** | Table + MCSE + refusal rates + claim-class sentence in recovery-checkpoint + check-log |
| **Directional-conservative** | Systematically over-covers (H0 Layer B vocabulary) — **expected ceiling** for this arc |
| **Nominal-ish** | Coverage in ~[0.92, 0.98] for interior cells — stretch only, not a gate |
| **Fails / caveat** | Under-covers or high refusal near boundary → document; do not remove SEs |

## R twin pointer

R `repeatability_interval` / sparse `target=repeatability` stays **partial** and
docs remain "asymptotic, NOT coverage-calibrated" until evidence is banked and
Rose clears claim-class wording. Optional S3 recorder is deferred (dirty Dropbox
R tree; no twin edit from this Julia lane).

## Harness

- Script: `sim/phase3_k_effect_coverage.jl`
- Outputs: replicate TSV + summary under
  `docs/dev-log/recovery-checkpoints/` (smoke) and later campaign dirs.

## Compute rule

Before any heavy (N≥500 or multi-cell) launch, ask aloud: **"Totoro or DRAC?"**
Smoke = Totoro by G0 freeze; heavy = owner answer after smoke report.
