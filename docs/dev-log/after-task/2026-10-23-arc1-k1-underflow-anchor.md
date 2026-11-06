## 1. Goal

Prevent a singular reconstructed K0 residual covariance from blocking all 64 scheduled K1 reference starts when finite factor parameters underflow in Float64. Preserve the reference model and schedule. This is an engineering repair, not a gate result.

## 2. Implemented

K0 reference anchors now retain the residual-factor coordinates. K1 starts use those exact coordinates when supplied, after checking that there are ten finite values. The existing covariance-to-Cholesky path remains for older anchors that have no factor coordinates. The production K0-to-K1 path copies the fitted K0 coordinates directly into the K1 anchor. No jitter, clamp, alternative start, or optimizer change was added.

## 3a. Decisions and Rejected Alternatives

Preserved the K0 residual factor representation because it is the exact optimizer coordinate vector and does not change the model or frozen 64-start schedule. Rejected adding jitter, clamping, substituting a different anchor, or changing the start count because each would alter the reference rule. No assumptions about the historical attempts were made; their reference maxima remain unresolved. I mistakenly started the full package suite as routine verification before recognizing that it includes fit tests; I interrupted it as soon as I recognized the conflict with the active no-fits instruction.

## 4. Files Touched

- `sim/arc1/reference.jl`
- `test/arc1_simulation_reference.jl`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-10-23-arc1-k1-underflow-anchor.md`

Other dirty and untracked files were pre-existing and were left unchanged.

## 5. Checks Run

- `graft grep "arc1_reference_k1_starts"`: identified the helper and its production call.
- `graft callers arc1_reference_k1_starts --depth all`: checked connected source and test callers.
- `python3 ~/shinichi-brain/tools/route.py HSquared.jl`: returned the HSquared LOAD-FIRST manifest.
- `bash ~/shinichi-brain/tools/lane_preflight.sh /Users/z3437171/.codex/worktrees/b9ae/HSquared.jl --file sim/arc1/reference.jl --file test/arc1_simulation_reference.jl`: both paths had no missing edits in other lanes.
- `JULIA_DEPOT_PATH=/private/tmp/hsquared-codex-depot:/Users/z3437171/.julia julia --project=. test/arc1_simulation_reference.jl`: passed 155 assertions across 11 testsets.
- The default Julia depot failed before test execution because its compiled-cache lock was outside the writable sandbox. The same command passed using the temporary writable depot.
- A full `Pkg.test()` run was started with four Julia threads and BLAS one after the focused suite. It was interrupted after 21m02.1s while `Arc1 source-bound one-attempt executor` had passed 497 of 527 assertions. The Julia stack was in `inspect_artifacts.jl:372`. The package suite is incomplete and is not a pass. The suite ran fit-related unit tests before interruption; no pilot/confirmation seed or K1 reference grid was launched.
- `Rscript ~/shinichi-brain/tools/check-after-task.R <absolute report path>`: passed report structure. Its ledger scan saw only the root `GATES.md` scope index; the referenced canonical eight-gate ledger is absent from this checkout, so this gives no Arc 1 gate credit.
- `python3 ~/shinichi-brain/tools/evidence_gate.py --root <current worktree>`: could not run because `memory/evidence-registry.tsv` is absent from this checkout. A default-root run found 8 claims in the linked protected Dropbox tree; it is excluded as evidence for this worktree.
- `git diff --check`, `bash tools/preamble_cap.sh`, and `python3 ~/shinichi-brain/tools/slop_check.py <absolute report path>`: passed; preamble was within its cap and slop checker reported 0 findings.
- The combined `closeout.py check` wrapper failed because its resolved root was the protected Dropbox checkout, whose acceptance ledger differs from this managed worktree. The report-structure and prose checks were run directly; the evidence-registry check is unavailable in this checkout.

## 6. Tests of the Tests

The new direct regression was run before the source fix. It errored at `_cov_to_chol_params` with `PosDefException` on the underflowed covariance, as expected. After the fix it confirmed all 64 starts were valid and their residual-factor coordinates exactly matched the finite K0 coordinates. An integration test also forced underflowed K0 diagonal coordinates and verified that K1 optimizer starts received those coordinates unchanged. The reference suite passed after the integration check was added.

## 7a. Issue Ledger

The K1 reference-maximum failures for prior attempts remain tracked by the existing Arc 1 issue (#476 in the prior project record). The issue's current remote state was not rechecked or changed. This repair does not recreate their missing reference maxima and grants no evidence credit to those attempts.

## 8. Consistency Audit

The helper, its production K0-to-K1 call, the simulator test file, and source-bound receipt execution call path were reviewed. The parameter ordering remains K0 residual coordinates 5:14 and K1 residual coordinates 9:18. The rounded residual covariance remains available as a diagnostic. The result does not show that the exact objective is finite for any real attempted dataset; that requires source-bound evidence under the applicable source lock.

## 9. What Did Not Go Smoothly

The first route lookup using the absolute worktree path found no LOAD-FIRST manifest; using the registered project name `HSquared.jl` returned it. The repository-local lane preflight script was absent, so the canonical brain tool was used. The closeout helper resolved its root to the protected Dropbox checkout. Its report-creation attempt was denied and its combined check consulted that checkout's ledger; no Dropbox file changed. I created the report in the managed worktree. The direct structure check passed, but its gate scan found only a scope index and not the canonical Arc 1 ledger, so it cannot support any gate-status claim. The evidence registry is absent here, so its gate could not run; the default linked-tree pass was excluded. The prose check passed directly. The initial Julia command also hit the sandbox's write restriction on the default compiled cache and succeeded with a temporary depot. I started the full test suite before noticing its fit tests conflict with the no-fits boundary and then interrupted it.

## 10. Known Residuals

This is an uncommitted local code/test change in a dirty managed worktree. The full Julia package test was interrupted and has no pass result; this change has not had an independent review of the final diff, a source-frozen likelihood/gradient check, or a fresh-seed study. The reported residual covariance may still be singular after underflow. Attempts 2 and 14, the other pilot cells, interval scoring, and all gates G2-G8 remain unresolved. No R parity was exercised. Do not use this change to revise the historical result or claim reliability.

## 11. Team Learning

Memory receipt: loaded the `HSquared.jl` LOAD-FIRST manifest, the project instructions, and the validation-harness guidance. The numerical review that preceded this implementation identified the lossy covariance round trip; no new subagent was started for this slice. The exact source coordinates should be retained across optimization stages when a rounded diagnostic matrix cannot faithfully recover them.

Golden Set: not run. This slice did not change a public estimand, model formula, interval, simulator, or acceptance rule.

## 12. Cross-Product Coverage

Covers: the Julia simulation reference initializer and its K0-to-K1 start handoff.

Does NOT cover: R-facing controls or bridge parity, the primary fitting selector, historical reference maxima, fresh simulation evidence, uncertainty calibration, package-wide checks, G2-G8, covered capability status, GPU, releases, or publication.
