# Check log: post-fit marker scan and backend control reviews

Date: 2026-09-30

- Henderson reviewed the post-fit mixed marker scan and direct tests read-only. Conditional algebraic pass for an interior converged fit; zero additive variance, failed-fit provenance, and positional marker-row order remain findings. The requested `test/runtests.jl` pin did not match; the current exact hash is recorded in the receipt. No test execution is claimed.
- Gauss reviewed general backend metadata and parser contracts read-only. Conditional pass: CPU and thread options are metadata only; no threaded execution evidence. A deliberately defined custom backend subtype can reach a `MethodError` in `backend_info`. The current `src/control.jl` pin was captured after the first review read, so exact-current immutability for that dependency is not claimed.
- No tests, fits, simulations, benchmarks, accelerator code, or GPU work were run. Exact pins and limits: `docs/dev-log/source-review/2026-09-30-postfit-marker-scan-review.md` and `docs/dev-log/source-review/2026-09-30-backend-control-contract-review.md`.
- These two component reviews do not close full source coverage, E1, A2, V3, or any capability gate.
