# H3 replacement S11 decision template — awaiting maintainer choices

**Status:** ENGINE-/CAPABILITY-INERT TEMPLATE ONLY.  This is not a ratified S11
pre-registration, does not select campaign parameters, and refuses execution.

## Bound evidence basis

The template binds the two separately retained successful replacement S10
receipts at source closeout `93cdc044`:

| Cell | Estimand | S10 seed | Measured runtime | Receipt digest |
| --- | --- | ---: | ---: | --- |
| `rg` | `r_g` | 2026090901 | 8.15 s | `0c6bb55e…be09ca9` |
| `ram` | `r_am` | 2026090902 | 43.26 s | `79e657ce…725a26` |

Both receipts are PATH_ONLY and each retains `claim_eligible=false` and
`s11_authorized=false`. They establish a feasible one-rep interval path only;
they do not estimate coverage, calibrate an interval, or select an S11 design.

## Fields deliberately not decided

The sealed template requires these literal unresolved values:

1. a fresh, disjoint per-estimand seed schedule;
2. retained replicates per estimand;
3. an interval-success denominator floor;
4. MCSE calculation and pass band;
5. a per-estimand classification rule; and
6. a compute route after a pre-run estimate.

`r_g` and `r_am` remain separate throughout. No pooled denominator, classifier,
or promotion path is available.

## Required future decision

Before a real S11 manifest can replace this template, the maintainer must
ratify all six fields above and separately authorize compute. The resulting
manifest must use fresh seeds and preserve every failed fit in its own
estimand-specific denominator. The existing S10 timing is an input to routing,
not authorization to submit an array.

Until then every authorization is false and the only execution mode is
`refusal_only` with exit code 78. No capability, public R surface, version,
tag, registry, or release action follows from this document.
