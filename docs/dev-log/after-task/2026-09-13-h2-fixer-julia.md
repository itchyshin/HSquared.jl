# After-task — 2026-09-13 H² twin fixer campaign, Julia half

## 1. Goal

Close the four `HSquared.jl` issues the H² twin test campaign filed (#331, #327, and the
Julia halves of hsquared#212 and hsquared#214/#217), each with a failing-test-first fix,
local checks, green CI, and a Rose claim-vs-evidence audit, merged to `main`; no version
bump, no capability-status/validation-debt status-cell change. This report and the matching
`check-log.md` entry are the Julia-lane records; the R half of the campaign is a separate
report in the `hsquared` repo.

## 2. Implemented

Five PRs, all merged to `main` in the order Rose required (each rebased onto the new `main`
and re-CI'd before the next merged):

- **#337** (`d5b45b01`, engine half of hsquared#212) — `src/bridge_payload_v2.jl`:
  `fit_payload_v2`/`_dispatch_fit` gained `initial`/`iterations` kwargs, forwarded only to
  the `:multi_effect` (dense) and `:direct_maternal` dispatch arms, which previously
  hardcoded the engine call and silently discarded both. `src/genomic.jl`: `fit_gblup_reml`,
  `fit_single_step_reml`, `fit_metafounder_single_step_reml` gained an `iterations` kwarg,
  threaded to `fit_animal_model`'s `kwargs...` passthrough. Every new kwarg defaults to
  `nothing`, omitted unless supplied — every default call stays byte-identical.
  `test/test_212_engine_controls.jl` (new).
- **#341** (`3c16298e`, engine half of hsquared#214/#217) — `src/likelihood.jl`: generalized
  `_check_dense_validation_size` into a `(nobs, nanimals, max_dense_cells)` method that names
  the effective cap in its `ArgumentError` text (previously only the observed cell count was
  named); the existing `AnimalModelSpec` method now delegates to it. Added
  `max_dense_cells::Integer = DEFAULT_MAX_DENSE_CELLS` to `fit_repeatability_reml`, which
  previously built its dense `inv(Symmetric(Matrix{Float64}(Ainv)))` with no size guard at
  all, unlike its three sibling fitters. `test/test_214_217_dense_cells.jl` (new).
- **#342** (`28b58581`, closes #327) — `src/nongaussian.jl`: `NonGaussianFit` gained
  `boundary::Bool` and `restart_estimate::Union{Nothing,Float64}`, set in every one of
  `fit_laplace_reml`'s nine family branches (single-variance Brent-bracket families;
  `:ordered_probit` split by `K`; `:gamma`; and new ±8-log-unit joint safety rails added to
  `:gaussian`/`:nbinom`, which had no bound at all before). `nongaussian_three_field_payload`
  now refuses a `boundary = true` fit with an actionable `ArgumentError`. New opt-in
  `restart_check::Bool = false` kwarg: one hard-coded non-recursive refit from
  `sa0 * exp(3.0)`, comparing log-scale point estimates. `converged` semantics unchanged (the
  R twin's existing consumer does not break). `test/test_327_boundary_flag.jl` (new).
- **#339** (`885f884f`, closes #331) — `src/multivariate.jl`: `_mv_nparams` now subtracts
  `r(r-1)/2` from the raw loading-parameter count for `:lowrank`/`:factor_analytic`, removing
  the rotational-indeterminacy overcount `ledermann_slack` already implied but `_mv_nparams`
  ignored. `covariance_structure_lrt` now calls `nested_lrt(...; boundary_df = 0, ...)`
  **unconditionally** (the `interior ? 0 : df` conditional is gone), so a structured
  comparison never enters `nested_lrt`'s convex-cone chi-bar-mixture branches — it always
  reports the plain χ²`df` tail, with a new `reference` field naming which distribution
  produced the p-value. `src/validation_status.jl`: two `evidence` strings corrected (not the
  `claim_boundary` field the generated docs page renders). `test/test_331_structured_lrt_df.jl`
  (new), plus a new pinning assertion added to the pre-existing `mv2_lr`/`lrt_lr`
  `:lowrank t=2 rank=1` testset in `test/runtests.jl`.
- **#338** (`a4cf08e5`, docs-only, merged last by design) — `src/genomic.jl`: `fit_snp_blup`
  docstring no longer states the GBLUP↔SNP-BLUP equivalence unconditionally (#333).
  `tools/write_validation_status_page.jl`: dropped the `<!-- regenerated: ... -->` timestamp
  comment that dirtied a tracked file on every `docs/make.jl` run (#334), with a new
  idempotency test (`test/test_334_status_page_idempotent.jl`). `src/likelihood.jl`: `σ_P` →
  `σ²_P` on every user-visible docstring/runtime string (hsquared#210, Julia half; 4 sites).
  `docs/src/twin-boundary.md`: a twin-contract-rule paragraph, worded to stay true whether or
  not the matching R-side paragraph has landed. `docs/src/changelog.md`: Unreleased entries
  for all five PRs in this wave.

## 3a. Decisions and Rejected Alternatives

- **F1 (Rose wave A, BLOCK on #339).** The naive df fix for #331 silently routed the headline
  factor-analytic case into `nested_lrt`'s 50:50 chi-bar-mixture branch — exactly the
  reference distribution the PR's own new docstring said the function does not compute. Two
  resolutions were offered: (1) make the code match the docstring's naive-χ² claim, or (2)
  make the docstring match the mixture the code actually applies. **Resolution 1 was chosen**:
  `covariance_structure_lrt` now always requests the plain `boundary_df = 0` tail for a
  structured null; a genuine PSD-boundary null (e.g. `:lowrank`) still reports `boundary =
  true` but with the naive χ² tail and its direction stated as unknown, never the mixture.
  This is a substantive statistical decision, not a wording change, and it changes a returned
  number on an already-tested path (see below).
- **The `:lowrank t=2 rank=1` p-value now doubles.** Rose's wave-C re-audit (J1R-3) found that
  this resolution silently changes the p-value on a pre-existing, already-covered test case
  (`test/runtests.jl`'s `mv2_lr`/`lrt_lr` fixture, `df == 1`): previously the 50:50 mixture
  returned half the naive χ²₁ tail; the fix returns the full tail. CI stayed green throughout
  because that testset never asserted `pvalue` before. Rather than let this pass silently, a
  new pinning assertion was added (`lrt.reference == :chisq_naive_boundary`, `pvalue` checked
  against `_chisq_sf` directly, comment noting "was 0.5x this before #331"), and three ledger
  rows' prose (not status cells) were updated to state the change explicitly.
- **`:gaussian`/`:nbinom` gain a rail on the default path, not just an opt-in one.** #327's fix
  could have made the new ±8-log-unit rail configurable/opt-in for these two families (which
  previously had no bound at all); instead it applies unconditionally, matching the ±8 rail
  `:gamma` already used. Accepted as the disclosed intent of the fix (stated plainly in the PR
  body) — it can change a returned estimate on badly-scaled default-`initial` data, which is
  exactly the boundary-honesty problem #327 exists to surface via `fit.boundary`.
- **`restart_check` defaults to `false` and is not recursive.** A single hard-coded inner
  refit, never chained — avoids runaway recursion and keeps the default fit path's cost
  unchanged. The two-start fence itself was sized against a different configuration than the
  one shipped (measured: `:poisson` only, factor-of-10 relative gap; shipped: all nine
  families, factor-of-`e³` log-scale gap) — disclosed rather than mis-cited as "measured".
- **Merge order was load-bearing, not cosmetic.** Rose's wave-B shared-file map showed
  `test/runtests.jl` as a universal collision point across all five PRs, with #338 and #341
  appending to the byte-identical tail hunk. The chosen order (#337 → #341 → #342 → #339 →
  #338) rebases each PR onto the new `main` and lets CI re-run to completion before the next
  merges, rather than trusting a green run measured only against the old `main`. #338 merged
  last by explicit design: its #331/#327 changelog entries are only true once #339/#342 land.
- **Follow-ons opened rather than silently deferred.** Every "NOT COVERED" item that describes
  a real, reachable gap (not merely an out-of-scope design choice) got its own issue (#340,
  #343, #344, #345) rather than a dangling PR-body footnote — Rose required this explicitly
  for #342 (J2-4) after noticing j1/j3 had done it and j2 initially had not.
- **No version bump, no status-cell change, attempted anywhere.** Confirmed mechanically at
  every audit round (`git diff <base> <head> -- Project.toml docs/design/capability-status.md
  docs/design/validation-debt-register.md`), not merely asserted.

## 4. Files Touched

This records-only pass touched, in the `claude/h2-fixer-records` worktree:

- `docs/dev-log/check-log.md` — one new entry appended at the end of the file (2026-09-13,
  H2 fixer campaign Julia half).
- `docs/dev-log/after-task/2026-09-13-h2-fixer-julia.md` — this report (new).

Files touched by the five merged PRs (already on `main` before this pass started; listed for
the record, not re-touched here): `src/bridge_payload_v2.jl`, `src/genomic.jl`,
`src/likelihood.jl`, `src/nongaussian.jl`, `src/multivariate.jl`, `src/validation_status.jl`,
`tools/write_validation_status_page.jl`, `docs/src/twin-boundary.md`,
`docs/src/changelog.md`, `docs/design/capability-status.md`,
`docs/design/validation-debt-register.md`, `Project.toml` (test-only `Distributions`
dependency added by #339, `version` line untouched), `test/runtests.jl`,
`test/test_212_engine_controls.jl`, `test/test_214_217_dense_cells.jl`,
`test/test_327_boundary_flag.jl`, `test/test_331_structured_lrt_df.jl`,
`test/test_334_status_page_idempotent.jl`, `test/a3_three_field.jl`,
`test/a4_binomial_observation_scale.jl`.

## 5. Checks Run

- `Pkg.test()` — **not re-run in this pass**, per this task's explicit brief: it already
  passed on this exact merged `main` (`a4cf08e5`) at the orchestrator's own run, 2026-09-13
  ~13:3x local (`Testing HSquared tests passed`, exit 0). Cited, not repeated.
- `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=4 julia --project=docs docs/make.jl` — run fresh
  in this worktree (background, watched with a Monitor until-loop, no sleep chain). Clean
  VitePress/Documenter build; deployment correctly skipped locally (`Documenter could not
  auto-detect the building environment` — expected with no `CI` env set); only the
  pre-existing "docstrings not included in @docs/@autodocs" warning list (unrelated,
  pre-existing on `main`). `git status --porcelain` **clean** afterward — confirms #334's fix
  holds on merged main (the tracked `docs/src/validation-status.md` page is not dirtied by a
  plain build).
- `bash tools/preamble_cap.sh` — `CAP OK`: 11024 B (~2756 tok) of a 14000 B cap; 1 snapshot
  entry of a cap of 1.
- CI on `main` (`gh run list -R itchyshin/HSquared.jl --branch main -L 6`): green throughout
  the merge sequence, with one transient exception (§9).

## 6. Tests of the Tests

- Every builder report records an explicit red run before the fix and a green run after,
  reproduced by stashing the source change and re-running the same test file (j1, j2, j3, j4
  all show this pattern with verbatim error text: `MethodError: unsupported keyword
  argument`, `type NonGaussianFit has no field boundary`, `ArgumentError: df = 0`).
- Rose independently re-ran the red→green cycle herself for #337/#338/#339 in scratch
  worktrees rather than trusting the builder reports (`rose-julia-a.md` §Method), confirming
  the red state was real against pre-fix `main` and the green state matched the reported
  numbers.
- #339's new pinning assertion (`lrt_lr.pvalue ≈ HSquared._chisq_sf(...) atol=1e-12`) is
  specifically designed to be non-regressible: Rose noted the recorded red-state numbers
  differed by exactly a factor of two (`1.49e-45` vs `2.99e-45`), which is the 50:50-mixture
  signature and "could not have been fabricated" — i.e. the test would catch a silent
  reversion to the old mixture branch.
- #342's `restart_check` test (c) pins the no-recursion guarantee by an independent manual
  refit comparison rather than by counting calls — the stronger check, per Rose's wave-B note.
- #334's idempotency test runs `write_validation_status_table!()` twice into a scratch copy
  and requires byte-identical output with no `regenerated:` line — this pass's own
  `docs/make.jl` run against merged `main` is a live re-confirmation of that guarantee.

## 7a. Issue Ledger

Closed by a merged PR: HSquared.jl **#331** (PR #339), **#327** (PR #342). Julia halves fixed
(not closed — R half is separate) of hsquared **#212** (PR #337), **#214**/**#217** (PR #341).
Docs-only fixes for HSquared.jl **#333**, **#334**, and the Julia half of hsquared **#210**
(PR #338). Follow-on issues opened, all `OPEN`: **#340** (`ngen` optimizer parameter count,
follow-on to #331), **#343** (`:auto`-path `initial`/`iterations` drop, follow-on to
hsquared#212/#337), **#344** (`laplace_reml_interval` does not consume `boundary`, follow-on
to #327/#342), **#345** (R bridge reads only `converged`, follow-on to #327/#342; R-lane work,
pointed at the twin issue `itchyshin/hsquared#222`).

## 8. Consistency Audit

- **Same-class check for #327 (boundary honesty):** Rose's wave-B audit verified `boundary` is
  set in *every* one of the nine `fit_laplace_reml` family branches, including the two
  (`:gaussian`, `:nbinom`) that previously had no rail at all — not just the family named in
  the original issue. Confirmed table in `rose-julia-b.md`, branch-by-branch with exact line
  numbers.
- **Same-class check for #331 (df/reference honesty):** the fix was checked against every
  reachable structured-null shape, not just the FA case the issue named — the wave-C audit
  found and fixed the `:lowrank t=2 rank=1` case that was *already in the test suite* and
  would have silently changed behaviour with no record.
- **Same-class check for the `:auto` silent-drop pattern (#212/#337):** Rose's wave-A audit
  found the same silent-drop defect class recurs on the `scale_method = :auto` path that #337
  did not fix — filed as #343 rather than left as an uncorrected claim in the fixed PR's own
  comment.
- **Same-class check for evidence-pointer dangling (dangling "see docs page" references):**
  found once in wave A (#333's pointer to `genomic-models.md`, which lacks the measurement)
  and again, amplified to three places, in wave C when #338's repair had not fixed it —
  corrected in all three places (docstring, changelog, PR body) rather than one.
- **Same-class check for follow-on issue discipline:** j1 (#340) and j3 (#343) opened their
  follow-ons correctly; j2 initially did not (J2-4) — caught in the same wave-B audit and
  fixed with two issues, filed in the right repo/label after a second correction (J2R-3, wave
  C) moved #345's substance to the R-lane's own issue tracker.

## 9. What Did Not Go Smoothly

- **Named-lens agent types declined to implement.** j2 (#327) and j4 (#214/#217) were
  originally dispatched to `gauss-numerical-engineer`/`karpinski-julia-performance`; both
  declined to write code and had to be relaunched as `general-purpose` agents. Lesson: the
  named lenses in `.claude/agents/*.md` are review-only personas, not implementation agents —
  recorded so the next campaign dispatches builders correctly the first time.
- **A transient `gh-pages` push race at #337's merge.** The `Documenter` CI run at merge
  commit `d5b45b01` (run `34773980346`) failed — not from a build or content error (the
  VitePress build itself completed clean) but from `git push -q upstream HEAD:gh-pages`
  exiting 1 with `! [rejected] HEAD -> gh-pages (fetch first)`, a non-fast-forward race against
  a concurrent gh-pages write. The very next Documenter run, at #341's merge commit
  `3c16298e` (run `34774458164`), succeeded — confirming the race was infrastructure, not a
  regression. Per Rose's J5R-7, the correct response was to let the job re-run, not to "fix"
  the docs chasing a phantom error.
- **Three Rose audit rounds and two repair rounds were all substantively needed**, not
  ceremony: round A found a genuine statistical-correctness BLOCK (F1) that no test caught;
  round B found completeness gaps (missing follow-on issues, an unbound R-facing string,
  self-contradicting prose) that CI's green state said nothing about; round C, re-auditing the
  *repairs themselves*, found a new substantive defect (J1R-3's silent p-value doubling on an
  already-covered path) that the repair for round A's finding introduced. Skipping any one
  round would have shipped either a statistically dishonest fix, an internally contradictory
  changelog, or a silent behaviour change on covered code with no test and no record.
- **`main` merged into feature branches, never rebased.** Because `test/runtests.jl` was a
  five-way collision point (every PR appended to it), rebasing would have rewritten shared
  history mid-campaign; ordinary merge commits kept each branch's own history intact while
  still picking up the previous merge's changes before the next PR's CI ran.

## 10. Known Residuals

- **`ngen` (fit_multivariate_reml`'s optimizer parameter-vector sizing) still overcounts** the
  same rotational indeterminacy #331 fixed only in the *reporting* `df` — filed as #340,
  deliberately not touched here (larger blast radius: the fitter's own search space, not just
  a downstream count).
- **The `scale_method = :auto` path on `fit_payload_v2`'s `:multi_effect` arm still drops
  `initial`/`iterations`** — filed as #343; an experimental opt-in path with no test coverage
  in #337, not fixed there.
- **`laplace_reml_interval` does not consume `NonGaussianFit.boundary`** — filed as #344; a
  boundary-riding point estimate still yields a self-consistent but uninformative interval,
  with no warning from the interval call itself.
- **The R twin does not yet read `boundary` at all** — filed as #345 (Julia side) and
  `itchyshin/hsquared#222` (R side, the repo where the fix must actually land); the R bridge's
  generic wrapper (`R/julia-bridge.R:767-778`) still reads only `converged`.
- **`repeatability_interval` is not guarded or configurable by #341** — it rebuilds the same
  dense inverse internally at the default `max_dense_cells` cap regardless of what the caller
  passed to the outer call, a gap Rose required be disclosed in #341's PR body (J4-1) rather
  than fixed, since it was outside the named scope.
- **Two other pre-existing `max_dense_cells` guards use a different error-text shape** (`n*n`
  observations-only, vs. the new `nobs^2+nanimals^2` shape) — recorded by Rose as a uniformity
  question for a future wording-only slice, not required here.
- **`Project.toml`'s `version = "0.9.0"` does not reconcile with `changelog.md`'s newest
  released section, `0.8.0`** — a pre-existing, pre-campaign discrepancy (confirmed present on
  `main` before this campaign started) that Rose and #338's PR body both flag as belonging to
  the release owner, not to this fixer campaign.
- **The R half of this campaign (r1–r5, closing the eleven remaining R-side issues) is a
  separate, ongoing lane** with its own report in the `hsquared` repo — not this report's
  scope.

## 11. Team Learning

- **Builders that implement code must be dispatched as `general-purpose` agents, not the
  named review-lens types** (`gauss-numerical-engineer`, `karpinski-julia-performance`, etc.)
  — those types are review-only personas and will decline an implementation task. Route
  implementation to `general-purpose` with the lens named in the brief instead.
- **Every Rose CHANGES round in this campaign found something a green CI run could not have**:
  a statistical-honesty contradiction between a docstring and the code path it describes (F1),
  a silent behaviour change on an already-covered test case with no assertion (J1R-3), and
  several claims about a *sibling repo* (the R twin) that were false on that repo's own `main`
  at the time they were written. Green CI proves the code does not crash; it says nothing
  about whether the code's own claims about itself, or about its twin, are true.
- **Merge `main` into an in-flight branch; never rebase it**, once multiple PRs are queued
  against a shared collision file (here, `test/runtests.jl`'s tail). Rebasing would have
  silently reordered five PRs' independent history; merging kept each branch's provenance
  intact while still re-running CI against the latest `main` before every merge.
- **A CI leg that fails on infrastructure (a `gh-pages` push race) must be distinguished from
  one that fails on content** before "fixing" anything — the fix for the former is "re-run it,
  do not touch the diff"; treating it as a content failure would have wasted a repair round
  chasing a phantom defect.
- **A claim about the other twin belongs where the other twin's reader will see it** — #345
  was initially filed in the wrong repo with the wrong label, which Rose's own campaign
  thesis ("a claim about the other twin has to reach the other twin's reader") caught applied
  to its own paperwork.

## 12. Cross-Product Coverage

This campaign touched four cross-cutting surfaces on the Julia engine. Coverage below is
stated per surface, not just per issue.

- **Engine-control forwarding (`initial`/`iterations`), #212.** Covers ✓: the `:multi_effect`
  (dense `scale_method`) and `:direct_maternal` dispatch arms of `fit_payload_v2`, and
  `fit_gblup_reml`/`fit_single_step_reml`/`fit_metafounder_single_step_reml`. Does NOT
  cover ✗: the `:multi_effect` arm's `scale_method = :auto` (matrix-free) path, which accepts
  the same controls through `fit_multi_effect`'s `kwargs...` but is not forwarded there
  (#343); `multi_effect_ratio_interval`'s internal refit path, called directly from R rather
  than through `fit_payload_v2` (not fixed by this PR, flagged for a follow-up engine slice);
  the `:animal`/`:two_effect` dispatch arms (already had their own correctly-forwarding R
  paths, out of scope by design); the R-side forwarding itself (`hs_control()` → the Julia
  call sites) — a separate slice in the `hsquared` repo.
- **Dense-validation size guard (`max_dense_cells`), #214/#217.** Covers ✓:
  `gaussian_loglik`, `fit_variance_components`, `bootstrap_variance_component_interval` (error
  text sharpened only — they already had the kwarg), and `fit_repeatability_reml` (newly
  guarded). Does NOT cover ✗: `fit_ai_reml` (deliberately — genuinely sparse, never
  materializes a dense object, and structurally cannot receive the kwarg since it has no
  `kwargs...` catch-all); `repeatability_interval`, which independently rebuilds the same
  dense inverse at the default cap regardless of what the outer call was configured with
  (#341's own NOT-COVERED note, required by Rose); the two pre-existing guards using the
  `n*n`-only error-text shape (recorded, not required to change); the R-side forwarding of
  `engine_control$max_dense_cells` into `hs_fit_julia_payload`'s and
  `hs_fit_julia_repeatability_payload`'s `julia_command()` calls — a separate R-lane slice.
- **Boundary honesty (`NonGaussianFit.boundary`), #327.** Covers ✓: all nine
  `fit_laplace_reml` family branches (the Brent-bracket single-variance families;
  `:ordered_probit` split correctly by `K`; `:gamma`; and the two families that gained a rail
  for the first time, `:gaussian`/`:nbinom`); `nongaussian_three_field_payload`'s refusal gate;
  the opt-in `restart_check` two-start fence. Does NOT cover ✗: `laplace_reml_interval`,
  which does not read `boundary` at all and still anchors its profile search on a possibly
  boundary-riding point estimate (#344); the R bridge's generic wrapper, which reads only
  `converged` (#345, `itchyshin/hsquared#222`); the two-start fence's own sizing evidence,
  which was measured on `:poisson` only with a different gap statistic than the one shipped
  (disclosed in the docstring, not re-measured for the other eight families).
- **Structured-null LRT reference distribution (`covariance_structure_lrt`), #331.** Covers ✓:
  `_mv_nparams`'s parameter count for `:lowrank`/`:factor_analytic`; the reference-distribution
  choice for every structured-null comparison (`:factor_analytic` — regular submanifold,
  `boundary = false`, plain χ²; `:lowrank` — genuine PSD boundary, `boundary = true`, naive χ²
  tail with direction stated as unknown); the pre-existing `:lowrank t=2 rank=1` test case,
  now pinned against the doubled p-value. Does NOT cover ✗: `fit_multivariate_reml`'s own
  optimizer parameter-vector sizing (`ngen`), which still searches over the flat rotational
  directions the reporting fix removed only from the *count* (#340); whether a fit whose
  factor-analytic `ψ̂` has been driven onto its `1e-4` regularization floor (a Heywood case on
  a *different* constraint boundary) invalidates the "regular submanifold" argument — flagged
  in the docstring (J1R-5) as an unstated, unchecked condition, not verified against any
  actual fit; any R-facing surface for the new `reference` field, which no R consumer reads
  today (the payload already refuses `:lowrank`/`:factor_analytic` outright) but which nobody
  has decided whether to expose.
