# Check Log

Newest entries go at the top.

## 2026-06-13 Phase 1J Dense PEV And Reliability

- Goal: add dense experimental prediction-error-variance and reliability
  extractors for the low-level Gaussian animal-model validation path.
- Active lenses: Ada, Henderson, Gauss, Fisher, Curie, Mrode, Grace, Rose.
- Spawned subagents: none.
- Implementation evidence:
  - Added `prediction_error_variance(fit)`.
  - Added `reliability(fit)`.
  - PEV uses the lower-right random-effect block of the dense
    mixed-model-equation inverse.
  - Reliability uses `1 - PEV_i / (sigma_a2 * A_ii)` and does not clip values.
- Tests:
  - Added identity-relationship checks against a test-side MME inverse.
  - Extended the Henderson MME fixture to check PEV and reliability against the
    same equation system used for fixed effects and EBVs.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 148 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - Generated docs artifacts were removed after the build.
  - `git diff --check` passed.
  - Claim scan found only allowed dense-experimental wording and blocked/audit
    rows, not public claims that production sparse reliability/PEV, sparse
    production fitting, AI-REML, R-to-Julia bridge execution, or GPU support are
    implemented.
- Boundary:
  - Dense validation path only.
  - Not production sparse reliability/PEV.
  - Not external comparator validation.
  - Not included in `result_payload()` until the R result contract grows those
    fields.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1I HSData Input Container

- Goal: mirror the R `hs_data()` input-container contract in Julia without
  widening claims to file-backed storage, genomic modelling, QTL/eQTL, or model
  fitting.
- Active lenses: Ada, Shannon, Hopper, Emmy, Jason, Karpinski, Grace, Rose.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `644c75e` added `hs_data()` for phenotypes, optional
    pedigree, genotypes, markers, expression, annotation, and environment.
  - R local/remote evidence was reported green in the coordination handoff.
- Implementation evidence:
  - Added `HSData`, `HSDataIDMap`, and `id_map()`.
  - Added exact ID-map fields aligned to the R vocabulary.
  - Added tests for repeated phenotype IDs, normalized and raw pedigree IDs,
    matrix genotypes with explicit IDs, expression IDs, mismatch fields, and
    invalid input errors.
  - Added Documenter page `docs/src/data.md` and design note
    `docs/design/09-hsdata-contract.md`.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 140 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - Generated docs artifacts were removed after the build.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims that
    file-backed storage, QTL/eQTL, genomic relationship construction, live
    R-to-Julia marshalling, sparse production fitting, AI-REML, or GPU support
    are implemented.
- Boundary:
  - `HSData` is an in-memory exact-ID container.
  - It does not normalize IDs across types.
  - It does not read large file formats, construct genomic relationships, run
    scans, or fit models.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1H Result Payload Contract

- Goal: align Julia dense fit result names with the R `hsquared_fit` extractor
  contract before live bridge execution is wired.
- Active lenses: Ada, Shannon, Hopper, Emmy, Fisher, Karpinski, Grace, Rose.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `e543cd7` added `hs_new_fit()` and extractors over mocked
    result fields.
  - Expected result names are `variance_components`, `heritability`,
    `breeding_values`, `fixed_effects`, `random_effects`, `loglik`, `df`,
    `nobs`, `predictions`, `diagnostics`, and `converged`.
- Implementation evidence:
  - Added `result_payload(fit)`.
  - Added exact field-name tests and value tests for the R contract names.
  - Kept internal `AnimalModelFit` stable; bridge result shaping is explicit.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 121 checks
    across Phase 0, pedigree/Ainv, spec validation, likelihood, dense
    optimizer, dense extractor/result payload, direct payload target, and
    Henderson MME validation testsets.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims that R
    live execution returns fitted objects, R extractors consume real Julia
    results, production sparse reliability/PEV, sparse diagnostics, or GPU/QTL
    support are implemented.
- Boundary:
  - Result shape exists on the Julia side.
  - R live execution and result marshalling remain planned.
  - Reliability, PEV, and sparse solver diagnostics remain planned.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1G Henderson MME Validation Fixture

- Goal: add a first MME validation fixture for the dense Phase 1 output path.
- Active lenses: Ada, Henderson, Mrode, Gauss, Fisher, Curie, Rose.
- Spawned subagents: none.
- Implementation evidence:
  - Added a test-only Henderson mixed-model-equation solver.
  - Added a five-animal pedigree fixture with founders, offspring, repeated
    records, fixed effects, sparse `Z`, and supplied variance components.
  - Cross-checked dense marginal-output fixed effects, breeding values, fitted
    values, and heritability against the MME solution.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 105 checks
    across Phase 0, pedigree/Ainv, spec validation, likelihood, dense
    optimizer, dense extractor, direct payload target, and Henderson MME
    validation testsets.
- Boundary:
  - MME fixture is a deterministic validation check, not a full textbook Mrode
    reproduction.
  - No external comparator package has been run yet.
  - Sparse production solves remain planned.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1F Direct Bridge Payload Target

- Goal: implement the Julia method that the R parser currently names as its
  bridge target: `fit_animal_model(y, X, Z, Ainv; method = :REML)`.
- Active lenses: Ada, Shannon, Hopper, Boole, Henderson, Gauss, Karpinski,
  Grace, Rose.
- Spawned subagents: none.
- Implementation evidence:
  - Added direct payload `fit_animal_model(y, X, Z, Ainv; ids, family, method,
    kwargs...)`.
  - The method validates through `animal_model_spec()` and dispatches to the
    dense `fit_variance_components()` path.
  - Added parity tests showing direct payload fitting matches validated-spec
    fitting for likelihood, variance components, method, IDs, and breeding
    value IDs.
  - Mirrored R payload semantics from `hsquared` head `b57b48e`: normalized
    parent-before-offspring IDs, parent index vectors, sparse `Z` dimensions,
    and Julia-side `Ainv` construction.
  - Added error tests for payload dimension and ID mismatches.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 100 checks across
    Phase 0, pedigree/Ainv, spec validation, likelihood, dense optimizer, dense
    extractor, and direct payload target testsets.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims that the
    R bridge executes, R formula calls fit through Julia, sparse production
    fitting works, AI-REML works, or results are comparator-validated.
- Boundary:
  - Julia target exists; R-to-Julia marshalling still does not.
  - Dense validation path only.
  - Not sparse production fitting or AI-REML.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1E Dense Fit Extractors

- Goal: add first low-level result extractors for the dense Gaussian
  validation path.
- Active lenses: Ada, Henderson, Gauss, Fisher, Falconer, Hopper, Karpinski,
  Grace, Rose.
- Spawned subagents: none.
- Implementation evidence:
  - Added `BreedingValues`.
  - Added `variance_components()`, `fixed_effects()`, `breeding_values()`,
    `fitted_values()`, and `heritability()`.
  - Added hand-checked dense tests with identity `A`, `V = 2I`, beta = 2,
    EBVs `[-0.5, 0, 0.5]`, fitted values `[1.5, 2, 2.5]`, and `h2 = 0.5`.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 85 checks across
    Phase 0, pedigree/Ainv, spec validation, likelihood, dense optimizer, and
    dense extractor testsets.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims of
    implemented production sparse EBVs, reliability, prediction error variance,
    AI-REML, R bridge execution, GPU, or QTL/eQTL support.
- Boundary:
  - Dense validation path only.
  - Not sparse production BLUP solving.
  - No reliability or prediction error variance yet.
  - No R bridge execution yet.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1D Dense Variance-Component Optimizer

- Goal: add a conservative dense optimizer for the Gaussian likelihood over
  positive additive and residual variance components.
- Active lenses: Ada, Shannon, Hopper, Henderson, Gauss, Fisher, Karpinski,
  Grace, Rose.
- Spawned subagents: none.
- R twin handoff recorded:
  - `hsquared` head `d85f356` parses the narrow `animal(1 | id, pedigree = ped)`
    grammar and stops at the Julia bridge boundary.
  - R local and remote checks were reported green, and the R pkgdown site is
    live at `https://itchyshin.github.io/hsquared/`.
  - Julia mirrored this as a payload-parity next seam; bridge execution remains
    planned.
- Implementation evidence:
  - Added `AnimalModelFit`.
  - Added `fit_variance_components()`.
  - Added `fit_animal_model(spec::AnimalModelSpec)` dispatch.
  - Added tests that the optimizer improves the tiny likelihood from a starting
    point, returns positive variance components, and validates bad initial
    values.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 76 checks across
    Phase 0, pedigree/Ainv, spec validation, likelihood, and dense optimizer
    testsets.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims of
    implemented sparse fitting, AI-REML, EBVs, heritability, GPU, or
    QTL/eQTL support.
- Boundary:
  - Uses dense matrices and `Optim.NelderMead()`.
  - Low-level Julia spec path only.
  - Not sparse production fitting, not AI-REML, not R bridge execution, and no
    EBVs/heritability yet.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1C Gaussian Likelihood Evaluation

- Goal: add a checked Gaussian ML/REML log-likelihood evaluator at supplied
  variance components.
- Active lenses: Ada, Henderson, Gauss, Fisher, Karpinski, Rose.
- Spawned subagents: none.
- Implementation evidence:
  - Added `src/likelihood.jl`.
  - Added exports: `GaussianLikelihoodResult` and `gaussian_loglik`.
  - Added tests against hand-calculated ML and REML values for a tiny `V = 2I`
    case.
  - Added error tests for non-positive variance components, unsupported method,
    and saturated REML design.
- Boundary:
  - The evaluator intentionally densifies matrices.
  - It evaluates an objective at supplied variance components.
  - It does not optimize variance components, compute EBVs, or fit a model.
- Rose verdict: clean with limitations. This may be described as experimental
  likelihood evaluation, not as animal-model fitting.

## 2026-06-13 Phase 1B Animal Model Spec Validation

- Goal: add the Julia-side typed validator for the low-level animal-model
  payload produced by the R parser lane.
- Active lenses: Ada, Shannon, Hopper, Henderson, Gauss, Karpinski, Rose.
- Spawned subagents: none.
- Coordination note:
  - R/coordinator lane reports an inert `animal()` marker and
    `hs_build_model_spec()` parser are now present in `hsquared`.
  - Julia mirrors that direction with `animal_model_spec()` for `y`, `X`, `Z`,
    `Ainv`, IDs, `GaussianFamily()`, and ML/REML method validation.
  - Bridge execution and model fitting remain planned.
- Implementation evidence:
  - Added `src/model_spec.jl`.
  - Added exports: `GaussianFamily`, `AnimalModelSpec`, and
    `animal_model_spec`.
  - Added tests for valid spec construction, method normalization, default IDs,
    dimension mismatches, ID mismatch, family mismatch, and method mismatch.
- Rose verdict: clean with limitations. This is a bridge-ready validator, not a
  fitting engine.

## 2026-06-13 Genomics QTL GPU HPC Roadmap

- Goal: turn the extended user direction on genomics, QTL/eQTL/GWAS,
  GLLVM-style models, CPU/GPU backends, and HPC into repo-visible Julia docs.
- Active lenses: Ada, Shannon, Jason, Hopper, Karpinski, Grace, Rose, Darwin,
  Falconer, Kirkpatrick.
- Spawned subagents: none.
- Added:
  - `docs/src/genomics-qtl-gpu-hpc.md`
  - `docs/design/08-genomics-qtl-gpu-hpc-plan.md`
- Updated:
  - `docs/make.jl`
  - `docs/src/index.md`
  - `docs/src/changelog.md`
- Source anchors checked:
  - CUDA.jl array and backend docs.
  - AMDGPU.jl quick-start docs.
  - Metal.jl docs and `MtlArray` docs.
  - oneAPI.jl repository.
  - KernelAbstractions.jl docs.
- Rose verdict: clean with limitations. The roadmap is ambitious and public,
  but wording marks genomics/QTL/eQTL/GPU/HPC as planned or experimental until
  implementation, validation, and benchmark evidence exist.

## 2026-06-13 Phase 1A Pedigree And Ainv Utility

- Goal: finish the first Julia Phase 1A engine slice: pedigree normalization,
  direct sparse `Ainv`, and docs-site scaffold.
- Active lenses: Ada, Shannon, Henderson, Mrode, Gauss, Karpinski, Grace,
  Jason, Rose, Pat.
- Spawned subagents: none.
- Coordination boundary:
  - Julia lane edited only `HSquared.jl`.
  - R/coordinator twin owns matching `hsquared` formula/model-spec/status work.
  - Shared contract note: R docs may say Julia `Ainv` construction exists, but
    model fitting remains planned.
- Sister references checked:
  - `DRM.jl/AGENTS.md`, `DRM.jl/docs/make.jl`, `DRM.jl/docs/src/index.md`
  - `GLLVM.jl/AGENTS.md`, `GLLVM.jl/docs/make.jl`,
    `GLLVM.jl/docs/src/index.md`
- Implementation evidence:
  - Added `src/pedigree.jl`.
  - Added exports: `Pedigree`, `normalize_pedigree`,
    `inbreeding_coefficients`, and `pedigree_inverse`.
  - Added tests for valid sorting, malformed parents, duplicate IDs,
    self-parent, same known sire/dam, cycle detection, cache limit, tiny
    hand-checked `Ainv`, and dense inverse comparison.
- Documentation evidence:
  - Added DocumenterVitepress scaffold: `docs/Project.toml`, `docs/make.jl`,
    `docs/src/`.
  - Updated formula/v0.1 contract notes to make R syntax parity the target and
    to require documented, tested bridge translations for any Julia
    discrepancies.
  - Added user-needs and comparator programme docs for breeders, evolutionary
    geneticists, genomic users, and production breeding comparators, while
    keeping superiority claims evidence-gated.
  - Added `Documenter.yml` workflow.
  - Updated README, roadmap, capability status, validation debt, public claims,
    engine contract, coordination board, and AGENTS.
  - Added scout note
    `docs/dev-log/scout/2026-06-13-julia-sister-boundaries.md`.
- Commands run:
  - `julia --project=. test/runtests.jl` passed: 17 Phase 0 checks and 15
    initial Phase 1A checks.
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed: 17 Phase 0 checks
    and 17 Phase 1A checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped,
    as expected outside CI. VitePress dependency audit reported npm advisories
    in generated dependencies; build succeeded.
  - `git diff --check` passed.
- Rose verdict: clean with limitations. `Ainv` construction is implemented as
  an engine utility with tiny deterministic evidence; animal-model fitting,
  EBVs, heritability, and R bridge execution remain planned.

## 2026-06-13 Phase 0 Julia Scaffold

- Goal: create the initial `HSquared.jl` package scaffold and operating docs.
- Active lenses: Ada, Shannon, Henderson, Hopper, Boole, Rose, Grace,
  Karpinski.
- Spawned subagents: none after R-lane worker shutdown; R lane belongs to the
  coordinator twin.
- Commands run:
  - `julia --project=. test/runtests.jl` passed with 17 tests.
  - `julia --project=. -e 'using Pkg; Pkg.test()'` first failed because
    `Test` was missing from package test targets.
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed after adding
    `Test` to `[extras]` and `[targets]`.
  - `gh repo create itchyshin/HSquared.jl --public --source=. --remote=origin --push`
    created the public GitHub repository and pushed `main`.
  - `gh run watch 27451520721 --repo itchyshin/HSquared.jl --exit-status`
    passed for Julia 1.10 and stable Julia.
  - `gh run watch 27451548449 --repo itchyshin/HSquared.jl --exit-status`
    passed after opting workflow actions into Node 24.
- GitHub verification:
  - `itchyshin/HSquared.jl` visibility is `PUBLIC`.
  - `itchyshin/hsquared` visibility was read-only checked as `PRIVATE` and
    left to the R/coordinator lane.
- Deliberately not run here: R package checks. The R/coordinator twin owns
  `/Users/z3437171/Dropbox/Github Local/hsquared`.

## 2026-06-13 Coordinator Closeout Sync

- Goal: finish the Phase 0 operating plan by syncing the Julia memory skeleton
  with the now-public R twin.
- Active lenses: Ada, Shannon, Rose, Grace, Gauss, Karpinski, Hopper.
- Spawned subagents: none.
- Verified before edits:
  - `git status --short --branch`
  - `git log --oneline --decorate -5`
  - `gh repo view itchyshin/HSquared.jl --json nameWithOwner,visibility,isPrivate,url,defaultBranchRef,licenseInfo,hasIssuesEnabled`
  - `gh run list --repo itchyshin/HSquared.jl --limit 5`
- Result before edits: clean `main`, public repo, issues enabled, MIT license
  detected by GitHub, latest CI green.
- Added mirrored project-local skills and launchable role configs:
  - `.agents/skills/`
  - `.codex/agents/`
- Added missing design surfaces to match the R-side operating skeleton:
  `00-vision.md`, `02-formula-grammar.md`, `03-engine-contract.md`,
  `04-validation-canon.md`, `05-roadmap.md`,
  `06-public-claims-register.md`, and `10-after-task-protocol.md`.
- Updated README and roadmap to remove stale Phase 0 next actions and
  unsupported `fast` wording.
- Validation after edits:
  - temporary PyYAML target plus
    `/Users/z3437171/.codex/skills/.system/skill-creator/scripts/quick_validate.py`
    validated all 11 mirrored project-local skills.
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 17 tests.
  - `git diff --check` passed.
  - unsupported-claim scan found only audit/register text, not public claims
    of implemented fitting or speed.
