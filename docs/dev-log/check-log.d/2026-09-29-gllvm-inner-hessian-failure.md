# 2026-09-29 GLLVM inner Hessian failure handling

## Goal

Prevent finite nonconverged GLLVM modes and invalid optimizer trial points from leaking raw Hessian failures. Keep outer optimizer status, inner mode status, and malformed-input errors distinct.

## Checks

```sh
JULIA_DEPOT_PATH=/private/tmp/hsquared-fa-gllvm-depot:/Users/z3437171/.julia JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. test/genetic_gllvm_trait_effects.jl
JULIA_DEPOT_PATH=/private/tmp/hsquared-fa-gllvm-depot:/Users/z3437171/.julia JULIA_PKG_OFFLINE=true JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. -e 'using Pkg; Pkg.test()'
JULIA_DEPOT_PATH=/private/tmp/hsquared-fa-gllvm-depot:/Users/z3437171/.julia JULIA_PKG_OFFLINE=true OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 julia --project=docs docs/make.jl
git diff --check
bash tools/build_check_log.sh --check
```

The default-depot focused test attempt could not write the Julia compiled-cache lock under `/Users/z3437171/.julia`. The bounded rerun used a writable temporary depot and passed all 61 assertions in the focused file. The first red regression reproduced a raw `PosDefException` for a finite nonconverged mode. The final 8/8 adversarial assertions cover structured nonconvergence, invalid observed curvature, nonfinite trial points, singular working curvature, final-fit rejection, and malformed `Ainv` propagation. A fresh full `Pkg.test()` on the integrated candidate exited 0 with `Testing HSquared tests passed` in about 2.5 minutes. The docs build passed from `/private/tmp/hsquared-fa-gllvm-docs-copy-20260929-codex` after copying the exact final `src/genetic_gllvm.jl` SHA-256 `fd0fb9832b1855f26dc36bb3cffd3b15e131629c4863a1c3db854e1aa8039df4`. It emitted the existing manual-block, deployment, favicon/configuration, and bundle-size warnings. `git diff --check` and `bash tools/build_check_log.sh --check` passed. The exact final source and test hashes are recorded in the Gauss review packet.

## Outcome and limits

Finite nonconverged modes return `loglik = NaN` and diagnostics before observed-curvature work. Nonfinite trial calculations and invalid observed curvature use typed internal errors. The optimizer converts only those errors to `Inf`; the final point must yield a converged finite inner mode. Gauss approved this narrow failure-path change. This is not GLLVM capability signoff, a calibration result, a full package check, a sparse-scale result, or source-review wave completion. No Totoro campaign, GPU work, release action, commit, or submission was performed.
