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
  whitespace-delimited BLUPF90 starter files under this directory, validates the
  generated packet shape, and probes for local BLUPF90-family executables.
- `../run_blupf90_multitrait.jl` — skip-safe opt-in runner. Without
  `HSQUARED_RUN_BLUPF90=true`, it validates the packet and exits without
  running external software.

Generated files are intentionally git-ignored:

- `blupf90_multitrait.dat`
- `blupf90_multitrait.ped`
- `animal_id_map.csv`
- `hsquared_targets.csv`
- `renumf90.par`
- BLUPF90-family outputs such as `renf90.par`, `renf90.dat`, `solutions`, and
  `airemlf90.log`

The BLUPF90 data file is numeric and uses the same column convention as the
R-lane executable handoff:

```text
trait1 trait2 intercept x animal_code
```

The pedigree file is integer-coded:

```text
animal_code sire_code dam_code
```

Use `animal_id_map.csv` to align BLUPF90 output back to the original fixture
animal IDs before comparing EBVs.

Generate the packet from the repo root:

```sh
julia comparator/prepare_blupf90_multitrait.jl
```

Or run the skip-safe preflight:

```sh
julia comparator/run_blupf90_multitrait.jl
```

Then, only on a machine with BLUPF90 executables available:

```sh
HSQUARED_RUN_BLUPF90=true julia comparator/run_blupf90_multitrait.jl
```

## Evidence Boundary

This packet is **not** BLUPF90 evidence. It is a reproducible input scaffold for
a future BLUPF90/AIREMLF90 run.

The preflight is evidence hygiene only: it confirms that the packet has the
expected row counts, target covariances, and no header/comment rows in
machine-consumed BLUPF90 inputs. It does not verify RENUMF90 syntax for every
BLUPF90-family release and it does not parse comparator estimates.

Do not promote `V4-MV-REML` from `partial` using this packet alone. A comparator
evidence record still needs:

- BLUPF90/RENUMF90/AIREMLF90 executable names and versions;
- the exact generated `renf90.par`;
- optimizer settings and convergence status;
- estimated `G0`, `R0`, fixed effects, EBVs, and any likelihood-scale caveat;
- alignment rules via `animal_id_map.csv` and tolerance against
  `test/fixtures/phase4_multitrait_parity`;
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
