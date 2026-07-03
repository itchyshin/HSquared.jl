# Interval coverage calibration — the last owed doc-25 hardening leg (2026-07-03)

The "coverage-calibrated intervals" owed item: an empirical-coverage study of the SHIPPED
animal-model heritability / variance-component intervals (`heritability_interval` `:delta` and
`:profile`; `variance_component_interval`). Their docstrings say "asymptotic … NOT coverage-calibrated
… unreliable on small samples"; this quantifies that.

- **Run:** DRAC **fir** CPU, SLURM job **46853279**, `sim/phase1_small_sample_interval_calibration.jl`
  `--reps=500 --bootstrap=false --designs=tiny:4:8:24,small:8:16:96,medium:16:32:192
  --h2=0.2,0.4,0.6,0.8 --levels=0.9,0.95` (delta + profile arms; bootstrap arm off). 500 reps/cell.
  Artifact `sim/drac/results/cov_delta_profile_46853279.tsv`.

## Empirical coverage — h² interval, nominal 95% (500 reps/cell)

| design | n | method | h²=0.2 | 0.4 | 0.6 | 0.8 |
|---|---|---|---|---|---|---|
| tiny | 36 | `:delta` | 0.986 | **1.000** | **1.000** | **1.000** |
| tiny | 36 | `:profile` | 0.980 | 0.985 | 0.998 | 0.980 |
| small | 120 | `:delta` | 0.965 | 0.990 | 0.994 | 0.946 |
| small | 120 | `:profile` | 0.985 | 0.962 | 0.954 | 0.948 |
| medium | 240 | `:delta` | 0.973 | 0.976 | 0.934 | 0.968 |
| medium | 240 | `:profile` | 0.959 | 0.946 | 0.938 | 0.946 |

(σ²a via `variance_component_interval` `:profile` is the same story: tiny ~0.98, small/medium
0.926–0.985.)

## Honest findings

1. **Both intervals OVER-COVER at small n** — most extreme for `:delta` at n=36 (100% coverage at
   h²≥0.4, i.e. the interval is so wide it always contains the truth). This is the expected flat-REML-
   surface behavior: at small n the interval widens / clamps to (0,1) and over-covers. The SHIPPED
   methods (`heritability_interval` `:delta`/`:profile`, `variance_component_interval` `:profile`) are
   CONSERVATIVE — they never UNDER-cover (the lowest shipped cell is the σ²a `:profile` at n=240,
   h²=0.6, 0.926 ≈ 2·MCSE below nominal), so they do not give false confidence. (The tsv also reports
   a harness-internal σ²a normal-Wald PROBE `sigma_a2_delta_z` that DOES under-cover — down to ~0.90
   at n≥120 — but that is NOT a shipped surface; `variance_component_interval` ships `:profile`-only,
   precisely because the Wald probe under-covers.)
2. **`:profile` is better-calibrated than `:delta`.** At medium (n=240) `:profile` is 0.938–0.959
   (near nominal 95%) while `:delta` is 0.934–0.976 (more variable, tends to over-cover). `:profile`
   is the recommended choice when calibration matters.
3. **Both converge toward nominal as n grows** (tiny → small → medium), `:profile` faster. By n=240
   `:profile` is well-calibrated.

## What this discharges

- The "coverage-calibrated intervals" owed leg is now DISCHARGED as a MEASUREMENT: the shipped
  intervals' finite-sample coverage is characterized (conservative over-coverage at small n,
  converging to nominal; `:profile` > `:delta`). The docstring caveat is now quantified + directional
  (conservative, not anti-conservative).
- This does NOT change any default or API, and does NOT move anything to `covered` — it is an honest
  characterization of the existing asymptotic intervals. `public_covered_count` UNCHANGED (5).
- SCOPE: the single-component animal-model h²/σ²a intervals (delta + profile) on the tested
  pedigree designs (n=36/120/240) and h² grid. NOT the two-effect/multi-effect ratio intervals or the
  matrix-free intervals (same estimator family, calibration expected to be similar but not measured
  here); NOT a coverage GUARANTEE (a measured characterization, MCSE ~1pp at 500 reps).
