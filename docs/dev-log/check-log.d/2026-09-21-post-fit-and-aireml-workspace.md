## 2026-09-21 — post-fit information matrix reuse + sparse AI-REML workspace `[JL]`

Owner-reported gap: the great tit animal + permanent-environment fit takes ~5–6 s through
`hsquared` against ~2 s for ASReml-R. Asked for a deep audit and an implementable plan,
then told to execute it. Branches `perf/post-fit-covariance-once` (`9af8aeae`) and
`perf/aireml-loop-symbolic-reuse` (`089588c5`, stacked on it), both PUSHED, **no PR opened**.

### What the audit actually found

The problem was not the fitter. Reconstructing the exact published problem in Julia from
`hsquared/dev-test/great_tit_breeding_data.csv` + `great_tit_pedigree.csv` (same prune loop
as the notebook) reproduces the recorded estimates exactly — n = 11,856 records, q = 10,937
pedigree rows, p = 63, `C` 21,937 × 21,937, σ²a/σ²pe/σ²e = 0.5954 / 0.52523 / 1.37276 — and
the steady-state Julia cost splits:

| stage | main |
| --- | --- |
| `fit_multi_effect` (10 AI-REML iterations) | 0.87 s |
| `multi_effect_variance_component_standard_errors` | 1.45 s |
| `multi_effect_ratio_standard_errors` | 1.42 s |
| `multi_effect_sum_ratio_interval` | 1.45 s |
| **total** | **5.19 s** |

That total matches the 5–6 s observed in R, so JuliaCall marshalling is NOT the cost — it is
all engine compute, and **83% of it is post-fit**. The three post-fit calls each build the
same finite-difference Hessian, and `_reml_fd_information` looped the full `d × d` grid at 4
evaluations per cell (36 at K = 2) while returning `Symmetric(-H)`, which reads only the
upper triangle — so 12 of those 36 were computed and discarded. 108 full REML
log-likelihood evaluations after convergence, against 10 iterations to reach it. Each
evaluation rebuilt the σ-independent conversions, the four cross-products, `y'y`, both
`log|Aᵢ⁻¹|` (5.7 ms) and the CHOLMOD symbolic analysis (26.3 ms of a 43.2 ms evaluation),
though the sparsity pattern of `C` is identical at every point.

### Changed

`_MultiREMLWorkspace` (internal) hoists every σ-invariant term, assembles `C` by rewriting
only `nzval` against a pattern built once, and reuses the symbolic analysis through
`cholesky!`. `_reml_fd_information` runs the upper triangle and mirrors it (36 → 24
evaluations). `multi_effect_uncertainty` (new, exported) returns the covariance, the
variance-component SEs, the ratio SEs and the summed-ratio interval from ONE information
matrix; the three standalone functions now share its derivation helpers. The same workspace
serves `fit_sparse_multi_effect_aireml`'s warm-start, every iteration and its closing
log-likelihood. `initial = :auto` adds an opt-in data-scaled start.

| | main | after |
| --- | --- | --- |
| one `sparse_multi_reml_loglik` evaluation | 43.2 ms | 9.08 ms |
| assemble + factorize, per AI iteration | 31.7 ms | 5.9 ms |
| fit | 0.87 s | 0.65 s |
| the three post-fit calls | 4.37 s | 0.60 s |
| post-fit via `multi_effect_uncertainty` | — | 0.17 s |
| **great tit total, as the R bridge calls it today** | **5.19 s** | **1.29 s** |
| great tit total, if R switches to one call | — | 0.86 s |

One machine (Apple silicon, Julia 1.13.0, 1 thread, BLAS 8), one dataset, one run per cell.
**No comparator claim:** the ASReml-R ~2 s is the owner's report, not a measurement taken
here, and no ASReml run was performed.

### Bitwise verification

Both branches were diffed against `main` at full `repr` precision using a `main` worktree
and the same harness: log-likelihood at and away from the optimum, β, both BLUP blocks, the
full 3×3 covariance, every standard error, and the interval endpoints — **all identical**;
and for the fit, variance components, log-likelihood, iteration count, convergence flag, β
and BLUPs across the default fit, `em_warmup = 3`, an explicit `initial`, and a K = 3
fixture — **all identical**. No estimand, interval or coverage claim changes.

### Checks (fresh, this worktree, final tree)

- `julia --project=. -e 'using Pkg; Pkg.test()'` — **passed** (`Testing HSquared tests passed`,
  171 test summaries, exit 0), Aqua included, nothing commented out. 93 new assertions in
  `test/test_post_fit_uncertainty_reuse.jl` (56) and `test/test_aireml_workspace_reuse.jl` (37).
- `bash tools/preamble_cap.sh` — **CAP OK** (AGENTS.md untouched).
- `python3 tools/check_capability_citations.py` — **OK, 81 verified, 0 skipped.** It FAILED on
  `main` in this same checkout, for a pre-existing stale anchor
  (`capability-status.md` → `test/runtests.jl:6926`, the Phase 4 direct–maternal row);
  re-pointed to `test/runtests.jl:7145`, the testset it names. That fix is incidental to this
  slice, not caused by it.
- `bash tools/build_check_log.sh --check` — all 189 entries well-formed.
- `julia --project=. tools/write_validation_status_page.jl` — re-run after the
  `src/validation_status.jl` edit; **56 rows, unchanged count**, one scope line rewritten.
- `julia --project=docs docs/make.jl` — Documenter stages (doctests, expansion,
  cross-references, document checks) pass; the build then dies at the
  `npm run … vitepress build` step, `ProcessExited(127)`. Confirmed to fail IDENTICALLY from
  `main` in this same checkout (`git checkout 4dfad4b9`), so it is environmental and
  pre-existing, not caused by this work. Note a `main` worktree in `/tmp` resolved a
  different docs environment and DID build, so this is a property of this checkout's
  `docs/Manifest.toml`, not of the repository.
- **CI: NOT run.** `.github/workflows/CI.yml` triggers only on `pull_request` and
  `workflow_dispatch`, so pushing these branches ran no tests (issue `#367`). Opening a PR
  would trigger it; none was opened.

### Claim boundary

Performance and code-structure only. No capability flips, no status changes, no new
estimand: `public_covered_count` stays **7**, version stays **0.9.0**. The K-effect standard
errors and the summed-ratio interval remain asymptotic and **NOT coverage-calibrated**
(`#366`); this slice makes them cheaper, not better-evidenced.

### Records gap closed, and one left open

The #352 arc that introduced those four exported functions (`5135a92e`, `4dfad4b9`,
2026-09-20) landed with **no check-log entry, no after-task report, and no row in either
ledger**. This slice adds the missing `capability-status.md` row and folds the surface into
`V1-HERIT-CI` in `validation-debt-register.md` and `src/validation_status.jl`. It does NOT
manufacture retroactive check evidence for that arc: the green suite recorded above is for a
tree CONTAINING those commits, run 2026-09-21, not evidence taken when they landed.
