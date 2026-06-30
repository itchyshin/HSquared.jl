# V3-TWOEFFECT-REML — BLUPF90 same-estimand REML comparator leg (2026-06-30)

Adds the external same-estimand REML comparator that doc-18 named as owed for v0.3 (standard-QG). Independent
of any prior leg (this is the FIRST external comparator for the two-effect REML estimator). **TRIAGE → the
covered close additionally needs a pre-declared bias/MCSE recovery gate + maintainer G10; this is the
comparator half only.**

## Executables

- `renumf90` 1.166 + `blupf90+` 2.60, Mac x86_64 under Rosetta (statically linked, no MKL) — same binaries
  as the V4-MV-REML BLUPF90 leg.

## Model + estimand (same as `fit_two_effect_reml`)

`y = μ + u1[animal] + u2[group] + e`, `u1 ~ N(0, A·σ1²)` (additive, pedigree A), `u2 ~ N(0, I·σ2²)`
(common-environment group, assigned independently of the pedigree), `e ~ N(0, I·σe²)`. AI-REML via
`OPTION method VCE`. Deterministic dataset reconstructs the recovery harness's first predeclared seed
(`sim/phase3_two_effect_recovery.jl`, seed 20260618): half-sib, 20 sires / 40 dams / 800 offspring (q=860),
80 random groups. Generator: `comparator/prepare_blupf90_two_effect.jl` (fits the engine, writes the
BLUPF90 packet + `engine_target.csv`).

## Packet correctness (the V4 bug avoided)

`prepare_blupf90_two_effect.jl` writes `renumf90.par` in the CORRECT renumf90 format from the start
(keyword/value on separate lines; `cross alpha`; `FILE_POS 1 2 3 0 0`), encoding the second random effect as
`RANDOM diagonal` (the common-environment ~ I). renumf90 accepted it directly (no manual fix needed) — 860
records, 2 random effects (`add_an_upginb` animal + `diagonal` group).

## Independent convergence

The engine-target run starts BLUPF90 at the engine estimates (confirms the AI-REML fixed point). The valid
independence test uses a NEUTRAL start (σe²=1.0, σ1²=0.5, σ2²=0.5; `renf90_neutral.par`): from there
`blupf90+` converged in **6 rounds** to the same optimum — NOT started at the answer.

## Agreement vs the engine REML target

| Component | BLUPF90+ 2.60 (neutral start) | engine `fit_two_effect_reml` | abs diff |
|---|---|---|---|
| σ1² (animal / additive) | 1.1457 | 1.14568061 | ~1.9e-5 |
| σ2² (common-environment) | 0.47933 | 0.47932655 | ~3e-6 |
| σe² (residual) | 0.88669 | 0.88668470 | ~5e-6 |

The ~1e-5 floor is the BLUPF90 5-significant-figure stdout printout. All three variance components agree.

## Evidence boundary (honest)

- This is ONE deterministic dataset (one seed, one truth point) confirming the REML **optimum / point
  estimate** for the two-effect kernel — NOT a multi-seed recovery gate and NOT coverage.
- It supplies the "external same-estimand REML comparator" owed for v0.3. **It does NOT by itself make
  `V3-TWOEFFECT-REML` covered:** a covered close still needs a PRE-DECLARED bias/MCSE recovery gate (the
  existing `sim/phase3_two_effect_recovery.jl` is a 5-seed rel-threshold harness — a stronger, predeclared
  bias/MCSE gate over more seeds is owed) + a real Rose audit + maintainer G10.
- `V3-REPEAT-REML` (repeatability, σa/σpe split ill-conditioned at validation scale) is a separate kernel —
  this leg is for the two-effect / common-environment model only.
- Binaries + generated `renf90.*`/`renadd*.ped`/`solutions`/logs are git-ignored or untracked — none committed.
