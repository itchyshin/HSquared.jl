# Coverage/recovery evidence reconciliation

Date: 2026-07-12. Lane: Julia engine. Status: evidence reconciled; nothing promoted.

## Why this checkpoint exists

The four coverage/recovery drivers merged to `main` on 2026-07-12 were described on the
coordination board as unrun scripts. That statement was stale. The same committed driver
lineage had already run on DRAC `fir` on 2026-07-10 while it was still on
`sim/2026-07-10-coverage-recovery-drivers`. The sibling R repository had banked the results,
but this repository had not reconciled them.

This checkpoint records a fresh, read-only verification against DRAC accounting and the raw
files. No job was resubmitted. In particular, the repeatability confirm was not rerun: doc 34
R4 freezes its banked negative and forbids a reseeded or higher-replicate rescue.

## Governing pre-registration and code identity

- Rule: sibling `hsquared/docs/design/34-interval-recovery-pre-registration.md`, committed
  before any `sbatch`.
- Driver commits: `8d782e0d`, `8aab5257`, `f0f90390`, `2a473b8d`.
- The DRAC checkout was at `2a473b8d`; those commits are ancestors of local `main`
  (`a6955220` at reconciliation). The executed drivers therefore match the merged driver
  lineage.
- Host/account: `fir`, `def-snakagaw_cpu`; Julia module `1.10.10`; one thread per task.
- Raw results remain off GitHub under
  `/home/snakagaw/projects/def-snakagaw/HSquared.jl/sim/drac/results/` on `fir`.

## Fresh DRAC accounting verification

| Campaign | Job | Fresh accounting result |
|---|---:|---|
| C1 interval coverage | 47925485 | 20/20 array tasks `COMPLETED`, exit `0:0` |
| C8 multivariate recovery reseed | 47925486 | 16/16 array tasks `COMPLETED`, exit `0:0` |
| supplied-K screen | 47928724 | 3/3 array tasks `COMPLETED`, exit `0:0` |
| repeatability screen | 47928725 | 6/6 array tasks `COMPLETED`, exit `0:0` |
| supplied-K confirm | 48022362 | 3/3 array tasks `COMPLETED`, exit `0:0`; submit line pins `SK_NSEEDS=2000,SK_TAG=confirm` |
| repeatability confirm, first pass | 48024165 | 40/40 tasks timed out at 90 minutes after writing resumable partial TSVs |
| repeatability confirm, resume | 48040475 | 40/40 tasks `COMPLETED`, exit `0:0`; same seed blocks, two-hour limit |

The timeout is not hidden: the resume-safe TSVs were completed by job 48040475, concatenated,
and aggregated with zero new fits. The pooled file contains 2,000 rows and 2,000 distinct seeds.

## Verified outcomes

### C1 — univariate interval coverage

Across the interpretable small design (`q=120`), interior `h2={0.3,0.5,0.7}`, and 0.95
level, the raw task summaries reproduce the sibling checkpoint:

- h2 intervals are directional-conservative across delta, profile, and bootstrap legs;
- sigma_a2 profile coverage is 0.947 at h2=0.5 and 0.956 at h2=0.7;
- sigma_a2 delta/Wald coverage is 0.897 at h2=0.5, so that leg remains
  experimental-only;
- the tiny design is non-interpretable where interval success falls below the preregistered
  floor, and the 0.90 level remains descriptive-only.

The driver labels `h2=0.1` as an interior grid point while the R-twin adjudication treats it
as boundary characterization. That classification mismatch remains a maintainer/Rose issue;
this checkpoint excludes `h2=0.1` from its interior claim summary.

This does not establish nominal calibration and does not change a capability count.

### C8 — multivariate recovery

All 16 cells contain 500 rows and 500 distinct seeds, with 500/500 convergence. Fourteen
cells pass the aggregate bias/MCSE gate. The only failures are the preregistered
single-record x extreme-correlation cells `rg_090_rec1` and `rg_095_rec1`. The covered-scope
negative control `base_inside` passes, so there is no R9 regression. This sharpens the
existing boundary; it does not promote a new capability.

### Supplied-K recovery

The 48-seed screen passes all three cells. The confirm artifacts each contain 2,000 rows and
2,000 distinct seeds (`20266000:20267999`), with 2,000/2,000 convergence and all
`abs(bias) <= 2*MCSE`:

- `arbK`: sigma2_k bias 0.001648, MCSE 0.001267;
- `identity`: sigma2_k bias 0.001191, MCSE 0.001168;
- `pedA`: sigma2_k bias 0.001058, MCSE 0.001432.

The driver's human-readable line still says `screening tier` because the confirm reused the
screen driver with `SK_NSEEDS=2000`; the SLURM submit line, row counts, distinct seed range,
and machine-readable JSON establish the 2,000-replicate run. This wording mismatch is
recorded rather than retroactively changing the executed driver.

Supplied-K remains unpromoted. Its same-estimand comparator, n-ladder/null, public-surface
claim chain, Rose audit, and maintainer G10 remain separate gates.
The supplied-K recovery run is not evidence for marker-Q construction or estimation despite
the sibling checkpoint's shorthand “supplied-K / Q” heading.

### Repeatability recovery

The 48-seed interior screen passes. The completed 2,000-seed pooled confirm reports:

```text
CONVERGENCE converged=1999/2000 rate=0.9995
GATE gate_pass=false bias=-0.00120 mcse=0.00057 within_2mcse=false
```

Thus `abs(bias)/MCSE = 2.10 > 2.0`: a banked negative at the confirm tier. Repeatability
stays experimental/partial. Per doc 34 R4, no higher-replicate or reseeded rescue is allowed.
The reused driver also leaves `screening_only=true` in the pooled confirm JSON; the 2,000-row
seed set and submit/resume provenance establish the confirm scale, but the stale label should
not be mistaken for a promotion signal.
The proposed finite-sample ratio-nonlinearity explanation is a hypothesis for a separate,
non-promoting analysis; it is not established by this reconciliation.

## Raw-artifact fingerprints

The following SHA-256 values fingerprint sorted per-directory TSV checksum manifests on
`fir` (not tarballs and not GitHub artifacts):

| Directory | Manifest digest |
|---|---|
| `c1_rerun_boot199` | `97d63dc52c3a2ba64d09a6d890ce872c0243e07883d5df10bf23129e8769944b` |
| `w1_v5` | `645d2cbd59dc64d74df381d767c52ec4ea88bfb9761635ed3fd35bc83de63996` |
| `supplied_k` | `91fbfc0b6773533e971757ad57ae5e22e1101197b4ae75a546aa669419b2fa7a` |
| `supplied_k_confirm` | `fa63d5cc14809de61d3ceb53da0c271dabc3a5ccb344f1c410c8612b3ed15039` |
| `rr_repeat` | `44f56947affbf4dabbaab82389e69137511c9c0e8a3e1070cb0caaa1f9aaf01f` |
| `rr_confirm` | `e84f3c8446c701fd58eb8e14e2186db4bc0ec16eb478a78762301cae34f1b4c5` |

Key files: pooled repeatability TSV SHA-256
`f064582f8626743177b8bf72de62f43ffdc00c086c34b03593f7f983b3dc1eba`; pooled log
SHA-256 `bf4eb3e1f5927c6b05e7e53f27c5946938df5a99fd0743791d1eb453a5118ccd`.

## Claim fence

- `public_covered_count` remains **5**.
- No capability-status row changes status.
- The C1 evidence is eligible only for proposed directional-conservative wording in the R
  lane; Rose audit and maintainer ratification remain pending, and it is not nominal
  calibration.
- C8 is broader-DGP characterization around an already-covered validation-scale engine
  capability; it is 500 seeds per cell, not doc 34's 2,000-seed confirm tier.
- Supplied-K is clean recovery evidence but not a completed promotion chain.
- Supplied-K does not cover marker Q.
- Repeatability is a banked confirm-tier negative and must not be rescued by rerunning.
