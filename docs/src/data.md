# Data Containers

`HSData` is the first Julia-side mirror of the R `hs_data()` container.

It is an in-memory contract for matching phenotypes, pedigrees, genotypes,
expression data, marker annotation, and environmental metadata. It does not
read PLINK, VCF, Arrow, Parquet, HDF5, or Zarr files yet, and it does not build
genomic relationship matrices or fit models.

## Minimal Phenotype Data

```@example data
using HSquared

phenotypes = (
    id = ["animal_1", "animal_1", "animal_2"],
    y = [1.0, 1.5, 2.0],
)

data = HSData(phenotypes; id = :id)
id_map(data).phenotype_ids
```

Repeated phenotype records are allowed. The ID map stores unique phenotype IDs
in first-seen order.

## Pedigree Matching

When a pedigree is supplied, every phenotyped ID must be present in the
pedigree. Extra pedigree ancestors are allowed.

```@example data
pedigree = normalize_pedigree(
    ["founder", "animal_1", "animal_2"],
    ["0", "founder", "founder"],
    ["0", "0", "0"],
)

data = HSData(phenotypes; pedigree = pedigree)
id_map(data).pedigree_ids
```

Raw table-like pedigrees can also be stored if they have an ID column. `HSData`
does not normalize raw pedigree parents; use `normalize_pedigree()` for the
engine pedigree representation.

Raw pedigree tables are allowed to carry warning conditions such as duplicate
IDs, missing known parent IDs, self-parent rows, or same-known-parent rows so
`data_status()` can report them. A normalized `Pedigree` cannot contain those
conditions because `normalize_pedigree()` rejects them before engine use.

## R Parser Integration

On the R side, `hs_data()` can now feed the v0.1 parser. R head `36efbf3`
allows `model_spec()` and `hsquared()` to accept an `hs_data()` object as
`data`; model variables are read from `data$phenotypes`, and formula
components such as `pedigree = pedigree` can be resolved from the bundle.
R heads `74eef82` and `39ca990` also allow the R-side shorthand
`animal(1 | id)` when the pedigree is already stored inside
`data = hs_data(..., pedigree = ped)`.

This does not change the Julia bridge payload shape. The bridge still targets
`y`, `X`, sparse `Z`, normalized pedigree and ID metadata, method, family, and
Julia target metadata. The explicit `animal(1 | id, pedigree = ped)` spelling
remains the shared portable contract, and Julia `HSData` object marshalling
remains planned.

## Genotype And Expression IDs

Matrix-like genotype data needs explicit row IDs because Julia base matrices do
not have row names.

```@example data
genotypes = [
    0.0 1.0
    1.0 0.0
    2.0 2.0
]

expression = (
    id = ["animal_2", "animal_4"],
    gene_a = [4.0, 5.0],
)

data = HSData(
    phenotypes;
    pedigree = pedigree,
    genotypes = genotypes,
    genotype_ids = ["animal_1", "animal_3", "founder"],
    genotype_marker_ids = ["m2", "m1"],
    markers = (
        marker = ["m1", "m2"],
        chr = ["1", "1"],
        pos = [10, 20],
    ),
    expression = expression,
)

id_map(data).phenotypes_without_genotypes
```

When marker metadata is supplied, `HSData` validates common marker-map aliases:

- marker ID: `marker`, `marker_id`, `snp`, `snp_id`, or `id`;
- chromosome: `chromosome`, `chr`, or `chrom`;
- position: `position`, `pos`, `bp`, or `base_pair`.

Marker IDs must be unique and non-missing. Chromosomes must be non-missing.
Positions must be finite, non-negative numeric values. If both `genotypes` and
`markers` are supplied, genotype marker names must match marker-map IDs
exactly after marker names are normalized to strings. For matrix-like
genotypes, use `genotype_marker_ids` because Julia base matrices do not carry
column names.

```@example data
data.marker_spec.marker_ids
```

```@example data
data.genotype_marker_spec.marker_map_index
```

`data_status()` exposes the same diagnostics directly:

```@example data
status = data_status(data)
[row.metric => row.count for row in status.id_overlap]
```

```@example data
[row.metric => row.count for row in status.pedigree_status]
```

```@example data
[row.metric => row.value for row in status.marker_status]
```

## Environment Metadata

`HSData` can also store an environment metadata table. If `environment_id` is
supplied, the same key column must be present in `phenotypes` and
`environment`; `data_status()` then reports overlap between phenotype
environment keys and environment metadata keys.

```@example data
environment = (
    env = ["E1", "E2", "E2"],
    temperature = [18.0, 20.0, 21.0],
)

pheno_env = (
    id = ["animal_1", "animal_1", "animal_2"],
    env = ["E1", "E1", "E3"],
    y = [1.0, 1.5, 2.0],
)

env_data = HSData(pheno_env; environment = environment, environment_id = :env)
env_data.environment_spec.phenotypes_without_environment
```

```@example data
env_status = data_status(env_data)
[row.metric => row.value for row in env_status.environment_status]
```

If an environment table is supplied without `environment_id`, it is stored but
reported as unkeyed:

```@example data
unkeyed_env_data = HSData(phenotypes; environment = (site = ["S1"],))
[row.metric => row.value for row in data_status(unkeyed_env_data).environment_status]
```

This is metadata hygiene only. `HSData` does not join environment covariates
into model matrices, add environmental model terms, or fit multi-environment
models.

```@example data
id_map(data).genotypes_without_phenotypes
```

```@example data
id_map(data).phenotypes_without_expression
```

```@example data
id_map(data).expression_without_phenotypes
```

## Current Boundary

`HSData` currently provides:

- exact-ID matching;
- repeated phenotype ID support;
- marker-map metadata validation and genotype-marker alignment checks;
- `data_status()` diagnostics for components, ID-overlap counts, pedigree
  status, marker status, and environment-key status;
- optional pedigree, genotype, expression, marker, annotation, and environment
  storage;
- conservative mismatch fields for later bridge and genomic work.

Planned later:

- file-backed phenotype and genotype storage;
- PLINK, VCF/BCF, Arrow, Parquet, HDF5, and Zarr readers;
- genotype parsing and imputation;
- QTL/eQTL scans and genomic relationship construction from genotype/marker
  data;
- direct Julia `HSData` to `AnimalModelSpec` construction;
- live Julia `HSData` object marshalling;
- production model fitting from data-container inputs.

IDs are not coerced. For example, `1` and `"1"` are different IDs until an
explicit normalization rule is added.
