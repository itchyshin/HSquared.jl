# Session Handoff: HSquared Twin To Claude

Meta: 2026-06-22 04:49 MDT. From Codex to Claude Code. This is a
file-backed handoff for both the Julia engine repo (`HSquared.jl`) and the R
public-interface repo (`hsquared`). Repository state is truth; this file is a
start packet.

## Critical Context

This is a twin-package system, not a single repo.

- `/Users/z3437171/Dropbox/Github Local/HSquared.jl` is the Julia engine lane.
- `/Users/z3437171/Dropbox/Github Local/hsquared` is the R-facing user
  interface, bridge, docs, and public-language lane.
- R owns public syntax and user claims; Julia owns engine reality.
- Green CI, green pkgdown, or a merged PR does not mean a partial capability is
  covered.

The clean checkpoint before this handoff:

- Julia `HSquared.jl`: `main` at `38286b1` (`Correct non-Gaussian bridge gap
  status (#154)`), aligned with `origin/main`, no open PRs.
- Julia remote checks: Pages `27924257024`, Documenter `27924194112`, and CI
  `27924194110` succeeded.
- R `hsquared`: `main` at `d4ec85d` (`Sync Julia non-Gaussian status correction
  (#97)`), aligned with `origin/main`, no open PRs.
- R remote checks: Pages `27924552655`, pkgdown `27924488120`, and PR #97
  R-CMD-check `27924407411` succeeded.
- R has two pre-existing untracked Codex handover files:
  `docs/dev-log/after-task/2026-06-21-codex-team-handover.md` and
  `docs/dev-log/handover/2026-06-21-codex-team.md`. Do not delete or stage them
  unless Shinichi explicitly asks.

The just-closed loop: non-Gaussian #44 wording ping-pong is closed. Both twins
now agree that R already has an opt-in `target = "nongaussian"` bridge for
Poisson/Binomial LA/VA fits. The remaining R-side activation gap is narrowly:
per-record varying-trial formula/bridge activation plus broader validation,
comparator, and calibration depth.

## What Was Accomplished

Most recent Julia lane:

- HSquared.jl PR #151 hardened the BLUPF90/AIREMLF90 multivariate starter packet
  to numeric, BLUPF90-ready artifacts. No executable comparator run was claimed.
- HSquared.jl PR #152 added the non-Gaussian parity fixture.
- HSquared.jl PR #153 mirrored R fixture consumption.
- HSquared.jl PR #154 corrected the too-broad non-Gaussian R bridge-gap wording,
  updated Julia #44, and left `V6-LAPLACE` partial.

Most recent R lane:

- hsquared PR #95 consumed the non-Gaussian parity fixture in Julia-free
  normalizer tests.
- hsquared PR #96 corrected stale R bridge-gap wording.
- hsquared PR #97 recorded HSquared.jl PR #154 as the final corrected Julia
  status mirror.

No covered/public status was promoted by these closing PRs. The v0.1 covered
public core remains the univariate Gaussian animal model by REML; other
surfaces are experimental, partial, or planned as recorded in each repo's
capability and validation ledgers.

## Current Working State

### Julia lane

- Path: `/Users/z3437171/Dropbox/Github Local/HSquared.jl`
- Branch: `main`
- Head: `38286b1`
- Open PRs: none at handoff.
- Open issues to remember: #61, #58, #56, #55, #54, #53, #52, #51, #50, #49,
  #48, #46, #44, #42, #41, #37, #8, #7, #6, #5.
- Current local tree after this handoff will include this new checkpoint file.

### R lane

- Path: `/Users/z3437171/Dropbox/Github Local/hsquared`
- Branch: `main`
- Head: `d4ec85d`
- Open PRs: none at handoff.
- Open issues to remember: #25, #24, #23, #22, #10, #9, #7, #6, #5.
- Current local tree already had the two untracked Codex handover files named
  above. This handoff also has a paired copy at
  `/Users/z3437171/Dropbox/Github Local/hsquared/docs/dev-log/handover/2026-06-22-claude-twin-handoff.md`.

## Key Decisions & Rationale

- Keep R and Julia lane boundaries strict. Claude should plan, review, and
  polish; Codex should run live Julia/R checks, simulations, bridge tests, and
  comparator executables.
- Do not use REML or AI-REML wording for non-Gaussian paths unless the repo
  already documents the exact method and evidence. For these recent
  non-Gaussian paths, preserve the project wording around Laplace/VA marginal
  fits and the known Bernoulli information limitation.
- Do not promote `partial` to `covered` without implementation, tests, docs,
  status ledgers, validation-debt updates, issue updates, and Rose claim audit.
- Treat BLUPF90/JWAS/MCMCglmm/sommer evidence precisely:
  - `sommer` is one same-estimand multivariate comparator leg.
  - `MCMCglmm` is Bayesian/MCMC agreement evidence, not same-estimand REML
    parity.
  - JWAS evidence is cross-estimator/Bayesian agreement unless the target is
    explicitly same-estimand.
  - BLUPF90/AIREMLF90 packet readiness is not executable comparator evidence.

## Files Created / Modified

Created by this handoff:

- `/Users/z3437171/Dropbox/Github Local/HSquared.jl/docs/dev-log/recovery-checkpoints/2026-06-22-claude-twin-handoff.md`
- `/Users/z3437171/Dropbox/Github Local/hsquared/docs/dev-log/handover/2026-06-22-claude-twin-handoff.md`

Pre-existing untracked R handover files, intentionally preserved:

- `/Users/z3437171/Dropbox/Github Local/hsquared/docs/dev-log/after-task/2026-06-21-codex-team-handover.md`
- `/Users/z3437171/Dropbox/Github Local/hsquared/docs/dev-log/handover/2026-06-21-codex-team.md`

No code or capability file is intentionally changed by this handoff.

## Next Immediate Steps

For Claude, start with orientation and planning:

1. Read this file first.
2. Read `/Users/z3437171/shinichi-brain/AGENTS.md`.
3. Read `/Users/z3437171/shinichi-brain/protocols/handoff.md`.
4. Read `HSquared.jl/AGENTS.md`.
5. Read `hsquared/AGENTS.md`.
6. Re-run the live state checks below before planning anything.

Best next work choices:

1. Comparator route (#49/#41/#10): decide the narrowest executable-backed
   comparator leg to pursue next. Highest value is a second independent
   same-estimand comparator for multivariate REML beyond `sommer`, or a
   BLUPF90/AIREMLF90 executable run from the hardened packet if executables are
   available. If executables are absent, record that as a blocker, not as
   evidence.
2. Fitted Mrode #46 continuation: confront the fitted target with a published
   or independently reproducible animal-model output path. Keep supplied-VC
   Mrode anchors separate from estimated-VC fitted evidence.
3. Non-Gaussian #44 continuation: plan the R per-record varying-trial formula
   and bridge activation. This is a bridge/API slice plus validation planning;
   live tests and JuliaCall checks should come back to Codex.
4. Marker-threshold #48/#23: plan calibrated threshold evidence, but do not
   activate R thresholds or public genome-wide-significance claims without a
   real calibration/comparator leg.
5. Structured covariance #42/#22: keep diagonal/unstructured banked, but leave
   lowrank/factor-analytic activation gated on loading exposure, rotation
   convention, comparator/calibration evidence, and R grammar design.

## Blockers / Open Questions

- External same-estimand comparator evidence remains the main promotion blocker.
- BLUPF90-family executables were previously absent on the R machine; verify
  live before planning around them.
- Per-record varying-trial Binomial support exists in Julia, but R formula and
  live bridge activation remain open.
- Calibrated marker thresholds remain inactive in R.
- Production sparse/large-pedigree claims need benchmarks and validation, not
  just correctness tests.

## Gotchas & Failed Approaches

- Do not collapse "fixture consumed" into "public workflow active".
- Do not collapse "R opt-in bridge exists" into "public default" or "covered".
- Do not call VA `logLik` comparable to Laplace `logLik`; VA is an ELBO/lower
  bound.
- Do not treat issue-body sync PRs as capability evidence.
- Do not stage or delete the pre-existing untracked R handover files.
- GitHub App writes may return `403`; use the authenticated `gh` CLI when
  needed.

## How To Resume

Pasteable live checks:

```sh
cd "/Users/z3437171/Dropbox/Github Local/HSquared.jl"
git status --short --branch
git log --oneline --decorate -8
gh run list --limit 8
gh pr list --state open --limit 20
gh issue list --state open --limit 30
```

```sh
cd "/Users/z3437171/Dropbox/Github Local/hsquared"
git status --short --branch
git log --oneline --decorate -8
gh run list --limit 8
gh pr list --state open --limit 20
gh issue list --state open --limit 30
```

Julia checks when Codex resumes execution:

```sh
cd "/Users/z3437171/Dropbox/Github Local/HSquared.jl"
julia --project=. -e 'using Pkg; Pkg.test()'
julia --project=docs docs/make.jl
```

R checks when Codex resumes execution:

```sh
cd "/Users/z3437171/Dropbox/Github Local/hsquared"
air format .
Rscript --vanilla -e 'devtools::test()'
Rscript --vanilla -e 'pkgdown::check_pkgdown()'
_R_CHECK_FORCE_SUGGESTS_=false Rscript --vanilla -e 'rcmdcheck::rcmdcheck(args = c("--no-manual", "--as-cran"), error_on = "error")'
```

For Claude: do not run a long live validation claim from chat memory. Draft the
plan, identify the exact executable/data dependency, then hand execution back
to Codex if it needs real Julia/R toolchain work.
