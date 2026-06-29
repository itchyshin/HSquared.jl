# Session Handoff: HSquared.jl small-sample interval calibration PR

Meta: 2026-06-29 · from Codex · to Claude · context high enough to hand off cleanly

You are Claude, picking up the HSquared.jl small-sample interval calibration
branch. The branch is a validation-scaffold PR, not a method-promotion PR.

## Mission Control Widget

| Repo | Branch / main | CI / checks | What shipped | Plan by leverage |
| --- | --- | --- | --- | --- |
| `HSquared.jl` (Julia engine) | branch `codex/small-sample-interval-calibration` on top of `main` `5f378a8d` | Local `Pkg.test()`, docs build, `validation_status()` and `git diff --check` passed before handover; latest visible GitHub runs green for Pages/Documenter/CI on the 2026-06-28 handover PR and latest main docs push; this branch PR should be watched after push | Planned debt row `V1-HERIT-TCAL`; ADEMP plan; local freqTLS + NotebookLM scouts; resumable Gaussian interval-calibration harness; smoke, 200-rep no-bootstrap triage, 10-rep/9-bootstrap subset; decision checkpoint saying do not expose t/Satterthwaite calibration yet | 1. Review this PR and tell the human when CI/Rose make it merge-ready; do not auto-merge. 2. For real coverage evidence, stage this branch on DRAC `/project` and submit SLURM arrays. 3. Only after stronger evidence revisit interval-method implementation. 4. Larger independent lanes remain V4 external comparator and GPU Track B G2-G5. |
| `hsquared` (R public twin) | clean `main` aligned with `origin/main` at `8c5c886` (#112) | Latest visible R-side runs green: Pages/pkgdown on `main`, and the #112 R-CMD-check PR run green; no R files changed in this slice | R CI was greened before this branch by fixing the validation-status non-ASCII warning; `em_warmup` R parity already landed in #111; no small-sample interval surface exists or changed in R | Keep R as public-language owner but do not add R wording/API for t/Satterthwaite calibration until Julia has implementation + tests + docs + status/debt updates + Fisher/Curie/Rose evidence. If this Julia branch merges, only mirror status language later if needed, still fenced as planned/triage. |

## Critical Context

- Covered surface is still v0.1 univariate Gaussian only. This branch must not
  grow the public/API/R-facing interval surface.
- R twin `hsquared` is currently clean on `main` at `8c5c886`; this branch does
  not edit R files and should not imply an R interval-calibration feature.
- Current Gaussian intervals are asymptotic: normal-z delta/Wald and chi-square
  profile-LRT. The parametric bootstrap is finite-sample-aware but opt-in and not
  coverage-calibrated.
- The branch deliberately records negative/triage evidence: residual/family t
  probes did not win cleanly, and the current Satterthwaite scaled-chi-square
  probe is unstable in low-h2 small designs.
- Two foreign untracked files are present locally and must never be staged:
  - `docs/dev-log/recovery-checkpoints/2026-06-22-r-twin-nongaussian-per-record-trials-spec.md`
  - `sim/phase6_nongaussian_interval_coverage.tsv`

## Goals / Mission

HSquared.jl is the Julia computational twin of the R package `hsquared`. The R
package owns the public user language; this repo owns engine reality. Capability
claims must remain evidence-gated: implementation + tests + docs +
capability/status/debt surfaces + Rose audit + comparator evidence where the
gate names one.

For this branch, the goal is narrow: make the small-sample interval-calibration
debt and harness recoverable and reviewable, while blocking premature
t-calibrated/Satterthwaite interval claims.

## Plans / Roadmap

Near-term lane:

1. Package/review/merge this branch without changing interval behavior.
2. Stage the branch on DRAC `/project` if larger simulation evidence is desired.
3. Run a predeclared, resumable SLURM-array coverage grid only after the staged
   checkout exists.
4. Keep profile-LRT and bootstrap as the safer finite-sample interval families
   to calibrate before considering any public prototype interval method.

Do not start with an API implementation. The df/effective-reference problem is
the hard part and remains unresolved.

## What Was Accomplished

Two commits are on the branch before this handover:

- `d7effc79 docs: bank small-sample interval calibration debt`
  - Added planned validation-debt row `V1-HERIT-TCAL`.
  - Added the ADEMP plan, df/grid checkpoint, freqTLS transfer note, NotebookLM
    SW/Satterthwaite scout, smoke TSV, 200-rep no-bootstrap triage TSV/summary,
    check-log, after-task report, and first opt-in harness.
- `6581828f sim: make interval calibration harness resumable`
  - Refactored `sim/phase1_small_sample_interval_calibration.jl` to write a
    replicate-level detail TSV and regenerate summaries from deduplicated rows.
  - Added `--detail-out` and `--resume=true|false`.
  - Made replicate seeds deterministic by master seed, design index, h2 index,
    and replicate number.
  - Added detail diagnostics: fit status, near-boundary flag, failure reason,
    bounds/width, fitted VCs, `h2_hat`, variance-component SE, Satterthwaite
    `df_eff`, `n_boot`, and bootstrap convergence count.
  - Added a focused bootstrap subset (`reps=10`, `nboot=9`, small/medium,
    `h2=0.4,0.7`) as wiring/resume evidence only.
  - Added a decision checkpoint: do not expose t/Satterthwaite calibration yet.

## Current Working State

- Working:
  - Branch: `codex/small-sample-interval-calibration`.
  - R twin `hsquared`: local `main` clean and aligned with `origin/main` at
    `8c5c886` (#112); latest visible Pages/pkgdown and #112 R-CMD-check signals
    are green.
  - Local branch contains the two commits above plus this handover/snapshot commit
    once committed.
  - Local validation before this handover:
    - `git diff --check` passed.
    - `validation_status()` reported `rows=48`, `planned=1`, `covered=5`.
    - `julia --project=. -e 'using Pkg; Pkg.test()'` passed.
    - `julia --project=docs docs/make.jl` passed with existing Documenter
      docstring-list warnings and npm audit warnings.
  - `gh run list --limit 5` on 2026-06-29 showed latest main docs/CI green and
    a separate 2026-06-28 handover PR green.
- In progress:
  - This handover doc and the AGENTS snapshot pointer are being committed on the
    same feature branch.
  - The branch still needs to be pushed and opened as a PR. Do not auto-merge.
- Not working / blocked:
  - No existing `HSquared.jl` checkout was found by shallow searches on
    Vulcan/Fir project/home roots, so DRAC-scale runs require staging or cloning
    the repo first.
  - `mibi` did not resolve as an SSH alias; `nibi` did.

## Key Decisions & Rationale

- Keep `V1-HERIT-TCAL` as `planned`, not `partial` or `covered`, because no
  interval method was implemented and the coverage evidence is triage-only.
- Do not transfer the `freqTLS` `n_obs - length(par)` df rule into HSquared.jl:
  animal-model BLUPs are integrated out, and the df target must be derived or
  empirically justified.
- Keep Satterthwaite/KR fixed-effect denominator-df machinery separate from
  variance-component interval calibration. For `sigma_a2`, the candidate family
  is scaled chi-square moment matching, but the current probe is unstable.
- Treat the bootstrap subset as path/resume evidence only. With `reps=10`,
  coverage MCSE is far too high for calibration claims.
- Larger runs belong on DRAC via SLURM arrays, not on login nodes and not on the
  local Mac as promotion evidence.

## Files Created / Modified

Branch diff from `main` before this handover:

- `docs/design/validation-debt-register.md`
- `docs/dev-log/after-task/2026-06-27-small-sample-interval-calibration-debt.md`
- `docs/dev-log/after-task/2026-06-27-small-sample-interval-resumable-bootstrap.md`
- `docs/dev-log/check-log.d/2026-06-27-small-sample-interval-calibration-debt.md`
- `docs/dev-log/check-log.d/2026-06-27-small-sample-interval-resumable-bootstrap.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-bootstrap-subset-summary.md`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-bootstrap-subset-replicates.tsv`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-bootstrap-subset.tsv`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-decision.md`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-plan.md`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-smoke-replicates.tsv`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-smoke.tsv`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-triage-summary.md`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-triage.tsv`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-df-and-grid.md`
- `docs/dev-log/scout/2026-06-27-freqtls-t-calibration-transfer.md`
- `docs/dev-log/scout/2026-06-27-notebooklm-sw-mixed-model-calibration.md`
- `sim/phase1_small_sample_interval_calibration.jl`

Handover commit adds/modifies:

- `AGENTS.md`
- `docs/dev-log/handover/2026-06-29-claude-handover.md`

Never-commit local files still untracked:

- `docs/dev-log/recovery-checkpoints/2026-06-22-r-twin-nongaussian-per-record-trials-spec.md`
- `sim/phase6_nongaussian_interval_coverage.tsv`

## Next Immediate Steps

1. Rehydrate:
   - Read `AGENTS.md`.
   - Read this handover.
   - Run/follow `.agents/skills/hsquared-rehydrate/SKILL.md`.
   - Read `docs/dev-log/coordination-board.md`,
     `docs/design/validation-debt-register.md`,
     `docs/design/capability-status.md`,
     `docs/dev-log/check-log.d/2026-06-27-small-sample-interval-calibration-debt.md`,
     `docs/dev-log/check-log.d/2026-06-27-small-sample-interval-resumable-bootstrap.md`,
     and the two after-task reports for this lane.
2. Before any outward claim, run a Rose claim-vs-evidence pass. The intended
   verdict should remain clean-with-limitations.
3. Push/open/watch the PR if Codex has not already done so, or inspect the PR
   opened from this branch. Do not auto-merge.
4. If CI fails, fix only branch-local issues and keep the two foreign untracked
   files out of staging.
5. If planning the next technical slice, write a DRAC staging/SLURM-array plan
   for the resumable harness rather than implementing an interval API.

## Blockers / Open Questions

- No staged DRAC checkout was found. A larger run needs a clone or rsync to
  `/project/aip-snakagaw` or `/project/def-snakagaw`, plus module/Julia setup.
- No animal-model df/effective-reference derivation exists yet.
- The current SW probe is not a promotion candidate. A better df target or
  scaled-reference derivation is needed before rerunning broadly.
- PR URL may not be embedded in this doc if the PR is opened after this commit;
  use `gh pr view --web` or `gh pr list --head codex/small-sample-interval-calibration`.

## Gotchas & Failed Approaches

- Do not `git add -A`; it will catch the two foreign untracked files.
- Do not run simulation compute on DRAC login nodes. Submit via SLURM.
- Do not interpret the 10-rep bootstrap subset as coverage evidence.
- Do not claim t-calibrated intervals exist. The branch explicitly says they do
  not.
- Do not move `V1-HERIT-TCAL` from `planned`.
- `mibi` is not a valid SSH alias in this environment; use `nibi`.

## TARGET-tuned Rehydration Recipe For Claude

Claude should use the repo's rehydrate skill and then review/plan, not assume it
has the same live Julia/DRAC toolchain Codex used.

Recommended read order:

1. `AGENTS.md`
2. `docs/dev-log/handover/2026-06-29-claude-handover.md`
3. `.agents/skills/hsquared-rehydrate/SKILL.md`
4. `docs/dev-log/coordination-board.md`
5. `docs/design/validation-debt-register.md`
6. `docs/design/capability-status.md`
7. `docs/dev-log/after-task/2026-06-27-small-sample-interval-calibration-debt.md`
8. `docs/dev-log/after-task/2026-06-27-small-sample-interval-resumable-bootstrap.md`

Claude should spawn/use the Rose lens before any public or PR-description claim.
If live Julia fits, DRAC staging, or large simulations are needed, hand that
back to Codex or run through an authenticated live toolchain session.

## How to Resume

From the repo root in an authenticated terminal, paste:

```sh
claude "Rehydrate from docs/dev-log/handover/2026-06-29-claude-handover.md + the AGENTS.md snapshot, then continue with the Next Immediate Steps."
```
