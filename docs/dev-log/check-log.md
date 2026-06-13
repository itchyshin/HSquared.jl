# Check Log

Newest entries go at the top.

## 2026-06-13 Repeatability REML Variance-Component Estimation

- Goal: complete the repeatability model into an estimator — REML estimation of
  (σ²a, σ²pe, σ²e) and the repeatability coefficient `t`.
- Active lenses: Gauss, Fisher, Henderson, Falconer, Curie, Rose (inline).
- Implementation:
  - `src/likelihood.jl`: `fit_repeatability_reml(y, X, Z, Ainv; initial)`
    maximizes the dense two-random-effect REML loglik (`_repeatability_dense`)
    over the log-variances (NelderMead); returns VCs, repeatability `t`,
    heritability `h²`, BLUPs, loglik, converged. Exported.
- Local checks:
  - `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` passed; 704
    total. New testset "Phase 3 repeatability REML (variance-component
    estimation)" = 13 checks: dense loglik reduces to the animal-model REML (up
    to a constant) at σ²pe=0; dense BLUPs match the sparse `repeatability_mme` at
    a supplied interior point (~1e-15); estimator converges with valid VCs and
    `t ≥ h²` in [0,1]; optimum beats a ±30% grid; guards. `validation_status()`
    22 → 23 (added `V3-REPEAT-REML`).
  - One-off seeded recovery (NOT committed; suite kept RNG-free): n=70 animals,
    true (1.0, 0.6, 1.5) → estimated ≈(0.94, 0.83, 1.48), `t` 0.516 → 0.545.
  - Decision note `2026-06-13-rng-recovery-test-harness.md` resolved (hybrid).
- Boundary:
  - Dense / validation-scale, REML-only; no committed recovery harness, no
    `t`/`h²` intervals, no external comparator, no R-facing model-spec.

## 2026-06-13 Repeatability / Permanent-Environment MME (Phase 3 start)

- Goal: first Phase-3 (standard quantitative-genetic) engine slice — a
  supplied-variance Henderson solve of the two-random-effect repeatability /
  permanent-environment animal model.
- Active lenses: Henderson, Falconer, Mrode, Gauss, Curie, Rose (inline).
- Implementation:
  - `src/likelihood.jl`: `repeatability_mme(y, X, Z, Ainv, σ²a, σ²pe, σ²e; ids)`
    assembles the MME for the stacked random effect `[a; pe]` with a
    block-diagonal relationship precision `blockdiag(Ainv/σ²a, I/σ²pe)` and
    solves. Additive — does not touch the single-random-effect path. Exported.
- Local checks:
  - `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` passed; 691
    total. New testset "Phase 3 repeatability / permanent-environment MME
    (supplied variance)" = 11 checks: pinned hand values (β=11, â, p̂e on a
    5-record / 3-animal repeated-records fixture), an independent marginal-GLS
    BLUP cross-check (~1e-9), reduction to the animal model as σ²pe→0, and
    positive-variance / dimension guards. `validation_status()` 21 → 22 (added
    `V3-REPEAT`).
- Boundary:
  - Supplied-variance only — no REML estimation of the three components, no
    R-facing `permanent()` model-spec, engine-internal. Requires repeated records
    to identify `a` vs `pe`.

## 2026-06-13 Heritability Intervals + Variance-Component Covariance

- Goal: give the heritability package an uncertainty for h² — variance-component
  standard errors and a confidence interval — the central missing inference.
- Active lenses: Fisher, Gauss, Curie, Noether, Rose (inline).
- Implementation:
  - `src/likelihood.jl`: `variance_component_covariance` (inverse of the REML AI
    matrix), `variance_component_standard_errors`, `heritability_standard_error`
    (delta method), and `heritability_interval(fit; level)` — a logit-transform
    delta interval, always in (0,1). Internal helpers `_reml_information_matrix`
    (recomputes the AI matrix) and `_standard_normal_quantile` (Acklam, self-
    contained — no Distributions/SpecialFunctions dependency). REML-only.
  - Exported the four public functions; `docs/src/api.md` updated.
- Local checks:
  - `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` passed; 680
    total. New testset "Phase 1 variance-component covariance and heritability
    interval" = 19 checks: Acklam quantile vs known z-values; AI matrix vs an
    independent finite-difference REML Hessian (rtol 0.12; observed ~8%);
    covariance symmetric + positive; SEs consistent; h² SE vs direct delta;
    logit interval in (0,1), contains the estimate, nests by level; level +
    REML-only guards; and the interval on a genomic REML fit. `validation_status()`
    20 → 21 (added `V1-HERIT-CI`).
  - Decision note `2026-06-13-heritability-interval-design.md` resolved
    (logit-delta chosen; profile / parametric-bootstrap = future).
- Boundary:
  - Asymptotic, REML-only; wide and unreliable at small n; not
    coverage-calibrated; no profile-likelihood / bootstrap alternative yet.

## 2026-06-13 Genomic Models Documentation Page

- Goal: a reader-facing Documenter page for the implemented genomic engine.
- Active lenses: Pat, Darwin, Florence, Rose (inline).
- Implementation:
  - `docs/src/genomic-models.md` with executed `@example` blocks for `G`/`Ginv`,
    GBLUP, genomic REML (6-animal fixture — AI-REML is flat on 4 animals),
    SNP-BLUP, and a prose section for the internal single-step `H⁻¹`; registered
    in `docs/make.jl` after "Pedigrees and Ainv". Explicit experimental /
    not-yet-R-wired / no-external-comparator boundary stated up front.
- Local checks:
  - `~/.juliaup/bin/julia --project=docs docs/make.jl` exit 0; all executed
    examples ran clean.
- Boundary:
  - Documentation only; documents engine APIs, not the public R interface.

## 2026-06-13 Genomic REML Variance-Component Estimation

- Goal: estimate the genomic variance components for GBLUP (previously
  supplied-variance only) by reusing the existing REML optimizers on a `Ginv`
  spec — engine-internal, additive, no new code.
- Active lenses: Gauss, Fisher, Curie, Henderson, Rose (inline).
- Implementation:
  - No new code: `fit_ai_reml` / `fit_sparse_reml` / `fit_animal_model(...;
    target = :ai_reml)` operate on a spec whose `Ainv` slot holds a genomic
    `Ginv`, estimating σ²g/σ²e.
- Local checks:
  - `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` passed; 661
    total. New testset "Phase 2 GBLUP REML variance-component estimation" = 11
    checks: AI-REML == NelderMead optimum on a genomic fixture (loglik rtol 1e-5,
    σ² rtol 2e-2), positive VCs, converged, `fit_gblup` at the estimate
    reproduces the REML breeding values (atol 1e-8), and target-dispatch reaches
    the same optimum from a different start. `validation_status()` 19 → 20
    (added `V2-GREML`; `V2-GBLUP` missing field updated).
  - One-off seeded recovery (NOT committed, to keep the suite RNG-free): n=400,
    m=600, true σ²g=1.0/σ²e=1.5 → estimated σ²g=0.997, h²=0.42 (true 0.40).
- Boundary:
  - Reuses the Phase-1 optimizers on a genomic spec; no external comparator
    parity (sommer/rrBLUP/BLUPF90 = R lane), no production sparse-`G` scaling.

## 2026-06-13 Address Phase-2 Adversarial-Review Findings

- Goal: act on the confirmed findings of the multi-lens adversarial review of the
  five Phase-2 engine slices (workflow `phase2-engine-review`, 11 agents). The
  review found ZERO numerical bugs and ZERO contract/claim drift; the 5 confirmed
  findings were documentation precision (1) and test quality (4).
- Active lenses: Curie, Gauss, Kirkpatrick, Rose (inline) + the review workflow.
- Fixes:
  - Reliability denominator stated precisely as `diag(inv(Ginv)) = diag(G)+ridge`
    (not `diag(G)`; the ridge perturbs reported reliability/accuracy) in the
    `reliability` docstring, `capability-status.md`, `validation_status.jl`
    (`V2-GBLUP`), `changelog.md`, and the genomic-reliability after-task report.
  - The genomic PEV test was tautological (algebraic reversal of `reliability`'s
    own definition) — replaced with an INDEPENDENT PEV anchor (re-assembled MME
    inverse) and reliability rebuilt from it, so a wrong denominator now fails.
  - `accuracy ≈ sqrt(rel)` (definitional) now checked against the independent
    reliability.
  - `diag(A) ≈ 1 + inbreeding_coefficients` was circular after the NRM dedupe —
    replaced with a hand-pinned inbreeding anchor `F = [0,0,0,0,0.25]`.
- Local checks:
  - `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` passed; 650
    total (genomic-reliability testset 5 → 7).
- Boundary:
  - Documentation + test-quality only; no engine logic change, no contract
    change, no new capability row.

## 2026-06-13 Single-Step H-Inverse Construction (_single_step_Hinv, internal)

- Goal: the single-step (ssGBLUP) H-inverse construction utility — the subtlest
  Phase-2 piece — shipped as an unexported, property-checked construction utility
  only (no fitting wiring, no comparator-validated blending).
- Active lenses: Henderson, Mrode, Kirkpatrick, Gauss, Mendel, Rose (inline).
- Implementation:
  - `src/genomic.jl`: `_single_step_Hinv(Ainv, A, G, genotyped_rows; tau, omega,
    blend_weight, ridge)` = `A⁻¹ + scatter(τ·Gʷ⁻¹ − ω·A₂₂⁻¹)`. Critically
    `A₂₂⁻¹ = inv(A[g, g])`, NOT `(A⁻¹)[g, g]`. PD guard on the (blended/ridged)
    genomic block. Reuses `_numerator_relationship` for `A`/`A₂₂`. Unexported,
    validation-only.
- Local checks:
  - `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` passed; 648
    total. New testset "Phase 2 single-step H-inverse construction" = 11 checks:
    `A₂₂⁻¹[1,1] = 11/6` vs `(A⁻¹)[g,g][1,1] = 2.5` distinctness, reduction
    (`G = A₂₂ ⇒ H⁻¹ = A⁻¹`, ~0), locality (off-block unchanged), symmetry,
    scattered genotyped rows `[1,3,5]`, singular-`G` throws / blend rescues, and
    a dimension guard. `validation_status()` 18 → 19 (added `V2-SSHINV`).
- Boundary:
  - Construction utility only — NOT exported, NOT wired into fitting;
    `single_step()` stays inert. Blending/τ/ω/ridge defaults are NOT
    comparator-validated. Dense, validation-scale; no large-pedigree claim.

## 2026-06-13 Genomic Reliability / PEV / Accuracy Semantics

- Goal: confirm and document that the existing reliability/PEV/accuracy
  extractors produce correct genomic quantities for a GBLUP fit (denominator =
  genomic self-relationship `diag(G)`), and that `:selinv` PEV carries over to a
  genomic `Ginv`.
- Active lenses: Fisher, Gauss, Kirkpatrick, Curie, Rose (inline).
- Implementation:
  - `src/likelihood.jl`: docstring-only clarification on `reliability`
    (`A = inv(Ainv)`; for a genomic spec `A_ii = diag(G)`). No logic change.
- Local checks:
  - `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` passed; 637
    total. New testset "Phase 2 genomic reliability / PEV / accuracy semantics"
    = 5 checks: `rel ∈ [0,1]`; `PEV = (1−rel)·σ²a·diag(G+ridge·I)` to ~1e-16;
    `diag(G+ridge·I) ≠ 1` (genomic, not pedigree `diag(A)=1`); `accuracy = √rel`;
    `:selinv` PEV == dense PEV (~3e-16). `V2-GBLUP` evidence updated (no new row).
- Boundary:
  - Self-consistent only; not validated against an external genomic-reliability
    comparator. No performance claim for selinv on dense `Ginv` (no speedup until
    sparse/APY `G`).

## 2026-06-13 Dense NRM Helper (_numerator_relationship, internal)

- Goal: extract the numerator-relationship recursion (previously computed and
  discarded inside `inbreeding_coefficients`, and duplicated as a test-only
  helper) into one internal `_numerator_relationship` — a prerequisite for the
  single-step H-inverse and a dedupe.
- Active lenses: Henderson, Mrode, Curie, Rose (inline).
- Implementation:
  - `src/pedigree.jl`: `_numerator_relationship(pedigree)` (full dense `A`) and
    `_numerator_relationship(pedigree, rows)` (`A[rows, rows]`, for `A₂₂`);
    `inbreeding_coefficients` now takes its diagonal. The bounded-cache guard
    moved into the shared helper. Unexported, validation-only.
  - `test/runtests.jl`: removed the duplicate `_dense_relationship_for_test`;
    the two pedigree-inverse cross-checks now call
    `HSquared._numerator_relationship`.
- Local checks:
  - `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` passed; 632
    total. New testset "Phase 2 dense NRM helper" = 7 checks: pinned `A`
    (5-animal pedigree, full-sib parents ⇒ inbred animal 5, `A[5,5]=1.25`),
    symmetry, cross-check vs `inv(pedigree_inverse)`, diagonal vs
    `inbreeding_coefficients`, `A₂₂ == A[g,g]` pinned, and the cache guard.
    Existing pedigree/inbreeding tests unchanged and green (refactor-safe).
- Boundary:
  - Internal infrastructure; no capability/validation-debt/validation_status row
    (graduates no user-facing capability), no public API change, dense /
    validation-scale only.

## 2026-06-13 SNP-BLUP + GBLUP↔SNP-BLUP Equivalence (fit_snp_blup)

- Goal: add SNP-BLUP / RR-BLUP marker effects via the existing Henderson MME and
  prove the GBLUP↔SNP-BLUP equivalence — a strong comparator-free check that
  also validates the VanRaden centering/scaling convention.
- Active lenses: Kirkpatrick, Gauss, Henderson, Curie, Rose (inline).
- Implementation:
  - `centered_markers(markers; allele_frequencies)` in `src/genomic.jl` →
    `(W, p, k)`; `genomic_relationship_matrix` refactored to delegate to it
    (single source of the centering/scaling; the 9-check G testset guards the
    refactor — still 9/9).
  - `fit_snp_blup(y, X, markers, sigma_g2, sigma_e2; allele_frequencies, ids)` →
    `(marker_effects, gebv = W·â, beta, k, p)`. Markers are the random effect
    (`Z = W`, `Ainv = I_m`, `σ²_marker = σ²_g/k`); the random block is
    deliberately relabelled `marker_effects` (not `breeding_values`/EBV). Both
    exported.
- Local checks:
  - `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` passed; 625
    total. New testset "Phase 2 SNP-BLUP and GBLUP-SNP-BLUP equivalence" = 15
    checks: pinned `p`/`k`/centering, pinned β/marker-effects/GEBV/predictions,
    relabel check, and the equivalence `gebv == W·â` matching GBLUP via the
    marginal `V = σ²_g·G + σ²_e·I` to ~5e-17 (`n>m`) and ~2e-16 (`n<m`), plus
    `σ²_g ≤ 0` and monomorphic guards. `validation_status()` 17 → 18 (added
    `V2-SNPBLUP`).
- Boundary:
  - Engine-internal/additive. The equivalence proves the parameterization
    bridge, NOT field-correct absolute numbers (external comparator still gates
    that). Unweighted VanRaden method-1 / identity prior only; supplied-variance
    only; no REML estimation; no performance claim for large `m`.

## 2026-06-13 GBLUP Supplied-Variance Solve (fit_gblup)

- Goal: graduate the genomic relationship utilities into an actual fitted GBLUP
  solve by reusing the existing Henderson MME — engine-internal, additive, no
  contract change. (Preceded by a small docs commit `ee2fa07` adding the genomic
  + AI-REML functions to `docs/src/api.md`; local Documenter build green.)
- Active lenses: Henderson, Gauss, Kirkpatrick, Falconer, Curie, Rose (inline).
- Spawned subagents: 5-scout + 1-design planning workflow (`phase2-engine-plan`)
  produced the ordered DoD-gated plan; all pinned numbers re-verified locally.
- Implementation:
  - `fit_gblup(y, X, Z, Ginv, sigma_a2, sigma_e2; ids, method)` in
    `src/genomic.jl`: `spec = animal_model_spec(y, X, Z, Ginv; ...)` then
    `henderson_mme(spec, ...)`. The genomic precision enters the same `Ainv`
    slot (`AnimalModelSpec.Ainv::AbstractMatrix`); no new solver, no new result
    type. Exported.
- Local checks:
  - `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` passed; 610
    total checks. New testset "Phase 2 GBLUP supplied-variance solve" = 11
    checks: pinned 3-individual fixture (β = 10.9448698315, GEBVs pinned),
    independent dense-MME agreement (~7e-15), G = A reproduces pedigree BLUP
    (~1.6e-30), variance-ratio invariance, finiteness, and a `sigma_a2 ≤ 0`
    guard. `validation_status()` row count 16 → 17 (added `V2-GBLUP`).
- Boundary:
  - Engine-internal/additive. Supplied-variance only; no genomic
    variance-component estimation, no single-step, no external comparator parity,
    no performance claim (dense `Ginv` loses the selinv sparsity advantage). The
    R-facing `genomic()` model-spec mapping stays coordinated with the R twin.

## 2026-06-13 Regularized Genomic Inverse (Ginv)

- Goal: finish the Phase-2 `Ginv` slice (present as an uncommitted draft in the
  working tree on resume) to Definition of Done — the ridge-regularized dense
  inverse of a genomic relationship matrix, the engine-internal step GBLUP will
  later consume.
- Active lenses: Kirkpatrick, Falconer, Gauss, Curie, Rose (inline perspectives).
- Spawned subagents: none.
- Implementation:
  - `genomic_relationship_inverse(G; ridge = 0.01)` in `src/genomic.jl`:
    returns `inv(Symmetric(G) + ridge·I)` with square / non-negative-ridge /
    positive-definite guards. Exported from the module. Docstring states it is a
    construction utility only and is not wired into model fitting.
- Local checks:
  - `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'` passed; 599
    total checks. New testset "Phase 2 regularized genomic inverse (Ginv)" = 10
    checks: pinned hand inverse at `ridge = 0` (det = 3.75), the defining
    identity `(G + ridge·I)·Ginv ≈ I`, symmetry, ridge-changes-result, a
    singular matrix throwing at `ridge = 0`, a rank-deficient marker-`G`
    round-trip with the default ridge, and non-square / negative-ridge guards.
    `validation_status()` row count 15 → 16 (added `V2-GINV`).
- Boundary:
  - Additive engine utility — no bridge / result / model-spec change. The
    contract-touching GBLUP wiring (G into the MME) and the R
    `genomic()`/`markers()` → engine model-spec mapping remain the next slice and
    will be coordinated with the R twin before landing.

## 2026-06-13 Genomic Relationship Matrix (VanRaden G)

- Goal: begin Phase 2 (genomic) with the VanRaden genomic relationship matrix
  construction — a self-contained, GPU-relevant dense engine utility.
- Active lenses: Falconer, Kirkpatrick, Curie, Jason, Rose (inline perspectives).
- Spawned subagents: none.
- Implementation:
  - Added `src/genomic.jl` with `genomic_relationship_matrix(markers;
    allele_frequencies = nothing)`: VanRaden (2008) `G = ZZ'/(2Σp(1-p))`,
    `Z = markers - 2p`, frequencies estimated from the columns unless supplied.
    Included in the module and exported.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. New testset
    "Phase 2 genomic relationship matrix (VanRaden)" = 9 checks: pinned
    hand-computed entries (G[1,1]=1.130435, G[1,2]=-1.304348), symmetry, PSD,
    supplied-frequency parity, and coding/length/monomorphic guards.
- Boundary:
  - Phase boundary; heads-up posted to `hsquared` issue #9. Construction utility
    ONLY — additive, no bridge / result / model-spec change. No Ginv, GBLUP,
    single-step, or marker-effect estimation. G is rank-deficient when markers <
    individuals and needs regularization before inversion (the next slice).

## 2026-06-13 Average-Information REML (fit_ai_reml)

- Goal: a fast, validated sparse REML variance-component estimator —
  average-information (AI) REML — built on the selinv score traces.
- Active lenses: Gauss, Fisher, Curie, Karpinski, Rose (inline perspectives).
- Spawned subagents: forensic DRM.jl AI-REML investigation (workflow
  `wf_81a0948a`, read-only); no code-writing subagents.
- Implementation:
  - Added `fit_ai_reml(spec; ...)` to `likelihood.jl`: each iteration solves the
    sparse MME, reads the variance-component score from the BLUP solution + the
    Takahashi selected inverse, forms the average-information matrix from two
    working-variate re-solves (reusing the factor), and takes an AI/Newton step
    with positivity step-halving. REML-only, 2-component, Gaussian.
  - Helpers `_reml_project`, `_ai_newton_step`; `target = :ai_reml` dispatch;
    exported `fit_ai_reml`; `validation_status` row `V1-AI-REML`.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. New testset
    "Phase 1 AI-REML estimator" = 16 checks: AI recovers the same optimum as the
    NelderMead optimizer (logLik identical), diagnostics, dispatch, guards.
  - AI-validity check: the AI matrix matches the observed information at the
    optimum (ratio 0.988 / 0.986) on a 250-animal simulation — a valid Newton
    metric (the DRM.jl failure mode was a ~5× undersized AI metric).
  - Benchmark (warmed): AI-REML 10 / 7 iters at N=250 / 1000; vs EM-REML
    169 / 195 iters; AI fastest at N=1000 (386 ms vs NelderMead 645 ms vs EM
    11.4 s); NelderMead fastest at N=250.
- Boundary:
  - Experimental Gaussian-only REML estimator. The AI form is exact for the
    Gaussian LMM, NOT for non-Gaussian/Laplace models (observed-info Newton
    there). No external comparator, large-pedigree, or boundary hardening yet;
    not the public default; `result_payload()` unchanged.

## 2026-06-13 REML Optimizer Recovery Validation

- Goal: verify the dense and sparse REML optimizers recover the SAME optimum
  (not just improve over the start), strengthening V1-OPT / V1-SPARSE-REML-OPT.
- Active lenses: Curie, Gauss, Fisher, Rose (inline perspectives).
- Spawned subagents: none.
- Implementation:
  - Added testset "Phase 1 REML optimizer recovery (dense vs sparse)": an
    interior 8-animal fixture where `fit_variance_components(:REML)` and
    `fit_sparse_reml` recover the same variance components, heritability,
    log-likelihood, and EBVs; multi-start robustness; and dense/sparse agreement
    at the σ²a = 0 boundary.
  - Strengthened V1-SPARSE-REML-OPT and V1-OPT evidence (validation_status and
    validation-debt-register).
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed; recovery testset =
    11 checks. Exploratory fit: interior optimum σ²a≈1.322, σ²e≈0.226;
    dense == sparse to ~5 digits; ll = -10.855294.
- Boundary:
  - Internal recovery against an independent optimizer and starting point, not
    external comparator parity or fitted Mrode. V1-MRODE-FIT and V1-COMPARATORS
    stay planned; the external comparator is coordinated to the R twin (issue #7).

## 2026-06-13 Sparse Selected-Inversion PEV/Reliability

- Goal: production-scale sparse prediction error variance and reliability via a
  Takahashi selected inverse of the sparse Henderson MME coefficient matrix,
  reusing the MIT sibling kernel instead of reinventing it.
- Active lenses: Gauss, Karpinski, Curie, Fisher, Rose (inline perspectives).
- Spawned subagents: none.
- Implementation:
  - Added `src/takahashi_selinv.jl` (`takahashi_selinv`, `takahashi_diag`),
    adapted near-verbatim from DRM.jl (MIT) with attribution.
  - Added `_selinv_mme_random_pev` and a `_pev_values` dispatcher in
    `likelihood.jl`; `prediction_error_variance`/`reliability` now accept
    `method = :dense` (default, unchanged) or `:selinv`.
  - Added a `validation_status()` row `V1-SELINV-PEV`.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. New testset
    "Phase 1 sparse selected-inversion PEV/reliability" (10 checks): selinv
    diagonal == dense MME inverse diagonal, and `:selinv` PEV/reliability ==
    `:dense` to machine precision (3.3e-16) on tiny + fit fixtures; edge guards.
- Boundary:
  - Experimental sparse PEV path; exact at the `L+Lᵀ` pattern (diagonal/PEV
    exact). Default extractor path stays dense; `result_payload()` unchanged.
    Not AI-REML, not fitted Mrode, no external comparator, no large-pedigree
    validation yet.

## 2026-06-13 Sparse REML Validation Optimizer

- Goal: add a Julia-only sparse REML optimization atom without changing the
  R bridge payload or claiming production sparse fitting.
- Active lenses: Ada, Shannon, Henderson, Gauss, Fisher, Curie, Karpinski,
  Grace, Rose, Hopper.
- Spawned subagents: none.
- R lane boundary:
  - The sibling R repo was observed with an uncommitted edit in
    `R/validation-fixtures.R`; this Julia slice did not touch the R repo.
  - No R bridge payload fields were added or required.
- Julia implementation:
  - Added exported `fit_sparse_reml()`.
  - Added `fit_animal_model(...; target = :sparse_reml)` dispatch for validated
    REML specs and direct `y`, `X`, `Z`, `Ainv` payloads.
  - Extended `AnimalModelFit` with metadata for `target`,
    `dense_validation_path`, `sparse_mme_path`, and
    `variance_components_source`, while preserving the existing constructor
    used by current tests and fixtures.
  - Updated `fit_diagnostics()` and compact `result_payload()` diagnostics to
    report the stored validation-path metadata.
  - Kept `result_payload()` field names unchanged.
- Local checks so far:
  - Initial `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 540
    checks.
  - Initial `julia --project=docs docs/make.jl` exposed a
    non-positive-definite sparse objective trial in the quickstart example.
  - Updated `fit_sparse_reml()` to treat non-positive-definite sparse objective
    trial points as invalid optimizer points rather than aborting.
  - Final `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 543
    checks.
  - Final `julia --project=docs docs/make.jl` passed. Local deployment was
    skipped as expected outside CI; Vitepress dependency installation still
    reported npm advisories in generated/transient build artifacts.
  - `git diff --check` passed.
  - Claim-boundary scan found expected blocked/status wording only.
- Boundary:
  - Experimental REML-only sparse validation optimizer.
  - Not AI-REML.
  - Not the default public R fitting path.
  - Not production sparse fitting.
  - No fitted Mrode or external fitted-model comparator claim.

## 2026-06-13 Mission-Control Documenter Page

- Goal: add a dashboard-style Documenter page for the Julia lane, matching the
  R/Julia twin operating style without turning planned capabilities into
  claims.
- Active lenses: Ada, Shannon, Hopper, Emmy, Karpinski, Grace, Rose, Pat.
- Spawned subagents: none.
- Implementation:
  - Added `docs/src/mission-control.md`.
  - Added the page to the Documenter navigation.
  - Linked the dashboard from the docs homepage, roadmap, and README.
- Local checks:
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; Vitepress dependency installation still reported
    npm advisories in generated/transient build artifacts.
- Boundary:
  - Documentation dashboard only.
  - No new fitting, validation, bridge, backend, GPU, QTL/eQTL, GLLVM, or
    performance claim.

## 2026-06-13 Fit Diagnostics Metadata Helper

- Goal: mirror the R twin's `fit_diagnostics()` surface in Julia as a
  metadata-only extractor for existing low-level result objects.
- Active lenses: Ada, Shannon, Hopper, Emmy, Karpinski, Grace, Rose, Pat.
- Spawned subagents: none.
- R handoff:
  - `hsquared` head `060988d` adds exported `fit_diagnostics()` for
    `hsquared_fit` objects.
  - R evidence reported green: R-CMD-check `27465274019`, pkgdown
    `27465274023`, Pages `27465310482`.
- Julia implementation:
  - Added exported `fit_diagnostics()`.
  - Added `fit_diagnostics(fit::AnimalModelFit)` with engine, result type,
    target, method, family, convergence, optimizer status, iterations,
    log-likelihood, `df`, `nobs`, path flags, and variance-component source.
  - Added `fit_diagnostics(result::HendersonMMEResult)` with supplied-variance
    MME metadata and `loglik = nothing`, `df = nothing`.
  - Kept `result_payload()` unchanged.
  - Updated README, quickstart/API docs, engine contract, capability status,
    validation debt, public claims, coordination board, roadmap, and changelog.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed after code/test
    edits. Testset totals sum to 515 checks; dense fit extractor testset has
    76 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; Vitepress dependency installation still reported
    npm advisories in generated/transient build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches.
  - Claim-boundary scan found expected blocked/status wording only.
- Remote checks for commit `2eecd3d`:
  - CI `27465830901`: success on Julia 1 and Julia 1.10.
  - Documenter `27465830922`: success.
  - Pages deploy `27465866797`: success.
  - GitHub Actions reported non-blocking Node 20 deprecation annotations for
    the action stack.
- Live docs:
  - `https://itchyshin.github.io/HSquared.jl/dev/api.html`: HTTP 200 and
    contains `HSquared.fit_diagnostics`.
  - `https://itchyshin.github.io/HSquared.jl/dev/quickstart.html`: HTTP 200
    and contains the metadata-only `fit_diagnostics()` example and bridge
    payload boundary wording.
- Boundary:
  - Metadata extraction only.
  - No optimizer rerun.
  - No gradient/information diagnostics.
  - No backend/device diagnostics.
  - No bridge payload widening.
  - No new fitting, sparse production, or performance claim.

## 2026-06-13 Mrode-Style Supplied-Variance Validation Fixture

- Goal: add a Julia-native Mrode9-shaped supplied-variance validation fixture
  for dense/sparse likelihood identity, Henderson MME outputs, PEV,
  reliability, derived accuracy, and `h2`, while keeping fitted Mrode and
  variance-component-estimation claims blocked.
- Active lenses: Ada, Shannon, Henderson, Curie, Fisher, Gauss, Grace, Rose.
- Spawned subagents: none.
- R coordination context:
  - R already records optional `nadiv::Mrode9` / `nadiv::makeAinv()` pedigree
    inverse comparator evidence at head `369d14a`.
  - R later added `fit_diagnostics()` at head `060988d`; Julia records that as
    a possible follow-up but did not implement diagnostics in this slice.
- Julia implementation:
  - Added a 12-animal Mrode9-shaped supplied-variance fixture in
    `test/runtests.jl`.
  - Pinned normalized IDs, `Ainv`, ML and REML likelihood values, fixed
    effects, EBVs, fitted values, PEV, reliability, derived accuracy, and
    `h2`.
  - Cross-checked sparse REML against dense REML and `henderson_mme()` against
    the independent test-only dense MME solve.
  - Updated `validation_status()`, validation canon, capability status,
    validation debt, public claims, README, ROADMAP, and Documenter validation
    page.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed after the code-only
    fixture edit.
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed after docs/status
    edits. Testset totals sum to 487 checks; the Phase 0 scaffold/status
    testset has 138 checks and the new Mrode-style supplied-variance testset
    has 31 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; Vitepress dependency installation still reported
    npm advisories in generated/transient build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan found only Julia's existing `≈` test operator in
    new test assertions.
  - Claim-boundary scan found expected blocked/status wording only.
- Remote checks for commit `b8c75d0`:
  - CI `27465516616`: success on Julia 1 and Julia 1.10.
  - Documenter `27465516626`: success.
  - Pages deploy `27465552850`: success.
  - GitHub Actions reported non-blocking Node 20 deprecation annotations for
    the action stack.
- Live docs:
  - `https://itchyshin.github.io/HSquared.jl/dev/validation-status.html`:
    HTTP 200 and contains `Mrode9-shaped supplied-variance fixture` plus the
    fitted-Mrode boundary wording.
- Boundary:
  - Supplied variance components only.
  - No variance-component estimation.
  - No AI-REML.
  - No fitted Mrode output validation.
  - No external fitted-model comparator parity.
  - No production sparse fitting or production sparse PEV/reliability claim.

## 2026-06-13 HSData Genotype Diagnostics

- Goal: mirror the R twin's `hs_data()` genotype-status diagnostics in Julia
  `HSData` without changing bridge payloads or adding genomic/QTL/GWAS/eQTL
  modelling.
- Active lenses: Ada, Emmy, Jason, Pat, Hopper, Karpinski, Rose, Grace.
- Spawned subagents: none.
- R handoff:
  - `hsquared` head `f067cd9` adds genotype-status diagnostics to
    `summary(hs_data(...))` and `data_status()`.
  - R evidence: focused hs-data tests 108 pass, full tests 402 pass,
    R-CMD-check `27464852608`, pkgdown `27464852619`, Pages `27464895368`
    passed.
- Julia implementation:
  - Added `HSDataGenotypeStatusRow` and `genotype_status` on `HSDataStatus`.
  - Added genotype-status diagnostics for table-like and matrix-like genotype
    inputs.
  - Stored `genotype_id` in `HSData` so table-like marker columns can be
    counted after excluding the genotype ID column.
  - Added missing-genotype-value counts for in-memory matrix and table-like
    genotype inputs.
  - Updated tests, README, Documenter pages, roadmap, engine/HSData contracts,
    capability status, validation debt, public claims, coordination board, and
    changelog.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 453 checks; the Phase 1 HSData ID container testset has 113 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; Vitepress dependency installation still reported
    npm advisories in generated/transient build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches.
  - Claim-boundary scan found expected status and limitation wording only.
- Remote checks for commit `11a8421`:
  - CI `27465127241`: success on Julia 1 and Julia 1.10.
  - Documenter `27465127247`: success.
  - Pages deploy `27465161162`: success.
  - GitHub Actions reported non-blocking Node 20 deprecation annotations for
    the action stack.
- Live docs:
  - `https://itchyshin.github.io/HSquared.jl/dev/data.html`: HTTP 200 and
    contains `Genotype Metadata` and `genotype_status`.
  - `https://itchyshin.github.io/HSquared.jl/dev/api.html`: HTTP 200 and
    contains `HSDataGenotypeStatusRow`.
- Boundary:
  - Metadata diagnostics only.
  - No bridge payload change.
  - No PLINK/VCF parsing, genotype imputation, genomic relationship
    construction, marker scans, QTL/GWAS/eQTL fitting, GLLVM workflows,
    GPU workflows, or production modelling claim.

## 2026-06-13 HSData Expression Diagnostics

- Goal: mirror the R twin's `hs_data()` expression-status diagnostics in
  Julia `HSData` without changing bridge payloads or adding eQTL/omics/GLLVM
  modelling.
- Active lenses: Ada, Emmy, Jason, Pat, Hopper, Karpinski, Rose, Grace.
- Spawned subagents: none.
- R handoff:
  - `hsquared` head `06cdf59` adds expression-status diagnostics to
    `summary(hs_data(...))` and `data_status()`.
  - R evidence: focused hs-data tests 101 pass, full tests 395 pass,
    R-CMD-check `27464585327`, pkgdown `27464585334`, Pages `27464619135`
    passed.
- Julia implementation:
  - Added `HSDataExpressionStatusRow` and `expression_status` on
    `HSDataStatus`.
  - Added expression-status diagnostics for table-like and matrix-like
    expression inputs.
  - Stored `expression_id` in `HSData` so table-like feature columns can be
    counted after excluding the expression ID column.
  - Updated tests, README, Documenter pages, roadmap, engine/HSData contracts,
    capability status, validation debt, public claims, coordination board, and
    changelog.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 446 checks; the Phase 1 HSData ID container testset has 106 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; Vitepress dependency installation still reported
    npm advisories in generated/transient build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches.
  - Claim-boundary scan found expected status and limitation wording only.
- Remote checks for commit `81e82b0`:
  - CI `27464814149`: success on Julia 1 and Julia 1.10.
  - Documenter `27464814148`: success.
  - Pages deploy `27464876181`: success.
  - GitHub Actions reported non-blocking Node 20 deprecation annotations for
    the action stack.
- Live docs:
  - `https://itchyshin.github.io/HSquared.jl/dev/data.html`: HTTP 200 and
    contains `Expression Metadata` and `expression_status`.
  - `https://itchyshin.github.io/HSquared.jl/dev/api.html`: HTTP 200 and
    contains `HSDataExpressionStatusRow`.
- Boundary:
  - Metadata diagnostics only.
  - No bridge payload change.
  - No automatic expression joins, eQTL/omics fitting, GLLVM workflows,
    marker/QTL/GWAS workflows, genomic fitting, file-backed expression
    storage, or production modelling claim.

## 2026-06-13 HSData Annotation Diagnostics

- Goal: mirror the R twin's `hs_data()` annotation-feature diagnostics in
  Julia `HSData` without changing bridge payloads or adding eQTL/omics/GLLVM
  workflows.
- Active lenses: Ada, Emmy, Jason, Pat, Hopper, Karpinski, Rose, Grace.
- Spawned subagents: none.
- R handoff:
  - `hsquared` head `87888d9` adds annotation-feature diagnostics to
    `summary(hs_data(...))` and `data_status()`.
  - Reported R evidence: R-CMD-check `27464280256`, pkgdown `27464280265`,
    and Pages `27464310951` success.
- Julia-side action:
  - Added `HSAnnotationSpec` for keyed annotation metadata.
  - Added `HSDataAnnotationStatusRow` and `annotation_status` on
    `HSDataStatus`.
  - Added `annotation_id` validation for `HSData`.
  - Added keyed and unkeyed annotation-status tests plus missing-key,
    missing-value, duplicate-annotation-feature, empty-expression-feature, and
    matrix-expression-without-feature-name coverage.
  - Updated API docs, data-container docs, README, ROADMAP, Documenter
    roadmap, engine contract, HSData contract, capability status, validation
    debt, public claims register, and coordination board.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 440 checks; the Phase 1 HSData ID container testset has 100 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; Vitepress dependency installation still reported
    npm advisories in generated/transient build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches.
  - Claim-boundary scan found expected status and limitation wording only.
- Remote checks for commit `09a3718`:
  - CI `27464551542`: success on Julia 1 and Julia 1.10.
  - Documenter `27464551547`: success.
  - Pages deploy `27464583353`: success.
  - GitHub Actions reported non-blocking Node 20 deprecation annotations for
    the action stack.
- Live docs:
  - `https://itchyshin.github.io/HSquared.jl/dev/data.html`: HTTP 200 and
    contains `Annotation Metadata` and `annotation_status`.
  - `https://itchyshin.github.io/HSquared.jl/dev/api.html`: HTTP 200 and
    contains `HSAnnotationSpec` and `HSDataAnnotationStatusRow`.
- Boundary:
  - Metadata diagnostics only.
  - No bridge payload change.
  - No automatic annotation joins, eQTL/omics fitting, GLLVM workflows,
    marker/QTL/GWAS workflows, genomic fitting, or production data-container
    modelling claim.

## 2026-06-13 HSData Environment Diagnostics

- Goal: mirror the R twin's `hs_data()` environment-key diagnostics in Julia
  `HSData` without changing bridge payloads or adding environmental model
  terms.
- Active lenses: Ada, Emmy, Darwin, Pat, Hopper, Karpinski, Rose, Grace.
- Spawned subagents: none.
- R handoff:
  - `hsquared` head `e7fbb31` adds environment-key diagnostics to
    `summary(hs_data(...))` and `data_status()`.
  - Reported R evidence: R-CMD-check `27463966276`, pkgdown `27463966261`,
    and Pages `27463998276` success.
- Julia-side action:
  - Added `HSEnvironmentSpec` for keyed environment metadata.
  - Added `HSDataEnvironmentStatusRow` and `environment_status` on
    `HSDataStatus`.
  - Added `environment_id` validation for `HSData`.
  - Added keyed and unkeyed environment-status tests plus missing-key,
    missing-value, and duplicate-environment-ID coverage.
  - Updated API docs, data-container docs, README, ROADMAP, Documenter
    roadmap, engine contract, HSData contract, capability status, validation
    debt, public claims register, and coordination board.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 421 checks; the Phase 1 HSData ID container testset has 81 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; Vitepress dependency installation still reported
    npm advisories in generated/transient build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches.
  - Claim-boundary scan found expected status and limitation wording only.
- Remote checks for commit `6162e9b`:
  - CI `27464260362`: success on Julia 1 and Julia 1.10.
  - Documenter `27464260366`: success.
  - Pages deploy `27464291912`: success.
  - GitHub Actions reported non-blocking Node 20 deprecation annotations for
    the action stack.
- Live docs:
  - `https://itchyshin.github.io/HSquared.jl/dev/`: HTTP 200.
  - `https://itchyshin.github.io/HSquared.jl/dev/data.html`: HTTP 200 and
    contains `Environment Metadata` and `environment_status`.
  - `https://itchyshin.github.io/HSquared.jl/dev/api.html`: HTTP 200 and
    contains `HSEnvironmentSpec` and `HSDataEnvironmentStatusRow`.
- Boundary:
  - Metadata diagnostics only.
  - No bridge payload change.
  - No environment-covariate joins, environmental model terms,
    multi-environment fitting, genotype parsing, marker scanning, QTL/eQTL, or
    GLLVM workflow claim.

## 2026-06-13 EBV BLUP Accuracy Extractor Parity

- Goal: mirror the R twin's EBV/BLUP/accuracy extractor ergonomics in Julia
  without changing the compact bridge payload or widening fitting claims.
- Active lenses: Ada, Hopper, Henderson, Fisher, Karpinski, Rose, Grace.
- Spawned subagents: none.
- Julia-side action:
  - Added exported `EBV()` and `BLUP()` aliases over `breeding_values()`.
  - Added exported `accuracy()` as a checked square-root transform of
    `reliability()`.
  - Added tests for `AnimalModelFit` and supplied-variance
    `HendersonMMEResult` objects.
  - Added tests that invalid, non-finite, or mismatched reliability inputs
    error before accuracy is computed.
  - Updated API docs, quickstart, README, roadmap, engine contract, capability
    status, validation debt, public claims register, validation-status rows,
    and coordination board.
- Local checks:
  - Initial `julia --project=. -e 'using Pkg; Pkg.test()'` failed because the
    shared Henderson MME fixture has reliability outside `[0, 1]`; the test was
    corrected to assert that `accuracy(mme)` errors for that fixture.
  - Final `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals
    sum to 403 checks; dense extractor testset has 48 checks and the Henderson
    MME supplied-variance validation fixture has 42 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; Vitepress dependency installation still reported
    npm advisories in generated/transient build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches after replacing new test
    `isapprox` shorthands with ASCII calls.
  - Claim-boundary scan found expected status and limitation wording only.
- Remote checks for commit `18dea52`:
  - CI `27463928722`: success on Julia 1 and Julia 1.10.
  - Documenter `27463928730`: success.
  - Pages deploy `27463962899`: success.
  - GitHub Actions reported non-blocking Node 20 deprecation annotations for
    the action stack.
- Boundary:
  - `EBV()` and `BLUP()` are aliases, not new estimators.
  - `accuracy()` is derived from reliability and adds no independent accuracy
    validation.
  - No `result_payload()` fields were added.
  - No production sparse reliability, production sparse PEV, fitted Mrode
    validation, or external fitted-model comparator claim.

## 2026-06-13 Direct Henderson MME Fit Target

- Goal: add a Julia-side direct `fit_animal_model(...; target =
  :henderson_mme, variance_components = ...)` convenience path that mirrors the
  R twin's explicit supplied-variance bridge target without changing the
  default dense optimizer path.
- Active lenses: Ada, Hopper, Henderson, Fisher, Karpinski, Rose, Grace.
- Spawned subagents: none.
- Julia-side action:
  - Added `target` and `variance_components` keywords to
    `fit_animal_model(spec)` and the direct `fit_animal_model(y, X, Z, Ainv;
    ...)` payload method.
  - Kept the default `target = :variance_components` dispatch on the existing
    dense validation optimizer.
  - Added `target = :henderson_mme` dispatch returning `HendersonMMEResult` at
    supplied variance components.
  - Added tests for spec and direct-payload target dispatch plus missing
    variance component, unsupported target, and unsupported optimizer-keyword
    errors.
  - Updated capability status, validation debt, public claims, engine
    contract, README, ROADMAP, Documenter pages, and coordination board.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 383 checks; dense variance-component fitting testset has 22 checks and
    bridge payload fit target testset has 20 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; Vitepress dependency installation still reported
    npm advisories in generated/transient build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches.
  - Claim-boundary scan found expected status and limitation wording only.
- Remote checks for commit `308a103`:
  - CI `27463613983`: success on Julia 1 and Julia 1.10.
  - Documenter `27463613984`: success.
  - Pages deploy `27463649844`: success.
  - GitHub Actions reported non-blocking Node 20 deprecation annotations for
    the action stack.
- Boundary:
  - This is supplied-variance equation solving only.
  - The target returns `HendersonMMEResult`, not `AnimalModelFit`.
  - No log-likelihood, AIC, `df`, optimizer output, variance-component
    estimation, AI-REML, production sparse fitting, or fitted Mrode validation
    claim.

## 2026-06-13 MME-Backed Fitted Values

- Goal: make `fitted_values(fit::AnimalModelFit)` use the same Henderson MME
  solve as `breeding_values(fit)` at the fit's variance components.
- Active lenses: Ada, Henderson, Fisher, Karpinski, Rose, Grace.
- Spawned subagents: none.
- Julia-side action:
  - Changed `fitted_values(fit)` to call
    `henderson_mme(fit.spec, sigma_a2, sigma_e2)` and return
    `fitted_values(mme; include_random = include_random)`.
  - Added tests that `fitted_values(fit)` matches `fitted_values(mme)` with
    and without random effects for both the dense extractor fixture and the
    shared Henderson MME fixture.
  - Updated capability status, validation debt, public claims, engine
    contract, README, ROADMAP, Documenter pages, validation-status evidence,
    and coordination board.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 371 checks; dense extractor testset has 33 checks and the Henderson MME
    supplied-variance validation fixture has 37 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; Vitepress dependency installation still reported
    npm advisories in generated/transient build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches.
  - Claim-boundary scan found expected status and limitation wording only.
- Remote checks for commit `e6e38f2`:
  - CI `27463342065`: success on Julia 1 and Julia 1.10.
  - Documenter `27463342069`: success.
  - Pages deploy `27463373649`: success.
  - GitHub Actions reported non-blocking Node 20 deprecation annotations for
    the action stack.
- Evidence update checks:
  - `julia --project=docs docs/make.jl` passed after recording remote
    evidence. Local deployment was skipped as expected outside CI; Vitepress
    dependency installation still reported npm advisories in transient build
    artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches.
- Boundary:
  - EBV/BLUP and fitted-value extraction are MME-backed at fitted variance
    components.
  - Variance-component estimation is still the experimental dense path.
  - No production sparse fitting claim.
  - No production sparse reliability or PEV claim.
  - No fitted Mrode output validation or external fitted-model comparator
    claim.

## 2026-06-13 MME-Backed EBV Extractor

- Goal: replace the dense covariance equation inside `breeding_values(fit)`
  with the Henderson MME solve at the fit's variance components.
- Active lenses: Ada, Henderson, Fisher, Karpinski, Rose, Grace.
- Spawned subagents: none.
- Julia-side action:
  - Changed `breeding_values(fit::AnimalModelFit)` to call
    `henderson_mme(fit.spec, sigma_a2, sigma_e2)` and return that animal-effect
    block.
  - Added tests that `breeding_values(fit)` matches `breeding_values(mme)` for
    the dense extractor fixture and the shared Henderson MME fixture.
  - Updated capability status, validation debt, public claims, engine contract,
    README, ROADMAP, Documenter pages, and validation-status evidence.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 366 checks; dense extractor testset has 31 checks and the Henderson MME
    supplied-variance validation fixture has 35 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; Vitepress dependency installation still reported
    npm advisories in generated/transient build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches.
  - Claim scan found expected status and limitation wording only.
- Remote checks for commit `55e91b8`:
  - CI `27463043491`: success on Julia 1 and Julia 1.10.
  - Documenter `27463043481`: success.
  - Pages deploy `27463077970`: success.
  - GitHub Actions reported non-blocking Node 20 deprecation annotations for
    the action stack.
  - Live quickstart page contains the Henderson MME and MME-backed
    `breeding_values(fit)` wording.
- R twin coordination:
  - R head `d7e8914` records green CI evidence for supplied-variance
    `target = "henderson_mme"` bridge enrichment from
    `prediction_error_variance(mme)` and `reliability(mme)` when those Julia
    methods are available.
  - Reported R evidence: R-CMD-check `27463031064`, pkgdown `27463031056`,
    and Pages `27463061893` success.
- Evidence update checks:
  - `julia --project=docs docs/make.jl` passed after recording remote and R
    evidence. Local deployment was skipped as expected outside CI; Vitepress
    dependency installation still reported npm advisories in transient build
    artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches.
  - Claim-boundary scan found expected status and limitation wording only.
- Boundary:
  - EBV/BLUP extraction is MME-backed.
  - Variance-component estimation is still the experimental dense path.
  - No production sparse fitting claim.
  - No production sparse reliability or PEV claim.
  - No fitted Mrode output validation or external fitted-model comparator
    claim.

## 2026-06-13 R Henderson MME Bridge Target Sync

- Goal: mirror the R twin's explicit opt-in supplied-variance Henderson MME
  bridge target in Julia docs/status without changing Julia APIs or
  `result_payload()`.
- Active lenses: Ada, Hopper, Henderson, Fisher, Rose, Grace.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `99d974a` adds the Henderson MME bridge target.
  - `hsquared` head `00b9e33` records CI evidence.
  - Reported R evidence: R-CMD-check `27462763849`, pkgdown `27462763842`,
    and Pages `27462799025` success.
- Julia-side action:
  - Recorded `engine_control$target = "henderson_mme"` as external
    supplied-variance bridge evidence.
  - Updated capability status, validation debt, public claims, engine contract,
    README, ROADMAP, Documenter roadmap, changelog, and coordination board.
- Boundary:
  - Documentation/status sync only.
  - No Julia API change.
  - No `result_payload()` widening.
  - No variance-component estimation.
  - No AI-REML.
  - No log-likelihood/AIC/df/optimizer output claim for the R bridge target.
  - No fitted Mrode output validation or production sparse fitting claim.

## 2026-06-13 Henderson MME Variance Component H2 Methods

- Goal: add supplied-variance `variance_components()` and `heritability()`
  methods for `HendersonMMEResult` without claiming variance-component
  estimation.
- Active lenses: Ada, Henderson, Fisher, Hopper, Rose, Grace.
- Spawned subagents: none.
- Julia-side action:
  - Added `variance_components(result::HendersonMMEResult)`.
  - Added `heritability(result::HendersonMMEResult)`.
  - Added two shared Henderson fixture assertions for supplied variance
    components and `h2`.
  - Updated status and Documenter wording.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 364 checks; the Henderson MME supplied-variance validation fixture has
    34 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; Vitepress dependency installation still reported
    npm advisories in generated/transient build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches.
  - Claim scan found expected status and limitation wording only.
- Remote checks for commit `ed2c932`:
  - CI `27462729581`: success on Julia 1 and Julia 1.10.
  - Documenter `27462729578`: success.
  - Pages deploy `27462764899`: success.
  - GitHub Actions reported non-blocking Node 20 deprecation annotations for
    upstream actions.
- Boundary:
  - Supplied variance components are reported; they are not estimated.
  - `heritability(mme)` is the simple ratio from supplied components.
  - No `result_payload()` widening.
  - No production sparse fitting or fitted Mrode validation claim.

## 2026-06-13 Henderson MME PEV Reliability Methods

- Goal: extend validation-scale `prediction_error_variance()` and
  `reliability()` to supplied-variance `HendersonMMEResult` objects without
  changing `result_payload()` or claiming production sparse PEV/reliability.
- Active lenses: Ada, Henderson, Fisher, Hopper, Rose, Grace.
- Spawned subagents: none.
- Julia-side action:
  - Refactored the dense MME inverse-block helper so dense `AnimalModelFit` and
    supplied-variance `HendersonMMEResult` use the same calculation.
  - Added tests in the shared Henderson fixture for `prediction_error_variance(mme)`
    and `reliability(mme)`.
  - Updated capability status, validation debt, public claims, engine contract,
    README, roadmap, and Documenter pages.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 362 checks; the Henderson MME supplied-variance validation fixture has
    32 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; Vitepress dependency installation still reported
    npm advisories in generated/transient build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches.
  - Claim scan found only expected status and limitation wording; no
    production sparse PEV/reliability, variance-component estimation, AI-REML,
    Mrode fitted-output validation, or performance claim was added.
- Remote checks for commit `c69e594`:
  - CI `27462530598`: success on Julia 1 and Julia 1.10.
  - Documenter `27462530592`: success.
  - Pages deploy `27462564061`: success.
  - GitHub Actions reported non-blocking Node 20 deprecation annotations for
    upstream actions.
- Live docs:
  - Quickstart page returned HTTP 200 and contains
    `prediction_error_variance(mme)` plus `HendersonMMEResult` wording.
  - Roadmap page returned HTTP 200 and contains the supplied-variance
    Henderson MME validation-path wording.
  - Validation-status page returned HTTP 200 and retains the partial
    validation boundary.
- Boundary:
  - Supplied-variance validation-scale extractor methods only.
  - No base `result_payload()` widening.
  - No production sparse selected inversion.
  - No variance-component estimation.
  - No fitted Mrode or external fitted-model comparator claim.

## 2026-06-13 Henderson MME Supplied-Variance Fixture Sync

- Goal: mirror the R twin's issue #7 supplied-variance Henderson MME validation
  fixture in Julia tests and docs without promoting variance-component
  estimation, AI-REML, fitted Mrode validation, or production sparse fitting.
- Active lenses: Ada, Shannon, Curie, Henderson, Fisher, Hopper, Karpinski,
  Rose, Grace.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `ec2a9cc` adds
    `hs_henderson_mme_validation_fixture()` and an independent R MME reference
    solve.
  - `hsquared` head `ca8bce1` records CI evidence.
  - Reported R evidence: R-CMD-check `27461992645`, pkgdown `27461992626`,
    and Pages `27462024756` success.
- Julia-side action:
  - Pinned the shared five-animal fixture in `test/runtests.jl`.
  - The fixture checks expected `Ainv`, fixed effects, EBVs, fitted values,
    and `h2 = 0.6` at `sigma_a2 = 1.2` and `sigma_e2 = 0.8`.
  - Updated `validation_status()`, validation canon, capability status,
    validation debt, public claims, engine contract, README, roadmap, and
    Documenter pages with supplied-variance-only wording.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 358 checks; the Henderson MME supplied-variance validation fixture has
    28 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; Vitepress dependency installation still reported
    npm advisories in generated/transient build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches.
  - Claim scan found only expected boundary wording around no
    variance-component estimation, no AI-REML, no fitted Mrode validation, no
    external fitted-model parity, no production sparse fitting, and no
    performance claim.
- Remote checks:
  - CI `27462230519`: success on Julia 1 and Julia 1.10.
  - Documenter `27462230492`: success.
  - Pages deploy `27462261478`: success.
  - GitHub Actions reported non-blocking Node 20 deprecation annotations for
    upstream actions; no action required in this slice.
  - Live validation-status page
    `https://itchyshin.github.io/HSquared.jl/dev/validation-status`: HTTP 200
    and contains `ca8bce1`, `h2 = 0.6`, and no-variance-component-estimation
    wording.
  - Live quickstart page `https://itchyshin.github.io/HSquared.jl/dev/quickstart`:
    HTTP 200 and contains the supplied-variance Henderson fixture wording.
  - Live roadmap page `https://itchyshin.github.io/HSquared.jl/dev/roadmap`:
    HTTP 200 and contains the shared R/Julia fixture wording.
- Boundary:
  - Supplied-variance MME validation only.
  - No variance-component estimation.
  - No AI-REML.
  - No fitted Mrode animal-model validation.
  - No ASReml/BLUPF90/DMU/WOMBAT/sommer/MCMCglmm fitted-model parity.
  - No production sparse fitting claim.

## 2026-06-13 Documenter NPM Cache Hardening

- Goal: reduce repeat risk from the transient DocumenterVitepress/npm cache
  failure seen on the first remote Documenter attempt for commit `4363512`.
- Active lenses: Ada, Shannon, Grace, Karpinski, Hopper, Rose.
- Spawned subagents: none.
- Trigger:
  - Documenter run `27461779343` initially failed with an npm cache temporary
    file collision and a generated `docs/package-lock.json` cleanup error.
  - Rerunning failed jobs passed, and Pages deploy `27461844908` succeeded, so
    this was treated as CI hygiene rather than a docs-content failure.
- Julia-side action:
  - Set `npm_config_cache` for the Documenter build step to
    `${{ runner.temp }}/npm-cache`.
  - Remove transient npm cache tmp files and generated `docs/package-lock.json`
    before running `julia --project=docs docs/make.jl`.
- Local checks:
  - `ruby -e 'require "yaml"; YAML.load_file(".github/workflows/Documenter.yml"); puts "yaml ok"'`:
    passed.
  - `julia --project=docs docs/make.jl`: passed. Local deployment was
    skipped as expected outside CI; Vitepress dependency installation still
    reported npm advisories in generated/transient build artifacts.
  - `julia --project=. -e 'using Pkg; Pkg.test()'`: passed. Testset totals
    sum to 351 checks.
  - `git diff --check`: passed.
  - Additions-only ASCII scan: returned no matches.
  - Claim scan found only expected boundary wording that this is workflow
    hygiene and makes no capability, validation, fitting, bridge,
    backend-execution, GPU, or performance claim.
- Remote checks:
  - CI `27461986532`: success on Julia 1 and Julia 1.10.
  - Documenter `27461986538`: success on the first attempt after the npm-cache
    hardening.
  - Pages deploy `27462018363`: success.
  - CI and Documenter reported non-blocking Node 20 deprecation annotations for
    upstream actions; no action required in this slice.
- Boundary:
  - Workflow hygiene only.
  - No package API change.
  - No docs content change.
  - No capability, validation, fitting, bridge, backend-execution, GPU, or
    performance claim.

## 2026-06-13 HSData Pedigree Status Diagnostic

- Goal: mirror the R twin's pedigree-status diagnostics in
  `data_status(::HSData)` without changing bridge payloads or claiming raw
  pedigree normalization, Ainv construction, or model fitting.
- Active lenses: Ada, Shannon, Emmy, Hopper, Henderson, Karpinski, Pat, Rose,
  Grace.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `3fafa08` adds pedigree-status diagnostics to
    `summary(hs_data(...))` and `data_status()`.
  - Reported R evidence: focused hs-data tests 55 pass, full tests 263 pass,
    pkgdown no problems, `devtools::check()` 0/0/0, R-CMD-check
    `27461235870`, pkgdown `27461235877`, and Pages `27461267695` success.
- Julia-side action:
  - Added `HSDataPedigreeStatusRow`.
  - Extended `HSDataStatus` with `pedigree_status`.
  - `data_status()` now reports pedigree rows, unique pedigree IDs,
    phenotype coverage, pedigree-only IDs, founders, nonfounders, known parent
    links, missing known parent IDs, duplicate raw pedigree IDs,
    self-parent rows, and same-known-parent rows.
  - Raw table-like pedigree IDs can be duplicated for diagnostics; normalized
    `Pedigree` inputs still reject duplicate, missing-parent, self-parent,
    same-known-parent, and cycle errors before engine use.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 351 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches.
  - Claim scan found only expected guardrail and blocked-wording hits around
    diagnostics, bridge payloads, raw-pedigree Ainv construction,
    relationship construction, fitted animal-model support, genomic fitting,
    marker scanning, and QTL/eQTL fitting.
- Remote checks:
  - CI `27461589231`: success.
  - Documenter `27461589180`: success.
  - Pages deploy `27461624269`: success.
  - GitHub Actions reported non-blocking Node 20 deprecation annotations for
    upstream actions.
  - Live data page `https://itchyshin.github.io/HSquared.jl/dev/data`: HTTP
    200 and contains `pedigree_status`, `duplicate IDs`, and
    `normalize_pedigree`.
  - Live API page `https://itchyshin.github.io/HSquared.jl/dev/api`: HTTP 200
    and contains `HSDataPedigreeStatusRow` and `data_status`.
  - Live roadmap page `https://itchyshin.github.io/HSquared.jl/dev/roadmap`:
    HTTP 200 and contains `pedigree status` and `marker-alignment status`.
- Boundary:
  - Diagnostic only.
  - No bridge payload change.
  - No raw-pedigree Ainv construction.
  - No relationship-matrix construction from `HSData`.
  - No fitted animal-model, Mrode fitted-output, genomic fitting, marker scan,
    or QTL/eQTL claim.
- Coordination update:
  - After the Julia diagnostic slice was pushed, the R twin reported
    `74eef82` and `39ca990`: `animal(1 | id)` can use the pedigree stored in
    `data = hs_data(..., pedigree = ped)`.
  - Recorded Julia-side parity wording in formula and bridge docs. This is
    R parser/data-container ergonomics only; explicit
    `animal(1 | id, pedigree = ped)` remains the shared portable contract, and
    the Julia engine API plus bridge payload shape are unchanged.
  - Reran `julia --project=. -e 'using Pkg; Pkg.test()'`,
    `julia --project=docs docs/make.jl`, `git diff --check`, additions-only
    ASCII scan, and shorthand/claim scan after the wording update; all passed.

## 2026-06-13 HSData Data Status Diagnostic

- Goal: mirror the R twin's `data_status()` diagnostics for `HSData` without
  changing bridge payloads or claiming genotype/genomic modelling.
- Active lenses: Ada, Shannon, Emmy, Jason, Pat, Rose, Grace.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `1fe0f4c` adds exported `data_status()` for `hs_data()`
    objects.
  - Reported R evidence: focused hs-data tests 46 pass, full tests 254 pass,
    pkgdown no problems, `devtools::check()` 0/0/0, R-CMD-check
    `27461011499`, pkgdown `27461011484`, and Pages `27461044101` success.
- Julia-side action:
  - Added `HSDataIDOverlapRow`, `HSDataMarkerStatusRow`, `HSDataStatus`, and
    `data_status(::HSData)`.
  - `data_status()` reports component presence, ID-overlap counts, and
    marker-map/genotype-marker alignment status.
  - Updated data docs, API docs, HSData contract, capability status,
    validation debt, public claims, README, roadmap, changelog, and
    coordination board.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 334 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches.
  - Claim scan found only expected guardrail and blocked-wording hits around
    diagnostics, bridge payloads, genotype parsing, relationship construction,
    marker scanning, genomic fitting, and QTL/eQTL fitting.
- Remote checks:
  - CI `27461262496`: success.
  - Documenter `27461262492`: success.
  - Pages deploy `27461295761`: success.
  - GitHub Actions reported non-blocking Node 20 deprecation annotations for
    upstream actions.
  - Live data page `https://itchyshin.github.io/HSquared.jl/dev/data`: HTTP
    200 and contains `data_status()`, ID-overlap wording, and current boundary
    wording.
  - Live API page `https://itchyshin.github.io/HSquared.jl/dev/api`: HTTP 200
    and contains `data_status`, `HSDataStatus`, `HSDataIDOverlapRow`, and
    `HSDataMarkerStatusRow`.
  - Live roadmap page `https://itchyshin.github.io/HSquared.jl/dev/roadmap`:
    HTTP 200 and contains `data_status()` component-presence and
    marker-alignment status wording.
- Boundary:
  - Diagnostic only.
  - No bridge payload change.
  - No genotype parsing.
  - No relationship-matrix construction.
  - No marker scanning, genomic fitting, or QTL/eQTL fitting.
- Follow-up handoff:
  - R head `3fafa08` adds pedigree-status diagnostics to
    `summary(hs_data(...))` and `data_status()`. Reported R remote evidence:
    R-CMD-check `27461235870`, pkgdown `27461235877`, and Pages
    `27461267695` success. Julia pedigree-status parity is a later slice, not
    part of this commit.

## 2026-06-13 HSData Marker Metadata Validation

- Goal: align Julia `HSData` local metadata hygiene with the R twin's marker-map
  and genotype-marker alignment validation, without changing bridge payloads or
  claiming genomic modelling.
- Active lenses: Ada, Shannon, Emmy, Jason, Pat, Rose, Grace.
- Spawned subagents: none.
- R twin handoffs:
  - `hsquared` head `5923fcd` validates marker-map metadata columns, including
    marker ID, chromosome, and finite non-negative position.
  - `hsquared` head `d1eb174` validates genotype marker columns against
    marker-map IDs exactly, allowing different order but rejecting missing or
    extra marker IDs.
  - `hsquared` head `b1a4e48` adds marker-status summaries to
    `summary(hs_data(...))`; this is R-only diagnostic reporting with no
    bridge payload change and no required Julia action.
  - Reported R remote evidence: R-CMD-check `27460445869` / `27460602501`,
    pkgdown `27460445866` / `27460602502`, and Pages `27460479795` /
    `27460635647` success.
  - Reported R remote evidence for the R-only marker-status summary:
    R-CMD-check `27460847536`, pkgdown `27460847546`, and Pages
    `27460886355` success.
- Julia-side action:
  - Added internal `HSMarkerMapSpec` and `HSGenotypeMarkerSpec`.
  - `HSData` now validates marker-map aliases, marker ID uniqueness,
    non-missing chromosomes, finite non-negative positions, matrix genotype
    marker IDs, and genotype-marker/map alignment.
  - Updated data docs, HSData contract, capability status, validation debt,
    public claims, README, roadmap, changelog, and coordination board.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 324 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches.
  - Claim scan found only expected guardrail and roadmap wording around
    metadata validation, file formats, and planned genotype/genomic/QTL work.
- Remote checks:
  - CI `27460961889`: success.
  - Documenter `27460961892`: success.
  - Pages deploy `27460991912`: success.
  - GitHub Actions reported non-blocking Node 20 deprecation annotations for
    upstream actions.
  - Live data page `https://itchyshin.github.io/HSquared.jl/dev/data`: HTTP
    200 and contains `genotype_marker_ids`, marker-map metadata wording,
    genotype parsing as planned, and the current boundary.
  - Live API page `https://itchyshin.github.io/HSquared.jl/dev/api`: HTTP 200
    and contains `HSMarkerMapSpec` and `HSGenotypeMarkerSpec`.
  - Live roadmap page `https://itchyshin.github.io/HSquared.jl/dev/roadmap`:
    HTTP 200 and contains `HSData` marker-map metadata and genotype-marker
    alignment status.
- Boundary:
  - Metadata validation only.
  - No bridge payload change.
  - No genotype parsing.
  - No PLINK/VCF ingestion.
  - No marker imputation.
  - No marker scanning, genomic fitting, or QTL/eQTL fitting.

## 2026-06-13 Validation Status Diagnostic

- Goal: add a Julia-side validation evidence diagnostic that makes covered,
  external, partial, and planned validation rows queryable without running
  comparator packages or widening modelling claims.
- Active lenses: Ada, Shannon, Henderson, Mrode, Fisher, Curie, Rose, Grace.
- Spawned subagents: none.
- R twin context:
  - the R twin has optional `nadiv::Mrode9` / `nadiv::makeAinv()` pedigree-Ainv
    comparator evidence;
  - the latest R-only `hs_data()` summary and marker-map validation handoffs
    had no Julia payload changes and required no Julia action.
- Julia-side action:
  - Added `ValidationStatusRow`, `ValidationStatus`, and
    `validation_status()`.
  - Added a Documenter Validation Status page.
  - Updated API docs, README, roadmap, validation canon, capability status,
    validation debt, public claims, and changelog.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 307 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Additions-only ASCII scan returned no matches. Full edited-file scan sees
    pre-existing approximate-equality test operators in `test/runtests.jl`,
    not new text.
  - Smoke check printed validation rows: `length(validation_status()) == 11`,
    `V1-AINV-MRODE9` as `covered_external`, and `V1-MRODE-FIT` as planned with
    `Fitted Mrode validation is not covered.`
  - Claim scan found only expected status, planned, and blocked wording, not
    claims that the diagnostic runs comparators, fits models, covers fitted
    Mrode outputs, or adds genomic/QTL support.
- Remote checks:
  - CI `27460547802`: success.
  - Documenter `27460547823`: success.
  - Pages deploy `27460576218`: success.
  - Live validation-status page
    `https://itchyshin.github.io/HSquared.jl/dev/validation-status`: HTTP 200
    and contains `validation_status()`, `V1-AINV-MRODE9`, `covered_external`,
    and `Fitted Mrode validation is not covered`.
  - Live API page `https://itchyshin.github.io/HSquared.jl/dev/api`: HTTP 200
    and contains `validation_status` plus `ValidationStatusRow`.
- Boundary:
  - Diagnostic only.
  - No comparator execution.
  - No fitted Mrode validation.
  - No fitted comparator parity.
  - No fitting expansion.

## 2026-06-13 R hs_data Parser Integration Sync

- Goal: mirror the R twin's `hs_data()` parser integration without changing
  Julia payload fields or claiming live Julia `HSData` object marshalling.
- Active lenses: Ada, Shannon, Hopper, Emmy, Rose, Grace, Pat.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `36efbf3` connects `hs_data()` to the v0.1 R parser.
  - `model_spec()` and `hsquared()` can accept an `hs_data()` object as
    `data`.
  - Model variables are read from `data$phenotypes`.
  - Formula components such as `pedigree = pedigree` are resolved from the
    `hs_data()` bundle.
  - The bridge payload shape is unchanged: `y`, `X`, sparse `Z`, normalized
    pedigree/ID metadata, method, family, and Julia target metadata.
  - Reported remote evidence: R-CMD-check `27460091544`, pkgdown
    `27460091551`, and Pages `27460131691` success.
- Julia-side action:
  - Updated the HSData contract, Data Containers page, v0.1 contract, engine
    contract, capability status, validation debt, public claims, README,
    roadmap, changelog, and coordination board.
  - No Julia code changed.
- Local checks:
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 294 checks.
  - `git diff --check` passed.
  - Edited-file ASCII scan returned no matches.
  - Claim scan found only expected guardrail wording around no file-backed
    storage, no genotype/omics automatic model construction, no production
    bridge hardening, no general fitting, and no live Julia `HSData` object
    marshalling.
- Remote checks:
  - CI `27460283615`: success.
  - Documenter `27460283625`: success.
  - Pages deploy `27460318154`: success.
  - Live data page `https://itchyshin.github.io/HSquared.jl/dev/data`: HTTP
    200 and contains `36efbf3`, `This does not change the Julia bridge payload
    shape`, and `object marshalling remains planned`.
  - Live roadmap `https://itchyshin.github.io/HSquared.jl/dev/roadmap`: HTTP
    200 and contains `36efbf3`, `hs_data`, and `bridge payload shape
    unchanged`.
- Boundary:
  - Phenotype/pedigree parser integration only.
  - No file-backed storage.
  - No genotype/omics automatic model construction.
  - No production bridge hardening.
  - No general fitting.
  - No live Julia `HSData` object marshalling.

## 2026-06-13 R Model Spec Preview Sync

- Goal: mirror the R twin's exported `model_spec()` preview surface as a
  formula-to-bridge parity tool in Julia docs/status.
- Active lenses: Ada, Shannon, Hopper, Boole, Emmy, Rose, Grace, Pat.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `bacef9c` adds exported `model_spec()`.
  - It validates the same v0.1 grammar as `hsquared()` and builds the same
    internal bridge payload, but does not fit models or execute Julia.
  - It previews response/family/method, fixed-effect columns, sparse `Z`
    dimensions, normalized animal IDs, observed ID mapping, pedigree founder
    count, and Julia targets.
  - Reported remote evidence: R-CMD-check `27459924245`, pkgdown
    `27459924261`, and Pages `27459952909` success.
- Julia-side action:
  - Updated formula grammar, model-spec grammar, v0.1 contract, engine
    contract, capability status, validation debt, public claims, README,
    roadmap, quickstart, changelog, and coordination board.
  - No Julia code changed.
- Local checks:
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 294 checks.
  - `git diff --check` passed.
  - Edited-file ASCII scan returned no matches.
  - Claim scan found only expected preview guardrails such as "does not fit"
    and public-claims/after-task blocked wording, not unsupported claims that
    `model_spec()` fits models, executes Julia, or expands grammar.
- Remote checks:
  - CI `27460048735`: success.
  - Documenter `27460048734`: success.
  - Pages deploy `27460080421`: success.
  - Live model-spec grammar page
    `https://itchyshin.github.io/HSquared.jl/dev/model-spec-grammar`: HTTP 200
    and contains `model_spec()` plus `previews the same v0.1
    formula-to-bridge contract`.
  - Live quickstart `https://itchyshin.github.io/HSquared.jl/dev/quickstart`:
    HTTP 200 and contains `model_spec()` plus `without executing Julia`.
  - Live roadmap `https://itchyshin.github.io/HSquared.jl/dev/roadmap`: HTTP
    200 and contains `model_spec`, `preview evidence`, `bacef9c`, and `without
    fitting or Julia execution`.
  - GitHub Actions emitted Node 20 deprecation annotations from upstream
    actions, but all jobs completed successfully.
- Boundary:
  - R preview only.
  - No model fitting.
  - No Julia execution.
  - No grammar expansion beyond `animal(1 | id, pedigree = ped)`.

## 2026-06-13 R Bridge PEV Reliability Enrichment Sync

- Goal: mirror the R twin's new tiny/local PEV/reliability bridge enrichment
  wording without changing Julia engine APIs or base `result_payload()`.
- Active lenses: Ada, Shannon, Hopper, Lovelace, Emmy, Rose, Grace, Pat.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `8235289` enriches opt-in local Julia bridge results with
    PEV/reliability if sibling Julia exports `prediction_error_variance(fit)`
    and `reliability(fit)`.
  - R still starts from `result_payload(fit)` and merges these two fields if
    available.
  - Reported remote evidence: R-CMD-check `27459709156`, pkgdown
    `27459709148`, and Pages `27459742852` success.
- Julia-side action:
  - Updated v0.1 contract, engine contract, public claims, capability status,
    validation debt, README, quickstart, roadmap, changelog, and coordination
    board.
  - Kept `result_payload()` compact.
  - No code or test behavior changed.
- Local checks:
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 294 checks.
  - `git diff --check` passed.
  - Edited-file ASCII scan returned no matches after replacing a pre-existing
    `approx` symbol in `docs/src/quickstart.md` with `isapprox(...)`.
  - Claim scan found only public-claims rows or after-task blocked-wording
    rows, not unsupported claims that PEV/reliability are base
    `result_payload()` fields or production sparse capabilities.
- Remote checks:
  - CI `27459918418`: success.
  - Documenter `27459918414`: success.
  - Pages deploy `27459952166`: success.
  - Live quickstart
    `https://itchyshin.github.io/HSquared.jl/dev/quickstart`: HTTP 200 and
    contains the R bridge enrichment wording plus `isapprox`.
  - Live roadmap `https://itchyshin.github.io/HSquared.jl/dev/roadmap`: HTTP
    200 and contains the R PEV/reliability bridge enrichment evidence plus
    compact `result_payload()` wording.
  - GitHub Actions emitted Node 20 deprecation annotations from upstream
    actions, but all jobs completed successfully.
- Boundary:
  - Tiny/local bridge enrichment only.
  - No production sparse PEV/reliability.
  - No fitted Mrode-output validation.
  - No general animal-model fitting claim.
  - No base `result_payload()` widening.

## 2026-06-13 Expanded Genomics QTL GPU Roadmap Mirror

- Goal: mirror the R twin's expanded genomics/QTL/GLLVM/GPU/HPC plan into
  Julia Documenter and design memory.
- Active lenses: Ada, Shannon, Jason, Karpinski, Hopper, Rose, Pat, Grace.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `f806a96` expanded `docs/design/07-genomics-qtl-gpu-plan.md`.
  - `hsquared` head `2c18b30` records expanded plan CI evidence.
  - Reported remote evidence for the R evidence commit: R-CMD-check
    `27459454821`, pkgdown `27459454815`, and Pages `27459486904` success.
  - Boundary from R: roadmap/design only. No genomic fitting, QTL/eQTL scan,
    GLLVM animal model, GPU execution, APY, Takahashi selected inverse,
    AI-REML, HPC, or performance claim.
- Julia-side action:
  - Added Documenter page `docs/src/backend-algorithm-roadmap.md`.
  - Added design note `docs/design/09-backend-algorithm-roadmap.md`.
  - Linked the new page from `docs/make.jl`, `docs/src/index.md`, and
    `docs/src/genomics-qtl-gpu-hpc.md`.
  - Corrected the public R grammar example to `precision(1 | id, Q = Q)` and
    kept the direct Julia qualification note for `HSquared.precision()`.
  - Updated root and Documenter roadmaps to the expanded phase order.
  - Updated ecosystem lessons with local leads from `DRM.jl`,
    `GLLVM.jl`, and `gllvmTMB`.
  - Updated capability status, validation debt, public claims, and
    coordination board.
- Local checks:
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped
    as expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed. Testset totals sum
    to 294 checks.
  - `git diff --check` passed.
  - Edited-file ASCII scan returned no matches.
  - Claim scan found only status, audit, planned, or blocked-wording rows.
- Remote checks:
  - CI `27459769402`: success.
  - Documenter `27459769391`: success.
  - Pages deploy `27459799372`: success.
  - Live docs root `https://itchyshin.github.io/HSquared.jl/`: HTTP 200.
  - Live backend/algorithm page
    `https://itchyshin.github.io/HSquared.jl/dev/backend-algorithm-roadmap`:
    HTTP 200 and contains `Backend And Algorithm Roadmap`, `AI-REML`,
    `Takahashi selected inversion`, and the blocked wording
    `GPU execution works`.
  - GitHub Actions emitted Node 20 deprecation annotations from upstream
    actions, but all jobs completed successfully.
- Boundary:
  - Roadmap and documentation mirror only.
  - No engine API, result payload, parser, backend execution, or model fitting
    behavior changed.

## 2026-06-13 Formula Status Diagnostic Mirror

- Goal: mirror the R twin's `formula_status()` grammar diagnostic in Julia and
  Documenter.
- Active lenses: Ada, Shannon, Boole, Hopper, Noether, Rose, Pat.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `52d57dd` added exported `formula_status()`.
  - `hsquared` head `7ba2df4` records formula status CI evidence.
  - Reported remote evidence: R-CMD-check `27459105695`, pkgdown
    `27459105696`, and Pages `27459143480` success.
  - R issue note:
    `https://github.com/itchyshin/hsquared/issues/4#issuecomment-4697748409`.
- Julia-side action:
  - Added `FormulaStatusRow`, `FormulaStatus`, and `formula_status()`.
  - Mirrored the R table columns: `term`, `category`, `phase`,
    `syntax_status`, `fitting_status`, and `current_behavior`.
  - Added a 20-row Documenter status table to `model-spec-grammar.md`.
  - Updated API docs, README, roadmap, capability status, validation debt,
    public claims, and coordination notes.
- Boundary:
  - Diagnostic only.
  - No formula parser expansion.
  - No model-spec construction for reserved/planned terms.
  - No fitting expansion.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 293 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - `julia --project=. -e 'using HSquared; s = formula_status(); println(length(s)); println(s[1].term); println(s[1].syntax_status); println(s[end].term); println(s[end].syntax_status)'`
    printed the expected 20-row boundary rows.
  - Claim scan found only blocked-wording/audit rows, not public claims that
    `formula_status()` parses formulas, constructs model specs, expands
    fitting, or enables any reserved/planned term.
  - Follow-up docs alignment check: `julia --project=docs docs/make.jl`
    passed after left-aligning the Documenter status table.
- Remote checks for commit `72bc28f`:
  - CI `27459348834`: success.
  - Documenter `27459348823`: success.
  - Pages deploy `27459383483`: success.
  - Live docs root `https://itchyshin.github.io/HSquared.jl/`: HTTP 200.
  - Live grammar page `https://itchyshin.github.io/HSquared.jl/dev/model-spec-grammar`:
    HTTP 200 and contains `formula_status()`, `experimental tiny bridge only`,
    and `qtl_scan(position, genotype_probs = probs)`.
  - GitHub issue note:
    `https://github.com/itchyshin/HSquared.jl/issues/6#issuecomment-4697782885`.

## 2026-06-13 Planned Quantitative-Genetic Marker Vocabulary Mirror

- Goal: mirror the R twin's inert planned standard quantitative-genetic,
  parental, inheritance-kernel, and custom-kernel formula markers as Julia
  vocabulary reservations.
- Active lenses: Ada, Shannon, Boole, Hopper, Noether, Mendel, Henderson, Rose,
  Pat.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `14e5781` added planned-only `permanent()`,
    `common_env()`, `maternal_genetic()`, `maternal_env()`,
    `paternal_genetic()`, `paternal_env()`, `cytoplasmic()`, `imprinting()`,
    `dominance()`, `epistasis()`, `relmat()`, and `precision()` markers.
  - `hsquared` head `10e8fd7` records QG marker CI evidence.
  - R parser detects these terms before model-frame construction and errors
    with planned-not-implemented wording.
  - Reported remote evidence: R-CMD-check `27458718993`, pkgdown
    `27458718981`, and Pages `27458751023` success.
- R docs-sync handoff:
  - `hsquared` head `92c1d12` added pkgdown article
    `vignettes/articles/formula-grammar.Rmd`.
  - `hsquared` head `794722f` records formula-grammar article CI evidence.
  - Reported remote evidence: R-CMD-check `27458881927`, pkgdown
    `27458881926`, and Pages `27458916142` success.
- Julia-side action:
  - Extended `planned_model_terms()` and added `planned_quantgen_terms()`.
  - Added exported `permanent()`, `common_env()`, `maternal_genetic()`,
    `maternal_env()`, `paternal_genetic()`, `paternal_env()`,
    `cytoplasmic()`, `imprinting()`, `dominance()`, `epistasis()`,
    and `relmat()` functions that throw planned-not-implemented errors.
  - Added qualified `HSquared.precision()` for the planned precision-kernel
    marker because `Base.precision` already exists.
  - Updated formula grammar, engine contract, README, docs pages, status
    tables, validation debt, public claims, and coordination board.
  - Added Documenter page `docs/src/model-spec-grammar.md` to mirror the R
    formula-grammar status separation.
- Local checks:
  - First `julia --project=. -e 'using Pkg; Pkg.test()'` failed because
    exporting `precision()` conflicted with `Base.precision`. Fixed by keeping
    the marker available as `HSquared.precision()` and reserving `:precision`
    in the vocabulary table without exporting the unqualified function.
  - Final `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 282
    checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims of
    Phase 2+ QG fitting, custom relationship/precision kernels, genomic
    prediction, marker scans, QTL/eQTL scans, GPU execution, ASReml
    superiority, backend benchmarking, or CPU/GPU numerical agreement.
- Remote checks for commit `d82c2a9`:
  - CI `27459073863`: success.
  - Documenter `27459073865`: success.
  - Pages deploy `27459131950`: success.
  - Live docs root `https://itchyshin.github.io/HSquared.jl/`: HTTP 200.
  - Live grammar page `https://itchyshin.github.io/HSquared.jl/dev/model-spec-grammar`: HTTP 200 and contains `HSquared.precision()`.
- Boundary:
  - Syntax/model-term vocabulary reservation only.
  - No permanent/common environment fitting.
  - No maternal or paternal effect fitting.
  - No cytoplasmic, imprinting, dominance, or epistasis fitting.
  - No custom relationship or precision-kernel fitting.

## 2026-06-13 Planned Genomic/QTL Marker Vocabulary Mirror

- Goal: mirror the R twin's inert planned genomic/QTL formula markers as Julia
  vocabulary reservations.
- Active lenses: Ada, Shannon, Boole, Hopper, Noether, Jason, Rose, Pat.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `dc53584` added planned-only `genomic()`,
    `single_step()`, `markers()`, `marker_scan()`, and `qtl_scan()` markers.
  - `hsquared` head `3c82c9a` records genomic marker CI evidence.
  - R parser detects these terms before model-frame construction and errors
    with planned-not-implemented wording.
  - Reported implementation evidence: local formula tests 17 pass, local full
    tests 158 pass, `devtools::check()` 0/0/0, R-CMD-check `27458338370`,
    pkgdown `27458338374`, and Pages `27458374477` success.
- Julia-side action:
  - Added `planned_model_terms()`.
  - Added exported `genomic()`, `single_step()`, `markers()`, `marker_scan()`,
    and `qtl_scan()` functions that throw planned-not-implemented errors.
  - Updated formula grammar, engine contract, README, docs pages, status
    tables, validation debt, public claims, and coordination board.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 227 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims of
    genomic prediction, single-step fitting, marker-effect estimation, marker
    scans, QTL/eQTL scans, GPU execution, ASReml superiority, backend
    benchmarking, or CPU/GPU numerical agreement.
- Remote checks for commit `bc0fe77`:
  - CI `27458684148`: success.
  - Documenter `27458684126`: success.
  - Pages deploy `27458715550`: success.
  - Live docs `https://itchyshin.github.io/HSquared.jl/`: HTTP 200.
- Boundary:
  - Syntax/model-term vocabulary reservation only.
  - No genomic prediction.
  - No marker-effect estimation.
  - No marker scans, QTL scans, or eQTL scans.
  - No single-step fitting.

## 2026-06-13 Backend Status Diagnostics Mirror

- Goal: mirror the R twin's `backend_info()` honest status diagnostic in Julia.
- Active lenses: Ada, Shannon, Hopper, Karpinski, Grace, Rose, Pat.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `498d41f` added public `backend_info()`.
  - `hsquared` head `8266a82` records backend diagnostics CI evidence.
  - rows: `cpu`, `threads`, `cuda`, `amdgpu`, `metal`, `oneapi`;
  - columns: `backend`, `accelerator`, `requested`, `selectable`,
    `execution_available`, `status`, and `note`;
  - all rows are selectable, execution unavailable, and planned.
  - Reported implementation evidence: local R tests 151 pass,
    `devtools::check()` 0/0/0, R-CMD-check `27458148965`, pkgdown
    `27458148970`, and Pages `27458179717` success.
  - R evidence commit checks: R-CMD-check `27458206919`, pkgdown
    `27458206905`, and Pages `27458237087` success.
- Julia-side action:
  - Added `BackendInfoRow` and `BackendInfo`.
  - Added `backend_info(control = HSControl())`.
  - Added tests for row order, requested flags, selectable flags,
    `execution_available == false`, and `status == :planned`.
  - Updated README, API docs, engine contract, status tables, public claims,
    and coordination board.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 211 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims of
    runtime backend probing, GPU execution, backend benchmarking, CPU/GPU
    numerical agreement, QTL/eQTL support, or ASReml superiority.
- Remote checks for commit `80bd8be`:
  - CI `27458402884`: success.
  - Documenter `27458402883`: success.
  - Pages deploy `27458435663`: success.
  - Live docs `https://itchyshin.github.io/HSquared.jl/`: HTTP 200.
- Boundary:
  - Status diagnostic only.
  - No runtime backend probing.
  - No GPU execution.
  - No backend benchmarking.
  - No CPU/GPU numerical agreement claim.

## 2026-06-13 Planned Backend Vocabulary Mirror

- Goal: mirror the R twin's planned backend and accelerator vocabulary in
  Julia controls and docs.
- Active lenses: Ada, Shannon, Hopper, Karpinski, Grace, Rose.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `5feac1f` expanded `hs_control()` metadata vocabulary.
  - backend names: `auto`, `cpu`, `threads`, `cuda`, `amdgpu`, `metal`,
    `oneapi`;
  - accelerator names: `auto`, `none`, `gpu`, `cuda`, `amdgpu`, `metal`,
    `oneapi`;
  - R-CMD-check `27457948686`, pkgdown `27457948693`, and Pages
    `27457985141` were green.
- Julia-side action:
  - Added marker types: `ThreadsBackend`, `AMDGPUBackend`, `MetalBackend`, and
    `OneAPIBackend`.
  - Expanded `HSControl()` validation for the shared backend and accelerator
    vocabulary.
  - Updated API docs, roadmap, capability status, validation debt, public
    claims, and coordination board.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 197 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
- Remote checks:
  - CI `27458145243`: success.
  - Documenter `27458145252`: success.
  - Pages `27458175711`: success.
  - Live docs returned HTTP 200.
- Boundary:
  - Control metadata only.
  - CPU remains the trusted always-available path.
  - CUDA, AMDGPU, Metal, and oneAPI are future optional-extension markers.
  - No GPU execution, backend availability diagnostics, backend benchmarking,
    or CPU/GPU numerical agreement claim.

## 2026-06-13 Phase 1N Sparse REML Identity And Mrode9 Ainv Sync

- Goal: add a sparse supplied-variance REML likelihood identity and mirror the
  R twin's optional Mrode9/nadiv pedigree-Ainv comparator evidence.
- Active lenses: Ada, Shannon, Henderson, Gauss, Fisher, Curie, Mrode, Grace,
  Rose.
- Spawned subagents: none.
- Implementation evidence:
  - Added `sparse_reml_loglik(spec, sigma_a2, sigma_e2)`.
  - The evaluator uses the sparse Henderson MME determinant identity at
    supplied positive variance components.
  - Shared the sparse MME system builder with `henderson_mme()`.
  - Kept `fit_animal_model()` and `result_payload()` unchanged.
- Test evidence:
  - Added dense-vs-sparse REML equivalence tests on the simple identity
    relationship fixture.
  - Added dense-vs-sparse REML equivalence tests on the existing Henderson MME
    validation fixture.
  - Added error tests for non-positive variances and saturated REML design.
- R twin handoff:
  - Verified read-only from the sibling R repo.
  - `hsquared` head `f0e71c7` added optional `nadiv`, the
    `hs_mrode9_pedigree_validation_fixture()`, and
    `tests/testthat/test-mrode-validation.R`.
  - `hsquared` head `369d14a` recorded green CI evidence.
  - The R test computes `nadiv::makeAinv()` for `nadiv::Mrode9` and compares
    it with Julia `normalize_pedigree()` plus `pedigree_inverse()` at
    tolerance `1e-10`.
- Local checks:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 192 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
- Boundary:
  - `sparse_reml_loglik()` evaluates REML at supplied variance components
    only. It is not variance-component estimation, AI-REML, or production
    sparse fitting.
  - The Mrode9/nadiv evidence covers pedigree inverse agreement only. It is not
    fitted Mrode animal-model validation, EBV/h2/variance-component validation,
    ASReml/BLUPF90/DMU/WOMBAT comparison, or large-pedigree readiness.

## 2026-06-13 R Tiny Ainv Fixture Mirror

- Goal: mirror the R twin's first deterministic Ainv validation atom in the
  Julia design/status ledger.
- Active lenses: Ada, Henderson, Curie, Mrode, Grace, Rose.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `c161a7f` added `hs_tiny_animal_validation_fixture()`.
  - `hsquared` head `fe7e346` recorded green CI evidence.
  - Fixture: out-of-order calf/sire/dam input; normalized IDs `sire`, `dam`,
    `calf`; sire indices `0, 0, 1`; dam indices `0, 0, 2`; expected Ainv
    `[1.5 0.5 -1.0; 0.5 1.5 -1.0; -1.0 -1.0 2.0]`.
  - R-CMD-check `27457553099`, pkgdown `27457553093`, and Pages
    `27457582221` were reported green.
- Julia-side action:
  - Recorded the shared fixture in the engine contract, capability status,
    validation debt, and coordination board.
  - No code changed.
- Boundary:
  - Tiny Ainv fixture only.
  - Not Mrode validation, external comparator validation, production sparse
    fitting, large-pedigree readiness, or genomic/single-step validation.

## 2026-06-13 Phase 1M Sparse Henderson MME Supplied-Variance Solve

- Goal: add a sparse Henderson mixed-model-equation solve at supplied variance
  components and record the R twin's sparse `Z` marshalling handoff.
- Active lenses: Ada, Henderson, Gauss, Karpinski, Fisher, Mrode, Grace, Rose.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `2a9ba37` uses sparse `Z` bridge marshalling.
  - `hsquared` head `398e019` records green CI evidence.
  - R now calls `HSquared.sparse_csc_matrix(...; index_base = :zero)` for
    `Matrix::dgCMatrix` `Z` slots.
  - `hs_fit_julia_payload()` no longer takes or uses `max_dense_cells`.
  - R-CMD-check `27457295759`, pkgdown `27457295761`, and Pages `27457326836`
    were reported green.
- Implementation evidence:
  - Added `HendersonMMEResult`.
  - Added `henderson_mme(spec, sigma_a2, sigma_e2)`.
  - The solver forms Henderson's equations from sparse `X`, `Z`, and `Ainv`
    and solves for fixed effects plus animal effects at supplied variance
    components.
  - Added `fixed_effects()`, `breeding_values()`, and `fitted_values()` methods
    for `HendersonMMEResult`.
  - Kept `result_payload()` fields unchanged.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 180 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - Generated docs artifacts were removed after the build.
  - `git diff --check` passed.
  - Claim scan found only blocked/planned/historical-audit wording, not public
    claims that sparse production fitting works, Mrode validation is complete,
    AI-REML is implemented, or PEV/reliability are returned through the bridge
    payload.
- Boundary:
  - Supplied variance components only.
  - Not variance-component estimation, AI-REML, production sparse fitting,
    Mrode validation, external comparator validation, or a bridge payload
    change.

## 2026-06-13 Phase 1L Dense Validation Size Guard And R PEV Sync

- Goal: add a Julia-side dense validation size guard aligned with the R
  `engine_control$max_dense_cells` vocabulary, and record the R twin's
  PEV/reliability extractor-contract handoff without changing Julia bridge
  payload fields.
- Active lenses: Ada, Shannon, Hopper, Karpinski, Gauss, Grace, Rose.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `78ba5ff` added exported
    `prediction_error_variance()` and `reliability()` generics and fitted-object
    methods.
  - R has future-compatible normalization if Julia later returns
    `prediction_error_variance` or `reliability`.
  - Current R live-bridge tests expect those fields to be absent from Julia
    `result_payload()`.
- Implementation evidence:
  - Added `max_dense_cells` to `gaussian_loglik()`.
  - Threaded `max_dense_cells` through `fit_variance_components()`,
    `fit_animal_model(spec)`, and direct
    `fit_animal_model(y, X, Z, Ainv; ...)` dispatch.
  - Guard fails before the current dense validation path converts covariance or
    relationship matrices.
  - Kept `result_payload()` fields unchanged.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 169 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - Generated docs artifacts were removed after the build.
  - `git diff --check` passed.
  - Claim scan found only blocked/planned wording in old after-task reports and
    the claims register, not public claims that PEV/reliability are returned
    through the bridge, sparse production fitting works, Mrode validation is
    complete, or GPU/QTL support exists.
- Boundary:
  - `max_dense_cells` is a guard for the temporary dense path, not a sparse
    production solver.
  - R PEV/reliability bridge fields remain a planned lockstep task.
  - Sparse production fitting, Mrode validation, and production reliability/PEV
    remain planned.
- Rose verdict: clean with limitations.

## 2026-06-13 Phase 1K Sparse CSC Bridge Marshalling

- Goal: add a Julia sparse CSC marshalling helper for R `Matrix::dgCMatrix`
  slots and record the R twin's opt-in Julia engine path.
- Active lenses: Ada, Shannon, Hopper, Karpinski, Grace, Rose.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `9eabf0d` added
    `hsquared(..., control = hs_control(engine = "julia"))`.
  - Default remains `hs_control(engine = "validate")`.
  - R-specific Julia controls stay in `engine_control`: `julia_project`,
    `initial`, and `max_dense_cells`.
  - R-CMD-check `27456875004`, pkgdown `27456874995`, and Pages `27456904688`
    were reported green.
- Implementation evidence:
  - Added `sparse_csc_matrix()`.
  - Supports zero-based R slots and one-based Julia slots.
  - Validates dimensions, column pointers, row indices, value lengths, and row
    ordering within CSC columns.
  - Added direct payload integration test showing a `Z` reconstructed from
    zero-based slots feeds the same `fit_animal_model()` path as the original
    sparse matrix.
- Commands run:
  - `julia --project=. -e 'using Pkg; Pkg.test()'` passed with 163 checks.
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - Generated docs artifacts were removed after the build.
  - `git diff --check` passed.
  - Claim scan found only blocked-wording/audit rows, not public claims that R
    already uses sparse `Z` marshalling, production sparse fitting works, Mrode
    validation is complete, or bridge performance has been demonstrated.
- Boundary:
  - Julia helper exists.
  - Superseded by Phase 1M: R head `398e019` now consumes sparse `Z` slots
    through this helper; relationship-object marshalling beyond `Z` remains
    planned.
  - Production fitting, Mrode validation, and stable production controls remain
    planned.

## 2026-06-13 R Internal Julia Bridge Smoke Sync

- Goal: record the R twin's internal JuliaCall smoke evidence without changing
  Julia result payload fields or claiming public fitting support.
- Active lenses: Ada, Shannon, Hopper, Lovelace, Emmy, Grace, Rose.
- Spawned subagents: none.
- R twin handoff:
  - `hsquared` head `c837f2d` added internal `hs_fit_julia_payload()`.
  - The smoke activates the sibling local `HSquared.jl` checkout and calls
    `normalize_pedigree()` -> `pedigree_inverse()` ->
    `fit_animal_model(y, X, Z, Ainv; ids = ..., method = ...)` ->
    `result_payload()`.
  - R normalizes the returned result into the current internal `hsquared_fit`
    contract.
  - Public `hsquared()` still stops before fitting.
- R remote evidence reported:
  - R-CMD-check `27456664820`: success.
  - pkgdown `27456664821`: success.
  - Pages `27456696277`: success.
- Julia-side action:
  - Updated engine, formula, v0.1, roadmap, capability, validation, public
    claims, and coordination docs.
  - Kept `result_payload()` field names stable.
  - Did not add dense PEV/reliability to `result_payload()` because the R result
    contract has not grown those fields.
- Commands run:
  - `julia --project=docs docs/make.jl` passed. Local deployment was skipped as
    expected outside CI; generated Vitepress dependencies reported npm
    advisories in temporary build artifacts.
  - Generated docs artifacts were removed after the build.
  - `git diff --check` passed.
  - Claim scan found only planned/blocked wording, not public claims that
    `hsquared()` fits through Julia, full sparse bridge marshalling is complete,
    stable user-facing engine controls exist, or Mrode validation is complete.
- Boundary:
  - Internal bridge smoke exists externally in the R twin.
  - Public R fitting remains planned.
  - Sparse `Z` marshalling, stable engine controls, and Mrode validation remain
    next shared gates.
- Rose verdict: clean with limitations.

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
