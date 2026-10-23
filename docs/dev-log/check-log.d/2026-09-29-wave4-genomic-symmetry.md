# 2026-09-29 Wave 4 single-step symmetry tolerance follow-up

- Deterministic review probe: a positive-definite but asymmetric G matrix with entries around `1e-12` passed the old absolute tolerance and was averaged. The reproduction took seconds.
- TDD red run: the new tiny-scale assertion expected `ArgumentError`, but the old code returned a precision matrix.
- Fixed by normalizing by the maximum absolute entry before checking relative asymmetry. The check uses no unit-sized absolute floor.
- Focused `test/test_212_engine_controls.jl`: 24/24 passed. This includes tiny and huge asymmetric matrices, a tiny symmetric positive-definite control, and a finite `1e308` symmetric control.
- Full Julia 1.10.0 `Pkg.test()` on the overflow-safe averaging edit passed and ended `Testing HSquared tests passed`. The existing Project/Manifest mismatch warning remains; no dependency resolution.
- `git diff --check`: passed.
- Independent numerical re-review of the exact final source/test hashes passed, including the normalized symmetry condition and overflow-safe midpoint expression.
- Only the single-step symmetry validator finding is closed. E1/Wave 4, A2 and V3 remain open. No simulation, GPU work, hosted CI, release, registry, merge, or tag.
