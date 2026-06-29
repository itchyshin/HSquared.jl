# After-task — small-sample interval resumability + bootstrap subset — 2026-06-27

## Task goal

Complete the follow-on slices after the small-sample interval debt commit:
make the harness resumable, add diagnostic detail rows, run a focused bootstrap
subset, and write the decision checkpoint. No interval method or public claim is
introduced.

## Active lenses and spawned agents

Active lenses: Fisher, Curie, Grace, Rose.

Spawned agents: none.

## Live phase snapshot

HSquared.jl is on branch `codex/small-sample-interval-calibration`, one local
commit ahead of `main` at `d7effc79` before this slice. `origin/main` remains at
`5f378a8d` from the Codex handover snapshot. This slice is still validation
scaffold only: public-default covered surface remains v0.1 Gaussian, and no
covered capability or R-facing surface changes.

## Files changed

- `sim/phase1_small_sample_interval_calibration.jl`
- `docs/design/validation-debt-register.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/check-log.d/2026-06-27-small-sample-interval-resumable-bootstrap.md`
- `docs/dev-log/after-task/2026-06-27-small-sample-interval-resumable-bootstrap.md`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-plan.md`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-smoke.tsv`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-smoke-replicates.tsv`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-bootstrap-subset.tsv`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-bootstrap-subset-replicates.tsv`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-bootstrap-subset-summary.md`
- `docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-decision.md`

## What changed

The harness now writes a replicate-level detail TSV and can resume from it. Each
replicate is seeded deterministically from the master seed, design index, h2
index, and replicate number, so completed rows can be skipped without changing
later simulated data. The summary table is regenerated from deduplicated detail
rows and now includes `n_boot`.

Detail rows include fit status, near-boundary flag, failure reason, interval
bounds and widths, point estimates, standard error, Satterthwaite `df_eff`, and
bootstrap convergence counts. This makes the earlier SW negative result easier
to audit without promoting it.

The focused bootstrap subset (`reps=10`, `nboot=9`, small/medium designs,
`h2=0.4,0.7`) passed and wrote both summary and detail files. It is explicitly
triage-only because the MCSE is too large for coverage conclusions.

## Checks run and exact outcomes

- `julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=1 --bootstrap=false --designs=tiny:2:4:8 --h2=0.4 --levels=0.95 --out=/tmp/hsq_tcal_resume_summary.tsv --detail-out=/tmp/hsq_tcal_resume_detail.tsv --resume=false`
  -> passed; detail file had one header plus 9 method rows.
- Same command with `--resume=true`
  -> passed; detail file stayed at 10 lines.
- `julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=2 --nboot=3 --resume=false --out=docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-smoke.tsv`
  -> passed; summary has 11 method rows plus header and detail has 22 method rows plus header.
- Same smoke command with `--resume=true`
  -> passed; detail file stayed at 23 lines.
- `julia --project=. sim/phase1_small_sample_interval_calibration.jl --reps=10 --nboot=9 --resume=false --designs=small:8:16:96,medium:16:32:192 --h2=0.4,0.7 --levels=0.95 --out=docs/dev-log/recovery-checkpoints/2026-06-27-small-sample-interval-calibration-bootstrap-subset.tsv`
  -> passed; summary has 44 method rows plus header and detail has 440 method rows plus header.
- Same bootstrap command with `--resume=true`
  -> passed; detail file stayed at 441 lines.
- DRAC SSH probe:
  `vulcan`, `trillium`, `rorqual`, `nibi`, `narval`, and `fir` responded; `mibi`
  did not resolve; shallow Vulcan/Fir searches found no existing `HSquared.jl`
  checkout; no compute was run on a login node.
- `git diff --check`
  -> passed.
- `julia --project=. -e 'using HSquared; rows=validation_status(); println("rows=", length(rows)); println("planned=", count(r -> getproperty(r, :status) == "planned", rows)); println("covered=", count(r -> getproperty(r, :status) == "covered", rows));'`
  -> `rows=48`, `planned=1`, `covered=5`.
- `julia --project=. -e 'using Pkg; Pkg.test()'`
  -> passed; retained the existing stale-manifest warning recommending `Pkg.resolve()`.
- `julia --project=docs docs/make.jl`
  -> passed; retained existing Documenter docstring-list warnings and npm audit warnings.
- Rose targeted scan for t-calibration / Satterthwaite / promotion wording
  -> clean-with-limitations; hits are fenced as "do not expose", "triage only",
  "not promotion-grade", or "no public/R-facing claim".

## Public claim audit

Rose verdict: clean-with-limitations. The limitation is intentional: the new
bootstrap subset is tiny and only proves the path is wired and resumable. No
interval-method implementation, no default change, no `validation_status()` row,
no capability-status promotion, and no R-facing wording were added.

## Tests of the tests

The resume test reran identical commands and checked detail-file line counts.
The bootstrap subset checked both bootstrap interval rows and summary generation
from the detail rows. The detail schema records failure reasons and df/width
diagnostics needed for future DRAC-scale runs.

## Coordination notes

The user noted access to Vulcan, Trillium, Rorqual, Nibi, Narval, and Fir.
Aliases are live except `mibi` (unresolved typo). A larger run should stage this
branch on DRAC `/project` and submit through SLURM arrays.

## What did not go smoothly

No cluster-side checkout was found on Vulcan/Fir by a shallow search, so the
focused subset was run locally rather than on DRAC. This was acceptable for the
small triage grid but not for promotion-grade evidence.

## Known limitations

The df problem remains unresolved. The SW probe is still diagnostic only, and
bootstrap subset MCSE is too high for coverage claims.

## Next actions

1. Commit this slice separately from the debt/harness baseline commit.
2. Stage or clone the branch on DRAC `/project`.
3. Submit a predeclared larger resumable grid via SLURM arrays.
4. Keep any prototype interval method blocked until Fisher + Curie + Rose review
   of a stronger effective-df derivation and coverage evidence.
