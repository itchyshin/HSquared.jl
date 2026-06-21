# 2026-06-21 BLUPF90 numeric packet hardening

- Goal: align the Julia BLUPF90/AIREMLF90 multivariate starter packet with the
  R-lane executable handoff convention so a future comparator host receives
  numeric BLUPF90-ready files plus an explicit animal ID map.
- Lenses: Curie + Fisher + Mrode (same-estimand target), Rose (no evidence
  overclaim), Grace (checks), Ada + Shannon (R/Julia lane split).

## Commands

- `julia comparator/prepare_blupf90_multitrait.jl` -- passed. Generated and
  validated 80 phenotype rows and 20 pedigree rows. Local executable probe
  found `renumf90`, `airemlf90`, `blupf90`, `remlf90`, and `gibbsf90` absent
  from `PATH`.
- `julia --project=. -e 'using Pkg; Pkg.test(; test_args=["BLUPF90 multivariate starter packet preflight"])'`
  -- passed. This invocation ran the package test suite; the BLUPF90 preflight
  testset passed 37/37.
- `julia --project=. -e 'using Pkg; Pkg.test()'` -- passed. The BLUPF90
  preflight testset passed 37/37.
- `julia --project=docs docs/make.jl` -- passed, with standing local-build
  warnings for omitted internal docstrings, skipped deployment detection,
  default Vitepress assets, missing local logo/favicon, and npm audit output.

## Boundary

This is packet setup hygiene only. The generated BLUPF90 data file is now:

```text
trait1 trait2 intercept x animal_code
```

The generated pedigree file is now:

```text
animal_code sire_code dam_code
```

`animal_id_map.csv` aligns BLUPF90 integer codes back to the fixture animal IDs.
No BLUPF90-family executable was run, no aligned estimates were parsed, and
`V4-MV-REML` remains partial.

## Final Checks

- `Rscript /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-21-blupf90-numeric-packet.md` -- passed.
- `git diff --check` -- passed.
