# Recovery checkpoint — 2026-06-13 — Phase 2 genomic engine + heritability intervals

Use this to rehydrate fast. Repository state is the source of truth.

## Where the work lives

- **Branch `phase2-genomic-engine` → PR #9** (https://github.com/itchyshin/HSquared.jl/pull/9),
  12 commits ahead of `origin/main`, **680 tests pass**, CI + Documenter **green**.
- **NOT merged to `main`** — a direct push to the default branch was blocked by
  policy; merging is a user action.
- `origin/main` is still at `ba93225` (pre-session). Local `main` carries the 12
  commits (mirrored on the PR branch).

## What landed this session (all engine-internal / additive — no R↔Julia contract change)

Phase 2 genomic engine:
- `genomic_relationship_inverse(G; ridge)` — regularized `Ginv`.
- `fit_gblup(y, X, Z, Ginv, σ²a, σ²e)` — GBLUP (reuses `henderson_mme`).
- `fit_snp_blup` + `centered_markers` — SNP-BLUP; `gebv = W·â` == GBLUP (~1e-16, marginal V).
- genomic reliability/PEV/accuracy semantics (denominator `diag(inv(Ginv)) = diag(G)+ridge`).
- internal `_single_step_Hinv` — ssGBLUP `H⁻¹` construction utility (unexported; `A₂₂⁻¹` trap guarded).
- internal `_numerator_relationship` — dense NRM/`A₂₂` (dedupe).
- genomic REML — existing AI/sparse REML on a `Ginv` spec (no new code).
- docs: "Genomic models" page.

Phase 1 inference:
- `variance_component_covariance` / `_standard_errors`, `heritability_standard_error`,
  `heritability_interval(fit; level)` — logit-delta CI (always in (0,1)), on the REML AI matrix.
  Internal `_reml_information_matrix`, `_standard_normal_quantile` (Acklam).

Quality: multi-lens adversarial review (11 agents) — **0 numerical bugs, 0 contract drift**;
doc/test-quality findings fixed. Full DoD per slice (tests + `validation_status.jl`/
capability-status/validation-debt rows + changelog + check-log + after-task reports).
`validation_status()` has 21 rows.

## Blocked / pending (need a human or the other lane)

1. **Merge PR #9** to `main` — user action (push to default branch blocked).
2. **Post the Phase-2 coordination ask** to issue #6 — outbound comment blocked;
   ready-to-paste text is in the PR #9 description.
3. **R-facing `genomic()` / `single_step()` model-spec wiring** — R twin (`hsquared`).
4. **External comparators** (AGHmatrix / sommer / rrBLUP / BLUPF90) — R lane; JWAS
   unusable (GPL-2.0 vs MIT, MCMC-only). Plan: a shared serialized fixture (format TBD).
5. **Phase 3** (repeatability / permanent env / maternal …) — needs a
   multi-random-effect engine generalization + contract coordination.
6. **h² intervals v2** — profile-likelihood / parametric-bootstrap (bootstrap needs
   an RNG test harness; suite is currently RNG-free). See the decisions log.

## Control centre

Live at **http://localhost:8791** (persistent dir `~/.claude/hsquared-control-centre/`,
`python3 -m http.server 8791`). Relaunch: `cd ~/.claude/hsquared-control-centre && nohup python3 -m http.server 8791 --bind 127.0.0.1 &`.

## Standard commands

```sh
~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'
~/.juliaup/bin/julia --project=docs docs/make.jl
gh pr view 9
```
(`julia` is not on the non-interactive PATH; use `~/.juliaup/bin/julia`.)

## Update — later same day

- **Phase 3 started**: `repeatability_mme` (supplied-variance two-random-effect
  solve: additive + permanent-environment) landed (`V3-REPEAT`). Suite now **691
  tests**. PR #9 has all of the above, CI green, still unmerged.
- **Two open decisions recorded** (`docs/dev-log/decisions/`):
  - `2026-06-13-heritability-interval-design.md` — *resolved* (logit-delta shipped).
  - `2026-06-13-rng-recovery-test-harness.md` — **open**: shipping the
    **3-component REML** estimator (to estimate σ²a/σ²pe/σ²e and the repeatability
    coefficient) needs a recovery validation that requires simulated data; the
    suite is RNG-free. The dense 2-random-effect REML loglik is prototyped and
    verified (matches the animal-model REML to 1e-6), but the estimator was NOT
    shipped pending the RNG-test-harness decision. This is the current frontier.
- Net: the clean, deterministically-validatable autonomous frontier for Phases
  1–3 (engine side) is reached. Further engine progress (multi-component REML,
  general multi-random-effect models, maternal/common-env) needs either the RNG
  decision above or the R-twin model-spec contract.
