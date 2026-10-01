## 1. Goal

Reject invalid `boundary_tol` values before interval and uncertainty calculations, and verify the Julia candidate after the repair.

## 2. Implemented

Added one shared validator requiring a finite, nonnegative tolerance. Applied it to the exact and matrix-free public interval routes, the covariance-backed ratio standard-error route, and the shared interval helper. Added regression assertions for negative, NaN, and infinite values across six API routes. Exact source hashes: `src/likelihood.jl` `90cc76897c2b977f4bebc456d1e6c8d8f2647a7bb7ec6e8c9135884da0f17e30`; `src/iterative_solve.jl` `91968ebd2b437b7abb570a82dd05e94742b108a69e0d7a65c23287c26be56a75`; `test/test_post_fit_uncertainty_reuse.jl` `e7b816f8636d0dd611fd684f5c2719a74aebd0d3bd3d0d57f366729738f91539`.

## 3a. Decisions and Rejected Alternatives

Kept the valid domain finite and nonnegative, including `0.9`, which is a classification threshold and need not be small. Used one helper so public routes cannot drift. Variance estimands, boundary classification semantics, capability status, and user-facing claims stay unchanged.

## 4. Files Touched

- `src/likelihood.jl`
- `src/iterative_solve.jl`
- `test/test_post_fit_uncertainty_reuse.jl`
- `GATES.md`
- `docs/dev-log/after-task/2026-09-30-boundary-tol-validation.md`
- `docs/dev-log/check-log.d/2026-09-30-boundary-tol-validation.md`

## 5. Checks Run

- Focused `test/test_post_fit_uncertainty_reuse.jl`: 74/74 assertions passed, including 18 invalid-input assertions.
- Full Julia 1.10 `Pkg.test()` on the current candidate: exited 0; `Testing HSquared tests passed`. This includes the FA, GLLVM, bridge, and boundary-tolerance test groups.
- `git diff --check`: passed.
- `bash tools/preamble_cap.sh`: passed at 11,024 B of 14,000 B.
- Unlazy reverify of `GATES.md`: V1 and V2 passed with exact approved commands; ledger now reports 8/11 met, with A2, E1, and V3 still open.
- The current-source Documenter build in `/private/tmp/hsq-fa-gllvm-doc-check` exited 0 and rendered pages. Its source tree matches the worktree under `src/`; setup warnings include 47 omitted docstrings, deployment skipped, missing favicon, and a large-bundle warning. This is local build evidence, not deployment evidence.

## 6. Tests of the Tests

Before the validator was added, the new assertions failed for all 18 negative, NaN, and Inf route/value combinations. With the validator, all 18 pass by observing an `ArgumentError` that names `boundary_tol`. The separate valid `0.9` case remains covered.

## 7a. Issue Ledger

- Fixed: invalid tolerance values could silently bypass boundary classification because negative values and NaN make the intended comparisons ineffective.
- Deferred: add `-Inf` to the invalid-value matrix and repeat the valid high-threshold check through every direct API. The common helper governs those routes, but broader per-route assertions would make the contract more explicit.
- No issue ID assigned. This repair validates an existing API input only; capability status stays unchanged.

## 8. Consistency Audit

Checked the shared delta-method helper, the covariance-backed ratio standard-error route, the multi-effect and summed-ratio interval routes, the uncertainty wrapper, and the matrix-free interval route. The exact-current Rose audit confirmed validation precedes fitting or information work on the public routes and matched all three source/test hashes. The independent iterative-solver review had identified this gap; the repair closes that specific input-validation finding only.

## 9. What Did Not Go Smoothly

The repo routing command could not load a `LOAD-FIRST` manifest for this managed worktree. The first local docs build could not rewrite its generated validation page due to filesystem permissions, so the docs build was repeated in a disposable copy. The closeout tool needed an absolute report path; its R check used the brain root, so I reran the repo acceptance ledger from this repository. The initial GATES insertion duplicated the file suffix; I removed only the repeated suffix before validation. The full suite took about eight minutes because the FA unit-transformation test took nearly two minutes. Its first gate-run attempt hit the default 120-second timeout; the same gate passed after rerun with a 1,200-second timeout.

## 10. Known Residuals

This does not close FA likelihood identifiability, ordinary-start recovery, or uncertainty calibration. It does not close the Poisson GLLVM acceptance gates or the broad Julia source and bridge review. A2, E1, and V3 remain open. The long FA recovery campaign remains unrun pending the required approval. No release or GPU action occurred.

## 11. Team Learning

Memory receipt: attempted `route.py`; no load-first manifest was available for this worktree. The prior ask-brain retrieval found no direct boundary-tolerance note; `WHAT-WORKS` supported preserving exact candidate evidence and scoped review. That shaped the exact-hash recheck and the narrow status language. Golden Set: not in scope because this repair changes API input validation and does not evaluate a known simulation or recovery failure class.

## 12. Cross-Product Coverage

Covers: Julia exact and matrix-free interval and uncertainty APIs that accept `boundary_tol`.

Does NOT cover: R-side validation, fitted FA or GLLVM usability, statistical identification, interval calibration, population recovery, deployment, or release status.
