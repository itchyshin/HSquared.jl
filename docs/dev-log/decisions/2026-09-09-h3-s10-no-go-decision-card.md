# H3 S10 no-go — next scientific decision card

## Decision status

**HELD.**  This card records a failure boundary; it is not an authorization to
change the H3 fixture, rerun S10, submit S11, promote a capability, or release
0.9.0.

## Observed basis

The sealed H3 candidate was `82f836f368e37cf75609f721f7a03bde3113e10b`.
One actual Totoro PATH_ONLY smoke ran only the ratified `h3_rg` and `h3_ram`
cells at seed `20260903`, one replication per cell and one Julia/BLAS thread.
It completed in 12.04 seconds, then its committed validator rejected the
output:

| Estimand | Result | Consequence |
| --- | --- | --- |
| `r_g` | fit returned but `fit_converged=false` | no interval; not eligible |
| `r_am` | direct-maternal information matrix not positive definite | no interval; not eligible |

The retained receipt, including raw rows, logs, resource report, and hashes, is
recorded in `docs/dev-log/check-log.d/2026-09-09-h3-s10-totoro-no-go.md` and
the source-inert closeout is
`docs/dev-log/after-task/2026-09-09-h3-s10-totoro-no-go.md`.

## What this decides already

- H3 supplied **zero** successful intervals; it cannot support H3 calibration,
  a directional interval statement, S11 routing, or a release claim.
- The observed 12.04-second driver duration is not a valid campaign estimate:
  the acceptance condition failed before an interval formed.
- The S9-A4 provenance controls remain valid and source-inert at Julia
  `4d4a55c14c9234270979a76c53888d65634a6eaf` and R
  `fd2825795d3d481311912d29f3c377f2897d321d`; this no-go does not alter their
  three-field contract.
- H1's separately retained evidence remains a per-ratio,
  directional-conservative characterization only.  It neither repairs H3 nor
  permits pooling or inheritance of a claim.

## Decision required before H3 can move

Choose exactly one of these routes in a new ratification record.

1. **Replacement H3 protocol.**  Ratify a newly identified, fixed H3 DGM for
   each estimand (`r_g` and `r_am`), including exact pedigree/records/truth,
   seed allocation, convergence and interval-success denominators, negative
   controls, pass bands, and the allowed claim tier.  A new immutable manifest
   and a fresh one-smoke S10 authorization would then be required before any
   compute.
2. **Keep H3 unpaid for 0.9.0.**  Amend the 0.9 release decision map to remove
   any H3 interval claim from the release target.  This is a scope decision,
   not a hidden downgrade: it must be reconciled with H0/H1 requirements and
   the R/Julia public contract before Gate B can be considered.

## Explicitly not authorized

No trial-and-error fixture tuning, retry under a new seed, tolerance/sentinel
relaxation, random seed filtering, S11/DRAC array, R public/API change,
candidate integration, capability flip, package versioning, tag, registry
action, or release follows from this card.
