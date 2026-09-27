# After-task: Julia source-review wave 1

## 1. Goal
Review sparse Gaussian and genomic source paths against baseline `faed40182cdbba2bf69f3e8dff0c5054be2dd214`; record scoped fixes and remaining review debt.

## 2. Implemented
Three assigned defects were repaired: downstream PCG consumers now reject unconverged solves; extreme two-sided genomic p-values preserve positive tails and sign symmetry; CPU genomic inverse/APY/cache inputs reject asymmetry. Coordinator follow-up also fixed bootstrap acceptance to require convergence. The packet remains **HOLD** because likelihood/genomic spans and independent panel signoff remain open.

## 3a. Decisions and Rejected Alternatives
Kept changes narrow to assigned paths. Standalone PCG diagnostics retain their return behavior; checks are placed at downstream consumption. CUDA dispatch was untouched. Bootstrap repair belongs to coordinator and is not self-certified by the review packet.

## 4. Files Touched
Review packet: `docs/dev-log/source-review/2026-09-27-wave1.md`. Repairs listed there: `src/iterative_solve.jl`, `src/genomic.jl`, dedicated regression file; coordinator bootstrap follow-up in `src/likelihood.jl` and tests. This report records the review; it does not claim ownership of those edits.

## 5. Checks Run
Packet records focused wave evidence: 676 assertions total (24 new plus 652 neighbors); bootstrap negative regression red before and 4/4 green after. No full-package test, full-file review, or GPU execution is claimed here.

## 6. Tests of the Tests
PCG regression uses a deterministic eight-record SPD fixture with `maxiter=1`, requiring all downstream routes to reject; successful information is compared to an independent dense marginal-covariance projector. Tail tests compare ±8, ±9, ±12 against independently tabulated values and preserve central marker parity. Asymmetry regression rejects `[2 .25; .5 2]`. Bootstrap regression excludes a finite-positive unconverged refit.

## 7a. Issue Ledger
Open: W1-05 SIMD fit/score trajectory parity; W1-06 response-shift cancellation stability is unmeasured; W1-07 stationary-point accuracy is not established by small-step convergence. Bootstrap fix requires integrating reviewer verification. Full likelihood and genomic regions remain unreviewed.

## 8. Consistency Audit
Sparse bridge and Takahashi selected-inverse files were statically reviewed over complete source spans for their stated contracts. Fit-level SIMD comparison, broader scale/calibration, and listed optimizer/profile/payload/PEV regions remain outside evidence. See the packet's explicit unreviewed-span lists.

## 9. What Did Not Go Smoothly
Graft line maps were stale against the candidate; exact baseline candidate spans were used. This was a bounded static review with targeted regression evidence.

## 10. Known Residuals
Whole-wave review and Gauss/Noether signoffs are open. No capability promotion, statistical validation claim, benchmark campaign, GPU execution, or final candidate-commit signoff follows from this packet.

## 11. Team Learning
A finite PCG iterate is not evidence of a converged downstream fit; check the solver's true residual at each consumer. Tail symmetry should be tested at both signs where cancellation is possible.

## 12. Cross-Product Coverage
This source wave covers only the reviewed Julia sparse/Gaussian and genomic paths. It does NOT cover the full likelihood/genomic source, R bridge parity, CUDA execution, or public capability promotion. Panel signoff remains open.
