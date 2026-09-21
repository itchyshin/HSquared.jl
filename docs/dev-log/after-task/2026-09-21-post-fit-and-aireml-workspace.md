# After-task — 2026-09-21 post-fit information-matrix reuse and the sparse AI-REML workspace

## 1. Goal

Owner report: the great tit animal + permanent-environment fit runs ~5–6 s through
`hsquared`'s Julia route against ~2 s for ASReml-R. Asked for a deep audit and a detailed
implementable plan ("better inverses or factorisation? Further pruning of redundant code and
operations?"), then instructed to execute it in sequence, push, and close the records.

## 2. Implemented

Two branches, both PUSHED, **no PR opened** (the owner asked for pushes, not PRs).

- **`perf/post-fit-covariance-once` (`9af8aeae`).** `_MultiREMLWorkspace` (internal) hoists
  every σ-independent quantity of `sparse_multi_reml_loglik` — the `Float64`/`sparse`
  conversions, the four cross-products, `y'y`, each `log|Aᵢ⁻¹|` — and reuses the CHOLMOD
  symbolic analysis through `cholesky!`. `_reml_fd_information` runs the upper triangle and
  mirrors it (`4·d²` → `4·d·(d+1)/2` evaluations; 36 → 24 at K = 2). `multi_effect_uncertainty`
  (new, exported) returns the covariance, variance-component SEs, ratio SEs and summed-ratio
  interval from ONE information matrix; the three standalone functions were refactored onto
  shared derivation helpers so no formula is restated. The four #352 functions and the new one
  were added to `docs/src/api.md`, which they had never reached.
- **`perf/aireml-loop-symbolic-reuse` (`089588c5`, stacked).** The same workspace now serves
  `fit_sparse_multi_effect_aireml`'s EM warm-start, every AI iteration and its closing
  log-likelihood. `_assemble_lhs_rhs!` rewrites only `nzval` against a pattern built once —
  and the pattern is taken FROM `_sparse_multi_lhs_rhs` at σ = 1, so the in-place path can only
  write into the structure the original produced; `_nz_index_map` throws rather than guessing
  if an entry is ever absent. `_factorize!` reuses the symbolic analysis, falling back to a
  fresh `cholesky` on `PosDefException`. Adds `initial = :auto`, an opt-in data-scaled start.
- **Ledgers.** New `capability-status.md` row for the #352 K-effect uncertainty surface (which
  had none); `V1-HERIT-CI` extended in `validation-debt-register.md`, `src/validation_status.jl`
  (evidence, debt and scope) with the K-effect analogue, the 6.1% AI-vs-FD gap, the
  finite-difference noise floor, the performance record, and the uncalibrated-coverage debt
  (`#366`). Row count unchanged at 56; `docs/src/validation-status.md` regenerated.
- **Incidental fix.** `tools/check_capability_citations.py` FAILED on `main` in this checkout
  for a pre-existing stale anchor (Phase 4 direct–maternal row → `test/runtests.jl:6926`);
  re-pointed to `7145`. Also fixed an unresolvable `[_ratio_delta_ci](@ref)` in the
  `multi_effect_sum_ratio_interval` docstring, which was invisible until `api.md` began
  including that function and then failed the docs build outright.

## 3a. Decisions and Rejected Alternatives

- **Rejected: reuse the AI matrix instead of the finite-difference Hessian.** The AI-REML loop
  already builds the `(K+1)×(K+1)` average-information matrix every iteration and discards it,
  so this looked like a free 4.8×. Measured at the great tit optimum, its inverse gives SEs
  **6.1% different** (0.0663 against 0.0706 for σ²a). That is an estimand change requiring a
  Rose audit and a coverage study, not an optimization. Not done; recorded on `V1-HERIT-CI`
  so it is not re-proposed as a performance idea.
- **Rejected: collapse the finite-difference diagonal to `θ` and `θ ± 2h`** (24 → 19
  evaluations). Measured to move the covariance by ~6e-5 relative, because the `4·h_i·h_j`
  divisor amplifies the log-likelihood noise floor. Bitwise identity was worth more than 45 ms.
- **Rejected: drop the dead permanent-environment levels.** The R bridge builds the PE identity
  at pedigree size, so 3,597 of 10,937 PE levels (32.9%) carry no record. Verified their
  contribution cancels exactly (log-likelihood difference 1.3e-9, identical variance
  components) — but measured at only **1.03×**. A correctness-neutral tidy, not a lever; not
  done, to keep the diff on what the measurement justified.
- **Rejected: rely on the open selected-inverse PRs.** `#361`/`#363` report 28×/76× at fill 471.
  Measured on this problem: mean clique **17.7**, max 309, against the removed cap of 2000 — so
  `main`'s dense-block path already runs for every column and those PRs do essentially nothing
  here. They remain right for large-pedigree work. Recorded because the PR titles invite the
  opposite assumption.
- **`initial = :auto` is opt-in, NOT the default.** It helps when the response is far from unit
  scale (10 → 8 iterations, 0.67 → 0.52 s at `var(y) = 3.0`) and HURTS when it is not (12
  against 10 on a unit-variance fixture). Beyond that, moving the optimizer path perturbs a
  converged estimate in its last bits and changes reported `iterations`, and this repo's
  recovery checkpoints and pre-declared bias/MCSE gates were all run from `(1,…,1)`. Flipping
  the default is an evidence decision for the owner.
- **No R-lane edit.** The last 0.4 s needs `julia-bridge.R` to call `multi_effect_uncertainty`
  once instead of three functions. `CLAUDE.md` forbids editing the R repo from this lane; left
  as a named cross-lane item.
- **No new validation-debt ROW; folded into `V1-HERIT-CI`** — following the 2026-09-17
  precedent, since this is a performance change to an existing experimental surface, not a new
  capability. A new `capability-status.md` row WAS added, because the #352 surface genuinely
  had none.

## 4. Files Touched

- `src/likelihood.jl` — `_MultiREMLWorkspace`, `_multi_reml_workspace`, `_multi_reml_loglik!`,
  `_nz_index_map`, `_assemble_lhs_rhs!`, `_factorize!`, `_reml_fd_information`,
  `sparse_multi_reml_loglik`, `_vc_se_from_cov`/`_ratio_se_from_cov`/`_sum_ratio_ci_from_cov`,
  the three #352 functions, `multi_effect_uncertainty`, `fit_sparse_multi_effect_aireml`.
- `src/HSquared.jl` — export `multi_effect_uncertainty`.
- `test/test_post_fit_uncertainty_reuse.jl` (new, 56 assertions),
  `test/test_aireml_workspace_reuse.jl` (new, 37), `test/runtests.jl` (two includes).
- `docs/src/api.md`, `docs/design/capability-status.md`,
  `docs/design/validation-debt-register.md`, `src/validation_status.jl`,
  `docs/src/validation-status.md` (regenerated).
- `docs/dev-log/check-log.d/2026-09-21-post-fit-and-aireml-workspace.md`, this report.

## 5. Checks Run

Fresh, final tree: `Pkg.test()` **passed** (171 summaries, exit 0, Aqua included, nothing
commented out); `tools/preamble_cap.sh` **CAP OK**; `check_capability_citations.py` **OK, 81
verified** (FAILS on `main` here — see §2); `build_check_log.sh --check` **190 entries
well-formed**; `write_validation_status_page.jl` **56 rows**, count unchanged.
`docs/make.jl` completes all Documenter stages and then dies at `npm run … vitepress build`
(`ProcessExited(127)`), confirmed to fail IDENTICALLY from `main` in this same checkout — a
`main` worktree in `/tmp` resolved a different docs environment and DID build, so this is a
property of this checkout, not the repo. **CI did not run:** `CI.yml` has no `push` trigger
(`#367`), so pushing branches tests nothing; no PR was opened.

The load-bearing check is not any of those. Both branches were diffed against a `main`
worktree at full `repr` precision: log-likelihood at and away from the optimum, β, both BLUP
blocks, the full 3×3 covariance, every SE, the interval endpoints; and for the fit, variance
components, log-likelihood, iteration count, convergence, β and BLUPs across the default fit,
`em_warmup = 3`, an explicit `initial` and a K = 3 fixture. All **bitwise identical**.

## 6. Tests of the Tests

- **A false pass was caught and fixed.** The first fit-verification run diffed two files that
  were both EMPTY — the script had errored on a malformed K = 3 fixture (`repeat(…, inner=7)`
  giving 560 indices for 600 rows) and `diff` duly reported no differences. It printed
  "BITWISE IDENTICAL". Fixed by sizing the fixture correctly and printing line counts
  alongside the diff, so an empty comparison can no longer read as success.
- **Two test claims were wrong and the suite caught them, not inspection.** (i) A rail test
  asserted that `multi_effect_uncertainty` returns standard errors when a component sits at
  1e-14; it does not — the covariance itself is unavailable there, and it throws. The test was
  rewritten to separate the two cases (rail via `boundary_tol` with a healthy covariance;
  near-zero component refused once), which is the behaviour actually worth pinning. (ii) A
  test asserted `:auto` never costs extra iterations; on a unit-variance fixture it costs 12
  against 10. Both the test and the docstring now state that iteration count is a property of
  the data, not of the option.
- The FD-loop test counts calls (`@test calls[] == 4*3*4 ÷ 2`), so reinstating the discarded
  lower-triangle cells fails loudly rather than silently costing 50%.
- The in-place assembly test compares `colptr`, `rowval` AND `nzval` against
  `_sparse_multi_lhs_rhs` at five σ in mixed order, so a later assembly inheriting state from
  an earlier one would show up.

## 7a. Issue Ledger

No issue opened or closed. References `#352` (the arc these functions came from), `#360`
(owner handover of performance work), `#343` (`initial` not forwarded on the sparse route —
`:auto` addresses the engine half, not the bridge half), `#366` (the coverage-calibration
debt, untouched), `#367` (no `push` CI trigger — confirmed, and it is why these pushes ran no
tests), `#353`/`#361`/`#363` (selected inverse — measured not to be this workload's lever).
Twin-repo: `julia-bridge.R:1352–1412` should call `multi_effect_uncertainty` once; not edited
from this lane.

## 8. Consistency Audit

Review lenses were applied as PERSPECTIVES. **No subagent was spawned** in this session.

- **Gauss / Karpinski (numerics, performance).** Every claim in the plan was measured before
  being proposed and re-measured after implementation; the two hypotheses that did not survive
  measurement (AI matrix, dead PE levels) were dropped rather than shipped. The one structural
  assumption — that the Henderson pattern is σ-invariant — is enforced at runtime by
  `_nz_index_map` throwing, not assumed.
- **Rose (claim-vs-evidence).** Points checked: no capability flip, `public_covered_count`
  stays 7, version stays 0.9.0, no `validation_status()` row added or removed, the new
  capability row carries its own fences (experimental, asymptotic, uncalibrated, no external
  comparator, great tit ASReml agreement is development-only because ASReml is licence-absent),
  and every performance figure is stated as one machine / one dataset / one run with the
  ASReml comparison explicitly NOT claimed. The scope line of `V1-HERIT-CI` said
  "univariate-Gaussian, dense/validation-scale" while the row now carries a sparse K-effect
  surface; corrected rather than left.
- **Grace (CI/release).** The honest finding is that pushing proves nothing here: `#367` means
  these two branches have no CI evidence at all, which the check-log states plainly rather than
  implying green.

## 9. What Did Not Go Smoothly

- **`graft` was unavailable** (MCP server `ENOENT`, no CLI on `PATH`), though `CLAUDE.md`
  requires getting context from it before grepping. The audit fell back to direct reading.
  Worth fixing before the next slice, since the instruction is repo-wide.
- **The docs build sent me down a false trail.** A `main` worktree in `/tmp` built docs
  successfully while the branch did not, which looked like a regression I had caused. It was
  two different `docs/Manifest.toml` resolutions; the correct comparison (checking out `main`
  in the SAME checkout) showed identical failure. That second comparison also rewrote
  `docs/Project.toml` with a machine-local `[sources]` entry, which had to be reverted — the
  same `docs/make.jl` + `git` gotcha recorded in the 2026-09-17 report, hit again.
- **A real docs error hid behind the known one.** Because the npm failure was expected, the
  first branch build's `:cross_references` error was nearly filed as "the usual npm thing". It
  was a genuine unresolvable `@ref` that my `api.md` change had surfaced.

## 10. Known Residuals

- **The R lane must change for the last 0.4 s.** `julia-bridge.R` still makes three calls.
- **`selinv_block_traces` is now the dominant remaining cost** — roughly 0.40 s of the 0.65 s
  fit. `sparse(ch.L)` is only 2.3 ms of its 48.9 ms, so the `Θ(Σⱼ|L[:,j]|²)` recursion itself
  is the term. Options, unmeasured: thread it over independent elimination-tree subtrees
  (`Threads.nthreads()` is 1 here), or benchmark SelectedInversion.jl on THIS factor (`#353`)
  — its recorded lead was measured at high fill and may not survive at clique 17.7.
- **No coverage calibration** of the K-effect SEs or the summed-ratio interval (`#366`). This
  slice made them cheaper, not better-evidenced.
- **No CI evidence** for either branch (`#367`), and no PR opened.
- **One dataset, one machine, one run per cell.** No replication, no second architecture, and
  no ASReml run of our own — the ~2 s figure remains the owner's report.
- **The #352 arc's own check-log entry and after-task report do not exist** and were not
  manufactured. The green suite recorded here is for a tree containing those commits, run
  2026-09-21, not evidence from when they landed.
- **`AGENTS.md`'s Live Phase Snapshot is stale** (dated 2026-09-07, says "version 0.8.0 …
  0.9.0 NOT authorized" while `Project.toml` is 0.9.0 and `v0.9.0` is tagged). Flagged at
  rehydration, out of scope here, and it requires archiving the current entry verbatim first.

## 11. Team Learning

- **"Why is this slow" was answered by the wrong component twice in a row.** The 2026-09-17
  slice found a memory bug, the 2026-09-19 slice found the selected-inverse constant — and on
  the owner's actual dataset neither is the cost. 83% of it was post-fit uncertainty that no
  performance work had looked at, because the profiling had always been aimed at the fitter.
  Profile the workload the user runs, not the function whose name matches the complaint.
- **A cheaper quantity that differs by 6% is a different quantity.** The AI matrix was sitting
  there, already computed and discarded, and would have been an easy "optimization" to ship
  without checking. Measuring it against the shipped estimand is what stopped it.
- **An empty diff is not a passing diff.** A verification harness that can report success
  while producing no output is worse than no harness. Print the row count next to the result.
- **Adding a function to `api.md` is a check, not just documentation.** Two pre-existing
  defects (an unresolvable `@ref`, and — separately — a stale citation anchor) surfaced only
  because previously-undocumented functions were finally included.

## 12. Cross-Product Coverage

- **Post-fit uncertainty surface.** Covers ✓: bitwise identity of the log-likelihood, BLUPs,
  covariance, SEs and interval against the pre-change code on a real 11,856-record fixture and
  on a seeded fixture; the combined entry point equalling the three standalone functions
  exactly; the FD evaluation count; rail and boundary behaviour separated; argument guards.
  Does NOT cover ✗: coverage calibration of any of it (`#366`); any K > 3; correlated random
  effects; non-Gaussian; the R bridge actually calling the combined entry point.
- **Sparse AI-REML fit loop.** Covers ✓: in-place assembly equalling `_sparse_multi_lhs_rhs`
  in structure and values at five σ in mixed order; symbolic reuse equalling a fresh factor on
  `logdet` and on a solve; the closing log-likelihood bitwise equal to the standalone one;
  reduction to the dense oracle re-pinned; `em_warmup` and `initial = :auto` paths; bitwise
  identity against `main` for default / warm-start / explicit-initial / K = 3. Does NOT cover
  ✗: the matrix-free dispatch branch (untouched but not re-verified at scale); any pedigree
  larger than 10,937; a non-PD `C` actually exercising the `_factorize!` fallback (no
  deterministic fixture built for it — the fallback is reasoned, not tested).
- **Records and ledgers.** Covers ✓: the #352 surface now has a capability row and debt
  coverage; citations verify; the shard validates; the status page regenerates unchanged in
  row count. Does NOT cover ✗: retroactive check evidence for the #352 arc; a spawned Rose
  audit (lens applied as a perspective only); CI on either branch.
