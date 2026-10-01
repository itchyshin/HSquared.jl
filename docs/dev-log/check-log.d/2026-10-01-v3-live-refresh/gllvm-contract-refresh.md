# GLLVM.jl automatic-rank contract refresh, 2026-10-01

Read-only scout for HSquared automatic FA rank follow-on. No fits or simulations run.

## State inspected

- Checkout: `/Users/z3437171/Dropbox/Github Local/GLLVM.jl`, `HEAD=ba5c5068abd2db379f573ac5fa3a252b435d6936` (`docs/claude-handover-20260924`); worktree reported two uncommitted paths (`.worktrees/`, `docs/dev-log/inbox/`), left untouched.
- Cached `origin/main=7b2f155439f2e63eec251eca7a420b2e147e6d8b` (2026-10-01, merge #656). The previously documented reference commit `dbd229a02166b650341ba4f90743b03a8158abec` is an ancestor of this cached main. `git fetch origin main` was attempted and denied because sandbox permissions prevent writing `.git/FETCH_HEAD`; therefore this receipt does not claim a fresh remote refresh or current GitHub/PR status.
- Owner-supplied live verification after the initial scout: read-only `gh api repos/itchyshin/GLLVM.jl/commits/main --jq '.sha'` returned `7b2f155439f2e63eec251eca7a420b2e147e6d8b`, matching cached `origin/main`. The repository remote URL is `git@github.com:itchyshin/GLLVModels.jl.git`. This establishes live main SHA only; the earlier fetch failure remains recorded, and no hosted PR status was checked.
- Automatic-rank history on cached refs includes merged PR #518 (`620ded69039012e6a59391c68734fb7f3b74ddde`), earlier selector commits `5a8ba3180`, `f0dfd4466`, `74db53059`, `e77ca2ec6`, `9ced6500e`, and later parity work on `origin/claude/true-parity-select-lv-twin` (`06a409ab6a75ec77af272e7b240bdcd967fab522`), merged into `origin/claude/true-parity-isdm-546-wire` (`b57ce64f0f8e0a1cf582af7653e0607a44ad2543`). A cached closeout branch exists at `origin/claude/auto-d-lanekit-closeout-20260929` (`98a1a46e0`). These branch names/refs do not establish their current hosted PR state.

## Current main contract (source: cached `origin/main`)

- `fit_gllvm(Y; K omitted)` runs `select_lv` for `K=1:Kmax`; default `Kmax=min(5,p-1)`. Explicit `Kmax` is only allowed when K is omitted. `Kmax>=1`; hence one-response auto selection errors at the bound. `Multinomial` is exempt (fixed-effects, no LV). The default route refuses K omission with `row_eff` or `pervar`; it forwards other supported fit keywords, including `disp_group`, to selection. Source: `src/families/fit_gllvm.jl` at `7b2f1554`, lines 160-167, 208-234.
- `select_lv` sweeps `1:Kmax` and accepts criteria `:bic_sites` (default, log(number of observed sites)), `:bic` (log observed cells, respecting mask), and `:aic`; `Kmax` defaults to 3 for direct `select_lv` calls. Each attempted K appears in `attempts`; accepted fits and criteria are separate aligned vectors. Source: `src/model_selection.jl` at `7b2f1554`, lines 202-223, 291-309.
- Rejection guards: thrown fit, runaway loading, and an objective below the best converged/non-runaway smaller-K bar beyond `max(tol,1e-6*abs(bar))`. A fit that is merely unconverged is retained by default and flagged; `require_converged=true` rejects it. For single-trial Binomial on the Laplace default route, loading ridge defaults to 2.0 unless overridden or disabled with `binary_ridge=Inf`; criteria use unpenalised likelihood at the penalised optimum, while the nesting guard uses the penalised objective. These special cases are GLLVM-specific and should not be ported as assumptions for HSquared. Source: `src/model_selection.jl` at `7b2f1554`, lines 137-183, 225-253, 255-300.
- With warm starts enabled, a rejected nonmonotone/unconverged/runaway fit can receive one retry from the last accepted fit padded with lower-triangular loading columns, if that fitter exposes β/Λ and accepts init keywords. A thrown fit is retained as failed and is not warm-retried. Interrupts propagate; K=1 configuration `ArgumentError` is rethrown. If no rank is accepted, selection errors with the attempt ledger in the message. Source: `src/model_selection.jl` at `7b2f1554`, lines 74-88, 246-304.
- Accepted K values are accumulated in increasing order; `argmin(crit)` returns the first minimum. Exact criterion ties therefore select the smallest accepted rank as an implementation consequence, not a published selector policy. No dedicated tie regression was found in `test/test_model_selection.jl` at `7b2f1554` (argmin assertions at lines 32-48; no tie fixture).

## Test coverage and gaps

`test/test_model_selection.jl` at `7b2f1554` covers an ordinary real sweep and criterion argmin (lines 3-49), explicit requested candidate range and `Kmax=1` through omitted-K tests (lines 221-243), retained thrown-fit diagnostics and warm-start behavior (lines 91-160), interrupt propagation, criterion options, masking, unconverged-default behavior, and Binomial ridge handling. No dedicated exact-tie test, multi-rank top-bound selection test, complete all-candidates-rejected diagnostic assertion, or real alternative-start robustness test was found. Existing source/docs also mark trait-order and response-scale stability as unestablished.

## Deviations / updates to HSquared follow-on note

Compared with `/Users/z3437171/.codex/worktrees/b9ae/HSquared.jl/docs/design/auto-fa-rank-follow-on.md` (read at current workspace state):

1. The note's stated contract remains substantially accurate. Refresh identifiers to cached main `7b2f1554...`, and qualify it as a cached local ref because remote fetch was blocked.
2. Add current single-trial Binomial ridge behavior and its narrow Laplace-route applicability; this is implementation-specific and has changed since the note's general summary.
3. Clarify retry scope: fit exceptions are recorded but are not retried; retry is for returned fits rejected by convergence/runaway/monotonicity checks.
4. The note is right that smallest-admissible-rank tie behavior is an implicit consequence and lacks a dedicated tie test. Make the policy explicit if HSquared adopts that design.
5. Automatic `K` is present through `fit_gllvm` and the core selector is in merged main per cached commit ancestry, but this evidence is not current GitHub state, R-side `d="auto"`, or HSquared R-Julia validation.

## Navigation/ownership note

`lane_preflight.sh` classified this repo as a live multi-lane checkout (12 active lanes, this checkout on a Claude handover branch, unrelated dirty paths). I made no repo edits. `graft map` / `graft ask` could not run because the `graft` executable is absent from PATH and was not located in the repo tool paths checked; source inspection therefore used cached main blobs directly after the preflight. `route.py` returned no load-first manifest for this repo path.
