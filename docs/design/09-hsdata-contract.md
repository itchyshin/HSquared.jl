# HSData Contract

Date: 2026-06-13

Active lenses: Ada, Shannon, Hopper, Emmy, Jason, Darwin, Pat, Rose.

Spawned subagents: none.

## R Handoff

The R twin reports `hsquared` commit `644c75e` with an `hs_data()` input
container. Its current contract stores:

- `phenotypes` with a checked ID column;
- optional `pedigree`, requiring phenotyped IDs to be present when supplied;
- optional `genotypes` with explicit row-name IDs or an ID column;
- optional `markers`, `expression`, `annotation`, and `environment`;
- `id_map` fields for phenotype, pedigree, genotype, and expression overlap.

R head `36efbf3` connects that container to the v0.1 R parser:

- `model_spec()` and `hsquared()` can accept an `hs_data()` object as `data`;
- model variables are read from `data$phenotypes`;
- formula components such as `pedigree = pedigree` are resolved from the
  `hs_data()` bundle;
- the bridge payload shape is unchanged: `y`, `X`, sparse `Z`, normalized
  pedigree/ID metadata, method, family, and Julia target metadata.

R heads `74eef82` and `39ca990` add a narrower R-side default: if the formula
uses `animal(1 | id)` and `data = hs_data(..., pedigree = ped)` supplies a
pedigree, R fills the same v0.1 pedigree contract. The explicit
`animal(1 | id, pedigree = ped)` spelling remains the shared portable syntax.
This does not change Julia `HSData`, the engine API, or the bridge payload.

R heads `5923fcd` and `d1eb174` add marker-map and genotype-marker alignment
validation to the R container. Those handoffs did not change the bridge
payload. Julia mirrors the same local metadata hygiene in `HSData`: marker maps
need marker ID, chromosome, and finite non-negative position columns, and
genotype marker names must match marker-map IDs exactly when both components
are supplied.

R head `1fe0f4c` adds `data_status()` diagnostics for component presence,
ID-overlap counts, and marker-map/genotype-marker alignment status. Julia
mirrors this as `data_status(::HSData)` with typed rows. This is diagnostic
only and does not change the bridge payload.

R head `3fafa08` adds pedigree-status diagnostics to `summary(hs_data(...))`
and `data_status()`. Julia mirrors those counts in `data_status(::HSData)`:
pedigree rows, unique pedigree IDs, phenotype coverage, pedigree-only IDs,
founders, nonfounders, known parent links, missing known parent IDs, duplicate
raw pedigree IDs, self-parent rows, and same-known-parent rows. This is a
diagnostic surface only. It does not normalize raw pedigree tables or build
relationship matrices.

R head `f067cd9` adds genotype-status diagnostics to
`summary(hs_data(...))` and `data_status()`. Julia mirrors those counts in
`data_status(::HSData)`: genotype rows, matched genotype IDs, genotype marker
columns, named marker columns, unnamed marker columns, duplicate named marker
columns, missing genotype value counts, and genotype component type. Plain
Julia matrices are reported as matrix components with unnamed marker columns
because base matrices do not carry marker names.

R head `06cdf59` adds expression-status diagnostics to
`summary(hs_data(...))` and `data_status()`. Julia mirrors those counts in
`data_status(::HSData)`: expression rows, matched expression IDs, expression
feature columns, named feature columns, unnamed feature columns, duplicate
named feature columns, and expression component type. Plain Julia matrices are
reported as matrix components with unnamed features because base matrices do
not carry feature names.

R head `e7fbb31` adds environment-key diagnostics to `summary(hs_data(...))`
and `data_status()`. Julia mirrors those counts with `environment` plus
`environment_id`: keyed containers record phenotype environment IDs,
environment metadata IDs, phenotype environment IDs with and without metadata,
environment-only IDs, and duplicate environment IDs. Unkeyed environment
tables are accepted and reported as not key-checked.

R head `87888d9` adds annotation-feature diagnostics to
`summary(hs_data(...))` and `data_status()`. Julia mirrors those counts with
`annotation` plus `annotation_id`: keyed containers record annotation feature
IDs, expression feature IDs, expression features with annotation metadata,
annotation-only features, expression features without annotation metadata, and
duplicate annotation feature IDs. Unkeyed annotation tables are accepted and
reported as not key-checked.

## Julia Mirror

`HSquared.jl` mirrors the in-memory contract with:

```julia
HSData(
    phenotypes;
    id = :id,
    pedigree = pedigree,
    genotypes = genotypes,
    genotype_ids = genotype_ids,
    markers = markers,
    expression = expression,
    annotation = annotation,
    annotation_id = :feature,
    environment = environment,
    environment_id = :site,
)
```

and:

```julia
id_map(data)
```

## ID-Map Vocabulary

The Julia ID map uses the same conservative vocabulary:

- `phenotype_ids`
- `pedigree_ids`
- `genotype_ids`
- `expression_ids`
- `phenotypes_without_pedigree`
- `phenotypes_without_genotypes`
- `phenotypes_without_expression`
- `genotypes_without_phenotypes`
- `expression_without_phenotypes`

Repeated phenotype records are allowed. Normalized `Pedigree`, genotype, and
expression IDs must be unique in this first mirror. Raw table-like pedigree
inputs can contain duplicate IDs so `data_status()` can report them before any
engine normalization step; `id_map(data).pedigree_ids` stores unique IDs in
first-seen order.

## Matching Policy

IDs are matched exactly. The Julia engine does not coerce `1` to `"1"` or
otherwise rewrite IDs across sources in this slice. Any future normalization
rule must be explicit and mirrored in both twins.

When a pedigree is supplied, every unique phenotype ID must appear in the
pedigree. Extra pedigree ancestors are allowed. Genotype and expression
mismatches are recorded rather than rejected because ungenotyped and
unexpressed phenotyped individuals are valid future inputs.

## Current Boundary

Implemented:

- in-memory data storage;
- exact ID overlap checks;
- marker-map metadata validation;
- genotype-marker alignment validation;
- `data_status()` diagnostics for components, ID-overlap counts, pedigree
  status, genotype status, marker status, expression status,
  annotation-feature status, and environment-key status;
- matrix-like genotype inputs with explicit row IDs;
- table-like phenotype, pedigree, genotype, and expression ID columns.
- external R parser integration from `hs_data()` to the same v0.1 bridge
  payload shape.

Planned:

- file-backed storage;
- PLINK, VCF/BCF, Arrow, Parquet, HDF5, and Zarr readers;
- genotype imputation hooks;
- automatic genotype-to-relationship construction;
- marker maps, QTL/eQTL scans, and genomic relationship construction;
- automatic expression-feature joins;
- eQTL/omics workflows from expression/annotation metadata;
- direct Julia `HSData` to `AnimalModelSpec` construction;
- live Julia `HSData` object marshalling.

Rose audit: this can be called a conservative data-container mirror. It must
not be described as genomic modelling, file-backed storage, QTL/eQTL support,
genotype parsing, imputation, genotype-to-relationship construction,
environment-covariate joining, environmental model terms, expression-feature
joining, annotation-covariate joining, eQTL/omics fitting,
genotype/omics/annotation/environment automatic model construction, production
bridge hardening, or general fitting.
