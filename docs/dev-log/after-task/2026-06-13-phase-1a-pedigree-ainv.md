# Phase 1A Pedigree And Ainv Utility

Date: 2026-06-13

Active lenses: Ada, Shannon, Henderson, Mrode, Gauss, Karpinski, Grace, Jason,
Rose, Pat.

Spawned subagents: none.

## Scope

Finish the first Julia Phase 1A engine slice:

- normalize and validate pedigrees;
- recode IDs and parent labels to integer indices;
- sort parent rows before offspring rows;
- construct a sparse inverse additive relationship matrix `Ainv`;
- scaffold Julia package documentation with DocumenterVitepress;
- keep public claims bounded to engine utilities, not fitted animal models.

The R/coordinator twin owns matching R formula/model-spec/status work in
`hsquared`. This slice did not edit the R repository.

## Implementation

Added `src/pedigree.jl` with:

- `Pedigree`;
- `normalize_pedigree`;
- `inbreeding_coefficients`;
- `pedigree_inverse`.

The direct inverse path uses Henderson-style per-animal contributions. Parental
inbreeding values are computed through a bounded relationship cache. This is
appropriate for initial validation and engine work; it is not a huge-scale
performance claim.

## Tests

Added tests for:

- topological sorting when offspring appear before parents;
- founder, one-known-parent, and two-known-parent `Ainv` hand checks;
- a tiny inbreeding coefficient check;
- dense inverse comparison on a tiny pedigree;
- duplicate IDs;
- unknown parent labels;
- self-parent;
- same known sire/dam;
- parent-offspring cycles;
- relationship-cache limit errors.

## Documentation

Added:

- `.github/workflows/Documenter.yml`;
- `docs/Project.toml`;
- `docs/make.jl`;
- `docs/src/index.md`;
- `docs/src/quickstart.md`;
- `docs/src/pedigree-ainv.md`;
- `docs/src/audience-comparators.md`;
- `docs/src/roadmap.md`;
- `docs/src/api.md`;
- `docs/src/changelog.md`;
- `docs/design/07-user-needs-and-comparator-program.md`;
- `docs/dev-log/scout/2026-06-13-julia-sister-boundaries.md`.

Updated:

- `AGENTS.md`;
- `README.md`;
- `ROADMAP.md`;
- `docs/design/01-v0.1-contract.md`;
- `docs/design/03-engine-contract.md`;
- `docs/design/05-roadmap.md`;
- `docs/design/06-public-claims-register.md`;
- `docs/design/capability-status.md`;
- `docs/design/validation-debt-register.md`;
- `docs/dev-log/check-log.md`;
- `docs/dev-log/coordination-board.md`.

The formula/v0.1 contract now states that R syntax parity is the target. Julia
may have small language-level discrepancies, but they must be deliberate,
documented, tested, and translated cleanly by the R bridge.

The audience/comparator notes record the intended users: breeders, plant and
livestock geneticists, evolutionary geneticists, genomic prediction users, and
applied analysts. Comparator software is listed as a validation target, not a
current claim of superiority.

## Checks

- `julia --project=. test/runtests.jl`: passed.
- `julia --project=. -e 'using Pkg; Pkg.test()'`: passed.
- `julia --project=docs docs/make.jl`: passed.
- `git diff --check`: passed.

The docs build reported local deployment skipping, which is expected outside
CI. It also reported npm audit advisories in generated VitePress dependencies;
the documentation build itself succeeded.

## Rose Audit

Verdict: clean with limitations.

Allowed public wording:

- pedigree validation and sorting are implemented as Julia engine utilities;
- direct sparse `Ainv` construction is implemented for validated pedigrees with
  tiny deterministic tests.

Blocked wording:

- animal models fit;
- REML/ML works;
- EBVs/BLUPs or heritability are available;
- huge-pedigree performance is established.

## Next Work

1. Coordinate the R contract/status wording so the R twin can mention the Julia
   `Ainv` utility without implying fitted model support.
2. Start fixed-effect and animal random-effect design handling.
3. Add Mrode/comparator validation before any model-fitting claim.
