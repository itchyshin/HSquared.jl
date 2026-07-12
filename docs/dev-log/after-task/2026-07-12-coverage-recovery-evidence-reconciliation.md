# After task: coverage/recovery evidence reconciliation

## 1. Goal

Determine whether the four merged coverage/recovery drivers still required execution, then
leave HSquared.jl with truthful, repo-visible evidence without duplicate compute or an
unsupported capability promotion.

## 2. Implemented

- Ran the mandatory git-first prior-work sweep across branches, worktrees, stashes, recent
  commits, repo dev logs, the R twin, and the second-brain index.
- Found that the requested campaigns had already run on DRAC `fir` before the driver branch
  merged to `main`.
- Independently rechecked SLURM accounting, exact submit lines, driver commit identity, raw
  TSV row/distinct-seed counts, machine-readable gate output, and checksum-manifest digests.
- Added a Julia-side recovery checkpoint with exact job IDs, outcomes, fingerprints, and
  claim fences.
- Replaced the stale coordination-board instruction to run the jobs with the verified
  evidence and the doc-34 R4 anti-rescue rule.
- Updated the repeatability capability row to record the confirm-tier banked negative while
  keeping its status experimental.
- Submitted no new compute and changed no code, tests, API, bridge payload, or public count.

## 3a. Decisions and Rejected Alternatives

- Rejected blindly executing the handoff. The repository/twin sweep is newer and showed the
  exact work was already complete.
- Rejected rerunning the 2,000-replicate repeatability confirm. Its marginal fail is the
  preregistered result; doc 34 R4 prohibits a reseeded or higher-replicate rescue.
- Rejected retroactively editing the executed supplied-K driver to replace its human-readable
  `screening tier` label. The confirm submit line (`SK_NSEEDS=2000,SK_TAG=confirm`), 2,000
  distinct rows per cell, and machine-readable result establish the run; the wording mismatch
  is preserved and disclosed.
- Rejected capability promotion. C1 is directional-conservative rather than nominally
  calibrated; C8 sharpens an existing boundary; supplied-K still owes the rest of its
  promotion chain; repeatability failed its confirm gate.

## 4. Files Touched

- `AGENTS.md`
- `docs/design/capability-status.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/phase-snapshot-archive.md`
- `docs/dev-log/recovery-checkpoints/2026-07-12-coverage-recovery-evidence-reconciliation.md`
- `docs/dev-log/check-log.d/2026-07-12-coverage-recovery-evidence-reconciliation.md`
- `docs/dev-log/after-task/2026-07-12-coverage-recovery-evidence-reconciliation.md`
- `docs/dev-log/after-task/2026-07-12-campaign-provenance-reconciliation.md`

## 5. Checks Run

- Local git sweep: clean `main` at `a6955220`; driver head `2a473b8d` is in `main`; no
  stash or alternate worktree held a newer implementation.
- `gh run list --limit 5`: latest relevant CI/Documenter runs green; no simulation job was
  run or inferred from GitHub Actions.
- Direct `fir` `sacct --array -X`: C1 20/20, C8 16/16, supplied-K screen 3/3,
  repeatability screen 6/6, supplied-K confirm 3/3, and repeatability resume 40/40
  completed. The first repeatability confirm attempt was correctly visible as 40/40 timeout.
- Direct raw-artifact audit: pooled repeatability has 2,000 rows / 2,000 distinct seeds;
  each supplied-K confirm cell has 2,000 / 2,000; each C8 cell has 500 / 500.
- Recomputed the C1 pooled interior 0.95 coverages from the 20 task summaries; they reproduce
  the sibling checkpoint, including sigma2_a delta/Wald 0.8966 at h2=0.5 and profile 0.9468.
- Exact directory and key-file SHA-256 fingerprints are recorded in the recovery checkpoint.
- Active-board stale-claim scan: no `drivers have not been run`, `no evidence yet`, or old
  submit-all-jobs action remains.
- `tools/status_cache.json`: `public_covered_count = 5`.
- `bash tools/preamble_cap.sh`: PASS after archiving the older snapshot verbatim (1 live
  entry; 12,012 bytes under the 14,000-byte cap).
- `git diff --check`: PASS.
- `Rscript shinichi-brain/tools/check-after-task.R ...`: PASS.
- `python3 shinichi-brain/tools/closeout.py check ...`: PASS.
- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: PASS, exit 0.

## 6. Tests of the Tests

- Accounting negative control: job 48024165 reports `TIMEOUT` for all 40 tasks, proving the
  check does not equate every submitted job with success; the distinct resume job 48040475
  reports 40/40 `COMPLETED`.
- Outcome negative control: the pooled repeatability machine-readable gate reports
  `gate_pass=false`; the audit preserves that negative rather than treating completed SLURM
  state as a scientific pass.
- Claim negative control: stale phrases such as `drivers have not been run` and the old action
  to submit all four jobs are scanned after the coordination edit and must be absent from the
  active board.
- Count negative control: the status cache remains pinned at `public_covered_count = 5`; no
  validation status changes from this documentation-only reconciliation.

## 7a. Issue Ledger

- FIXED: Julia coordination board contradicted the R twin and live DRAC state.
- FIXED: repeatability capability status omitted the banked 2,000-seed negative.
- RECORDED: supplied-K confirm reused a driver whose human-readable line says `screening tier`.
  The raw provenance is sufficient, but future confirm drivers should expose the tier in the
  machine-readable output.
- RECORDED: the repeatability pooled confirm JSON also retains `screening_only=true`.
- RECORDED: C1 labels h2=0.1 differently between the driver grid and R-twin adjudication;
  it is excluded from the interior claim summary pending maintainer/Rose resolution.
- RECORDED: C8 is 500 seeds per cell, not the doc-34 2,000-seed confirm tier, and supplied-K
  recovery does not validate marker Q.
- DEFERRED: analytic check of the proposed repeatability ratio-nonlinearity mechanism, using
  only banked data and no new seeds.
- DEFERRED: supplied-K comparator, n-ladder/null, Rose audit, and maintainer G10.

## 8. Consistency Audit

Checked the R twin's doc 34, results checkpoint, handover, capability surfaces, the Julia
ROADMAP, capability status, validation debt, validation canon, coordination board, driver
headers, sbatch submit contracts, and raw DRAC output. The result wording is consistent on the
load-bearing points: no public count move; supplied-K evidence is clean but incomplete as a
promotion chain; repeatability is a banked negative; C8 is boundary characterization; C1 is
not nominal calibration.

The neighbouring active-board stale statement was corrected. Historical notes that accurately
describe what was believed before the run were not rewritten.

Final independent Rose audit returned PROMOTE-WITH-CHANGES: it confirmed the no-rerun/R4
discipline, job provenance, banked negative, and unchanged count, while requiring the C1
summary to be narrowed to the interpretable `q=120`, 0.95-level interior cells and its public
wording to remain explicitly unratified. Those changes were applied.

## 9. What Did Not Go Smoothly

- The incoming handoff and active Julia coordination board were stale even though they were
  dated after the runs; the git/twin/brain sweep prevented expensive duplicate compute.
- The first attempt to generate this report with the hub closeout helper resolved its output
  relative to the hub rather than the repo; the generated file was moved immediately into this
  repository before editing.
- The first repeatability confirm job timed out; the pre-existing resume-safe design recovered
  the same seed blocks. This is recorded as part of the evidence rather than hidden.
- Two read-only plan-review subagents were dispatched, but their summaries did not return to
  the orchestrator after the user steered the active turn; all load-bearing checks were therefore
  independently rerun by the main agent.

## 10. Known Residuals

- Raw TSVs remain on `fir` under the existing local results tree; this repo records fingerprints
  and summaries, not thousands of raw result rows. They are not GitHub artifacts.
- The supplied-K driver still prints `screening tier` at 2,000 replicates; the executed evidence
  is immutable and the discrepancy is disclosed.
- The finite-sample ratio-nonlinearity explanation for repeatability is plausible but not yet
  demonstrated. It must not be used to relabel the banked fail.
- C1 directional-conservative public wording still requires Rose claim audit and maintainer
  ratification. Doc 34 itself labels `h2=0.1` inconsistently between its grid and boundary
  sections; the result is retained as boundary characterization, not treated as resolved.
- No external supplied-K comparator or repeatability interval-coverage result was added.

## 11. Team Learning

Memory receipt: loaded the repo `LOAD-FIRST` manifest, `hsquared-rehydrate`,
`hsquared-team-dispatch`, `validation-canon-review`, `validation-harness`, `ultra-plan`, and
`after-task-audit`. The git-first prior-work sweep and recovery-to-truth guard directly changed
the action from four compute submissions to a provenance audit. `/ask-brain` surfaced the
newer sibling evidence, which was then verified against the repos and DRAC rather than treated
as authority.

Golden Set: the relevant repeat-mistake class was checked in practice: external state was
verified externally, existence was not treated as validation, and the preregistered negative
was made load-bearing rather than rescued.

Durable lesson: a merged driver can be both newly present on `main` and already executed from
its branch. “Merged today” is not evidence either way; sweep branches/twins and query the
compute host before launching.

## 12. Cross-Product Coverage

Covers: the exact four committed Julia simulation drivers; DRAC `fir` job/accounting
provenance; the C1 small-design interval grid; the C8 two-trait broader-DGP grid; the supplied-K
three-cell recovery screen/confirm; and the repeatability interior recovery screen/confirm.

Does NOT cover: a new estimator, new API, R-Julia payload change, nominal interval calibration,
large-n C1 coverage, repeatability interval coverage, proof of the ratio-nonlinearity mechanism,
supplied-K external parity or n-ladder/null, production sparse scale, non-Gaussian models,
additional multivariate traits/designs beyond the recorded grid, any capability promotion, or
any change to `public_covered_count`.
