# Validation Canon

Validation is a first-class engine requirement. Public capability claims need
evidence in tests, docs, and the check log.

## Validation Hierarchy

1. Tiny deterministic hand checks.
2. Pedigree and sparse `Ainv` known examples.
3. Simple Mrode-style examples.
4. Comparator model outputs where available: ASReml, BLUPF90, DMU, WOMBAT,
   sommer, or MCMCglmm.
5. XSim simulation truth for later genomic and selection examples.

## V0.1 Validation Targets

`validation_status()` exposes the current validation ladder as a typed Julia
diagnostic. It does not run comparator packages, fit models, or promote planned
capabilities.

- ID recoding preserves animal labels.
- Pedigree sorting handles founders and unknown parents.
- Sparse `Ainv` matches tiny hand-computed examples.
- Gaussian animal-model likelihood recovers known tiny solutions.
- EBVs/BLUPs and heritability match the R-facing contract.
- Dense validation-path outputs agree with Henderson mixed-model equations at
  supplied variance components.
- Sparse supplied-variance Henderson MME solves agree with deterministic MME
  fixtures before being used inside production fitting.
- The shared R/Julia supplied-variance Henderson MME fixture pins a five-animal
  pedigree, `Ainv`, fixed effects, EBVs, fitted values, and `h2 = 0.6` at
  `sigma_a2 = 1.2` and `sigma_e2 = 0.8`. R head `ca8bce1` records an
  independent R MME reference and a live Julia comparison when the sibling
  checkout is available.
- A Julia-native Mrode9-shaped supplied-variance fixture uses the 12-animal
  `nadiv::Mrode9` pedigree structure and pins `Ainv`, ML/REML likelihood
  values, fixed effects, EBVs, fitted values, PEV, reliability, derived
  accuracy, and `h2` at supplied variance components. This is equation and
  extractor validation only.
- A Julia-native Mrode (2014) Example 3.1 published animal-model anchor pins
  the stated response/pedigree/design, `sigma_a2 = 20`, `sigma_e2 = 40`, the
  published EBVs for animals 1-8, and the invariant male-minus-female
  fixed-effect contrast. This is a supplied-variance textbook anchor, not
  variance-component estimation.
- A Julia-native genomic GBLUP/SNP-BLUP #49 target fixture serializes a small
  marker panel, supplied allele frequencies, positive-definite VanRaden `G`,
  `Ginv`, beta, GEBVs, marker effects, and metadata. The bundled test
  recomputes the target and pins route agreement, but this is not external
  comparator evidence.
- Pedigree inverse construction has optional external comparator coverage
  through the R twin's `nadiv::Mrode9` / `nadiv::makeAinv()` live test.

Still missing from the Mrode lane:

- an estimated-variance-component Mrode animal-model target beyond the R-lane
  gryphon/published-anchor bridge evidence;
- same-estimand REML comparator versions and tolerances for fitted outputs;
- broader fitted-output evidence for heritability, reliability, PEV, and
  accuracy at estimated variance components.

The supplied-variance Henderson and Mrode9-shaped fixtures are not fitted Mrode
models and do not estimate variance components. The Mrode Example 3.1 published
anchor is also supplied-variance evidence.

## Locked Derived-Estimand Identities (R-lane gate, mirrored here)

The R twin's `hsquared/docs/design/04-validation-canon.md` locks the
derived-estimand identities that the 2026-07-09 Standard-Tier Covered-Flip Gate
requires before a *derived* estimand may be called `covered`: a within-package
identity test asserting it equals its defining function of the covered
components, plus a locked, pinned citation for that identity. This section
mirrors that lock so the two lanes cannot drift on what the symbols mean. It
moves **no status**.

The multivariate (0.6) identities, in engine notation, with `σ²_a,k = G0[k,k]`
and `σ²_e,k = R0[k,k]`:

- **Genetic correlation.** `r_g[i,j] = σ_g,ij / sqrt(σ²_g,i · σ²_g,j)`, i.e.
  `r_g = D⁻¹ G0 D⁻¹` with `D = diag(sqrt.(diag(G0)))`. Julia
  `genetic_correlation(G0)` (`src/multivariate.jl`) is exactly that map and is
  the engine spelling of R's `cov2cor(G0)`. Locked citation: Falconer & Mackay
  (1996), *Introduction to Quantitative Genetics*, 4th ed., ch. 19; Lynch &
  Walsh (1998), *Genetics and Analysis of Quantitative Traits*, ch. 21.
- **Per-trait heritability.** `h²_k = σ²_a,k / (σ²_a,k + σ²_e,k)`, i.e.
  `diag(G0) ./ (diag(G0) .+ diag(R0))`. This is the per-trait variance ratio
  implied by *this model's* two-component partition — not a total-additive or
  Willham-style `h²_T`, and not a ratio over any further random effect the model
  does not contain. Locked citation: Falconer & Mackay (1996), ch. 8, 10; Lynch
  & Walsh (1998), ch. 4, 7.

Where the identity tests live, and what they do and do not establish:

- The gating identity tests are **R-lane** (`tests/testthat/test-multivariate.R`,
  MV-3), asserting the R extractors equal these functions of the covered
  components, verified on the engine's serialized `phase4_multitrait_parity`
  values.
- On the Julia side both quantities are computed **by construction** from the
  same fitted `G0hat`/`R0hat` inside `fit_multivariate_reml`, so they cannot
  numerically disagree with the definitions above — but construction is not a
  test, and a refactor that recomputed `h²` from somewhere else would not have
  turned the suite red. The engine therefore pins the definitions directly on
  the **estimated** path: `test/runtests.jl` § *Phase 4 derived-estimand
  identities on the REML fit path* asserts
  `heritability(fit) ≈ diag(G0) ./ (diag(G0) .+ diag(R0))` (extractor and
  stored field, trait by trait) together with
  `fit.genetic_correlation ≈ D⁻¹ G0 D⁻¹` and
  `fit.residual_correlation ≈ D⁻¹ R0 D⁻¹`, at `rtol = 1e-12`, across the
  `:unstructured`, `:diagonal`, `:lowrank`, `t = 1` and missing-record fits.
  The reference maps are written out in the notation above rather than obtained
  from `genetic_correlation`, which would be circular. The weaker pins remain
  alongside: ranges (`0 ≤ h²_k ≤ 1`, `-1 ≤ r_g[i,j] ≤ 1`), copy-returning
  extractors, and the supplied-covariance `multivariate_mme`
  `result.genetic_correlation ≈ genetic_correlation(G0)` identity.
- What those Julia assertions establish is **self-consistency of the engine's
  own estimates with the locked definitions** — that `heritability` and
  `genetic_correlation` denote the stated functions of `G0`/`R0`. They are
  **not** external-comparator evidence and do not bear on whether `G0`/`R0`
  themselves are right.
- Component `G0`/`R0` stay external-same-estimand-comparator gated (the
  `sommer` 4.4.5 and executed `blupf90+` 2.60 legs recorded on the
  `V4-MV-REML` row); the two derived quantities above are identity-test +
  locked-citation gated.

Unchanged by this mirror and by those assertions: Julia `V4-MV-REML` stays
`covered` (experimental, validation-scale, opt-in). R multivariate is now
**covered** at validation scale (G10; R `public_covered_count` **6**). This
section still moves **no** status by itself.

### Genomic GREML identities (0.7 candidate; mirrored from R)

Lock for the R-public opt-in genomic GREML derived estimand. Engine Genomic
REML (supplied-`Ginv`) is already **covered**; this lock does **not** change
that row and does **not** flip R genomic. Count stays **6** until Rose CLEAN +
lockstep flip. Recovery disposition: design-53 SUPERSEDE.

Locked construction citation:

- VanRaden, P. M. (2008). Efficient methods to compute genomic predictions.
  *Journal of Dairy Science* **91**(11): 4414–4423.
  doi:10.3168/jds.2007-0980 (method 1; sample allele frequencies).

- **Genomic variance ratio**
  \(r_G = \sigma_g^2 / (\sigma_g^2 + \sigma_e^2)\) on
  \(K_\lambda = G + 0.01\,I\), surfaced as `genomic_variance_ratio` — not
  pedigree narrow-sense \(h^2\). Identity scaffolding:
  `test/test_genomic_greml_s0_identity.jl` (marker vs supplied-Q; GBLUP/SNP-BLUP
  naming on the unregularized scale). Locked citation: VanRaden (2008) for \(G\);
  Falconer & Mackay (1996) ch. 8/10 for the two-component variance-ratio form on
  the declared genomic scale (explicit no-anchor: no clean Mrode genomic-\(h^2\)
  pin).

## Status Words

- `planned`
- `partial`
- `covered`
- `covered_external`
- `blocked`
- `deprecated`

Only `covered` capabilities may be described as working in public docs.
`covered_external` may be described only with its external-evidence boundary,
such as pedigree inverse agreement in the R twin, not as bundled Julia
coverage or fitted-model support.
