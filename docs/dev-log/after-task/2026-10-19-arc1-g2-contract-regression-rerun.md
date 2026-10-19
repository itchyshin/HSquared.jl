## 1. Goal

Rerun the deterministic G2 optimizer-contract suite against the current Arc 1 recovery checkout and preserve the narrow result without claiming scientific reliability.

## 2. Implemented

No source or test files were changed. I reran the existing deterministic optimizer-contract suite. At readback, `src/arc1_fa.jl` was SHA-256 `35eb9e1a9f8f44b1149b5c352a05c6fbf21849dfab6c9a76488a2910681b732f` and `test/arc1_optimizer_contracts.jl` was SHA-256 `df39249b82d143c7cebec133cccfeb6e5be73b3cc85560c438f1a2624699787b`.

## 3a. Decisions and Rejected Alternatives

This test-only rerun consumes no simulation seed and launches no fit. I recorded the passing contract suite as focused engineering evidence only. I did not change source, start a pilot, or infer ordinary-fit reliability from this result.

Assumptions made without asking: none.

## 4. Files Touched

- `docs/dev-log/after-task/2026-10-19-arc1-g2-contract-regression-rerun.md` (created)

## 5. Checks Run

- `julia --compiled-modules=no --project=. -e 'using Test; include("test/arc1_optimizer_contracts.jl")'`: exit 0; 289 passed of 289 in 11.9 seconds.
- Read `.unlazy/arc1-gaussian-reliability/GATES.md`: G2-G8 remain unchecked. This test result does not change the gate status.
- The structural report check passed. The closeout compiler returned exit 1 because the acceptance ledger still has unmet gates, naming `.unlazy/arc1-gaussian-reliability/GATES.md`. This is expected while Arc 1 remains unfinished; this report does not mark the goal complete.

No fit or simulation ran.

## 6. Tests of the Tests

The existing narrow-domain regression checks that the returned step remains inside the finite objective region and checks the line-search acceptance conditions. This turn did not mutate the implementation or inject a fault to test the regression. The passing result is not a negative-control or optimizer-reliability study.

## 7a. Issue Ledger

- G2 ordinary K1 fitting reliability remains open. No development, pilot, or confirmation evidence is claimed here.
- G3-G8 remain open in the current acceptance ledger.

## 8. Consistency Audit

I checked the current gate ledger, the optimizer-contract regression, and the current FA line-search source hashes. The regression is present in the Julia source. This run did not exercise the R bridge, rank-selection campaign, profile intervals, bootstrap calibration, or a package-level paired run.

The shared check log and coordination board were not updated because the live v4-lineage lease owns those files.

## 9. What Did Not Go Smoothly

The first lease-registry read used an absolute checkout path where the helper expected the repository identifier, so it showed an empty listing. Rechecking with `HSquared.jl-arc1-recovery-20261015` revealed the live handover and v4-lineage claims. The first relative-path closeout command resolved under the second-brain repository and was refused by filesystem permissions; using this checkout's absolute report path wrote the report in the intended location.

## 10. Known Residuals

This is focused, current-checkout test evidence only. The broader G2 reliability evidence is still missing. No R parity, candidate admission, seed use, study run, or G2-G8 gate credit follows. Capability remains experimental and the covered count remains seven.

## 11. Team Learning

Memory receipt: loaded the repository LOAD-FIRST manifest through `route.py HSquared.jl` and checked the lane-ownership guidance in the memory registry. The repo instructions shaped the test-only scope and ownership checks.

Golden Set: not checked; this was an unchanged deterministic test rerun and no implementation or known-mistake class was modified.

## 12. Cross-Product Coverage

Covers: the Julia optimizer-contract behavior exercised by the existing narrow finite-domain line-search regression.

Does NOT cover ordinary K1 fitting reliability, rank-selection calibration, uncertainty coverage, R parity, package checks, or capability promotion.
