## 1. Goal

Harden the experimental genetic-GLLVM latent-mode solver, ensure convergence diagnostics describe the returned mode, and correct the recovery evidence wording without promoting capability status.

## 2. Implemented

Added objective backtracking for Fisher/Newton mode steps and recompute the joint score after the last accepted step. `gradient_norm` and `converged` now refer to the returned fixed effects and genetic modes. The solver checks stationarity before constructing or solving the scoring Hessian, so an already-stationary mode does not require an invertible working Hessian. The backtracking permits decreases only within a small floating-point roundoff allowance.

Added an independent Poisson score reconstruction and a one-step Gaussian exact-reduction test. Corrected Gaussian uniqueness notation, record stacking prose, and the simulation/checkpoint description: the recovery runs start at true loadings and do not estimate signed bias or EBV rank.

## 3a. Decisions and Rejected Alternatives

Kept the fixed-rank Poisson target cell and the existing experimental status. Did not claim global optimization or broad recovery from a stationarity check. Did not rerun the larger recovery simulation because its truth-loading initialization cannot answer whether ordinary starts recover the target cell; that simulation needs a redesigned estimand and runtime estimate first.

## 4. Files Touched

- `src/genetic_gllvm.jl`
- `test/genetic_gllvm_trait_effects.jl`
- `docs/design/genetic-gllvm-objective-contract.md`
- `docs/dev-log/recovery-checkpoints/2026-06-20-genetic-gllvm-reml-recovery.md`
- `sim/phase6_gllvm_recovery.jl`
- `docs/dev-log/after-task/2026-09-28-gllvm-foundation-hardening.md`
- `.unlazy/hsq-gllvm-foundation/GATES.md`

The capability-status page, shared check log, and programme acceptance ledger remain owned by another active lane and were not edited.

## 5. Checks Run

- Focused GLLVM tests after solver change: all testsets passed, including four ordinary starts and independently reconstructed final score.
- The final focused GLLVM suite passed **43 assertions across six testsets**, including Gaussian one-step reduction (5), positive backtracking (4), independent trait-effect/score checks (4), Poisson intercept boundary (7), ordinary-start T=3/K=2 restarts and diagnostic contracts (18), and fitted trait effects (5).
- Full `Pkg.test()` against a writable copy of the latest candidate source and tests exited 0 and printed `Testing HSquared tests passed`. SHA-256 matched the candidate for `src/genetic_gllvm.jl` (`d7d2a2c3dd276cc86813081963e9d61350c5123c0b186b8e222b1630ba5944fd`), `src/iterative_solve.jl` (`83fdc2d2dbc971b9b2e78ce06dcbb6a67f2f60af15cbb77f35a727afbba45557`), `test/genetic_gllvm_trait_effects.jl` (`1c79e560616cc5eff3d8a351371f5460c6adaebb4ffa83b3805c5cfb71bfaff8`), `test/test_matfree_reml_inci_pins.jl` (`6d14c3456661b3c2160dbbcdb37ec8e240c710996b914a2a3540cecff9366b87`), and `test/wave1_numerical_contracts.jl` (`741d8af7012b7f84fac243443b8b55473d2199c061600e3409e309c3cc9cf5cc`). The Git-less temporary copy emitted two comparator preflight Git-metadata warnings; its comparator validation testset passed.
- Karpinski supplied a deterministic Beta-binomial fixture that drives positive damping. The regression asserts convergence, a finite log likelihood, `:converged`, and `backtracks > 0` without fixing the count. The focused suite passed 43/43; `Pkg.test()` was rerun afterward and again exited 0 with `Testing HSquared tests passed`. The final test-file SHA-256 is `1c79e560616cc5eff3d8a351371f5460c6adaebb4ffa83b3805c5cfb71bfaff8` in both candidate and test copy.
- Gauss, Noether, and Astra passed the objective alignment and final-score logic. Astra and Gauss confirmed the one-step Gaussian regression closes their docstring and coverage concern.
- Karpinski passed objective alignment, confirmed stationarity is checked before solving the working Hessian, accepted the separate outer-optimizer and final inner-mode diagnostics, and supplied the positive-backtracking fixture covered above.
- Rose passed the bounded Julia code and document slice but held public-claim synchronization. Capability-status row 152 still asserts unsupported Bernoulli bias direction and an information-limited explanation; the FA lane owns that file.
- `check-after-task.R` passed the report structure check but failed closed because the root `GATES.md` acceptance ledger is owned by the FA lane. The Golden Set detector self-test passed.
- `julia --project=docs docs/make.jl` in the managed worktree precompiled dependencies but stopped when its generator attempted to write `docs/src/validation-status.md` and received `Operation not permitted`. In a temporary copy, Documenter doctests, templates, cross-references, and document checks completed; direct VitePress rendering exited 0 in 4.79 seconds and created `docs/build/1/index.html`. The enclosing `docs/make.jl` wrapper remained silent at its VitePress subprocess and was interrupted. Page checks and direct rendering passed, but the full docs command did not exit successfully.
- `git diff --check`, `bash tools/preamble_cap.sh`, and the no-ai-slop checks for the four changed prose files passed.
- `graft` could not refresh its graph cache in this managed worktree (`EPERM`); exact source spans were inspected directly.
- The first Julia launch could not write to the default compiled-code cache. Subsequent checks used the writable temporary depot and package copy.

## 6. Tests of the Tests

The independent Poisson score check failed before the final-score repair: the function returned `1.3465e-11` while direct reconstruction at the returned mode gave `7.7421e-15`. The new Gaussian `maxiter=1` test is designed to fail under the previous pre-update convergence rule. Its current focused run passes and matches the independent multivariate REML objective.

## 6a. Public Claim Audit

No capability-status row or public user route changed. The GLLVM remains experimental/partial. The Julia slice does not establish global optimality, user-level recovery, matched external-comparator parity, or broad GLLVM coverage. Rose found a stale public capability-status claim at row 152; it remains open under the other lane's lease.

## 7a. Issue Ledger

- Fixed: mode convergence diagnostics described the pre-update score rather than the returned mode.
- Fixed: the solver now checks stationarity before solving the working Hessian.
- Fixed: undamped scoring could lower the penalized joint mode objective; backtracking now guards steps, allowing only a floating-point roundoff decrease.
- Fixed: the Gaussian wrapper prose omitted the trait-specific genetic term.
- Fixed: the covariance contract misstated the engine's record stacking order.
- Fixed: recovery notes inferred bias direction and EBV-rank recovery from unsigned covariance error without those metrics.
- Open: ordinary-start recovery on the planned Poisson `T=3`, `K=2` target cell has not been simulated. Existing restart test uses a deterministic eight-animal fixture.
- Fixed: an accepted damped scoring step is now directly exercised by a positive-backtracking regression. The test does not pin the number of halvings.
- Fixed: the fit object now separates outer optimizer convergence from final inner-mode stationarity and exposes inner gradient norm, iteration count, stop reason, and backtrack count.
- Open: capability-status wording awaits release of the file by its current owner.

## 8. Consistency Audit

Checked the supplied-loading marginal, fitted wrapper, Poisson score dimensions and factor ordering, Gaussian `G = ΛΛ′ + diag(ψ)` representation, `sqrt(ψ)` trait-effect reconstruction, independent REML reduction, simulation-script initialization, and nearby contract text. Model formulas and reported estimands align. Broader fit recovery and same-objective external comparison remain separate gates.

## 9. What Did Not Go Smoothly

The managed checkout did not permit Julia's default depot writes, and the first direct test launch stopped before running tests. The writable temporary package copy resolved that. The docs command could not write its generated status page in the managed checkout; a temporary copy allowed Documenter checks and direct VitePress rendering to pass, while the final wrapper command remained unverified after it stopped producing output. The after-task structure passed; the ledger-level check remains fail-closed because the root GATES file is owned by another lane. R-lane preflight also shows the bridge and opt-in test paths are leased there, so this lane did not touch them.

## 10. Known Residuals

Exact-head CI was not run. The docs status-page generator could not write in the managed checkout, and the enclosing docs command did not exit after the temporary-copy VitePress render, although Documenter checks and direct VitePress page rendering passed. The capability-status file and root acceptance ledger were not edited because another lane owns them. No R–Julia parity check, long recovery campaign, GPU work, release submission, or tag was performed.

## 11. Team Learning

Review panel: Gauss, Noether, Astra, Karpinski, and Rose were spawned as separate review agents. Gauss, Noether, and Astra passed the objective/final-score math. Karpinski passed the final diagnostic contract and supplied the positive-backtracking fixture now covered by the passing regression. Rose passed the bounded code/document slice and held only the stale capability-status wording owned by the FA lane.

For iterative mode solvers, convergence fields must be recomputed from the final returned state; checking only before an update can report a stale score. Recovery reports must name initialization and only interpret metrics that were actually computed. Static model prose about one-step behavior must be updated when convergence semantics change.

Memory receipt: `route.py HSquared.jl` returned the LOAD-FIRST manifest, which directed this task to `validation-harness`, the repo instructions, symbolic alignment, and the R-public/Julia-engine boundary.

Golden Set: I checked `partial-arc-negative-space` and `completion-overclaim`; the detector self-test passed. There is no dedicated final-mode-score case.

## 12. Cross-Product Coverage

- Julia internal GLLVM latent-mode solver: final score, accepted damped-step behavior, stop reason, and aggregate outer/inner convergence diagnostics covered ✓. The regression demonstrates at least one rejected full step before acceptance but does not pin the backtracking count.
- R bounded Poisson GLLVM route and R–Julia parity: this change does NOT cover those bridge surfaces.
- Gaussian FA usability, capability promotion, other families, missing responses, rank selection, and non-GPU source-review waves: this change does NOT cover them.
- GPU execution, release submission, and public tagging: this change does NOT cover them and none was performed.
