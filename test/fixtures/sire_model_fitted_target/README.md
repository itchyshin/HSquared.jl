# Sire-model fitted target fixture (#16, Mrode Ch.4)

The ENGINE fits its OWN sire model and serializes its OWN output — no textbook
numbers are typed by hand. A sire model is an ordinary animal-model spec with a
record→sire incidence `Z` and a sires-only `pedigree_inverse`; it needs no new
fitting kernel.

Files:
- `pedigree.csv` — sires-only pedigree (`sire`, `sire_sire`, `sire_dam`; dams unknown).
- `phenotypes.csv` — records (`record`, `sire`, `x`, `y`).
- `expected_variance_components.csv` — estimated `sigma_s2` (the sire variance, held
  in the engine's generic `sigma_a2` slot) and `sigma_e2`.
- `expected_beta.csv`, `expected_ebv.csv` (sire EBVs), `expected_reliability.csv`.
- `expected_metadata.csv` — `h2` (= `4·sigma_s2/(sigma_s2+sigma_e2)`), `loglik`,
  `sigma_s2`, `sigma_e2`, `sigma_a2_implied` (= `4·sigma_s2`), `converged`,
  `n_sires`, `n_records`, `method`, `model`.

**Honesty.** The engine's generic `heritability()` accessor returns
`sigma_s2/(sigma_s2+sigma_e2)`, which is NOT the narrow-sense h² for a sire model.
This fixture stores the corrected `h² = 4·sigma_s2/(sigma_s2+sigma_e2)` itself; the
CI self-consistency test pins both and that they differ.

This is a serialized confrontation **target**, not external evidence: the
same-estimand REML sire-model comparator (an R-lane `nadiv`/`pedigreemm` fit of the
SAME serialized data, with recorded tolerance) is open standing debt. The R-side
published supplied-variance Mrode Example 3.2 anchor is a supplied-variance anchor,
not estimated-VC fitted-output corroboration.

## Regenerate

    julia --project=. test/fixtures/sire_model_fitted_target/generate.jl
