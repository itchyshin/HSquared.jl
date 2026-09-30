# 2026-09-29 Wave 4 genomic boundary underflow and endpoint ties

- Focused registered `test/wave4_genomic_boundary_near_endpoint.jl`: **28/28 passed**.
- Full Julia 1.10 `Pkg.test()`: exit 0; output ended `Testing HSquared tests passed`.
- `git diff --check` passed for `src/likelihood.jl`, `test/wave4_genomic_boundary_near_endpoint.jl`, and `docs/design/59-v07-genomic-boundary-score-amendment.md`.
- Exact hashes: `src/likelihood.jl` `041e3c7c71a1c48e138d06c3bff0450d31f952108761ac08ce942f4c665ed383`; test `702a2a34e9d893907ce5a8a5f02e8417e0c73f41eab008fcfc129e09e15c89cf`; design amendment `4c07b8202596b8143e14337894ecc89adc4c01e23ab3d27a8e7643c4b155c235`.
- The package test emitted the existing Project/Manifest mismatch warning. No dependency resolution was run.
- Gauss and Noether passed their scoped exact-current reviews. Whole-wave E1, A2, and V3 remain open.
