# Genomic Models

`HSquared.jl` builds the genomic relationship engine on top of the same Henderson
mixed-model-equation machinery as the pedigree animal model. The functions below
are **engine APIs** (the Julia package's own functions). They are
**experimental**, are **not yet wired to the public R `genomic()` /
`single_step()` formula terms** (those still error as planned), and have **no
external-comparator parity yet** (AGHmatrix / sommer / BLUPF90 checks live in the
R lane). The dense paths here are validation-scale only — they do not gain the
sparse selected-inversion advantage.

## Genomic relationship matrix `G` and its inverse

`genomic_relationship_matrix` builds the VanRaden (2008) `G` from a 0/1/2 (or
dosage) marker matrix. `genomic_relationship_inverse` adds a ridge before
inverting: a VanRaden `G` is rank-deficient — column-centering puts the all-ones
vector in its null space (`rank(G) ≤ n − 1`), so a ridge is required.

```@example genomic
using HSquared, LinearAlgebra

M = [0.0 1 2; 2 1 0; 1 1 1; 0 2 1]   # 4 individuals x 3 markers
G = genomic_relationship_matrix(M)
Ginv = genomic_relationship_inverse(G; ridge = 0.01)
round.(Ginv; digits = 3)
```

## GBLUP

`fit_gblup` solves the genomic animal model by placing `Ginv` in the same
relationship slot the pedigree animal model uses, then reusing `henderson_mme`.
At supplied variance components it returns the usual result object and works with
every extractor (`fixed_effects`, `breeding_values`, `heritability`, …).

```@example genomic
y = [10.0, 12.0, 11.0, 13.0]
X = ones(4, 1)
Z = Matrix(1.0I, 4, 4)
fit = fit_gblup(y, X, Z, Ginv, 1.0, 2.0)
(beta = fixed_effects(fit), gebv = round.(breeding_values(fit).values; digits = 4))
```

The genomic variance components can be **estimated** by REML, by running the
existing optimizers on a genomic spec:

```@example genomic
M6 = [0.0 1 2; 2 1 0; 1 1 1; 0 2 2; 1 0 2; 2 1 1]
y6 = [10.0, 12.0, 11.0, 9.0, 13.0, 10.5]
Ginv6 = genomic_relationship_inverse(genomic_relationship_matrix(M6); ridge = 0.05)
spec = animal_model_spec(y6, ones(6, 1), Matrix(1.0I, 6, 6), Ginv6)
est = fit_animal_model(spec; target = :ai_reml)
est.variance_components
```

## SNP-BLUP and the GBLUP↔SNP-BLUP equivalence

`fit_snp_blup` fits marker effects: the centered markers `W` are the
random-effect design, with an identity prior and per-marker variance `σ²g / k`
(`k = 2 Σ p(1 − p)`). The implied breeding values `gebv = W·â` equal the GBLUP
breeding values for the same data — the classic equivalence (verified to machine
precision via the marginal covariance, the singular-`G`-safe route).

```@example genomic
snp = fit_snp_blup(y, X, M, 1.0, 2.0)
(marker_effects = round.(snp.marker_effects; digits = 4), gebv = round.(snp.gebv; digits = 4))
```

The random block is deliberately labelled `marker_effects`, not breeding values:
on a SNP-BLUP spec the random effects are marker effects, and reusing the
`breeding_values` / EBV vocabulary there would mislabel them.

## Single-step `H⁻¹`

An internal helper `HSquared._single_step_Hinv` assembles the single-step
relationship inverse

```math
H^{-1} = A^{-1} + \text{scatter}\big(\tau\,G_w^{-1} - \omega\,A_{22}^{-1}\big)
```

over the genotyped animals, where `A₂₂⁻¹ = inv(A[g, g])` is the inverse of the
*submatrix* of `A` (not the submatrix of `A⁻¹` — the two differ). It is a
validation-scale construction helper. The exported `single_step_inverse`,
`fit_single_step`, and `fit_single_step_reml` wrappers expose the same dense
relationship-precision path for tests and bridge targets. Its blending / `τ` /
`ω` / `ridge` knobs are not comparator-validated.

The supplied-Γ metafounder variant uses the same update with `A` replaced by
the animal block of `A^Γ`:

```math
H^{Γ^{-1}} = (A^Γ)^{-1} +
    \text{scatter}\big(\tau\,G_w^{-1} - \omega\,(A^Γ_{22})^{-1}\big)
```

`metafounder_single_step_inverse`, `fit_metafounder_single_step`, and
`fit_metafounder_single_step_reml` are dense, validation-scale bridge
primitives. `Γ` is supplied, not estimated. At `Γ = 0`, the helpers reduce to
the ordinary pedigree single-step path. They do not add R-facing formula syntax
or external BLUPF90 evidence by themselves.

## Validation boundary

Covered now (self-consistent, comparator-free):

- VanRaden `G` on a hand-computed fixture (symmetric, PSD, pinned entries);
- regularized `Ginv` (defining identity `(G + ridge·I)·Ginv ≈ I`, ridge/PD
  guards);
- GBLUP against an independent dense MME (~1e-15) and reproducing pedigree BLUP
  when `G = A` (~1e-30);
- SNP-BLUP `gebv = W·â` equal to GBLUP (~1e-16) via the marginal `V`, for both
  `n < m` and `n > m`;
- genomic reliability / PEV / accuracy from the
  `diag(inv(Ginv)) = diag(G) + ridge` denominator, with selinv PEV matching the
  dense diagonal;
- genomic REML: AI-REML and NelderMead reach the same optimum, and a seeded
  simulation recovers the variance components;
- single-step `H⁻¹` reduction (`H⁻¹ = A⁻¹` when `G = A₂₂`), locality, symmetry,
  and the `A₂₂⁻¹ ≠ (A⁻¹)[g,g]` distinctness guard;
- supplied-Γ `H^Γ` construction: reduction to ordinary single-step at `Γ = 0`
  and equality to the manually built `A^Γ` + ordinary single-step path.

Still planned / coordinated:

- the public R `genomic()` / `single_step()` formula mapping (coordinated with
  the R twin);
- external-comparator parity (AGHmatrix / sommer / rrBLUP / BLUPF90) — R lane;
- sparse / APY `G` and GPU acceleration of the dense products;
- comparator-validated single-step blending defaults.
