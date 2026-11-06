# Arc 1 pilot cross-source plan check

## 1. Goal

Check whether the retained eight-cell pilot batch can be admitted by the launcher in the current Codex worktree, without starting a fit.

## 2. Implemented

Ran the current worktree launcher in planning-only mode against the retained candidate batch and recovery source tree. It rejected the batch because a reviewed complete consumed-attempt history is required. No plan or result file was produced.

## 3a. Decisions and Rejected Alternatives

- Did not synthesize a history review or adapt the batch from the recovery-tree plan. The missing history is an admission requirement.
- Did not execute the batch or alter any seeds.
- Assumptions made without asking: none.

## 4. Files Touched

- Created this report.
- Created empty scratch directory `/private/tmp/arc1-pilot-cross-source-plancheck-20261024/` for the plan output. It contains no files.
- No source, admission, history, protected record, recovery-tree file, isolated R checkout, or Dropbox file was changed.

## 5. Checks Run

- `PYTHONDONTWRITEBYTECODE=1 python3 -B sim/arc1/run_pilot_cells.py --batch /private/tmp/arc1-pilot-admission-candidate-20261024-env-scope-fix/batch.json --source-root /private/tmp/HSquared.jl-arc1-recovery-20261015 --output-root /private/tmp/arc1-pilot-cross-source-plancheck-20261024/outputs --plan-output /private/tmp/arc1-pilot-cross-source-plancheck-20261024/plan.json --julia /home/snakagaw/hsq_work/julia-1.10.0/bin/julia`
- Result: exit 2, `launcher_rejected`, `a reviewed complete consumed-attempt history is required`.
- A filesystem check found no plan or fit-result files in the scratch directory.
- A read-only archive check restricted to 114 Arc1-named roots under Totoro `hsq_work` found 93 archive-named files. Seventy-five were readable archives. The 18 parse exceptions were 15 AppleDouble `._` sidecars and three 30-byte ASCII placeholders reading `evidence hsquared_0.9.0.tar.gz`; three actual copies of that package tarball parsed as gzip archives.

## 6. Tests of the Tests

No implementation or test changed. This invocation directly exercised the launcher's missing-history refusal branch.

## 7a. Issue Ledger

- Open: the retained recovery-tree plan is not admitted by the launcher in the current Codex worktree because the batch lacks the required reviewed complete consumed-attempt history.
- The recovery-tree plan-only PASS remains evidence for that exact recovery-tree source and launcher. It does not authorize execution through a different launcher.

## 8. Consistency Audit

No Julia process, fit, seed, output record, or pilot gate credit was created. The current report does not change the source lock, pilot threshold, Arc 1 gates, `public_covered_count=7`, or v7 HOLD.

## 9. What Did Not Go Smoothly

The first plan check showed that the candidate batch and current launcher do not share the same complete-history contract. The launcher failed closed before creating outputs.

## 10. Known Residuals

- A complete consumed-attempt history and independent review are still missing for the current launcher.
- The archive exceptions above do not contain unreadable archive payloads, but this audit did not search every member of all archives for proposed seed use. Remote stores outside `hsq_work` and missing historical paths also remain unexamined. No pilot can proceed from this plan check.
- G2 through G8 remain open.

## 11. Team Learning

Bind plan evidence to the exact launcher and source identity that produced it. A plan-only PASS from another checkout does not transfer across source lineages.

Memory receipt: `route.py` found no LOAD-FIRST manifest for this Codex worktree. The supplied AGENTS instructions and retained Arc 1 reports guided this check.

Golden Set: not run because no engine or test code changed.

## 12. Cross-Product Coverage

Covers: current-worktree pilot-launcher refusal for the retained eight-cell batch and recovery source root.

does NOT cover: pilot execution, complete seed-history enumeration, live R-to-Julia parity, selection reliability, uncertainty calibration, repeatability profiles, confirmation, GPU, release readiness, or Arc 1 completion.
