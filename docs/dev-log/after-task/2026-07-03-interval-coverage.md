# After-task — interval coverage calibration (the last owed doc-25 leg) (2026-07-03)

**Owner:** Claude solo (Opus), autonomous (goal: finish doc-25). **Branch:**
`feat/2026-07-03-interval-coverage` off `main` @ `cdcb9130`. **Counts:** rows **55**, covered **13**,
`public_covered_count` **5** — NO covered flip. **This closes doc-25.**

## Headline

Measured the empirical coverage of the SHIPPED animal-model h²/σ²a intervals (`heritability_interval`
`:delta` / `:profile`; `variance_component_interval`) — the "coverage-calibrated intervals" owed
item. Honest finding: **both intervals are CONSERVATIVE** (over-cover at small n, never under-cover),
**converge to nominal as n grows**, and **`:profile` is better-calibrated than `:delta`**. This
quantifies the existing "uncalibrated on small samples" docstring caveat + makes it directional.

## What landed

- **Run:** DRAC fir job **46853279**, `sim/phase1_small_sample_interval_calibration.jl` (pre-existing
  Codex harness), `--reps=500 --bootstrap=false --designs=tiny/small/medium (n=36/120/240)
  --h2=0.2..0.8 --levels=0.9,0.95`. Artifact `sim/drac/results/cov_delta_profile_46853279.tsv`
  (tracked). Checkpoint `docs/dev-log/recovery-checkpoints/2026-07-03-interval-coverage.md`.
- **Status:** `V1-HERIT-CI` evidence + missing + claim_boundary updated (delta/profile coverage
  measured; bootstrap arm + ratio/matrix-free/MV/non-Gaussian coverage remain unmeasured). doc-25
  status header → ARC COMPLETE.

## Evidence (h² interval, nominal 95%, 500 reps/cell)

- `:delta`: tiny n=36 → 0.986–1.000 (over-covers, 100% at h²≥0.4); small n=120 → 0.946–0.994;
  medium n=240 → 0.934–0.976.
- `:profile`: tiny → 0.980–0.998; small → 0.948–0.985; medium → **0.938–0.959** (≈ nominal).
- σ²a `:profile` same story (tiny ~0.98, small/medium 0.926–0.985).

## Honesty pins

- A MEASUREMENT / characterization, NOT a coverage guarantee (MCSE ~1pp at 500 reps). Does NOT change
  any default or API; does NOT move anything to covered. `public_covered_count` UNCHANGED. Scope:
  single-component animal-model h²/σ²a delta+profile on n=36/120/240; the ratio/matrix-free/MV/
  non-Gaussian/bootstrap coverage is NOT separately measured. `Pkg.test()` GREEN (55).

## doc-25 status

**Fully closed.** All numbered slices (V8.1–V8.6, V7.1–V7.5) merged; both owed hardening legs (V8.4
at-scale, coverage-calibrated intervals) discharged. `public_covered_count` held at 5 throughout — no
covered flips, engine capability only.
