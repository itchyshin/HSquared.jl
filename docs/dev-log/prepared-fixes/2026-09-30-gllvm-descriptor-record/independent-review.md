# Independent mechanical review: GLLVM descriptor and record boundary

Date: 2026-09-30. Scope: independent patch, pin, and focused runtime check of the isolated C3/C5 proposal. This is not numerical-engine approval or capability promotion.

## Verdict

**PASS for the bounded C3/C5 repair proposal and its 50 focused assertions.** The patch applies to the exact frozen working-tree source, its pins match the inventory, and the independent green run passes all 50 assertions. Keep the stated boundaries and merge dependency visible; no fit, optimizer, mode, Hessian solve, or R execution was run.

## Pins and patch application

Candidate worktree HEAD is `9c10f09c1bdc7f7ab19cb07c339d1dc83179f429`. The exact frozen working-tree `src/genetic_gllvm.jl` hash is `0727459d2f163835519ae8cf8481d2439b90ba5065cfc8d74ad2c0c08736d2ca`; its source tree hash is `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`. The prepared source hashes to `7cf01057c9a101e64f50f476eda10c17b47dddb04b090b416810467eeba453c9`, and its source tree hash is `017d3dd68d08158e849b585405bed15c7c9ff71f800e3f3d9e7c32bc5a4862f8`.

The base `Project.toml` and `Manifest.toml` hashes match the inventory. All listed isolated file hashes match: source, project, manifest, regression file, patch, red/green logs, and receipt. The patch SHA is `737bd4156a4ac8186ea49c9af1eb6ddc0275c68a1a7f3801d0fc6301e6ae680d`. `git apply --check` passed against a separate copy of the pinned frozen working-tree bytes; applying it reproduced the prepared source and test hashes. The committed `HEAD:src/genetic_gllvm.jl` blob differs from the frozen working-tree hash, so the review intentionally used the explicitly pinned frozen source file and source tree, not that older blob.

## Contract review

- **C3:** `_check_gllvm_record_family` rejects `BinomialVectorResponse` as a scalar family and within abstract or typed family vectors. It is the first statement in both `gllvm_laplace_marginal_loglik` and `fit_gllvm_laplace_reml`, before data conversion, precision checks, mode work, or optimization. No per-record GLLVM support is added; the message points to the standalone scalar animal-model route.
- **C5:** the `NamedTuple` descriptor overload checks covariance first, constrains `K` to a non-Boolean integer in `1:T`, checks optional loading metadata for matrix shape `T×K` and finiteness, and checks uniqueness length, finiteness, nonnegativity, structure compatibility, and `Ψ ≤ diag(G)`. FA requires uniqueness; low-rank permits absent or all-zero uniqueness. The descriptor still computes from `G` and `Ψ`: it checks loading metadata but does not use its values to establish `G = L L' + diag(Ψ)`. This preserves rotation-free output and does not certify arbitrary synthetic decompositions.
- The supplied-loading descriptor overload remains untouched, including its separate wider `K>T` contract. The regression checks this distinction.
- The T=3, K=2 Poisson marginal guard-path control remains intact. This patch changes only `src/genetic_gllvm.jl` and adds one Julia regression file. No R code or R route was run; the bounded R Poisson route is unchanged by this patch's file scope.

## Runtime evidence

Estimate stated before each run: under one minute; one Julia thread, one BLAS thread; existing candidate `Manifest.toml`; `JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`; `--startup-file=no --compiled-modules=no`.

- Frozen-source baseline, independent copy: **23 passed, 27 failed, 0 errors**, exit 1, 8.2 s. The final 50-assertion test file includes 11 retained-contract/fitter-entry assertions added after the earlier 39-assertion red receipt. Four of these newer entry-fence checks also fail on the unfenced baseline, so this independent full-file red run has 27 rather than the earlier logged 23 failures. All failures are expected on frozen code; the complete outer testset continued through both C3 and C5 groups.
- Patched source, independent copy: **50/50 passed**, exit 0, 6.8 s.

C3 fitter tests use `rank=0` as a fallback. If the record-family fence were absent, rank validation throws before the optimizer path; the successful-family marginal controls install a sentinel after the proper-integral guard and before mode work. No optimizer or mode call was reached. The C3 and descriptor tests are deterministic input-contract assertions, not fit or recovery evidence.

## Limits and integration notes

This proposal does not implement varying-trial GLLVM support. It does not close general design separation, outer parameter-failure handling, arbitrary synthetic loading decomposition certification, missing/unbalanced records, inference, recovery, calibration, or any public capability claim. C1/basic C4 input guards are a separate patch and are not stacked here. Both proposals touch nearby sections of `genetic_gllvm.jl`; integration must retain both sets of guards and both entry calls, then run the combined focused checks. The standalone test file is not wired into `test/runtests.jl` by this patch; parent integration owns that registration.

Graft returned the relevant source navigation and warned that its cache refresh was blocked by EPERM. It estimated 117,985 tokens saved. No source writes occurred outside the proposal and independent-check scratch directories.
