# Check-log — v0.8-V8.4 external comparator for the matrix-free fit (2026-07-03)

**Slice:** the external same-estimand comparator leg for the matrix-free Monte-Carlo REML fit
(`V3-NEFFECT-MATFREE-FIT`). New committed artifact: `comparator/matfree_blupf90_neffect.jl`. Branch
`feat/2026-07-03-v84-matfree-comparator`.

## What it validates

The EXACT multi-effect AI-REML estimator already has a blupf90 comparator (the `V3-NEFFECT-REML`
covered flip). This leg validates the DIFFERENT estimator — the matrix-free `fit_multi_effect_mc_reml`
(never forms/factors `C`; Hutchinson stochastic score-trace) — against blupf90 AIREMLF90 on a shared
fixture. Claim: the matrix-free fit reaches blupf90's optimum WITHIN its Monte-Carlo error band. This
is the **ESTIMAND leg at validation scale**, NOT the at-scale (large-fixture) leg (still owed, DRAC).

## Key result (live blupf90 run)

- **Estimand:** exact engine `fit_multi_effect_reml` vs `blupf90+` 2.60 AIREMLF90 → max abs diff
  **3.78e-5** (the blupf90 5-sig-fig floor). Re-confirms the covered exact estimand.
- **Matrix-free vs blupf90** (8 seeds, `shared_probes`, NEUTRAL start): across-seed mean reaches
  blupf90's optimum to **≤0.15%** — nprobe=128 → 0.05% (worst component 0.11·SD), nprobe=512 → 0.15%
  (worst 0.48·SD). blupf90 sits within ≤0.5 across-seed SD of the matrix-free mean for every
  component → the matrix-free fit is unbiased for the EXTERNAL optimum within its MC error.

## Evidence

- Script: `comparator/matfree_blupf90_neffect.jl` — reconstructs the shared K=3 fixture (seed
  20260800, q=860), writes the blupf90 packet, runs renumf90 → blupf90+ live (binaries in
  `comparator/bin/`), parses the VC estimates, runs exact + 16 matrix-free fits, writes
  `matfree_blupf90_comparison.csv`.
- Checkpoint (numbers banked): `docs/dev-log/recovery-checkpoints/2026-07-03-v84-matfree-blupf90-comparator.md`.
- No code change in `src/` — this is a comparator + evidence slice. `Pkg.test()` count UNCHANGED
  (55); no new validation_status row (the `V3-NEFFECT-MATFREE-FIT` row's evidence + owed-notes are
  extended in place). Binaries + generated packet are git-ignored.

## Honesty

- ONE deterministic fixture, moderate scale (q=860) where blupf90 also runs — validates the
  ESTIMAND, NOT coverage, NOT a multi-seed recovery gate (that is the separate pre-declared 48-seed
  gate). No covered flip; `V3-NEFFECT-MATFREE-FIT` stays `partial`. `public_covered_count` UNCHANGED.
- Owed: COVERAGE-CALIBRATED intervals + the AT-SCALE (large-fixture, exact-infeasible) comparator leg.
