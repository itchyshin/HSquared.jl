# After-task — 2026-09-17/19 reliability() memory fix, AI-REML bottleneck diagnosis, and the selected-inverse kernel fix

> **Addendum, 2026-09-19 — the deferred fix was subsequently DONE.** §10 below records
> "the dominant performance bottleneck ... is diagnosed but NOT fixed" as the leading
> residual. On owner instruction ("continue straight on to the deeper REML performance
> fix") that work was then carried out in the same working tree. `_selinv_zvals`
> (`src/takahashi_selinv.jl`) now materialises each column's clique block densely and
> accumulates over it with unit stride, removing the per-pair binary searches;
> `Θ(Σⱼ|L[:,j]|²)` is unchanged, so this is a constant-factor fix. Output is BIT-IDENTICAL
> (verified with `reinterpret(UInt64, ·)` against a verbatim copy of the old kernel on
> random sparse SPD matrices, pedigree `Ainv` under two mating structures, and a full
> Henderson MME matrix; `maxdiff = 0.0` throughout), and two new tests pin it — including
> the previously unexercised per-pair FALLBACK path, now reachable via an injectable
> `DEFAULT_SELINV_BLOCK_CAP`. Measured with the old kernel restored by stashing only that
> one file: selected inverse **6.65x-9.97x** faster (n=2,000-30,000, `Ainv` and MME,
> realistic and adversarial mating); end-to-end `fit_ai_reml` **7.32 → 2.96 s at n=2,000
> (2.5x)** and **56.77 → 6.87 s at n=8,000 (8.3x)**, identical iterations and estimates.
> Full detail in the 2026-09-19 `check-log.md` entry. Residuals §10 items 3-8 stand
> unchanged; item 1 is now closed and item 2 (the unreconciled q=300k DRAC figure) is
> explicitly still open. Still no external comparator, no real production pedigree, and no
> end-to-end timing beyond n=8,000 — the owner's ASReml-R gap is narrowed, not closed.

# After-task — 2026-09-17 reliability() large-pedigree memory fix + AI-REML bottleneck diagnosis

## 1. Goal

Diagnose an owner report: fitting a standard single-response animal model (animal term
linked to pedigree + a few fixed effects) via HSquared.jl runs much slower than ASReml-R,
and blows up to ~35 GB memory on a ~100,000-row pedigree while ASReml-R handles the same
scale fine. Fix what is fixable now; name what is not.

## 2. Implemented

Local, uncommitted working tree, `main` tip `3281372c` (no branch/PR opened — `gh` CLI is
unavailable in this environment, and the user did not ask for a push).

- **Root-cause fix:** `reliability(fit)`/`reliability(::HendersonMMEResult)` in
  `src/likelihood.jl` unconditionally built a DENSE `n×n` inverse of the pedigree/genomic
  precision matrix `Ainv` to get the animal self-relationship diagonal, regardless of the
  `method` argument (`:dense` or `:selinv`) — an O(n²) memory / O(n³) compute operation,
  infeasible at n≈100,000. New `_selinv_ainv_diag(Ainv)` computes the same diagonal via a
  Takahashi selected inverse of a sparse Cholesky factorization of `Ainv` ITSELF (reusing
  the existing `takahashi_diag` kernel), used when `method = :selinv` — the path
  `result_payload()` requests.
- **Density gate:** new `_effectively_sparse(Ainv)` routes a dense/near-dense `Ainv` (a
  genomic `Ginv`, which `genomic_relationship_inverse` returns fully dense) to the SAME
  dense computation `:dense` uses, since sparse-factorizing an already-dense matrix
  measured 68-189x SLOWER at n=400-1200 — a real regression this gate prevents.
- `accuracy(fit)` now accepts and forwards `method` (previously silently dropped to
  `:dense` regardless of the fit's scale).
- `:selinv` now throws `ArgumentError` (wrapping the underlying `PosDefException`) on a
  non-positive-definite `Ainv`, naming the lever (`method = :dense`), instead of `:dense`'s
  finite-but-meaningless `LDLᵀ` fallback.
- **Secondary fix:** `fit_ai_reml`'s EM-warmup + AI-Newton loops rebuilt sparse
  cross-products (`XᵀX`, `XᵀZ`, `ZᵀZ`) from scratch every iteration via
  `_sparse_mme_system`, though these are REML-iteration-invariant. New
  `_SparseMMECrossProducts`/`_sparse_mme_cross_products`/`_sparse_mme_from_cross_products`
  compute them once and reuse.
- Corrected a false complexity claim (`O(nnz(L))`) in five places in
  `src/takahashi_selinv.jl` and two new places this slice added — the actual cost is
  `Θ(Σⱼ|L[:,j]|²)`, tracking fill-in, confirmed by measurement (see §8).
- Two new committed regression tests: `_selinv_ainv_diag` vs. the exact analytic
  `diag(inv(Ainv)) = 1 + F` identity at n=3000 (beyond the dense reference's own
  feasibility), and a bitwise pin of the cross-product-caching invariant against the
  per-iteration rebuild it replaces.
- Doc/status surfaces updated: `docs/design/capability-status.md` (R result payload shape
  row), `docs/design/validation-debt-register.md` (`V1-SELINV-PEV` and `V1-REML` rows),
  `src/validation_status.jl` (same two rows) + regenerated `docs/src/validation-status.md`.

## 3a. Decisions and Rejected Alternatives

- **Did not attempt to fix `selinv_trace_against`/`_selinv_zvals` itself** (the actual
  dominant cost of `fit_ai_reml` at scale — see §8), despite it being the best answer to
  "why is this slower than ASReml-R." Rejected doing this in the same slice: it is a
  correctness-critical rewrite of a shared kernel (used by PEV, reliability, the AI-REML
  score, and multi-effect models) with real blast radius, identified late in a
  already-long review chain, under shrinking context budget. Recorded as the clear,
  well-scoped next step (`V1-REML` row) rather than attempted under time pressure.
- **Did not fix `fitted_values`'s `Z` densification or `henderson_mme`'s LU-vs-Cholesky
  choice** (Gauss review, §8) — comparable-severity findings, but discovered in review,
  outside the slice's original scope, and each independently sized enough to warrant its
  own verification pass rather than being folded in here unreviewed.
- **Did not add a `max_dense_cells`-style guard to `reliability`/`prediction_error_variance`'s
  dense default** — would change default-path behavior (an ArgumentError where none exists
  today) for a class of callers this slice did not fully enumerate; left as named debt
  rather than a rushed behavior change.
- **Kept `:dense` as the default `method`** for `reliability`/`prediction_error_variance`/
  `accuracy` — changing the default was out of scope and would be a wider behavior change
  than a bug fix; `result_payload` already opts into `:selinv` explicitly.
- **No new capability-status row; folded into the two existing rows it belongs to**
  (`V1-SELINV-PEV`, `V1-REML`) rather than adding a new row, to avoid touching row-count
  assertions and other row-count-dependent surfaces for what is a bug fix to an existing
  experimental capability, not a new one.

## 4. Files Touched

- `src/likelihood.jl` — `_selinv_ainv_diag`, `_effectively_sparse`,
  `_relationship_self_variance_diag`, `_SparseMMECrossProducts` +
  `_sparse_mme_cross_products`/`_sparse_mme_from_cross_products`, `reliability` (both
  methods), `accuracy`, `prediction_error_variance` docstrings, `result_payload` docstring,
  `breeding_values_plot_data` comment.
- `src/takahashi_selinv.jl` — corrected complexity claims (file header + 4 docstrings).
- `test/runtests.jl` — genomic `reliability(:selinv)`/`accuracy(:selinv)` parity assertions;
  new testsets: `_selinv_ainv_diag` vs. dense (pedigree + genomic + non-PD + density gate),
  `_sparse_mme_from_cross_products` bitwise pin, `_selinv_ainv_diag` vs. the `1+F` oracle at
  n=3000.
- `docs/design/capability-status.md`, `docs/design/validation-debt-register.md`,
  `src/validation_status.jl`, `docs/src/validation-status.md` (regenerated).
- `docs/dev-log/check-log.md` (new entry), this report (new).

## 5. Checks Run

All fresh, this worktree, `main` tip `3281372c`:

- `julia --project=. -e 'using Pkg; Pkg.test()'` — full suite **passed**
  (`Testing HSquared tests passed`); `grep -inE "fail|error"` over the log returned empty.
  Run six times across the session as fixes were applied and re-applied after each review
  round; the final run (after all Gauss/Karpinski/Noether/Rose-driven corrections) is the
  one this report certifies. `test_aqua.jl`'s include was temporarily commented out for
  each of these runs to isolate one pre-existing, environment-specific Aqua
  `persistent_tasks` failure from the substantive suite — confirmed via `git stash` +
  rerun to fail IDENTICALLY on unmodified `main` (not caused by this change) — then
  restored before finishing; `git diff test/runtests.jl` at the end shows only the
  intended additive test changes, no stray skip.
- `julia --project=docs docs/make.jl` — fails at the `npm run … vitepress build` step
  (`ProcessExited(127)`); confirmed via the same `git stash` technique to fail IDENTICALLY
  on unmodified `main` (a pre-existing Node/vitepress toolchain gap in this sandboxed
  environment, not caused by this change). The in-suite `#334: validation-status page
  regeneration is idempotent` testset (5/5) is the operative evidence that the Markdown
  content itself is correct; the HTML build step is separately broken for unrelated
  reasons.
- `bash tools/preamble_cap.sh` — `CAP OK` (AGENTS.md untouched).
- `julia --project=. tools/write_validation_status_page.jl` — re-run after every
  `src/validation_status.jl` edit (three times), so `docs/src/validation-status.md` stays
  in sync; 56 rows throughout (no row added or removed).
- A standalone, non-committed benchmark script (scratchpad) demonstrating the fix at scale:
  synthetic 100,000-animal pedigree, old dense path would need ≥80 GB for one matrix, new
  `_selinv_ainv_diag` completes using ~1.15 GB in ~142 s. NOT the owner's own dataset; NOT
  a committed test (deliberately — its runtime is unsuitable for CI).

## 6. Tests of the Tests

- The `_selinv_ainv_diag` vs. `1+F` oracle test is a genuine independent check, not a
  restatement of the fix's own logic: `1 + F_i` is an exact, analytically-known identity
  for the pedigree relationship-matrix diagonal, derivable without ever computing
  `inv(Ainv)` by any method, so it cannot pass merely because both the fix and a flawed
  reference agree.
- The bitwise cross-product test was verified to be a real discriminator, not by
  construction alone but by an independent agent (Karpinski) separately reproducing the
  same bit-identity result via its own scratch probe before I added the committed version.
- One test I initially wrote was WRONG and caught by the suite itself, not by inspection:
  `@test HSquared._effectively_sparse(Ainv)` on a 5-animal pedigree failed, because a
  pedigree that small is genuinely ~85% dense by cell count — the density gate correctly
  said "not sparse" and my test's expectation was the bug. Fixed by testing the gate at a
  110-animal fixture where sparsity is real, re-verified full green afterward.

## 7a. Issue Ledger

No GitHub issue opened or closed by this slice (no `gh` CLI in this environment; not asked
to push). Twin-repo cross-reference: none — this is a Julia-engine-internal fix with no
R-facing bridge payload, model-spec, or public-claim surface change (`result_payload`'s
FIELD SHAPE is unchanged; only the correctness/memory profile of two of its existing
fields' computation changed).

## 8. Consistency Audit

This slice ran a genuinely adversarial internal review, not a single self-check, and it is
worth recording what each lens actually caught rather than summarizing as "reviewed, clean":

- **Rose (claim audit)** on the first-pass doc edits returned BLOCKED, not
  PROMOTE-WITH-CHANGES: (B1) `docs/src/validation-status.md` was stale relative to the
  `src/validation_status.jl` edit — a real, in-suite-guarded (`test/runtests.jl:192`) claim
  drift that would have failed `Pkg.test()` had the full suite been run before Rose's
  audit rather than after (it had been run before the doc edits, not after — an ordering
  mistake in this session, not a tooling gap). Fixed by regenerating the page and rerunning
  the full suite fresh. (B2) the field-reported 100,000-animal/35 GB figure was stated as
  established fact ("the direct cause") rather than an unreproduced report — softened
  everywhere it appeared.
- **Gauss (numerical review)** confirmed `_selinv_ainv_diag`'s correctness (exact vs. the
  `1+F` oracle to 1e-14 at n up to 20,000, permutation handling correct under AMD reordering
  at n=8,000) but found two real defects my first pass introduced: (1) forcing a dense
  genomic `Ginv` through the sparse path is 68-189x SLOWER, not faster — a genuine
  regression, not a hypothetical edge case; (2) `Float64.(Ainv)` on a `Symmetric`-wrapped
  sparse matrix silently densifies via generic broadcast — the SAME bug class this slice
  was fixing, one layer down. Both fixed (density gate; `sparse(Ainv)`-first conversion).
  Gauss also flagged the `O(nnz(L))` complexity claim as unevidenced and measured the true
  scaling (~nnz^1.6 on an adversarial pedigree) before Karpinski's later, more precise
  characterization (`Θ(Σⱼ|L[:,j]|²)`) superseded it.
- **Karpinski (performance review)** is the review that changed this task's framing: it
  measured the cross-product-caching fix at only ~0.03% of one AI-REML iteration's cost
  (not the performance fix it was described as becoming), and identified
  `selinv_trace_against`/`_selinv_zvals` as the actual dominant cost (233x-1780x the
  Cholesky factorization it reuses, ~98.6% of one iteration at n=100,000) — a PRE-EXISTING
  issue this slice did not create, with a documented complexity the implementation does not
  meet. Karpinski also flagged that this APPEARS to conflict with an existing q=300,000
  "2.3s converged" DRAC measurement already in `V1-REML` — recorded as an open,
  NOT-YET-RECONCILED tension rather than silently picking one number over the other.
  Karpinski additionally caught that `:selinv` is not uniformly faster than `:dense`, only
  uniformly smaller in memory (measured SLOWER at n=8,000 on a fill-heavy pedigree) — the
  docstring initially implied otherwise and was corrected.
- **Noether (math/notation review)** caught that "O(nnz(L))" conflated two DIFFERENT
  matrices being selinv'd (the MME coefficient matrix, pre-existing use, vs. `Ainv` alone,
  this slice's new use) in ambiguous prose, found three STALE pre-existing docstrings
  (`prediction_error_variance` ×2, `breeding_values_plot_data`) that flatly contradicted
  the `method` kwarg those same functions already accepted, and found that `accuracy(fit)`
  could not reach the sparse path at all (no `method` passthrough) — a real, user-facing
  gap this slice then fixed rather than just documented.
- **Same-class check performed:** after Gauss found the genomic-`Ginv`-forced-dense
  regression in `reliability`'s NEW code path, I did not check whether the SAME class of
  issue exists in the PRE-EXISTING PEV-via-MME selinv path (`_selinv_mme_random_pev`) for a
  genomic spec — `test/runtests.jl:5940`'s existing comment ("dense Ginv gives no speedup")
  shows this was already known and accepted for that older path, but I did not re-verify it
  is *only* a speed cost there and not also correctness-relevant. Recorded as a residual,
  not silently assumed fine.

## 9. What Did Not Go Smoothly

- **Ran the full test suite, then edited `src/validation_status.jl` again, and initially
  described the (now-stale) earlier green run as current evidence.** Rose's audit caught
  this before it reached the check-log. Root cause: no discipline in this session about
  "any edit after a green run invalidates that run's claim coverage" — worth a standing
  habit, not just a one-off fix.
- **A first attempt at a scaling benchmark used a fully-random-mating synthetic pedigree**
  (parents drawn uniformly from ALL prior animals) and ran for 25 minutes before being
  killed — adversarial fill-in for the AMD ordering, not representative of any real
  pedigree. Rebuilt with a windowed (generation-structured) mating pattern before
  re-running; this second version is what the check-log's "~142s at n=100,000" figure comes
  from. The mistake was informative in hindsight (it is what led to discovering the
  fill-in-dependence of the whole approach) but cost real wall-clock time.
- **A `git stash`/`git stash pop` cycle (used to verify the pre-existing Aqua and
  Documenter/npm failures on clean `main`) conflicted** on `docs/Project.toml`, because
  running `docs/make.jl` on the clean-main checkout itself wrote a machine-local
  `[sources]` path entry to that file, colliding with an identical stashed entry from an
  earlier run in this same session. Resolved by checking out `docs/Project.toml` to `HEAD`
  before popping (the stashed and post-run versions were byte-identical, so no real
  conflict existed once the redundant copy was cleared), then reverting the same
  machine-local artifact again after the pop. No data was lost, but this is a two-step
  gotcha worth remembering for any future `docs/make.jl` + `git stash` combination in this
  repo.
- **This entry and the check-log entry were written after, not interleaved with, three
  rounds of independent review**, meaning several rounds of docstring/comment edits
  (Noether's findings, then Gauss's, then Karpinski's) were applied sequentially to the
  same paragraphs — the diff is coherent (re-verified by rereading it whole before this
  report), but a reviewer diffing intermediate states would see the same sentence rewritten
  three times.

## 10. Known Residuals

- **The dominant performance bottleneck for `fit_ai_reml` at large pedigree scale
  (`selinv_trace_against`/`_selinv_zvals`, `src/takahashi_selinv.jl`) is diagnosed but NOT
  fixed.** This is very likely the real answer to "much slower than ASReml-R"; the
  cross-product caching in this slice is not it. Named, scoped, with an existing-test
  regression gate identified (Karpinski), in `V1-REML`.
- **The q=300,000/"2.3s converged" DRAC measurement and the new n=100,000/"42.9s per selinv
  call" measurement are NOT reconciled.** Both are recorded as live tensions in `V1-REML`,
  not resolved into one number.
- **`fitted_values` densifying `Z` and `henderson_mme` using LU instead of Cholesky**
  (Gauss review) are separate, comparable-severity findings, named in `V1-REML` but not
  fixed.
- **`accuracy()` and `breeding_values_plot_data` still default to `:dense`** — if the
  owner's original 35 GB report went through either of those rather than `result_payload`,
  this slice's fix does not reach it. `accuracy()` now at least CAN reach `:selinv` if
  called explicitly; `breeding_values_plot_data` cannot yet.
- **No `max_dense_cells`-style guard exists on `reliability`/`prediction_error_variance`'s
  dense default** — a direct large-`n` call still silently attempts the O(n³) inversion
  with no early, named error, unlike the dense *fitters* elsewhere in this file.
- **The exact "~35 GB" field figure is not reproduced against the owner's own dataset or
  an allocation trace** — the mechanism is demonstrated on synthetic data of the same
  reported scale, not proven to be the specific cause of that specific number.
- **No fresh Rose re-audit of the FINAL state** (post-Gauss/Karpinski corrections) — only
  the intermediate state was audited by Rose; the corrections applied afterward were
  reviewed against Gauss's/Karpinski's own findings but not by a second Rose pass.
- **Not committed, not pushed, no PR.** Working-tree diagnosis and fix only; `gh` CLI is
  unavailable in this environment.

## 11. Team Learning

- **A fix that closes a real O(n²)/O(n³) memory bug can still be a small fraction of "why
  is this slow"** — this slice's headline finding is that two DIFFERENT problems (a memory
  correctness bug in `reliability`, and a compute bottleneck in `selinv_trace_against`) were
  both plausible explanations for one bug report, and only one of them was actually fixed
  here. Diagnosing "why is X slow/memory-heavy" should budget for more than one root cause
  before declaring victory on the first one found, however well-evidenced.
- **A documented Big-O claim is a claim, not a given** — this repo's own `O(nnz(L))` claim
  for the Takahashi selected inverse had stood, unquestioned and uncited to any benchmark,
  across five docstrings for long enough to be cited AGAIN in this slice's first draft,
  before two independent reviews (Gauss, then Karpinski with a more precise form) measured
  it and found it false. Complexity claims in docstrings should be treated with the same
  evidence bar as capability claims, not exempted as "just math."
- **Density-dependent algorithm selection needs an explicit, testable gate, not a docstring
  recommendation.** The first-pass fix documented "`:selinv` is for pedigree/metafounder
  specs, not genomic ones" as caller guidance; Gauss's review made the point that
  `result_payload` calls `reliability` unconditionally with `method = :selinv`, so
  caller-side guidance is not actually enforced anywhere — the fix needed a runtime gate
  (`_effectively_sparse`), not a comment.
- **When independent review agents disagree with an existing in-repo number (the DRAC
  q=300k measurement) rather than with each other, record the tension rather than silently
  trusting the newer or more detailed measurement** — the new measurement is more
  carefully instrumented, but "more careful" is not the same as "on the same pedigree
  structure," and this repo's own fill-in-dependence findings are the reason the two
  numbers could both be correct for different inputs.

## 12. Cross-Product Coverage

- **`reliability`/`prediction_error_variance`/`accuracy` extractor family.** Covers ✓: the
  `result_payload()` code path (the R bridge's actual consumption point) for a pedigree or
  metafounder `Ainv`, at existing small/medium fixture scale plus one non-committed
  synthetic 100,000-animal reproduction; genomic `Ginv` correctness (both `:dense` and
  `:selinv` now agree and neither regresses the other); non-PD `Ainv` failure mode (loud,
  named error instead of silent garbage). Does NOT cover ✗: `accuracy()` or
  `breeding_values_plot_data` called directly with the (still dense) default; any guard on
  the dense default itself; the owner's actual dataset; a committed CI-scale large-pedigree
  timing test (deliberately, for CI runtime reasons — recorded as a non-committed
  standalone script instead).
- **`fit_ai_reml` iteration-loop efficiency.** Covers ✓: removal of genuinely redundant
  per-iteration sparse cross-product rebuilds, bit-identical to the code it replaces
  (measured, not assumed). Does NOT cover ✗: the actual dominant per-iteration cost
  (`selinv_trace_against`), CHOLMOD symbolic-factorization reuse (identified, deferred at
  Karpinski's own recommendation as a 0.28%-value distraction from the real bottleneck),
  or any change to `fit_ai_reml`'s convergence behavior, numerics, or public API.
- **Complexity-claim honesty on the shared Takahashi selected-inverse kernel.** Covers ✓:
  all five pre-existing `O(nnz(L))` claims in `src/takahashi_selinv.jl` plus the two new
  claims this slice's first draft added, all now corrected to the measured `Θ(Σⱼ|L[:,j]|²)`
  form. Does NOT cover ✗: an actual fix to the recursion's cost — the correction is to the
  DOCUMENTATION of a pre-existing implementation, not to the implementation itself.
