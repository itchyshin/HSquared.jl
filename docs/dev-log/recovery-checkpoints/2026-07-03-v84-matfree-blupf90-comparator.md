# V8.4 — external same-estimand comparator for the MATRIX-FREE Monte-Carlo REML fit (2026-07-03)

The external-comparator leg doc-25 named as owed for the matrix-free multi-effect FIT
(`V3-NEFFECT-MATFREE-FIT`). The EXACT multi-effect AI-REML estimator (`fit_multi_effect_reml`)
already has a blupf90 same-estimand comparator (the `V3-NEFFECT-REML` covered flip). This leg
validates the DIFFERENT estimator — the matrix-free Monte-Carlo REML fit
(`fit_multi_effect_mc_reml`), which never forms/factors `C` and estimates the REML score-trace by
Hutchinson stochastic probes.

**Claim under test:** the matrix-free fit reaches blupf90's AIREMLF90 optimum WITHIN its
Monte-Carlo error band on a shared fixture. **This is the ESTIMAND leg at validation scale — NOT
the at-scale (large-fixture) leg**, which remains owed (a large-q blupf90/sommer run where the exact
path is infeasible needs DRAC and is a separate hardening item).

## Executables

- `renumf90` 1.166 + `blupf90+` 2.60 (`comparator/bin/`), Mac arm64 — the same binaries as the
  V3-NEFFECT-REML / V2-GREML legs. Run live end-to-end (renumf90 → blupf90+ AIREMLF90) by
  `comparator/matfree_blupf90_neffect.jl`.

## Model + fixture (shared with `prepare_blupf90_neffect.jl`)

`y = μ + u1[animal] + u2[group1] + u3[group2] + e`, `u1 ~ N(0, A·σa²)` (additive, pedigree A),
`u2 ~ N(0, I·σg1²)`, `u3 ~ N(0, I·σg2²)` (two independent environment groups), `e ~ N(0, I·σe²)`.
Deterministic dataset = the recovery-gate's first predeclared seed (20260800): half-sib 20 sires /
40 dams / 800 offspring (q=860), 80 + 60 groups; truth `(σa², σg1², σg2², σe²) = (1.0, 0.5, 0.5,
1.0)`. AIREMLF90 via `OPTION method VCE`, NEUTRAL 1.0 starts (isolation).

## Results (live blupf90 run, `comparator/matfree_blupf90_neffect.jl`)

**Estimand check — exact engine vs blupf90 (re-confirms the covered `V3-NEFFECT-REML` leg):**

| Component | blupf90+ 2.60 | exact `fit_multi_effect_reml` | abs diff |
|---|---|---|---|
| σa² (animal) | 1.01750 | 1.01754 | — |
| σg1² (group1) | 0.38014 | 0.38014 | — |
| σg2² (group2) | 0.50136 | 0.50136 | — |
| σe² (residual) | 0.96387 | 0.96386 | — |

max abs diff **3.78e-5** (the blupf90 5-significant-figure stdout floor).

**Matrix-free `fit_multi_effect_mc_reml` vs blupf90 (8 seeds, shared_probes, NEUTRAL start):**

| nprobe | max rel \|matfree mean − blupf90\| | worst-component gap in across-seed SD |
|---|---|---|
| 128 | **0.0005** (0.05%) | 0.11·SD (σg2²) |
| 512 | **0.0015** (0.15%) | 0.48·SD (σg1²) |

Per-component (nprobe=128): σa² 1.01731±0.01793 (0.01·SD from blupf90), σg1² 0.38015±0.00365
(0.00·SD), σg2² 0.50111±0.00231 (0.11·SD), σe² 0.96396±0.01051 (0.01·SD). The matrix-free across-seed
mean reaches blupf90's optimum to ≤0.15%, and blupf90 sits within ≤0.5 across-seed SD of the
matrix-free mean for every component — i.e. the matrix-free fit is unbiased for the EXTERNAL optimum
within its MC error.

(The nprobe=128 mean is nominally closer than nprobe=512 here — within-noise across the 8-seed
sample; both are ≤0.15%. More probes tightens the per-seed SD, not necessarily the 8-seed mean.)

## Evidence boundary (honest)

- ONE deterministic fixture (one seed's data, one truth point), moderate scale (q=860) where blupf90
  can also run — this validates the matrix-free **ESTIMAND** against an external tool, NOT coverage,
  NOT a multi-seed recovery gate (that is the separate pre-declared 48-seed gate,
  `2026-07-02-v08-s2fit-recovery-scale-result.md`).
- It supplies the "external same-estimand comparator through the matrix-free path" owed item **at
  validation scale**. It does NOT by itself flip anything to covered: `V3-NEFFECT-MATFREE-FIT` stays
  `partial`. Still owed: COVERAGE-CALIBRATED intervals, and the LARGE-FIXTURE comparator leg (a
  blupf90/sommer run at a q where the exact/direct path is infeasible — DRAC).
- `public_covered_count` UNCHANGED (engine capability, not an R-public model). The public-default
  fitting surface stays v0.1 Gaussian.
- Binaries + generated packet (`neffect.dat`/`.ped`/`renf90.*`/`solutions`/logs/comparison CSV) are
  git-ignored — none committed. The committed artifacts are `comparator/matfree_blupf90_neffect.jl`
  + this checkpoint.
