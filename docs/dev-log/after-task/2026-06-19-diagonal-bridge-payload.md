# After-task — Diagonal multivariate bridge payload (#42 scoped)

Date: 2026-06-19. Lane: Julia engine. Slice: BT2/BT3 programme, S2. Lenses:
Hopper + Boole + Emmy (bridge contract), Gauss + Noether (numerics), Rose (claim
gate).

## Context

On issue #61 the R lane asked to unblock the rotation-free `:diagonal` genetic
structure so they could wire the diagonal-vs-unstructured LRT (#47). I decided
yes (diagonal has no loadings/rotation ambiguity; the LRT is the clean interior
null) and posted the bridge-payload contract. This slice delivers the engine half.

## What was done

- `multivariate_result_payload(result)` (src/multivariate.jl, exported in
  src/HSquared.jl): the "boring" bridge `NamedTuple` matching the posted contract,
  scoped to the rotation-free `:unstructured`/`:diagonal` structures and rejecting
  `:lowrank`/`:factor_analytic` (rotation-nonidentified loadings). Never surfaces
  `genetic_loadings`/`genetic_uniqueness`. `n_genetic_params` (`:diagonal`=t,
  `:unstructured`=t(t+1)/2) makes the diagonal-vs-unstructured LRT df a difference.
- `test/fixtures/structured_covariance_parity/`: a deterministic two-trait
  `:diagonal` target (same inputs as `phase4_multitrait_parity`) + README +
  CI self-consistency test (`multivariate_mme` at the stored diagonal G0/R0
  reproduces β/EBVs/h²/loglik).
- Tests (Phase 4B testset, +18; fixture testset, +9): payload shape,
  `n_genetic_params` identity, `genetic_variances=diag(G0)`, the diagonal-vs-
  unstructured LRT df (interior null), lowrank/fa rejection, fixture
  self-consistency. `validation_status()` count 32 → 33 (new `V4-BRIDGE` row).
- Docs/rows: 03-engine-contract.md spec; capability-status row; validation-debt
  `V4-BRIDGE`; validation_status.jl `V4-BRIDGE` + honest V4-MV-REML/V4-FA
  claim-boundary updates (`:diagonal` now bridge-exposed; lowrank/fa NOT).

## Evidence

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` → **passed (exit 0)**.
- `~/.juliaup/bin/julia --project=docs docs/make.jl` → **exit 0**.
- **Adversarial review:** a 3-lens review workflow (Hopper bridge-parity, Gauss+
  Noether numerics, Rose claim-gate) was launched but its agents were **interrupted
  before returning structured findings** (the session was interrupted). I did the
  equivalent self-review manually against the green suite (which covers every
  correctness claim): payload↔contract parity, `n_genetic_params`/LRT-df identity,
  `genetic_variances=diag(G0)`, lowrank/fa rejection, fixture self-consistency, and
  the honesty of the new rows/spec. No issues found. Note: the payload's
  `breeding_values` carries an additive `traits` field beyond the posted
  `{ids, values}` (harmless superset; noted to the R lane on #61).

## Cross-lane

Posted the contract + build steps to #61 already; on merge I post the fixture path
(`test/fixtures/structured_covariance_parity/`) so the R lane can run its hermetic
diagonal-G parity test and wire `covariance_structure_lrt(diagonal, unstructured)`.

## Status discipline

Bridge-ready payload for the rotation-free `:unstructured`/`:diagonal` structures
ONLY. No loadings/uniqueness surfaced; no external comparator parity; fixture is an
input+target bundle, not external evidence; R-side activation is cross-lane
(#42/#47). Experimental, dense/validation-scale. No capability moved to covered.

## Live Phase Snapshot delta

`Pkg.test()` green (exit 0); `validation_status()` 32 → **33** rows (new
`V4-BRIDGE`). S1 + S2 landed; lowrank/fa bridge exposure remains gated on the
rotation convention (#42/#55).

## Next

R lane wires the diagonal LRT against the fixture; my side: the FA rotation-
convention decision note (gates #42 lowrank/fa + #55 evolvability), and the other
BT2 bridge wins (#43 PEV/reliability into `result_payload`, #45 post-fit scan).
