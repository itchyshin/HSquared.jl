# 2026-09-29 iterative-solver precision and control contracts

- Final exact-current source/test SHA-256 values are recorded in `source-review/2026-09-29-iterative-solve-precision-controls.md`.
- TDD negative control reproduced 10 failures / 88 passes in the focused wave-1 file before the fixes. Final focused run: **126/126 pass**.
- Final Julia 1.10 `Pkg.test()` exited 0 and printed `Testing HSquared tests passed`; command used `OPENBLAS_NUM_THREADS=1`, `JULIA_NUM_THREADS=4`, and `JULIA_DEPOT_PATH=/private/tmp/hsq-goal-julia-depot:/Users/z3437171/.julia`. The captured full log is `/private/tmp/hsq-pkg-test-final.log`.
- Julia docs were built from a writable copy after synchronizing the exact changed source/status/page files, using the local non-deploying driver. Documenter/VitePress rendered all pages; existing missing-docstring and VitePress default-config warnings were emitted.
- `git diff --check` and `bash tools/preamble_cap.sh` passed; the preamble remains 11,024 B against its 14,000 B cap.
- Gauss gave a clean component signoff at the final numerical source/test hashes. Rose found the public FA wording fix clean with limitations and confirmed no claim expansion.
- A2, E1, and V3 remain open. This does not promote FA, GLLVM, or unusual inheritance; no GPU, release submission, registry submission, merge, or tag action occurred.
