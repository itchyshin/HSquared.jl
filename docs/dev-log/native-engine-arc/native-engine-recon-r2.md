# Native-engine math contract recon — R2 (HSquared.jl src/)

Read-only. All citations `file:line` against current working tree
(branch `codex/2026-07-13-v07-performance-localization`).

## Animal-model-REML-estimand

**Pedigree inverse (Henderson direct method), `src/pedigree.jl`:**
- `_meuwissen_luo_inbreeding` (pedigree.jl:232-269): O(n·ancestors) sparse
  recursive inbreeding via a max-heap over ancestor contributions
  (Meuwissen & Luo 1992), avoiding the dense numerator relationship matrix.
  `F[i] = fi - 1.0` per animal; unknown-parent sentinel `f0(0) = -1.0`.
- `_mendelian_sampling_variance` (pedigree.jl:777-787): the four
  Henderson diagonal cases — `1.0` (both parents unknown), `0.75 - 0.25 F[dam]`
  / `0.75 - 0.25 F[sire]` (one known), `0.5 - 0.25(F[sire]+F[dam])` (both known).
- `pedigree_inverse` (pedigree.jl:298-328): for each animal, builds the
  `[1, -1/2, -1/2]` outer-product contribution over `{animal, sire, dam}`
  scaled by `1/variance`, accumulated as sparse triplets → `SparseMatrixCSC`.
  This is the standard Henderson/Quaas rule; matches the drmTMB back-port
  target noted in the brief (itchyshin/drmTMB#7).

**Model spec, `src/model_spec.jl`:**
- `AnimalModelSpec` (model_spec.jl:18-26): stores `y, X, Z, Ainv, ids, family
  (GaussianFamily only in Phase 1), method (:ML | :REML)`. Pure validation
  container (dimension/id checks, model_spec.jl:38-69) — not a fitting routine.

**MME assembly, `src/likelihood.jl`:**
- `_sparse_mme_system` (likelihood.jl:3299-3320): builds Henderson's mixed-model
  equations
  ```
  lhs = [ (1/σe²)X'X        (1/σe²)X'Z
          (1/σe²)Z'X   (1/σe²)Z'Z + (1/σa²)Ainv ]
  rhs = [ (1/σe²)X'y ; (1/σe²)Z'y ]
  ```
  plus `y'R⁻¹y = (1/σe²) y'y` returned as the third element (used in the
  REML quadratic form). `R = σe² I` (i.i.d. residual), `G⁻¹ = Ainv/σa²`
  (single random effect, Phase 1 univariate animal model only).
- `sparse_reml_loglik` (likelihood.jl:172-206) — the exact REML objective a
  TMB engine must reproduce:
  ```
  loglik = -1/2 [ (n-p) log(2π) + logdetR + logdetG + logdetC + quad ]
  logdetR = n log(σe²)
  logdetG = q log(σa²) - logdet(Ainv)      (Ainv factored via its own Cholesky, line 189)
  logdetC = logdet(C)                       (C = MME coefficient matrix, Cholesky of lhs)
  quad    = y'R⁻¹y - rhs'·C⁻¹·rhs           (line 194, via the MME solve, not a direct residual)
  ```
  `n` = nobs, `p` = ncol(X), `q` = nrow(Ainv) (number of animals). This is
  the classical Henderson/Harville sparse-equivalent REML log-likelihood
  identity — algebraically identical to the dense form in `gaussian_loglik`
  (likelihood.jl:104-161, which forms `V = Z A Z' σa² + σe² I` densely and is
  explicitly labelled a "Phase 1 validation bridge... does not optimize
  variance components", likelihood.jl:99-102) but evaluated through the
  sparse MME instead of a dense marginal covariance — this identity is what a
  TMB Laplace/joint-likelihood engine must match numerically, not the dense form.
- `beta` (fixed effects) = `solution[1:p]` from the same MME solve
  (likelihood.jl:199, and again as `HendersonMMEResult.beta` at
  likelihood.jl:1024/1032).
- **EBV/BLUP**: `henderson_mme` (likelihood.jl:1014-1037) solves the identical
  `_sparse_mme_system` at *supplied* variance components and splits the
  solution vector into `beta` (fixed, rows `1:nfixed`) and `animal_effects`
  (random/EBV block, rows `nfixed+1:end`) — `breeding_values`/`EBV`/`BLUP`
  (likelihood.jl:2648-2671) are aliases over this split. So EBVs are simply
  the random-effect block of the same MME solve used for the loglik, at the
  REML-optimal `(σa², σe²)`.
- **Prediction error variances**: diagonal of the random-effect block of
  `C⁻¹` (`_dense_mme_random_inverse_block`, likelihood.jl:3339-3358, dense
  validation reference) or the Takahashi selected inverse
  (`_selinv_mme_random_pev`, likelihood.jl:3380-3386) — same coefficient
  matrix `C`, so both agree to machine precision by construction.
- **Heritability**: `sigma_a2/(sigma_a2+sigma_e2)` (likelihood.jl:2706-2709) —
  simple narrow-sense h², no accounting for multiple random effects or
  fixed-effect absorption beyond the univariate animal model.

## Genomic-GBLUP-estimand

**G-matrix, `src/genomic.jl`:**
- `centered_markers` (genomic.jl:15-41): `W = M - 2p`, `p` = per-marker allele
  frequency (columns/`(2n)` if not supplied), `k = 2 Σ p_j(1-p_j)` (VanRaden
  scale). Guards `k>0` (rejects all-monomorphic marker sets).
- `genomic_relationship_matrix` (genomic.jl:78-117):
  - `:vanraden1` (default): `G = W W' / k`.
  - `:vanraden2`: per-marker standardized `Zs[:,j] = W[:,j]/√(2p_j(1-p_j))`,
    `G = Zs Zs' / m`; requires every marker polymorphic.
  - optional per-marker `weights` (vanraden1 only): `G = W diag(w) W' / Σ w_j
    2p_j(1-p_j)`.
  - `backend = :cuda` routes to `HSquaredCUDAExt` GPU twin (same estimand,
    reuses `centered_markers`); default `:cpu` unaffected (genomic.jl:85-93).
- `genomic_relationship_inverse` (genomic.jl:136 onward, ridge default 0.01):
  `Ginv = inv(G + ridge·I)`. Docstring explicitly notes **G is typically
  rank-deficient** (fewer markers than individuals — column-centering also
  puts the all-ones vector in `G`'s null space, so `rank(G) ≤ n-1`,
  genomic.jl:465-467) and MUST be ridge-regularized before inversion.
- `fit_gblup` (genomic.jl:481-493): supplied-variance GBLUP — literally
  `animal_model_spec(y,X,Z,Ginv) → henderson_mme(spec, σa², σe²)`; the genomic
  precision `Ginv` slots into the same `Ainv` argument the pedigree animal
  model uses. **No genomic-specific numerics** — same `_sparse_mme_system`
  code path as the pedigree animal model (confirmed: `henderson_mme` at
  likelihood.jl:1020 calls `_sparse_mme_system`, which wraps `Ainv` — here
  `Ginv` — via `sparse(Float64.(spec.Ainv))` regardless of density,
  likelihood.jl:3303).
- `fit_gblup_reml` (genomic.jl:510-521): `animal_model_spec(...; method =
  :REML) → fit_animal_model(spec; target = :ai_reml (default) | :sparse_reml)`.
  REML-estimates `(σa²,σe²)` over the genomic spec via the *same* AI-REML or
  NelderMead-sparse-REML machinery as the pedigree case (genomic.jl:496-521;
  docstring: "dense/validation-scale... the dense `Ginv` path gains no sparse
  selected-inversion advantage", genomic.jl:507-508). **This is the likely
  crash mechanism the collaborator hit**: `Ginv` from `inv(G+ridge·I)` is a
  DENSE matrix (no true zero structure to exploit), yet it is pushed through
  `sparse(Float64.(...))` and Cholesky-factored as if sparse — the sparse
  Cholesky factor `L` will have near-total fill-in on a dense `Ginv`, so
  memory/time scale like the dense case (or worse, with sparse-format
  overhead) rather than gaining any sparsity benefit. This is inferred from
  the code path, not measured in this recon — flagging as UNCERTAIN pending
  a direct large-G timing/memory run.
- `fit_snp_blup` / `fit_snp_blup_reml` (genomic.jl:545-590): SNP-BLUP/RR-BLUP
  equivalent, markers as `Z` with identity prior scaled by `sigma_g2/k`;
  documented GBLUP↔SNP-BLUP equivalence (`gebv = W·â`).

## Fit-optimizer-and-AI-REML-gap

**CONFIRMED, with an important correction to the brief's premise:**

1. `fit_sparse_reml` (likelihood.jl:283-333) — confirmed derivative-free:
   `Optim.NelderMead()` (likelihood.jl:309-314) minimizing
   `-sparse_reml_loglik(spec, exp(θ₁), exp(θ₂))`. Every NelderMead function
   evaluation re-forms `_sparse_mme_system` and re-factorizes the sparse MME
   from scratch inside `sparse_reml_loglik` (likelihood.jl:183-184) — this is
   the re-factorize-every-eval pattern the brief flagged as the >7 min/50k
   bottleneck.

2. **`fit_ai_reml` DOES exist** (likelihood.jl:367-556, delegates to
   `_fit_ai_reml_diagnostics`, likelihood.jl:389-556) — this is NOT a gap that
   is still open in the Julia engine; the brief's framing ("does an AI-REML
   path exist?") is answered YES. It is a genuine average-information
   Newton method, not derivative-free:
   - Each iteration factorizes `_sparse_mme_system` ONCE (likelihood.jl:453-455)
     — one Cholesky per iteration, not per NelderMead eval — and reuses that
     factor for the score, the Takahashi trace term
     (`selinv_trace_against`, likelihood.jl:460), and two working-variate
     re-solves (`_reml_project`, likelihood.jl:476-480) that build the AI
     information matrix (likelihood.jl:480).
   - REML score: `score_a = -1/(2σa⁴)·(q·σa² - tr(Ainv C^uu) - u'Ainv u)`,
     `score_e` analogous (likelihood.jl:463-466) — the closed-form REML score
     at the current `(σa²,σe²)`.
   - AI/Newton step via `_ai_newton_step(information, [score_a,score_e])`
     (likelihood.jl:481) with step-halving (up to 60 halvings,
     likelihood.jl:498-503) to keep variances positive; termination on score
     tolerance or relative-change tolerance (likelihood.jl:470-474, 519-526).
   - Optional EM-REML warm-start (`em_warmup`, default 0 → byte-identical to
     pre-warm-start path): closed-form monotone EM update
     `σa² = (u'Ainv u + tr(Ainv C^uu))/q`, `σe² = e'e/(n-p-q+tr(Ainv C^uu)/σa²)`
     (likelihood.jl:418-447) to give the AI step a good in-bounds start.
   - Docstring is explicit about scope limits: "exact for the *Gaussian*
     linear mixed model... does NOT transfer to Laplace-approximated /
     non-Gaussian models, where observed-information Newton is required
     instead" (likelihood.jl:350-354) — directly relevant to a TMB port,
     since TMB's default is Laplace + L-BFGS on the joint negative log-lik,
     not this closed-form Gaussian AI-REML.
   - Marked "REML-only and experimental... validated to recover the same
     optimum as the dense and sparse NelderMead optimizers, but is not yet
     checked against external comparators or hardened for boundary/large-
     pedigree cases" (likelihood.jl:348-350).

   `fit_gblup_reml`/`fit_snp_blup_reml` default `target = :ai_reml`
   (genomic.jl:516, :584), so the genomic path already prefers AI-REML over
   NelderMead by default in the Julia engine — but still runs it on a DENSE
   `Ginv` treated as sparse (see genomic estimand section above), which is a
   different bottleneck from the derivative-free-optimizer one.

3. **What is genuinely still missing** relative to ASReml-style AI-REML at
   scale, based on this reading (not measured — flagged as inference):
   `fit_ai_reml`'s per-iteration cost is one sparse Cholesky factorization of
   the MME plus a Takahashi selected inverse (for the trace term) plus two
   triangular re-solves — algorithmically the right shape for AI-REML, but
   this recon did NOT re-run today's timing numbers on `fit_ai_reml`
   specifically (the brief's `>7 min by 50k` timing was attributed to
   `fit_sparse_reml`'s NelderMead re-factorization; whether `fit_ai_reml`
   already closes that gap at 50k–100k scale is not established here).

## What-a-TMB-engine-must-match

A native R/TMB port of the animal-model REML engine must reproduce, exactly:

1. **Ainv construction** — Henderson direct-inverse rule with the four
   Mendelian-sampling-variance cases (`pedigree.jl:298-328, 777-787`), built
   from Meuwissen–Luo inbreeding (`pedigree.jl:232-269`). TMB's own PARAMETER
   declarations would need `u ~ N(0, σa² A)` via the *precision* `Ainv/σa²`,
   i.e. `-log p(u|θ) = 1/2 [ q log(2π) + q log(σa²) - logdet(Ainv) + u'Ainv u /σa² ]`
   — matching `logdetG` in `sparse_reml_loglik` (likelihood.jl:192).
2. **Joint objective** — the same REML identity as
   `sparse_reml_loglik` (likelihood.jl:172-206): `-1/2[(n-p)log2π + logdetR +
   logdetG + logdetC + quad]`, `C` = MME coefficient matrix, `quad = y'R⁻¹y -
   rhs'C⁻¹rhs`. In TMB terms this is exactly the Laplace-approximated
   marginal likelihood after integrating out `u` (and, for REML, also
   `β`) from the joint `nll = -log p(u|θ) - log p(y|u,θ)` — the same pattern
   drmTMB's `src/drmTMB.cpp` already uses per the brief, just with `u` =
   animal effects and `Ainv` in place of drmTMB's own latent precision.
3. **BLUP/EBV extraction** — the random-effect block of the same MME solve
   at the optimal `(σa²,σe²)` (`henderson_mme`, likelihood.jl:1014-1037); in
   TMB this is `ADREPORT`/`SdReport` on `u`, which TMB derives automatically
   from the Laplace-approximated posterior mode — the numerical target is
   the same MME solution vector.
4. **Genomic path** — same MME machinery with `Ginv = inv(G+ridge·I)` in the
   `Ainv` slot (`fit_gblup`/`fit_gblup_reml`, genomic.jl:481-521); a TMB port
   should NOT naively feed a dense `Ginv` through a sparse-precision assumption
   the way the Julia engine currently does (see crash-mechanism flag above) —
   if drmTMB's dense `chol2inv` pedigree path (per the brief) is the template,
   the genomic case may actually be a *better* match for a dense TMB path than
   for gllvmTMB's sparse Quaas builder, since VanRaden `G`/`Ginv` has no
   genuine pedigree-style sparsity to exploit.
5. **Optimizer target** — match `fit_ai_reml`'s closed-form Gaussian AI-REML
   numerically (score + AI information formulas above) if the port wants a fast
   native path, OR accept that TMB's default Laplace + `nlminb`/L-BFGS will
   find the same optimum via a different (slower per-iteration but standard)
   route — the docstring's own caveat (likelihood.jl:350-354) says these are
   NOT interchangeable outside the exact Gaussian linear model, so any
   non-Gaussian extension of this contract cannot reuse the AI-REML formulas
   as-is.

## Uncertainty flags

- The genomic dense-Ginv-through-sparse-Cholesky crash mechanism is inferred
  from code structure, not measured/profiled in this recon.
- `fit_ai_reml` timing at 50k–100k scale (whether it already closes the
  bottleneck the brief attributes to `fit_sparse_reml`) is not established
  here — would need a fresh timing run, not a code read.
- Only Phase 1 univariate single-random-effect (animal) and Phase 2 GBLUP/SNP-
  BLUP paths were read; multi-trait, direct-maternal, and metafounder variants
  exist elsewhere in `likelihood.jl` (lines ~1039-2500) but were not read in
  full for this recon (out of the requested scope).
