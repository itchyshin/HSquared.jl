# 2026-06-14 Structured Covariance Metadata Accessors

## Task Goal

Add Julia-local accessors for Phase 4B structured genetic covariance metadata,
keeping them as wrappers over existing `fit_multivariate_reml` fields and not as
a bridge payload change.

## Active Lenses And Spawned Agents

- Hopper/Rose: result-shape and bridge boundary.
- Gauss: structured covariance metadata semantics.
- Karpinski: copy-return behavior.
- Grace: checks and audit trail.
- Spawned agents: none.

## Files Changed

- `src/HSquared.jl`
- `src/multivariate.jl`
- `test/runtests.jl`
- `src/validation_status.jl`
- `docs/src/api.md`
- `docs/src/multivariate-models.md`
- `docs/src/validation-status.md`
- `docs/src/changelog.md`
- `docs/design/03-engine-contract.md`
- `docs/design/capability-status.md`
- `docs/design/validation-debt-register.md`
- `docs/design/06-public-claims-register.md`
- `ROADMAP.md`
- `docs/dev-log/check-log.md`
- this report

## What Landed

New exported Julia accessors:

```julia
genetic_structure(result)
genetic_loadings(result)
genetic_uniqueness(result)
```

They apply to multivariate REML `NamedTuple` results that already contain
structured genetic metadata. They return:

- `(structure, rank)` for `genetic_structure`;
- a copy of the loading matrix, or `nothing`, for `genetic_loadings`;
- a copy of the uniqueness vector, or `nothing`, for `genetic_uniqueness`.

They do not add fields to results. They only make existing Julia metadata easier
and safer to consume.

## Checks Run

- `~/.juliaup/bin/julia --project=. -e 'using Pkg; Pkg.test()'`: passed.
  - Phase 0 scaffold/validation-status block is now 171 checks.
  - Phase 4B structured covariance testset is now 61 checks.
- `~/.juliaup/bin/julia --project=docs docs/make.jl`: passed.
  - Known caveats remained: 8 docstrings not included in the manual; local
    deployment skipped outside CI; VitePress default config substitutions;
    missing local logo/favicon/package.json substitutions; 4 npm audit
    advisories in generated docs dependencies.
- `git diff --check`: passed.
- Claim-boundary scan found the new accessor wording together with explicit
  no-bridge/no-R-facing/no-rotation-identifiability boundaries.

## Public Claim Audit

Allowed:

- Julia has local accessors for existing structured covariance metadata in
  multivariate REML results;
- the accessors copy array/vector metadata before returning it;
- `V4-FA` remains partial.

Blocked:

- no `result_payload()` widening;
- no R bridge payload change;
- no R-facing covariance-structure syntax;
- no loading rotation or interpretability convention;
- no covariance SEs/LRTs;
- no external comparator evidence;
- no production sparse or GPU support.

## Tests Of The Tests

The Phase 4B testset now checks:

- unstructured results return `(structure = :unstructured, rank = nothing)` and
  `nothing` loading/uniqueness metadata;
- diagonal results return uniqueness copies and no loading matrix;
- low-rank and factor-analytic results return loading/uniqueness copies that
  cannot mutate the original result;
- unrelated `NamedTuple`s throw `ArgumentError`.

The validation-status test now requires `V4-FA` evidence and boundary text to
mention the structured-metadata accessors.

## Coordination Notes

No R repository code was edited. This does not require R action unless the R
lane later chooses to mirror these accessors in its own fitted-object surface.

## What Did Not Go Smoothly

Nothing material. One extra test/docs pass was needed after syncing the
validation-status boundary text.

## Known Limitations

- The accessors expose existing metadata only; they do not identify factor
  rotations.
- They do not create a bridge return contract.
- They do not add comparator evidence or move `V4-FA` beyond partial.

## Next Actions

1. Push and confirm GitHub Actions on the branch.
2. Post a Julia PR / issue coordination note; an R note is optional because no
   R action is required.
3. Keep loading rotation/identifiability as a separate design/evidence slice.
