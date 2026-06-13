# Pedigrees And `Ainv`

`HSquared.jl` now has the first Phase 1 engine utility: pedigree normalization
and direct sparse inverse additive relationship matrix construction.

## Pedigree Contract

Input is three equal-length vectors:

- `ids`: animal identifiers;
- `sire`: sire identifiers or unknown-parent markers;
- `dam`: dam identifiers or unknown-parent markers.

By default, unknown parents are represented by `missing`, `nothing`, `""`,
`"0"`, or `0`.

`normalize_pedigree` checks that:

- IDs are present and unique;
- parent labels are either unknown or listed in `ids`;
- an animal is not its own parent;
- sire and dam are not the same known parent;
- the parent graph has no cycle.

It returns a `Pedigree` whose rows are topologically sorted and whose `sire` and
`dam` fields are integer parent indices. `0` means unknown parent.

## Direct Sparse Inverse

`pedigree_inverse` applies Henderson's direct contribution pattern. Each animal
adds a scaled outer product over itself and its known parents. Founder animals
therefore contribute a single diagonal term; offspring with two known parents
contribute to the animal, parent, and parent-offspring entries.

```@example ainv
using HSquared

ped = normalize_pedigree(
    ["calf", "sire", "dam"],
    ["sire", "0", "0"],
    ["dam", "0", "0"],
)

Matrix(pedigree_inverse(ped))
```

The implementation computes parental inbreeding values through a bounded
relationship cache. That is adequate for validation and initial engine work. It
is not a huge-pedigree performance claim.

## Validation Boundary

Covered now:

- founder, one-known-parent, and two-known-parent hand checks;
- reordering where offspring appear before parents in the input;
- inbreeding coefficient check on a tiny pedigree;
- duplicate ID, unknown parent, self-parent, same known sire/dam, cycle, and
  cache-limit errors.

Still planned:

- production-scale pedigree algorithms;
- unknown parent groups;
- inbreeding and relationship-matrix comparator checks against packages such as
  `nadiv` or `AGHmatrix`;
- Gaussian animal-model fitting.
