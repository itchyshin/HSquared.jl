# Sparse REML Optimizer — Independent Review (270e7b2)

Active lenses: Gauss, Karpinski, Curie, Fisher, Rose (review perspectives).
Spawned subagents: a 5-agent review workflow (`wf_2773a875-85a`) was launched but
its review agents were interrupted mid-run by a user interrupt (13:18Z); no
structured results were captured. The review was therefore completed **inline**
(not by spawned subagents).

## Goal

Independently verify the landed sparse REML validation optimizer (`270e7b2`,
`fit_sparse_reml` / `fit_animal_model(...; target = :sparse_reml)`) per the
takeover plan's Phase B review step. The slice was authored on the Julia lane and
is already CI-green; this is a second, independent set of eyes — not a re-build.

## Verification evidence

- Local `julia --project=. -e 'using Pkg; Pkg.test()'` → **543 checks pass**.
- Remote CI `27466629703` + Documenter `27466629704` + Pages green.
- Read: `src/likelihood.jl` (`fit_sparse_reml`, dispatch, `_coerce_fit_target`,
  `AnimalModelFit` struct), `test/runtests.jl` additions, `validation_status.jl`,
  `capability-status.md`, `validation-debt-register.md`.

## Findings by lens

- **Gauss (numerics)** — sound. Log-variance parameterization keeps variances
  positive; NelderMead is derivative-free and appropriate for a tiny validation
  optimizer; the `PosDefException -> Inf` guard prevents crashes on non-PD trial
  points; the objective is recomputed at the optimum. No blocker.
- **Karpinski (types/perf)** — `AnimalModelFit` widened by four concrete-typed
  fields (`target::Symbol`, `dense_validation_path::Bool`, `sparse_mme_path::Bool`,
  `variance_components_source::Symbol`); all construction sites updated; no
  regression (543 green). Production performance is explicitly out of scope. No
  blocker.
- **Curie (tests) — FINDING (medium, non-blocking)**: the testset covers the API,
  the standalone-vs-`target`-dispatch parity, edge-case guards (`method != :REML`,
  non-positive initial variance, `target = :sparse_reml` with a non-REML spec,
  `target = :sparse_reml` + `variance_components` misuse), and the path-aware
  `fit_diagnostics` flags. **But the only optimum check is
  `loglik >= start.loglik`** (improves over the supplied start) — there is **no
  assertion that the sparse REML estimates AGREE with the dense REML optimizer**
  (`fit_variance_components(spec; method = :REML)`) or a pinned reference. The two
  REML objectives are mathematically identical, so a sparse-vs-dense agreement
  assertion on the tiny + Mrode9 fixtures is a cheap, strong correctness check
  that would catch an optimizer that improves over the start but converges to the
  wrong optimum. **Recommend adding it** to the `V1-SPARSE-REML-OPT` coverage.
- **Fisher / Rose (claims) — clean.** Status rows are exact and well-bounded:
  "Sparse REML validation optimization | experimental … REML-only, no AI-REML, no
  fitted Mrode/comparator evidence, no production sparse fitting claim";
  `V1-SPARSE-REML-OPT = partial`; `V1-REML` and "Sparse production fitting /
  AI-REML" remain `planned`. The path-aware `fit_diagnostics`/`result_payload`
  correctly derive flags from the struct fields (no hard-coded dense path). No
  overclaim.

## Verdict

**clean-with-limitations.** The slice is correct, honestly bounded, documented,
and CI-green. One recommended, non-blocking follow-up: add a sparse-vs-dense REML
agreement test.

## Coordination notes

- Recommendation posted to Julia issue #7 (validation canon) for the maintainer /
  R twin.
- Did **not** edit `test/runtests.jl` — the maintainer is actively committing to
  this repo; per the shared-file overlap rule (Shannon), the test addition is left
  to a coordinated slice rather than an out-of-band edit.

## What did not go smoothly

- The spawned review workflow (`wf_2773a875-85a`) died when a user interrupt
  cancelled its in-flight agents. **Process lesson:** long background review
  workflows are fragile against rapid interactive iteration; during active
  back-and-forth, prefer an inline review or a resumable/short workflow. The
  scout workflow (`wf_ce6cef1e-01f`) survived because its scan agents had already
  returned results (recovered from the journal); only its synthesis was redone
  inline.

## Next actions

1. (Recommended) sparse-vs-dense REML agreement test — coordinated via issue #7.
2. Next engine frontier: production sparse PEV/reliability via Takahashi selected
   inversion — **copy** `DRM.jl/src/takahashi_selinv.jl` (MIT) per the reuse map
   (`docs/dev-log/scout/2026-06-13-sister-reuse-map.md`); a shared-contract
   coordination point.
