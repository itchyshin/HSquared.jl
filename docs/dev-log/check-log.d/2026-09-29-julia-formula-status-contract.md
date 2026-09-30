# 2026-09-29 Julia formula-status contract correction

- Corrected the Julia-local `formula_status()` test after the first row was
  relabeled `engine bridge`: only `reserved` and `planned` rows are expected to
  say `not available`. Updated the roadmap summary to use the same labels.
- Reconciled adjacent capability prose: the grammar page now distinguishes the
  experimental validation-scale sparse REML optimizer from broader production
  sparse fitting; the backend roadmap row scopes its no-GLLVM statement to that
  page and points to the separate bounded experimental GLLVM row.
- The focused contract assertions passed. Full Julia 1.10 `Pkg.test()` exited 0
  with `Testing HSquared tests passed`, including FA and Poisson GLLVM testsets.
  The existing Project/Manifest mismatch warning remains; no resolve or update
  was run. `git diff --check` passed.
- Documenter plus VitePress built successfully in an isolated copy after the
  wording repairs. The generated `validation-status.md` matched the candidate
  byte-for-byte. Existing warnings include 47 undocumented docstrings,
  local-build deployment skipped, and bundle size. Rendered grammar and roadmap
  pages contain the corrected scope.
- Rose's exact-current wording review passed after the adjacent fixes, with no
  remaining hold for this wording slice. This is not broad FA/GLLVM signoff.
- No capability row, covered count, release status, or R formula grammar
  changed. This is a wording/test repair only. E1, A2, V3, and broader FA/GLLVM
  acceptance remain open. This does NOT cover parser parity, model fitting,
  source-review signoff, calibration, GPU, or release readiness.
