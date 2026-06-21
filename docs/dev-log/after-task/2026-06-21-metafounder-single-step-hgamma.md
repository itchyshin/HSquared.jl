# After-task — Supplied-Gamma single-step H^Gamma bridge primitive

Date: 2026-06-21. Lane: Julia engine (`HSquared.jl`). Branch:
`codex/metafounder-single-step-hgamma`. Type: engine bridge-readiness /
validation-scale relationship precision.

## Live Phase Snapshot

As of this report, Julia `main` is `6cdf739` after banking the multivariate
validation gate (#126) and BLUPF90 multivariate starter (#127). `V4-MV-REML`
remains `partial`: the `sommer` comparator and R-lane recovery evidence are
recorded, but the BLUPF90 second-comparator run is locally blocked because
`renumf90`, `airemlf90`, `blupf90`, `remlf90`, and `gibbsf90` are not on `PATH`.
This branch adds the supplied-Gamma single-step `H^Gamma` Julia primitive only;
no capability is promoted to covered.

## Summary

Added the Julia-owned supplied-Gamma single-step primitive:

- `metafounder_single_step_inverse`
- `fit_metafounder_single_step`
- `fit_metafounder_single_step_reml`

The helper builds `A^Gamma` from the existing supplied-Gamma metafounder
relationship machinery, then applies the ordinary single-step update over the
genotyped rows. This gives the R bridge a concrete engine target to ratify later
without forcing R syntax or payload changes in this Julia slice.

## Active Lenses

Hopper + Boole + Emmy checked that this is bridge-ready but not an R contract.
Gauss + Noether checked the precision-matrix construction. Curie + Fisher +
Mrode checked reduction and manual-construction gates. Rose kept the claim
boundary partial. Grace covered local checks. Ada + Shannon kept the R/Julia
lane split. No subagents were spawned.

## Files Changed

- `src/genomic.jl` — added the `H^Gamma` inverse and supplied-variance/REML
  wrappers.
- `src/HSquared.jl` — exported the three helpers.
- `test/runtests.jl` — added the `H^Gamma` bridge-primitive test set.
- `docs/src/api.md`, `docs/src/genomic-models.md`, `docs/src/validation-status.md`
  — surfaced the API and public-doc boundary.
- `src/validation_status.jl`, `docs/design/capability-status.md`,
  `docs/design/validation-debt-register.md`,
  `docs/design/12-bridge-compatibility.md` — updated ledgers.
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-21-metafounder-single-step-hgamma.md`

## Commands / Results

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` — passed.
  New test set: 10/10 assertions.
- `~/.juliaup/bin/julia --project=docs docs/make.jl` — passed, with existing
  local-build warnings for omitted internal docstrings, skipped deployment
  detection, default Vitepress assets, and npm audit output.
- BLUPF90-family executable probe — all of `renumf90`, `airemlf90`, `blupf90`,
  `remlf90`, and `gibbsf90` were missing on `PATH`.
- `git diff --check` — passed.

## Validation Evidence

- `Gamma = 0` reduction: `metafounder_single_step_inverse` equals ordinary
  `single_step_inverse` with the classical pedigree relationship.
- Nonzero `Gamma` identity: helper output equals manually building `A^Gamma` and
  calling the ordinary single-step constructor.
- Symmetry: the resulting precision is symmetric on the fixture.
- Wrapper identity: `fit_metafounder_single_step` equals direct `fit_gblup` with
  the constructed `H^Gamma` precision.
- REML reduction: at `Gamma = 0`, `fit_metafounder_single_step_reml` matches the
  ordinary single-step REML objective and variance components.
- Guards: wrong genotyped-row/G dimensions and singular raw `G` are rejected.

## Claim Boundary / Rose Audit

Clean with limitations. `Gamma` is supplied, not estimated. The helper is dense
and validation-scale. Blending / `tau` / `omega` / `ridge` defaults remain
unvalidated by external comparators. No BLUPF90-family comparator was run in
this environment. No R formula syntax, R bridge fixture, or public user-facing
metafounder single-step model is claimed. Nothing moved from `partial` to
`covered`.

## R Twin Coordination

This slice gives the R twin a concrete candidate target name and payload shape:
`metafounder_single_step` carrying plain `Gamma`, `group_of`, `G`, and
`genotyped_rows` fields. R should still own the formula grammar, user-facing
syntax, payload ratification, and live bridge tests. This Julia branch does not
edit `hsquared`.

## Next

- Run the PR #127 BLUPF90 packet on a machine with BLUPF90-family executables.
- Let the R twin ratify the metafounder/single-step formula and bridge payload.
- Add a hermetic R bridge fixture once that payload is accepted.
- Keep `V2-SSHINV` and `V1-METAFOUNDER` partial until external evidence and the
  R bridge are recorded.
