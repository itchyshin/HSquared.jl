# Phase 0 Julia Scaffold

## Summary

Created the initial `HSquared.jl` Phase 0 scaffold: package metadata, source
modules, tests, CI, team constitution, roadmap, design contracts, capability
status, validation debt, and dev-log structure.

This slice is intentionally not a modelling implementation. The public fitting
entry points throw Phase 0 errors.

## Active Lenses

Ada, Shannon, Henderson, Hopper, Boole, Rose, Grace, and Karpinski.

No spawned subagents were running after the R worker was shut down. The R lane
is owned by the coordinator twin.

## Files Added Or Updated

- `Project.toml`
- `src/HSquared.jl`
- `src/backends.jl`
- `src/control.jl`
- `src/errors.jl`
- `src/placeholders.jl`
- `test/runtests.jl`
- `.github/workflows/CI.yml`
- `README.md`
- `AGENTS.md`
- `ROADMAP.md`
- `docs/design/`
- `docs/dev-log/`

## Verification

Commands run:

```sh
julia --project=. test/runtests.jl
julia --project=. -e 'using Pkg; Pkg.test()'
gh repo create itchyshin/HSquared.jl --public --source=. --remote=origin --push
gh run watch 27451520721 --repo itchyshin/HSquared.jl --exit-status
gh run watch 27451548449 --repo itchyshin/HSquared.jl --exit-status
```

Both local Julia commands pass after adding `Test` to the package test target.
Both GitHub Actions CI runs pass on Julia 1.10 and stable Julia.

The second CI run opts actions into Node 24. GitHub still reports that upstream
actions target Node 20, but they are forced to run on Node 24.

## Rose Audit

The scaffold keeps implemented and planned support separate. Fitting,
pedigree processing, sparse `Ainv`, REML/ML, EBVs, heritability, G matrices,
and GLLVM-style animal models are documented as planned only.

## Next

The R twin is now public and green on GitHub Actions. The Phase 0 issue ledger
exists in both repos. Next work should move to Phase 1 design slices: sparse
pedigree parsing, direct sparse `Ainv`, and the explicit R-Julia v0.1 contract.

Coordinator closeout added the remaining design docs, mirrored project-local
skills and role configs, and refreshed roadmap wording so Phase 0 no longer
lists already-completed public-repo tasks as next actions.
