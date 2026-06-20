# Decision — Univariate fitted-target fixture + JWAS comparator protocol (#46/#49)

Date: 2026-06-19. Lane: Julia engine. Lenses: Mrode (validation canon) + Curie +
Fisher; Rose (claim gate). Mirrors
`docs/dev-log/decisions/2026-06-14-multitrait-comparator-protocol.md`.

## Decision

1. **#46 — Julia-native fitted univariate target is a SERIALIZED bundle, not
   external evidence.** The engine fits its OWN single-trait animal model (REML)
   and serializes its own variance components / fixed effects / EBVs / PEV /
   reliability / loglik to `test/fixtures/animal_model_fitted_target/`. No textbook
   (Mrode/gryphon) EBVs are typed from memory. The committed CI test checks only
   **self-consistency** (Henderson MME at the stored variance components reproduces
   the stored β/EBVs/PEV/reliability/loglik) — it does NOT claim external validation.

2. **#49 — external comparators are OPT-IN, outside CI, in a separate environment.**
   - **JWAS.jl** (`comparator/`, `HSQUARED_RUN_JWAS=true`, `--project=comparator`):
     fits the same model and reports **agreement** with the REML target. JWAS is
     MCMC/Bayesian vs the engine's REML, so agreement is **approximate by
     construction** — the runner reports it honestly and never says "parity" /
     "validation". JWAS is NEVER a package dependency and is never imported by the
     engine or its suite.
   - **R lane** runs the `nadiv`/`pedigreemm`/published confrontation against the
     same serialized targets (cross-lane; coordinate on #61/#46).

3. **No promotion to `covered`** for any fitted animal-model row on the strength of
   this fixture alone. Promotion requires a recorded external-comparator run
   (tolerance + package versions + design) — the fixture is the target such a run
   confronts.

## Rationale

The 2026-06-14 multitrait protocol established "serialize a Julia target; confront
externally; promote only with recorded evidence." This extends it to the univariate
fitted case (the long-standing fitted-Mrode debt, `V1-LIK`/`V1-OPT`/`V1-MME`), and
adds a Julia-native MCMC comparator (JWAS) alongside the R-lane REML comparators —
honestly labelled as a different estimator.

## Consequences

- Committed: the fixture + a deterministic self-consistency testset; the opt-in
  comparator scaffold (`comparator/Project.toml`, runner, README); `.gitignore` for
  the comparator Manifest. The package `Project.toml` is UNCHANGED (no JWAS).
- The fitted-Mrode validation-debt rows now cite the serialized target as the
  confrontation surface; they remain `partial` until an external run is recorded.
