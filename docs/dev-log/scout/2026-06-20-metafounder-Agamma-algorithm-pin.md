# Scout pin — Metafounder relationship matrix A^Γ algorithm (#53)

Date: 2026-06-20. Scout: Jason. Status: LEARN (algorithm pin only; no
implementation, no claim). Routing lenses for any future build:
Henderson + Mrode + Gauss (numerics) · Kirkpatrick (Γ as covariance) ·
Mendel + Falconer (interpretation) · Rose (claim gate).

## Sources checked (primary first)

- **Legarra, Christensen, Vitezica, Aguilar & Misztal (2015)** "Ancestral
  Relationships Using Metafounders: Finite Ancestral Populations and Across
  Population Relationships." *Genetics* 200(2):455–468.
  OUP: https://academic.oup.com/genetics/article/200/2/455/5936198 ·
  PMC (open): https://pmc.ncbi.nlm.nih.gov/articles/PMC4492372/ — **PRIMARY**:
  tabular recurrence, self/offspring rules, TDT′ inverse, γ=0 reduction.
- **García-Baccino et al. (2017)** "Metafounders are related to Fst fixation
  indices and reduce bias in single-step genomic evaluations." *GSE* 49:34.
  PMC: https://pmc.ncbi.nlm.nih.gov/articles/PMC5439149/ — Γ↔Fst, method-of-
  moments / GLS estimation of Γ from base allele frequencies. (Estimation of Γ,
  not matrix construction — out of scope for the construction spec but it is the
  source of the *values* one would feed in.)
- **Macedo, Legarra et al. (2022, invited review)** "Unknown-parent groups and
  metafounders in single-step genomic BLUP." *J Dairy Sci*.
  https://www.sciencedirect.com/science/article/pii/S0022030221010110 (403 to
  WebFetch; abstract via search) — UPG↔MF equivalence framing.
- **AGHmatrix** (rramadeu/CRAN), `Amatrix()` man page
  https://rdrr.io/cran/AGHmatrix/man/Amatrix.html and source. **Does NOT
  implement metafounders/Γ.** Args = `data, ploidy, w, verify, dominance,
  slater, ASV`. Standard Mrode(2014)/Henderson(1976) recurrence, ploidy
  extension = Kerr et al. (2012). No `gamma`/`metafounder` argument.
- **nadiv** (Wolak) — supports genetic groups (`ggcontrib`) but **no
  metafounder Γ matrix**. PITFALL: nadiv's "gamma" in its description means the
  ASReml variance-ratio γ, unrelated to metafounder Γ. Do not conflate.
- **BLUPF90 suite** — this is where Γ + (A^Γ)⁻¹ actually live in production:
  `GAMMAF90` / base-AF tools estimate Γ; `preGSf90` / renumf90 build (A^Γ)⁻¹.
  https://nce.ads.uga.edu/publications/all-publications-since-2008/

## What hsquared should LEARN / AVOID / DEFER / VALIDATE-AGAINST

- **LEARN**: the A^Γ construction is a *small, local* generalization of the three
  functions we already own in `src/pedigree.jl` (`_numerator_relationship`,
  `_mendelian_sampling_variance`, `pedigree_inverse`). The whole change is
  (a) seed metafounder rows/cols with Γ, (b) use F_mf = γ−1 in the existing
  d_i formula, (c) add Γ⁻¹ to the metafounder block of the inverse.
- **AVOID**: do NOT take Γ estimation on. That is a genomic/base-AF problem
  (García-Baccino MoM, BLUPF90 GAMMAF90). Treat Γ as a *supplied* m×m PD matrix
  (mirrors the supplied-covariance pattern already used in `random_regression_mme`
  `Ainv ⊗ inv(K_g)` and the diagonal bridge). Same boundary AGHmatrix draws.
- **DEFER**: ssGBLUP H^Γ assembly, UPG↔MF conversion, crossbred multi-Γ tuning.
- **VALIDATE AGAINST**: (1) reduction to the existing `pedigree_inverse` /
  `additive_relationship` at Γ=0; (2) an independent dense oracle (build A^Γ by
  the tabular recurrence, invert densely, compare to the direct sparse rule).
  Do NOT hardcode published numeric matrices — reduction + dense oracle only.

## Algorithm pin (verbatim-anchored)

Let there be m metafounders (pseudo-founders) and n real animals. Index
metafounders 1..m, animals m+1..m+n, in an order where every animal follows its
parents (topological). Unknown parents of real animals are *re-mapped to a
metafounder id* (the assignment is user/model input — in the single-population
case all unknown parents → the one metafounder).

### (1) Tabular recurrence for A^Γ  [Legarra 2015]

Metafounder block (seed):
  A^Γ[i,j] = Γ[i,j]   for i,j ≤ m   (so metafounder self = Γ[i,i] = γ_i).

Animal k (parents s,d, each either an animal index or a metafounder index;
"0/unknown" must already have been remapped to a metafounder, so there is no
literal 0 left for a real animal):
  off-diagonal  A^Γ[k,j] = ½(A^Γ[s,j] + A^Γ[d,j])           for j < k
  diagonal      A^Γ[k,k] = 1 + ½·A^Γ[s,d]
Both rules are the standard rules unchanged — the metafounders just supply
non-zero "founder" relationships into them. Verbatim anchors (single MF γ):
  "a metafounder … self-relationship a₁₁ = γ and inbreeding F_i = a₁₁ − 1 = γ − 1"
  "a₂₂ = 1 + 0.5·a₁₁ = 1 + γ/2"   (offspring of one metafounder)
  "a₁₂ = 0.5(a₁₁ + a₁₁) = γ"      (animal–metafounder)

### (2) Inverse via A^Γ = T·D·Tᵀ  →  (A^Γ)⁻¹ = (Tᵀ)⁻¹ D⁻¹ T⁻¹  [Legarra 2015]

Two-part build:
  - Metafounder block: invert the m×m Γ and place Γ⁻¹ in the metafounder
    sub-block of (A^Γ)⁻¹.  ("first, inverting Γ … then using Henderson's rules.")
  - Animal contributions: standard Henderson outer product, identical to the
    code we already have, with the metafounder F substituted:
      For animal k with parents s,d:
        d_k = 1 + ¼·(F_s + F_d) − ¼·(A^Γ[s,s] + A^Γ[d,d])
            = 0.5 − 0.25(F_s + F_d)     (the existing both-parents formula),
      where F_x = A^Γ[x,x] − 1, and for a *metafounder* parent x, F_x = γ_x − 1
      (can be NEGATIVE). One/both parents being metafounders changes nothing
      structurally — it only feeds γ−1 into F_s/F_d.
      Contribution: (1/d_k) · v vᵀ with v = e_k − ½e_s − ½e_d, accumulated over
      k,s,d (s and/or d may now be metafounder indices). This is *exactly* the
      existing `pedigree_inverse` outer product with the index set widened to
      include metafounders and Γ⁻¹ seeded first.
  - Inbreeding precompute: F-values come from the diagonal of the tabular A^Γ
    (extend `inbreeding_coefficients` to start metafounder F = γ−1).
  - Multi-MF efficiency note (optional, not required for correctness): with
    K = chol(Γ) (Γ = KKᵀ), the metafounder contribution to A_ii can be added as
    Σ (L_{i,1:m} K)² — an optimization, not a different matrix.

### (3) Reduction property  [Legarra 2015, verbatim]

  Γ = 0  ⟹  F_metafounder = γ − 1 = −1  ⟹  A^Γ ≡ standard numerator A.
  "considering γ = 0 (and therefore F = −1) … the size of the pool is infinite"
  → metafounders become mutually unrelated, non-inbred classical founders.
  This is THE correctness anchor: A^Γ(Γ=0) restricted to animal rows must equal
  `additive_relationship`, and (A^Γ)⁻¹(Γ=0) animal block must equal
  `pedigree_inverse` (after dropping the now-decoupled metafounder rows, OR
  keeping them with the Γ⁻¹ block → which at Γ=0 is singular, so the practical
  reduction test uses Γ = εI → 0 or drops MF rows).

## Sign / scaling pitfalls

- F_metafounder is NEGATIVE for γ<1 (γ=0 ⇒ F=−1). Any code that assumes F≥0
  (or clamps F at 0) is WRONG here. The existing d_i = 0.5−0.25(F_s+F_d) stays
  valid and can EXCEED 0.5 when parental F<0 (heterozygote excess) — this is
  correct, not a bug; do not clamp d_i ≤ 0.5.
- d_k must stay > 0. With sensible PD Γ it does; guard exactly like the current
  `variance > 0` check in `pedigree_inverse`.
- Γ must be symmetric PD for the Γ⁻¹ block. Validate before inversion.
- Exact-zero Γ makes the MF block singular — reduce via Γ=εI or by excluding MF
  rows from the comparison, never by inverting a literal 0.
- Remap-then-build ordering: unknown parents must be replaced by metafounder ids
  BEFORE the recurrence; a leftover literal 0 for a real animal would silently
  fall back to classical-founder behaviour and break the Γ contribution.
