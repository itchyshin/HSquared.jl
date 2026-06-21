# After-task — Binomial per-record n_trials (the general cbind GLMM, #61)

Date: 2026-06-20. Lane: Julia engine (`HSquared.jl`). Branch:
`julia/binomial-per-record-ntrials`. Surfaced by the engine reality while answering
the R lane's #61 question: the engine's Binomial family hard-coded `n_trials` as a
single scalar, so the general `cbind(successes, failures)` GLMM (varying trial
denominator per record) was unreachable. This slice closes that engine gap.

## Summary

Generalized the non-Gaussian Binomial family from a COMMON scalar `n_trials` to a
PER-RECORD `n_trials[i]` (`src/nongaussian.jl`, all internal). Design: a new
`BinomialVectorResponse(n_trials::Vector{Int})` plus a per-record resolver
`_fam_record(f, i)` — identity (`@inline`) for every scalar family (zero behavior
change on the existing Bernoulli/Poisson/scalar-Binomial paths) and a per-record
scalar `BinomialResponse(n_trials[i])` for the vector case. The resolver is threaded
into ALL 10 per-record kernel call sites across BOTH the Laplace
(`laplace_marginal_loglik`) and variational (`variational_marginal_loglik`) paths,
so the scalar family math is reused unchanged. `fit_laplace_reml` now accepts a
scalar OR a vector `n_trials` (length- and integer-checked; integer-valued reals
accepted since the R bridge marshals doubles, with a clean `ArgumentError` on
genuinely non-integer entries); `NonGaussianFit.n_trials` is widened to
`Union{Int,Vector{Int},Nothing}`; the bridge payload copies the vector.

## Definition of Done

- implementation — `src/nongaussian.jl`: `BinomialVectorResponse`, `_fam_record`,
  `_check_counts` vector method, the fitter + payload + field widening, docstrings.
  New symbols stay INTERNAL (not exported), matching the existing kernel/type policy.
- tests — "Phase 6 Binomial per-record n_trials (cbind GLMM)": 39 assertions
  (two reduction invariants to ~1e-12 + the fitted path; the all-ones==Bernoulli
  reduction; heterogeneous distinctness; FD score/weight; an INDEPENDENT per-record
  tensor Gauss–Hermite value gate; `_check_counts`/constructor guards; bridge-double
  acceptance + non-integer rejection). Full suite GREEN; the existing 31-assertion
  scalar-Binomial testset is unchanged.
- recovery — opt-in `sim/phase6_binomial_recovery.jl` adds a mixed-regime per-record
  scenario (`nₐ ~ Uniform{1..30}`, q=345): 5/5, rel ≤ 0.062, EBV cor 0.85–0.89.
- documentation — docstrings (file header, `BinomialResponse` sibling, fitter,
  `NonGaussianFit`, payload); the `V6-BINOMIAL` capability-status row + validation-debt
  row updated (stale "no/needs varying per-record n_trials" clauses removed, the new
  capability + validation + recovery recorded). `docs/make.jl` clean.
- check-log — `docs/dev-log/check-log.d/2026-06-20-binomial-per-record-ntrials.md`.
- after-task — this file.
- adversarial verification + Rose audit — the `verify-per-record-ntrials` Workflow
  (5 agents: Gauss/Noether/Curie review → adversarial verify → Rose gate). Verdict:
  CODE correct/narrow/well-tested, NO defect, NO overclaim; the one blocker was a
  stale-NEGATIVE register claim (honest-status doctrine both ways), now fixed. The
  Curie LOW (float-vector error) + NIT (mixed-regime recovery) were also addressed.
- clean local checks — `Pkg.test()` + `docs/make.jl` GREEN.
- clean CI — gated on the PR.

## Honest status

EXPERIMENTAL, dense/validation-scale. No intervals, no external comparator, no R
model-spec. `validation_status()` UNCHANGED (41 rows) — this widens an existing
experimental family (`V6-BINOMIAL`), it does not promote anything to `covered`.

## Cross-lane note (NOT posted — outward posting is the user's call)

This DIRECTLY resolves the engine side of the R lane's #61 Binomial-payload question.
R asked whether to pass `(y = successes, n_trials = total)` element-wise; the answer
is now "yes, and per-record totals are supported": the general `cbind(successes,
failures)` case (varying row totals) maps to a per-record `n_trials` vector, which
the engine now accepts (including R's marshaled double vectors). A draft #61 answer
reflecting the built capability is ready for the user to authorize.

## Next

R-side: wire the `cbind`/weights → `n_trials` vector mapping in the bridge (the
engine side is done). Engine: Binomial/threshold intervals; a probit/threshold
comparator; external GLLVM.jl/gllvmTMB parity. None gates this slice.
