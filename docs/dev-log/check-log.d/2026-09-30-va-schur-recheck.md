# 2026-09-30 variational fixed-effect Schur correction recheck

- Julia 1.10 `Pkg.test()` passed on candidate HEAD `a7ca8ed557b23ec23c8486365e97a7bac4b71c16` with the current dirty-tree source; output ended `Testing HSquared tests passed` (exit 0).
- Exact tested pins: `src/nongaussian.jl` `24a31752319a1c51dbded522d8e20d066227d208e71be970cb94891beb87da00`; `test/wave2_nongaussian_contracts.jl` `c7a6cd8eba56cf54f4b0ffed629ba1b5a5dfbd5220f2d5d7d09e3ec1cebaad60`; `test/runtests.jl` `b4802d82a430abc10134485a21bf387d9497d72bb2643c25afbbb6ec0cdc4691`.
- Focused tests previously passed 92/92 in `wave2_nongaussian_contracts.jl` and 13/13 in `test_nongaussian_inner_convergence.jl`. The red regression reproduced `PosDefException` for a valid shared-effect Gaussian design before the Schur repair.
- Astra/Noether scoped static review passed on all three exact hashes. The correction uses the mean-Hessian Schur complement `Hββ − Hβm Hmm⁻¹ Hmβ`, with `Hmm = Z'W̃Z + A⁻¹/σ²a`, in place of the restricted variational covariance. The regression checks convergence and finiteness; the exact 1/4 curvature value remains untested.
- Hygiene: `bash tools/preamble_cap.sh` passed; `git diff --check` passed. No documentation build was repeated because this recheck changed no manual pages or rendered documentation.
- This closes only the bounded VA Schur numerical finding. Other non-Gaussian audit findings remain carried; A2, E1, and V3 remain open. No capability, covered-count, GPU, release, submission, registry, or tag status changed.
- Detailed report: [`after-task/2026-09-30-va-schur-recheck.md`](../after-task/2026-09-30-va-schur-recheck.md).
