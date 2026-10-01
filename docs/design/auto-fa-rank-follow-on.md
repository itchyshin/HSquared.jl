# Automatic FA rank selection follow-on

## Scope boundary

The current 0.10 FA acceptance cell remains a fixed-rank Gaussian T=4, K=1 model. Its implementation, recovery, and bridge evidence must be judged at that fixed cell; it does not depend on automatic selection. The user has said work on `d = "auto"` is underway. The current twin candidate inspected for this arc still supplies `rank = 1L` to the bounded R route, so automatic selection is tracked separately and is not claimed complete here.

## Evidence required before calling automatic selection usable

Before the public route chooses rank for users, freeze and document:

1. The exact selection rule, candidate rank range, boundary handling, tie behavior, and returned diagnostics. Rank selection must be distinguishable from a fitted fixed-rank model.
2. An independently checkable reference for selected ranks and fit criteria, including rank-zero/no-signal, weak-factor, separated-factor, and upper-bound cases. Preserve every failure, non-convergence, and selected-rank result in the denominator.
3. Stability checks for trait permutation and units, with explicit limits where floors or selection criteria are scale-dependent. Check ordinary starts and restarts; do not initialize at true loadings in recovery tests.
4. R-Julia parity for selected rank, final covariance, convergence/failure status, and user diagnostics. Unsupported families, missingness patterns, and rank ranges must fail clearly until separately validated.
5. Visible documentation that users may retain a fixed rank and that automatic choice is a model-selection result with finite-sample uncertainty, not proof of the true biological rank.

The selected-rank distribution and recovery diagnostics are the primary validation outputs. The single successful fit or an optimizer's chosen rank alone is insufficient.

## GLLVM.jl reference checked 2026-09-30

The GLLVM.jl project reports automatic rank selection as merged on its main
branch. I checked `origin/main` at `dbd229a02166b650341ba4f90743b03a8158abec`,
including `src/model_selection.jl` and `src/families/fit_gllvm.jl`; PR #629 is
the recorded integration. This is a design reference, not HSquared validation
or code copied into this package.

In that Julia API, omitting `K` from the default `fit_gllvm` route runs a guarded
sweep over `K = 1:Kmax`; the default upper bound is `min(5, p - 1)`. The default
criterion is `:bic_sites`, with penalty `log(number of observed sites)`. Its
`:bic` option instead uses `log(number of observed cells)`, and `:aic` is also
available. `select_lv` returns the chosen fit and a record for every attempted
rank. A one-time warm-start retry is available; failed, runaway, or materially
non-monotone candidates are excluded. By default an unconverged result is not
excluded solely for that status, while `require_converged=true` requests strict
rejection. Under the single-trial Binomial Laplace route, a loading ridge can be
used; criteria use unpenalised likelihood at the ridge optimum, while the
nested-model guard uses its penalised objective. Rank-dependent inference is
reported as conditional on the selected rank.

The useful design pattern is to retain explicit fixed-rank fitting and make
automatic selection return the selected fit together with its complete attempt
table and diagnostics. The thresholds and Binomial ridge are specific to the
GLLVM loading parameterisation and its validation evidence. They must not be
copied into HSquared FA or genetic GLLVM without a separate estimand and recovery
study. The GLLVM project reports that its R-side `d = "auto"` work is on a
separate protected gllvmTMB branch; it is not evidence of HSquared R-Julia
parity.

The current GLLVM.jl implementation appends accepted ranks in increasing order
and uses Julia's `argmin`, so an exact criterion tie selects the smallest
accepted rank. This behavior is not stated as a public policy and has no
dedicated tie regression. Its selector tests cover a real ordinary-start sweep,
the requested candidate range and `Kmax = 1`, failure retention, interrupt
handling, and synthetic warm-start padding/retry. They do not establish
trait-order or response-scale invariance, real alternate-start robustness,
selection of the top rank in a multi-rank sweep, or a complete all-candidates-
rejected diagnostic. HSquared should state the smallest-admissible-rank tie rule
explicitly and add these checks to its own follow-on acceptance set.

## Status

Queued as a separate usability follow-on. No automatic-rank implementation, validation result, R-Julia parity evidence, capability-status row, or release claim is accepted by this note. No GPU work is part of the follow-on.
