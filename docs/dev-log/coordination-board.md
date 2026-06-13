# Coordination Board

## Active Lane Split

- Julia lane: this repository, `HSquared.jl`.
- R lane: sibling repository, `hsquared`.
- Coordinator lane: shared issue ledger, public-claim wording, and
  cross-repo contract checks.

## Current Rule

This Julia thread edits only `HSquared.jl`. The R/coordinator twin edits
`hsquared`.

## Shared Contract

- `hsquared` is the R public identity.
- `HSquared.jl` is the Julia engine.
- Phase 0 is operating system plus honest scaffold only.
- Fitting is planned, not implemented.
- Public claims require code, tests, docs, validation rows, and Rose audit.

## Current State

- Phase 0 public scaffold: complete.
- Public repos: `itchyshin/hsquared` and `itchyshin/HSquared.jl`.
- Initial GitHub issue ledger: issues #1-#7 in both repos.
- Next Julia lane: sparse pedigree parser and direct sparse `Ainv` design.
