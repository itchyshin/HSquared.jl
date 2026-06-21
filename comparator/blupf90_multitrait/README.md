# BLUPF90/AIREMLF90 Multivariate Starter Packet

This directory is the opt-in starter packet for a second independent
same-estimand comparator leg for `V4-MV-REML`.

It targets the existing deterministic fixture:

```text
test/fixtures/phase4_multitrait_parity/
```

The intended model is the same bivariate Gaussian animal model used by
HSquared.jl and by the R-lane `sommer` comparator:

```text
trait_k ~ intercept_k + beta_x,k * x + animal_k + residual_k
vec(animal effects) ~ Normal(0, A x G0)
vec(record residuals) ~ Normal(0, I_record x R0)
```

## What Is Committed

- `README.md` — this note.
- `../prepare_blupf90_multitrait.jl` — rewrites the committed CSV fixture into
  whitespace-delimited BLUPF90 starter files under this directory.

Generated files are intentionally git-ignored:

- `blupf90_multitrait.dat`
- `blupf90_multitrait.ped`
- `hsquared_targets.csv`
- `renumf90.par`
- BLUPF90-family outputs such as `renf90.par`, `renf90.dat`, `solutions`, and
  `airemlf90.log`

Generate the packet from the repo root:

```sh
julia comparator/prepare_blupf90_multitrait.jl
```

Then, only on a machine with BLUPF90 executables available:

```sh
cd comparator/blupf90_multitrait
renumf90 renumf90.par
airemlf90 renf90.par
```

## Evidence Boundary

This packet is **not** BLUPF90 evidence. It is a reproducible input scaffold for
a future BLUPF90/AIREMLF90 run.

Do not promote `V4-MV-REML` from `partial` using this packet alone. A comparator
evidence record still needs:

- BLUPF90/RENUMF90/AIREMLF90 executable names and versions;
- the exact generated `renf90.par`;
- optimizer settings and convergence status;
- estimated `G0`, `R0`, fixed effects, EBVs, and any likelihood-scale caveat;
- alignment rules and tolerance against `test/fixtures/phase4_multitrait_parity`;
- a Rose claim audit confirming this is a second independent comparator leg.

## Source Notes

The BLUPF90 family documentation says RENUMF90 prepares input for BLUPF90-family
programs, including multiple-trait models, and produces the parameter file used
by programs such as BLUPF90 and AIREMLF90. The current public RENUMF90 page also
states that it supports multiple traits, different effects per trait, and
alphanumeric or numeric fields.

References:

- <https://nce.ads.uga.edu/wiki/doku.php?id=readme.renumf90>
- <https://nce.ads.uga.edu/wiki/lib/exe/fetch.php?media=blupf90_all.pdf>
- <https://masuday.github.io/blupf90_tutorial/renum_mt.html>
