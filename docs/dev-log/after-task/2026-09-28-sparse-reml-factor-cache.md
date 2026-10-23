# After-task: sparse REML fixed-precision factor reuse

## 1. Goal

Remove repeated factorization of the unchanged relationship precision during
the sparse Gaussian REML validation optimizer, while preserving the public
likelihood and fitted result.

## 2. Implemented

`fit_sparse_reml` now forms and factors the sparse `Ainv` once, then reuses its
log-determinant for every objective evaluation and for the returned likelihood.
The standalone `sparse_reml_loglik` still validates and factors its own input.
The matrix-free optional log-likelihood path computes `logdet(Ainv)` only when
that path is enabled. Its docs now clarify that `compute_loglik=false` skips
optional likelihood work, while sparse Cholesky remains required for positive
definiteness validation.

## 3a. Decisions and Rejected Alternatives

Kept the internal cache helper private. No public API or estimator changed.
Did not promise zero Cholesky work for `compute_loglik=false`, because the
current model contract requires checking that each supplied precision is
positive definite. Did not add a performance benchmark: the source change
removes repeated fixed-matrix factorizations structurally, but speed and fill
depend on the precision pattern.

## 4. Files Touched

- `src/likelihood.jl`
- `src/iterative_solve.jl`
- `test/test_matfree_reml_inci_pins.jl`
- `docs/dev-log/source-review/2026-09-27-wave1.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/coordination-board.md`
- `docs/dev-log/after-task/2026-09-28-sparse-reml-factor-cache.md`

## 5. Checks Run

- TDD red: focused test stopped with `UndefVarError: _sparse_reml_loglik not
  defined` before implementation.
- Green focused `test/test_matfree_reml_inci_pins.jl`: **22/22** assertions.
- Full `Pkg.test()` from `/private/tmp/hsq-matfree-cachecheck-20260928`:
  exit 0, `Testing HSquared tests passed`.
- Before the full suite, `diff -qr` and SHA-256 checks confirmed the writable
  copy's `src/` and `test/` trees exactly matched the candidate. The three
  changed source/test file hashes were respectively
  `d73b31032f37f6ace2728a45a413582c1a2a7c8c89252c0dc8db2abeebc6787b`,
  `2f672e02f83faff8527e33e43eff92f139d58d1d5dc6cbe0bd7a8af6bb21a43d`, and
  `decca8dccfdb244e8260f5bfacf1da5c05a10602a70b718ba4761ea514608282`.
- `git diff --check`: passed.
- `bash tools/preamble_cap.sh`: `CAP OK`.
- The shared closeout generator could not be used to create this report because
  it resolved the project root to the separate `Shinichi` vault. The report is
  written to the exact project path. `check-after-task.R` reported the required
  section structure passed when acceptance-ledger recursion was disabled.
  Its ordinary invocation began re-running the global programme checks after
  printing the structural pass; that run was interrupted because the programme
  ledger still has open gates and this report is a bounded slice. The separate
  full ledger state remains A2/E1/V3 open.

## 6. Tests of the Tests

Before implementation, the new parity test failed because the cached internal
likelihood helper was absent. After implementation, it checks cached versus
standalone log-likelihood and fixed-effect equality, and checks the optimizer's
returned likelihood against a standalone evaluation. These tests establish
numerical parity; they do not count Cholesky calls or measure runtime.

## 7a. Issue Ledger

- Fixed: `fit_sparse_reml` refactored the fixed relationship precision at every
  Nelder-Mead objective evaluation.
- Fixed: the matrix-free `compute_loglik=false` documentation implied that no
  factorization occurred, although sparse Cholesky remains necessary for SPD
  validation.
- Carried: the outer `fit_matrix_free_reml` exact-likelihood path refactors
  `Ainv` after the matrix-free fit's validation factorization.

## 8. Consistency Audit

Reviewed direct and cached sparse likelihood calculations and the matrix-free
optional-likelihood wording. Full Julia package tests passed, including sparse
REML, matrix-free, multivariate FA, GLLVM, and payload tests. The independent
Gauss review also found no densification in the inspected matrix-free paths.
No sparse fill or memory benchmark was run.

## 9. What Did Not Go Smoothly

The first test launch tried to write Julia's compiled cache under the protected
user depot and failed with `EPERM`. Pointing `JULIA_DEPOT_PATH` first to the
writable temporary depot fixed that environment issue. The managed candidate
also contains read-only fixtures, so the full suite ran in a writable mirror.
The shared closeout generator resolved the wrong repository root, so its report
creation step failed; the report was then written directly under the project.
The unguarded after-task checker started global gate re-verification, so only its
structural check was retained; A2/E1/V3 remain open in the programme ledger.

## 10. Known Residuals

No runtime benchmark quantifies the gain. The matrix-free outer exact-likelihood
wrapper still repeats an `Ainv` factorization. This repair does not sign off
all Wave 1 spans, exact-head CI, the Julia review panel, A2, E1, V3, or the full
twin programme.

## 11. Team Learning

Keep fixed relationship-precision factorizations outside variance-component
objective closures. Separate the validation factorization from optional
log-determinant and exact-likelihood work in documentation and tests.

Memory receipt: `route.py` ran but found no worktree LOAD-FIRST manifest. The
repo operating instructions, matrix-free source-review packet, and TDD skill
shaped the work. Golden Set: not run; this was a bounded numerical/performance
repair and no routed known-mistake case was available.

## 12. Cross-Product Coverage

Covers: Julia `fit_sparse_reml` and its sparse REML likelihood helper; Julia
matrix-free optional log-likelihood documentation and determinant calculation.

Does NOT cover: the R bridge, CRAN status, automatic FA rank selection, FA or
GLLVM inference calibration, other Julia source-review spans, GPU execution,
release submission, or public tags.
