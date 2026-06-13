# v0.1 Gate: Validation-Status Finalization (R-lane evidence)

Active lenses: Rose, Fisher, Mrode, Curie (inline). Driven by the R twin's
`docs/dev-log/2026-06-13-v01-gate-handoff.md` handoff.

## Goal

Act on the R twin's v0.1 gate handoff: fix the `V1-AI-REML` honesty bug the R-lane
Rose audit flagged, and record the R-lane external validation of the Julia engine
in the validation ladder (in lockstep across the three status surfaces).

## Provenance (important)

The `src/validation_status.jl` and `test/runtests.jl` edits were found **staged
(uncommitted) in the working tree**, authored by the user or a parallel lane
implementing the handoff — not by this thread. This slice **verified** them (full
suite passes), **completed the lockstep** (the same fix in `capability-status.md`
and `validation-debt-register.md`, which the staged change had not touched), and
documented. Committed to a branch + PR for maintainer merge (this thread does not
merge to `main`).

## Files Changed

- `src/validation_status.jl` (staged): `V1-AI-REML` partial→covered; `V1-MRODE-FIT`
  and `V1-COMPARATORS` planned→covered_external.
- `test/runtests.jl` (staged): matching validation-row assertions (incl.
  `!occursin("250-animal", aireml_row.evidence)`).
- `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`
  (this slice — lockstep): dropped the "250-animal" claim from the AI-REML rows;
  cite the finite-difference REML Hessian + R-lane DGP/gryphon/sommer evidence.
- `docs/src/changelog.md`, `docs/dev-log/check-log.md`, this report.

## The honesty fix

The `V1-AI-REML` evidence cited a "250-animal observed-information check (ratio
~0.99)" with **no committed backing test** (the 250-animal sim was a one-off; the
suite is RNG-free). That is now replaced everywhere with the committed
finite-difference REML Hessian check (`V1-HERIT-CI`, ~8%) plus the R-lane
DGP/gryphon recovery — claims that are actually backed.

## The promotions (external, R-lane)

- `V1-MRODE-FIT` → `covered_external`: `fit_sparse_reml`/`fit_ai_reml` recover the
  published gryphon REML estimate (Wilson 2010: VA=3.3954, VE=3.8286, h²=0.470)
  exactly via supplied `A_gryphon`, within the maintainer-signed-off band. The raw
  gryphon pedigree is pathological and the engine correctly rejects it.
- `V1-COMPARATORS` → `covered_external`: sommer agreement on the gryphon anchor
  within the band (VC ~1–2 %, h² ~0.01–0.02, EBV r > 0.999).

## Checks

- `Pkg.test()`: passed (724). `julia --project=docs docs/make.jl`: green.

## Public Claim Audit

Allowed: the honesty fix (removing an unbacked claim) and the `covered_external`
promotions citing real, CI-green R-lane evidence + the committed finite-diff
check.

Blocked / still pending: Julia-native recovery/fitted fixtures; the default
`hsquared()` flip from validate-to-fit (gated on the full v0.1 predicate + the
maintainer's mechanical default-flip slice — the R lane's, not this thread's).

## Coordination Notes

This is the twin-side row-flip the R-twin handoff requested. Remaining v0.1 gate
twin items per the handoff: an estimator boundary-stability fixture (h²→0/1), and
then the R lane performs the default-flip when the full predicate holds.
