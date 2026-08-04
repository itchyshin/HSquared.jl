# Validation Status

`validation_status()` exposes the current validation ladder as typed Julia
rows. It is a diagnostic table, not a comparator runner and not a fitting
helper.

```@example validation_status
using HSquared

status = validation_status()
length(status)
```

```@example validation_status
[row.id => row.status for row in status]
```

## Current Rows

The table below is **generated from `validation_status()` at documentation build
time**, so it cannot disagree with the engine. It was hand-maintained until
2026-08-04 and had drifted to 33 of 56 rows, with one status stale
(`V5-MARKER-THRESHOLD`); a hand-copied status table is a claim that ages.

```@eval
using HSquared
using Markdown

cell(x) = replace(replace(string(x), "\\" => "\\\\"), "|" => "\\|")

io = IOBuffer()
println(io, "| id | capability | phase | status | claim boundary |")
println(io, "| :--- | :--- | :--- | :--- | :--- |")
for row in validation_status()
    println(io, "| `", cell(row.id), "` | ", cell(row.capability), " | ",
            cell(row.phase), " | ", cell(row.status), " | ",
            cell(row.claim_boundary), " |")
end
Markdown.parse(String(take!(io)))
```

<!--
The hand-maintained table that stood here until 2026-08-04 is retained in git
history only. Do not reinstate it: `validation_status()` is the single source,
and the generated block above renders every row it returns.
-->

## Boundary

`covered_external` means the evidence is recorded in the R twin or another
external validation path and is not independently bundled as Julia test data.
For example, the Mrode9 row records the R twin's optional `nadiv::Mrode9` /
`nadiv::makeAinv()` comparison against Julia `pedigree_inverse()`.

That evidence covers pedigree inverse agreement only. It does not cover fitted
Mrode variance components, EBVs, heritability, reliability, PEV, accuracy, or
external ASReml/BLUPF90/DMU/WOMBAT/sommer/MCMCglmm fitted-model parity.

The `V1-MME` row records the shared supplied-variance Henderson MME fixture
mirrored from the R twin at head `ca8bce1`. The fixture pins the pedigree
inverse, fixed effects, EBVs, fitted values, and simple `h2 = 0.6` for supplied
variance components `sigma_a2 = 1.2` and `sigma_e2 = 0.8`.

Julia now also bundles a published Mrode (2014) Example 3.1 animal-model anchor
at the stated variance ratio (`sigma_a2 = 20`, `sigma_e2 = 40`). The test pins
the published EBVs for animals 1-8 and the invariant male-minus-female sex
contrast. This is supplied-variance textbook evidence: it does not estimate
variance components and does not by itself establish same-estimand REML
comparator parity.

Julia also bundles a Mrode9-shaped supplied-variance fixture using the 12-animal
`nadiv::Mrode9` pedigree structure. It pins `Ainv`, ML/REML likelihood values,
fixed effects, EBVs, fitted values, PEV, reliability, derived accuracy, and
`h2` at supplied variance components. This strengthens the supplied-variance
equation and extractor checks, but it is still not fitted Mrode output
validation, variance-component estimation, AI-REML, or external fitted-model
parity.

The opt-in JWAS runner now executes outside CI from the separate
`comparator/` environment. On 2026-06-21, JWAS 2.3.6 ran the serialized
single-trait fitted target as a Bayesian/MCMC model (`chain_length = 50000`,
`burnin = 10000`, seed `20260620`) and aligned all 20 animal EBVs against the
REML target (`cor = 0.999`, max absolute difference `0.1103`). This is an
agreement probe only. JWAS and REML are different estimators, so the row remains
`partial` pending same-estimand fitted-output comparator evidence.

Julia now also bundles `test/fixtures/genomic_gblup_snpblup_target/` as a #49
genomic comparator target: a positive-definite supplied-frequency VanRaden `G`,
its `Ginv`, intercept-only phenotype data, supplied variance components, GBLUP
GEBVs, and SNP-BLUP marker effects/GEBVs. The CI test recomputes the fixture and
pins GBLUP/SNP-BLUP agreement. hsquared PR #84 (`52507da`) mirrors and consumes
that fixture in a Julia-free R test, but this is still internal route evidence,
not an external comparator run.

The Phase 4 multivariate rows are Julia-engine rows only. The accessor helpers
wrap existing result fields locally and do not change the R bridge payload. The
unstructured REML row now has opt-in Julia and R-lane cold-start recovery
evidence with no detectable bias at validation scale, plus one reproduced
external `sommer` 4.4.5 comparator leg on the serialized two-trait target
fixture. The R lane also records a published Mrode Example 5.1
supplied-covariance BLUP/MME anchor and a `MCMCglmm` Bayesian agreement probe.
Those are useful evidence, but only the `sommer` leg is same-estimand REML
parity; ASReml, BLUPF90, DMU/WOMBAT, or equivalent same-estimand parity remains
open. The BLUPF90/AIREMLF90 packet has a tested preflight for numeric
BLUPF90-ready files, an animal ID map, and a skip-safe opt-in runner, but that
is setup hygiene only until an executable run and aligned estimates are
recorded. The
structured covariance row covers diag/low-rank/factor-analytic engine metadata,
local copy-returning metadata accessors, and opt-in recovery checks with
explicit seed-list reporting. The rotation-free diagonal payload and
`structured_covariance_parity` fixture are banked for bridge work; lowrank/fa
raw loading exposure remains blocked. The rotation-identifiability decision note
records sign-only metadata as the current convention. The multivariate recovery
calibration protocol was executed and did not pass under the predeclared
thresholds. Deterministic log triage now records whether failed seeds exceeded
G-only, R-only, or both thresholds, but broad multi-seed calibration remains
validation debt; full rotation and interpretation remain validation debt.
