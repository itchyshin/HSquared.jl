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
    environment = environment,
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

Repeated phenotype records are allowed. Pedigree, genotype, and expression IDs
must be unique in this first mirror.

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
- matrix-like genotype inputs with explicit row IDs;
- table-like phenotype, pedigree, genotype, and expression ID columns.
- external R parser integration from `hs_data()` to the same v0.1 bridge
  payload shape.

Planned:

- file-backed storage;
- PLINK, VCF/BCF, Arrow, Parquet, HDF5, and Zarr readers;
- genotype imputation hooks;
- marker maps, QTL/eQTL scans, and genomic relationship construction;
- direct Julia `HSData` to `AnimalModelSpec` construction;
- live Julia `HSData` object marshalling.

Rose audit: this can be called a conservative data-container mirror. It must
not be described as genomic modelling, file-backed storage, QTL/eQTL support,
genotype/omics automatic model construction, production bridge hardening, or
general fitting.
