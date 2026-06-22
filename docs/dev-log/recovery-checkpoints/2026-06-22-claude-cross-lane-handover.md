# Claude Cross-Lane Handover Mirror: HSquared.jl

Meta: 2026-06-22 America/Edmonton · from Codex Julia twin checkpoint · to
Claude session · mirror of the R-lane handoff

## Critical Context

This is the Julia-side mirror of the R handoff in:

`/Users/z3437171/Dropbox/Github Local/hsquared/docs/dev-log/recovery-checkpoints/2026-06-22-claude-cross-lane-handover.md`

Start from live repository state, not chat memory.

- Julia repo: `/Users/z3437171/Dropbox/Github Local/HSquared.jl`, `main` at
  `38286b1` (`Correct non-Gaussian bridge gap status (#154)`), clean before the
  handoff branch.
- R repo: `/Users/z3437171/Dropbox/Github Local/hsquared`, `main` at
  `d4ec85d` (`Sync Julia non-Gaussian status correction (#97)`), with only the
  handoff files changed on its handoff branch.
- GitHub PR state checked during handoff: no open PRs in `itchyshin/HSquared.jl`
  and no open PRs in `itchyshin/hsquared`.
- Latest checked Julia main evidence: `CI` run `27924194110` and `Documenter`
  run `27924194112` succeeded for `38286b1`.

If this handoff branch has been merged, the commit containing this file is the
fresh-session start boundary. If it has not been merged, start from Julia main
`38286b1` and treat this file as a local checkpoint.

This file is the primary current Julia-side checkpoint. The same handoff branch
also contains the earlier same-session packet
`docs/dev-log/recovery-checkpoints/2026-06-22-claude-twin-handoff.md`; keep it
as useful context, but prefer this cross-lane mirror for the final start order.

## What Was Accomplished

The latest banked Julia slice was PR #154:

- Corrected Julia issue/status wording for non-Gaussian bridge status.
- Credited the existing opt-in R `target = "nongaussian"` bridge for
  `poisson(log)` and `binomial(logit)`.
- Kept the remaining R-side gap narrow: per-record varying-trial
  formula/bridge activation, plus broader validation/comparator/calibration
  depth.
- Preserved the boundary: no Julia behavior change, no R files touched, no
  external comparator evidence, no interval calibration, no public default, and
  no validation/public-claim promotion.

The R side then banked PR #97, recording this corrected Julia mirror. The
non-Gaussian status ping-pong is closed from the Julia side unless a future
source-doc or issue-body gap is found.

## Current Working State

- Working:
  - Julia main is clean at `38286b1`.
  - Recent Julia PRs #151-#154 are banked and green.
  - The Julia fixture/status surface now includes the non-Gaussian parity
    fixture and corrected R bridge-status wording.
- In progress / partial:
  - `V6-LAPLACE` remains partial. Per-record `n_trials` exists in the Julia
    engine lineage, but R formula/bridge activation for varying trials remains
    a separate R-lane follow-up.
  - `V4-MV-REML` remains partial. The same-estimand sommer evidence exists, but
    the second independent same-estimand comparator beyond sommer remains open.
  - BLUPF90 packet generation is hardened, but no BLUPF90-family executable run
    is recorded.
  - Structured lowrank/fa covariance payload and loading exposure remain open.
- Blocked locally:
  - Prior Julia checks recorded missing `renumf90`, `airemlf90`, `blupf90`,
    `remlf90`, and `gibbsf90` on PATH, so BLUPF90-family evidence is not
    available from this host.

## Key Decisions & Rationale

- Keep Julia as the engine reality. Do not use this handoff to change R syntax
  or user-facing claims.
- Treat this mirror as coordination evidence only. It does not add validation
  evidence or promote any validation row.
- For Claude: use this repo for status/prose/diff review unless the environment
  can run Julia checks. Live engine changes and comparator runs should return to
  Codex if Claude cannot execute them.

## Files Created / Modified By This Handoff

In `HSquared.jl`:

- already present on the handoff branch and preserved:
  `docs/dev-log/recovery-checkpoints/2026-06-22-claude-twin-handoff.md`
- `docs/dev-log/recovery-checkpoints/2026-06-22-claude-cross-lane-handover.md`
- `docs/dev-log/check-log.d/2026-06-22-claude-cross-lane-handover.md`
- `docs/dev-log/after-task/2026-06-22-claude-cross-lane-handover.md`

The paired R handoff touches the matching recovery checkpoint, after-task
report, check-log, and coordination board in `hsquared`.

## Next Immediate Steps

Recommended Claude start order for the Julia side:

1. Read `/Users/z3437171/shinichi-brain/AGENTS.md`.
2. Read this repo's `AGENTS.md`.
3. Read this handoff file.
4. Read
   `docs/dev-log/check-log.d/2026-06-21-r-nongaussian-bridge-gap-correction.md`
   and
   `docs/dev-log/after-task/2026-06-21-r-nongaussian-bridge-gap-correction.md`.
5. Run:

```sh
cd "/Users/z3437171/Dropbox/Github Local/HSquared.jl"
git status --short --branch
gh pr list --repo itchyshin/HSquared.jl --state open --limit 20
gh run list --repo itchyshin/HSquared.jl --branch main --limit 5
```

Then read the R handoff packet and choose one narrow cross-lane slice.

## Blockers / Open Questions

- Does the next machine have BLUPF90-family executables? If not, keep #49
  comparator evidence blocked.
- Should the next slice be R per-record varying-trial activation, a comparator
  runbook, or a Julia/R status-board stale-row cleanup?
- Should the Julia `AGENTS.md` live phase snapshot be refreshed? It contains
  historical context, but repo state and current check-log files remain the
  truth. Treat any such update as a separate docs-only slice.

## Gotchas & Failed Approaches

- Packet generation is not comparator evidence.
- MCMCglmm agreement is not same-estimand REML parity.
- R normalizer handling of serialized vector `n_trials` is not the same as
  live R formula activation for per-record varying trials.
- Do not make a capability promotion from this handoff.

## How to Resume

Paste this to Claude after reading the R handoff:

```text
You are in the Julia engine twin for hsquared.

Start path:
/Users/z3437171/Dropbox/Github Local/HSquared.jl

Pre-handoff checkpoint:
Julia main 38286b1, R main d4ec85d, no open PRs in either repo when checked.

Goal:
Continue from the cross-lane handoff without changing claims. Pick one narrow
slice. Keep Julia as engine reality and R as user-language reality. If a task
needs live Julia/R execution or comparator binaries unavailable to Claude, route
it back to Codex.
```

No widget/dashboard is currently running or required for this handoff.
