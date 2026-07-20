# Genomic Models

`HSquared.jl` builds the genomic relationship engine on top of the same Henderson
mixed-model-equation machinery as the pedigree animal model. The functions below
are **engine APIs** (the Julia package's own functions). A narrow R-twin
public-activation candidate now routes Gaussian REML models with one genomic
random intercept from raw markers or a supplied `Ginv` into the existing
supplied-precision solver. For marker input, the internal bridge construction
freezes sample-frequency, unweighted VanRaden method 1 with
`K_lambda = G + 0.01I`, and records engine-owned ID, marker, kernel, and precision
fingerprints. The deterministic cross-twin fixture in
`test/fixtures/genomic_public_activation_target/` is construction and route-
identity evidence. The original offset-5001 boundary candidate remains a banked
runtime failure because one cell reached 5.99x p95 against the frozen 3x cap.
The separately preregistered revised candidate passed its fresh offset-6001
holdout: 240/240 valid attempts, 40 wins, 0 losses, and every p95 ratio at or
below 1.370. This clears only the performance/closed-boundary gate. The
offset-7001 infrastructure attempt failed before fitting because the bridge
package was unavailable; it produced no recovery summary or recovery evidence,
and offsets 7001:7048 are retired. The offset-7101 pilot completed 432/432
successful converged fits, but the sealed adjudicator stopped on a logical
serialization defect before minting a receipt. Its three create-once summaries
all say `PRECISION_BLOCKER`: five cells require more than the frozen 2,000-fit
cap, with a maximum of 16,325. No confirmation manifest exists, offsets
7101:7148 are retired, and this is **not** broad recovery, production-scale
evidence, or permission to activate the R default. Recovery-v3 then produced
three separate 576-fit D0F corpora whose exact Julia replay stopped before row
1 for fixed-panel cardinality, concrete-`Cmd` typing, and missing
successful-gradient contract failures. All three roots and observed
phenotype/bootstrap seeds are permanently unadjudicated and retired. Retry 4
completed 576 official fits and 576 independent base-R recomputations, but
exact Julia replay stopped after 455 admitted rows on a one-ULP endpoint-
representation contract defect. Its root and seeds are retired and
unadjudicated; D1/D2 never opened. Retry 5 then stopped after one successful
official fit on a post-preseal runtime-tree blocker. Its immutable root and
complete seed spaces are retired, and a post-run audit found the admission
proof not contract-clean. The R surface therefore remains partial/held pending
the prospective Retry-6 repair, durable admission evidence, Rose, and G10. Retry 8 subsequently minted
the first D0F PASS/COMPLETE receipt, opening a D1 attempt but not a public route. That fresh D1 reseal4
attempt passed seed-free admission and its GREEN panel, drew four official smoke seeds, then terminated
`RC=21` because fewer than 16 smoke attempts completed. Its root and entire `2028000000/101:148` seed
space are retired/unadjudicated; there is no D1 corpus or receipt, no retry authorization, and no change
to `public_covered_count = 5`, V2-GRM/V2-GINV, or the held R route.
`single_step()` remains a separate
experimental surface.
The dense paths here are validation-scale only — they do not gain the sparse
selected-inversion advantage.

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

That equivalence applies when the two routes imply the same covariance. The
activation candidate instead fits `K_lambda = G + 0.01I`; adding the ridge changes
the covariance kernel, so this evidence does not establish an unqualified exact
ridge-regularized GBLUP–SNP-BLUP equivalence.

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

Engine evidence now available:

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
  simulation recovers the variance components; the supplied-`Ginv` estimator is
  `covered` through the preregistered 48-seed recovery gate and the historical
  same-precision `blupf90+` comparator;
- the v0.7 activation fixture freezes the sample-frequency VanRaden-1
  construction, `K_lambda = G + 0.01I`, `Q_lambda = inv(K_lambda)`, provenance
  fingerprints, and marker-fed versus supplied-precision fit identity across
  repeated records, a nonconstant fixed effect, and unphenotyped genotyped IDs;
- the #49 genomic GBLUP/SNP-BLUP target is mirrored and consumed in the R twin
  (hsquared PR #84) by recomputing supplied-frequency `G`, `Ginv`, GBLUP MME,
  and SNP-BLUP route agreement without live Julia;
- single-step `H⁻¹` reduction (`H⁻¹ = A⁻¹` when `G = A₂₂`), locality, symmetry,
  and the `A₂₂⁻¹ ≠ (A⁻¹)[g,g]` distinctness guard;
- supplied-Γ `H^Γ` construction: reduction to ordinary single-step at `Γ = 0`
  and equality to the manually built `A^Γ` + ordinary single-step path.

Still planned / coordinated:

- the original untouched performance holdout remains a banked failure
  (5.99x), while an output-equivalent numerical repair passed a separate fresh
  holdout. The offset-7001 infrastructure attempt failed before fitting because
  the bridge package was unavailable; it produced no recovery summary or recovery
  evidence, and offsets 7001:7048 are retired. The hash-pinned offset-7101 pilot
  completed 432/432 successful converged fits but produced no accepted
  adjudication receipt because of a logical serialization defect; all three
  summaries say `PRECISION_BLOCKER`, and offsets 7101:7148 are retired.
  Recovery-v3 then produced three separate 576-fit D0F corpora whose exact
  Julia replay stopped before row 1 for fixed-panel cardinality,
  concrete-`Cmd` typing, and missing successful-gradient contract failures.
  All three roots and observed phenotype/bootstrap seeds are retired. Retry 4
  completed 576 official fits and 576 independent base-R recomputations, but
  exact Julia replay stopped after 455 admitted rows on a one-ULP endpoint-
  representation contract defect. Its root and seeds are retired and
  unadjudicated; D1/D2 never opened. The narrow R `genomic()` candidate
  therefore stays held and `single_step()` remains separate;
- a broader construction oracle beyond the completed independent base-R
  reconstruction of the exact candidate kernel. A fresh hash-pinned `blupf90+`
  run now links the
  exact candidate precision to the supplied-precision estimator, but it is one
  point-estimate comparison rather than recovery or production evidence;
- sparse / APY `G` and GPU acceleration of the dense products;
- comparator-validated single-step blending defaults.
