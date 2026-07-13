# v0.7 genomic recovery-v2 pilot — precision blocker

**Outcome:** negative endpoint; no confirmation and no public activation.

The Totoro offset-7101 pilot ran the held R marker route into this engine for
432 fresh datasets. All 432 attempts succeeded and converged. The create-once
driver-R, independent base-R, and independent Julia summaries all report
`PRECISION_BLOCKER` because five cells require more than the frozen 2,000-fit
cap; the maximum requirement is 16,325.

| cell | required N | status |
| --- | ---: | --- |
| `n120_m600_r020` | 16,325 | `PRECISION_BLOCKER` |
| `n120_m600_r050` | 3,699 | `PRECISION_BLOCKER` |
| `n120_m600_r080` | 8,565 | `PRECISION_BLOCKER` |
| `n300_m150_r020` | 1,553 | `CONFIRMATION_ELIGIBLE` |
| `n300_m150_r050` | 335 | `CONFIRMATION_ELIGIBLE` |
| `n300_m150_r080` | 229 | `CONFIRMATION_ELIGIBLE` |
| `n300_m1000_r020` | 3,807 | `PRECISION_BLOCKER` |
| `n300_m1000_r050` | 911 | `CONFIRMATION_ELIGIBLE` |
| `n300_m1000_r080` | 2,021 | `PRECISION_BLOCKER` |

The sealed adjudicator did not mint a receipt: its R driver compared logical
`FALSE` in memory with the lower-case TSV text `false` as different strings.
The three persisted summaries agree numerically; Julia differs from driver R by
at most `3.33e-16`, below the frozen `1e-10` tolerance. The old root remains
immutable and unadjudicated. No confirmation manifest exists, offsets
7101:7148 are retired, and offsets 7201:7248 are reserved for a separately
admitted future design only.

Frozen old execution identities and hashes are recorded in the R twin's
matching checkpoint. The repaired Julia recomputer is
`sim/phase2_v07_genomic_recovery_v2_recompute.jl`, SHA-256
`af0d83a638f4060a6464d0fb85e87c262fbeec69af712ca1043821785b6298f1`.

The supplied-precision estimator remains covered. The ordinary R marker route
remains partial/held; `public_covered_count` remains 5. This checkpoint is not
accepted recovery evidence, G10, a release, or a production genomic claim.
