# W1 DRAC evidence week — ADEMP predeclaration (committed BEFORE any sbatch)

Date: 2026-06-29 · Lane: Julia engine (Claude solo, Codex out) · Status: PREDECLARATION (no run yet).
This file is the hard launch gate: the grids, seeds, and pass criteria below are fixed BEFORE any
`sbatch` (R4 discipline; no post-hoc threshold relaxation — the 2026-06-14 calibration-failure rule).
Both campaigns produce TRIAGE evidence until a gate clears; nothing is promoted without Rose + G10.

## Campaign 1 — interval coverage characterization (V1-HERIT-CI)

- **Aim:** characterize the finite-sample coverage of the EXISTING heritability/σ²a interval methods
  (`heritability_interval(:delta)`, `heritability_interval(:profile)`, `bootstrap_variance_component_interval`)
  on small animal-model designs. **Characterization only** — the t/Satterthwaite df path stays BLOCKED
  (`V1-HERIT-TCAL` planned); the t-/SW-probe columns are descriptive, never a covered claim.
- **Data-generating mechanism:** half-sib pedigrees `tiny:4:8:24` (q=36), `small:8:16:96` (q=120),
  `medium:16:32:192` (q=240); true h² ∈ {0.1, 0.3, 0.5, 0.7} at unit total variance (σ²a=h², σ²e=1−h²);
  Gaussian animal model fit by AI-REML. Harness: `sim/phase1_small_sample_interval_calibration.jl`
  (S1 fix: bootstrap drawn ONCE per replicate, both nominal levels off the shared draw set).
- **Estimand / targets:** nominal-vs-empirical coverage at levels {0.90, 0.95} for h² and σ²a, per method.
- **Methods:** delta (normal-z), profile (χ²₁ LRT), parametric-bootstrap percentile (n_boot=199, right-size
  after smoke; Rose: 299 in tiny/low-h² cells).
- **Performance measures:** per cell (design × h² × level × method) report the quadruplet
  `fit_success / interval_success / coverage±MCSE / near_boundary-rate`. **Coverage denominator is
  `interval_success`, NOT reps.** Flag any cell with `interval_success < 0.9·reps` as NON-INTERPRETABLE.
- **Sample size / seeds:** 20 array tasks × 100 reps, each task a distinct master seed
  `20260629+task` (independent rep streams) → 2000 reps/cell (95% MCSE ≈ 0.5pp at full interval_success).
- **Gate (characterization, no promotion):** report-only ±2pp descriptive band; a method is flagged
  mis-calibrated where `|empirical − nominal| > 2·MCSE` in interpretable cells. No pass/fail promotion.

## Campaign 2 — broader-DGP V4-MV-REML recovery (doc-33 path-b)

- **Aim:** discharge the retained `V4-MV-REML` broader-DGP recovery debt via a pre-declared cold-start
  recovery gate across a DGP factorial (the doc-33 substitutable path — the existing `sommer` same-estimand
  leg + a passing recovery gate finish the covered claim; a BLUPF90 2nd lineage is optional hardening).
- **Data-generating mechanism:** the 8 cells in `sim/drac/phase4_v4_cells.tsv` — a factorial over
  r_g ∈ {0.10, 0.42(base), 0.70}, records ∈ {1, 3}, one asymmetric-h² cell, one larger-size cell.
  `base_inside` reproduces the ALREADY-COVERED V4 scope (legacy G0/R0/design) and is tagged `inside`;
  all others are `new`. **No near-singular-G cell** (out-of-scope vacuous-pass trap; the harness rejects
  `cond(G0) > 1e6`). Harness: `sim/phase4_multivariate_reml_recovery.jl` (S2: parameterized cell + aggregate gate).
- **Estimand / targets:** G0/R0 entries (G[1,1],G[1,2],G[2,2],R[1,1],R[1,2],R[2,2]) + per-trait EBV accuracy.
- **Methods:** `fit_multivariate_reml`, **cold-start** (default phenotypic-scale init), iterations=5000.
- **Performance measures:** across-seed bias, MCSE (=sd/√m), and `|bias| ≤ 2·MCSE` per parameter; EBV
  accuracy; convergence count; Wilson 95% on the per-seed pass rate. The AUTHORITATIVE gate is the printed
  AGGREGATE block (machine-readable `GATE` line), NOT the per-seed Frobenius exit.
- **Sample size / seeds:** 50 cold-start seeds per cell (`20260629..20260678`); 8 cells (array 1–8).
- **Gate (pre-declared, per cell):** PASS = all 6 G0/R0 parameters within `|bias| ≤ 2·MCSE`
  (EBV≥0.85 is a reported floor, not the discriminator). A `new`-scope cell that fails → honest banked
  negative (records where the estimator's recovery degrades). 
- **⚠️ Covered-claim regression rule (R9):** the `base_inside` cell lies INSIDE the already-covered
  `V4-MV-REML` scope. If it FAILS its gate, that is a **STOP-and-ask covered-claim regression**, not a
  banked negative — narrow the covered row's scope or revisit the promotion. Do not proceed to any
  promotion on a regression.

## Run discipline (R4)

SLURM arrays only, never login-node compute; depot + checkout on `/project` (never `/scratch`); resumable
(`--resume` / per-task output); `seff` after the 1-task smoke to right-size `--time`/`--mem`/`n_boot`
before the full array; the two foreign untracked files are never staged. Cluster: a dual CPU+GPU DRAC
general node, default `fir` (`def-snakagaw_cpu`).

## What a pass/fail means

- Campaign 1 pass = an honest coverage table (the headline will likely be "delta under-covers / clamps at
  tiny + low-h²"); it tees up no promotion by itself (the t/df method stays blocked).
- Campaign 2 pass on the `new` cells + no regression on `base_inside` = the broader-DGP recovery evidence
  for the `V4-MV-REML` finish (E10), to be assembled with a real Rose audit + maintainer G10 sign-off.
- Any fail is a recorded, reusable negative (seeds/versions/MCSE committed). Neither outcome changes a
  default or public claim without Rose + sign-off.
