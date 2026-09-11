# H3 r_am scheduler-failure recovery amendment — 2026-09-10

## Scope

This amendment makes a scheduler-level failure visible without rerunning a
frozen seed. It changes neither the H3 DGP/fixture, interval construction,
model code, bridge, public API, nor any capability or release state.

## Controls

- Red: the new external-failure materialization test failed because no such
  receipt writer existed.
- Green: focused receipt and CLI tests passed 13 assertions. They require the
  frozen `r_am` seed, preserve the exact campaign/estimand/truth/level fields,
  write `fit_converged=false`, `interval_success=false`, and `covered=false`,
  reject overwrite/non-frozen/empty-reason cases, and emit a retained-row token.
- The closed manifest now binds the source-inert recovery bounds, `nc10901`
  exclusion, no-rerun rule, and the materializer SHA-256. Its mutation control
  rejects a changed rerun flag.
- Focused manifest validation and mutation controls passed; the full local
  `Pkg.test()` exited zero after the new test was registered.

## Next controlled action

Seal and hash the candidate, transfer only the sealed amendment bundle, then
materialize the five failure rows on Narval. Re-check their exact hashes and
only then submit the untouched `r_am` task range `495–2000%100` with
`--exclude=nc10901`. No promotion or release action is part of this recovery.
