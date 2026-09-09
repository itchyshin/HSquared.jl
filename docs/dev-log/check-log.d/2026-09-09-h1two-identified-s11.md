# H1-two identified S11 — retained two-wave evidence record

Status: **RETAINED TWO-WAVE NARVAL S11 COMPLETE — EVIDENCE ONLY; NO
PROMOTION OR RELEASE.**

Reading note: the local-sealing, Fir-discovery, and original-submission sections
below are **historical pre-submission material**. The later Narval two-wave
section is the completed retained-evidence record. Neither section authorizes a
capability promotion or release action.

## Frozen inputs

- Engine candidate used by the campaign driver: `36ae0691c9e4d30dda8947e162716ebaf30de762`.
- Sealing commit containing the manifest, reconciler, and sbatch contract:
  `a36f0ae2b050290782f01419ccc24fed56af6849`.
- Git bundle prepared locally (cloneable branch bundle):
  `1183255e714273b1910bab220655b81cf8019189c6c1a044dab90bfd484590b3`.
- Runtime `Manifest.toml` SHA-256:
  `a3d4803f05af9738bc5796b1534bdb3249a263efb6c618cae6088d3f0c7ce221`.
- S11 evidence manifest SHA-256:
  `400f0586228be0f7e298025243275cde757f0403e92c00314ccb66ff44510029`.
- Array script SHA-256:
  `0afa34664e9c1edbbb5641111724a331ec18c3aa2beaf93a1f76799d6d647b38`.
- Driver SHA-256:
  `111aadbfb81f235bfda8ca976ec1cef84e2e61aa9bb3348a6be9df31fffc63c0`.

## Local verification

All commands ran from
`/Users/z3437171/local-scratch/lanes/HSquared.jl-h1two-identified-20260909`:

| Check | Result |
| --- | --- |
| `test/test_h1two_identified_campaign.jl` | 16/16; `H1T_IDENTIFIED_S11_TESTS_OK` |
| `test/test_h1two_identified_s11_manifest.jl` | 13/13; manifest mutation controls pass |
| `test/test_reconcile_h1two_identified_s11.jl` | 8/8; duplicate retained row is rejected |
| `test/test_h1two_identified_s11_sbatch.jl` | 12/12; exactly 2,000 one-thread tasks |
| `tools/validate_h1two_identified_s11_manifest.jl --self-test` | `H1T_S11_MANIFEST_OK`; `H1T_S11_MANIFEST_MUTATIONS_OK` |
| `bash -n sim/drac/h1two_identified_s11.sbatch` | exit 0 |
| `Pkg.test()` | exit 0; normal package suite green |

## Fir read-only discovery

The existing non-interactive Fir socket reports account
`def-snakagaw_cpu`, module `julia/1.10.10`, and a 3-hour
`cpubase_bycore_b1` partition. Durable project storage is
`/project/6098264/snakagaw`. The S10 measurement was approximately 4.12
seconds/replicate, so S11 requests 5 minutes and 2 GB per one-thread task.

## Fir transfer attempt — retained failure

The user subsequently authorized the exact four-file transfer. Fir accepted the
top-level empty directory but refused its child staging/log/receipt/depot
directories with `Disk quota exceeded`; no file was copied and no `sbatch`
command was run.

`lfs quota` identifies the reason: project `6098264` has 499,736 of its 500,000
inode limit consumed (264 remain), although byte storage remains available.
The candidate source alone has 1,187 tracked files, before a Julia depot,
2,000 receipts + SHA files, and Slurm logs. This destination therefore cannot
retain the authorized campaign safely. The empty root directory remains at
`/project/6098264/snakagaw/hsq09-h1t-identified-s11-36ae0691/`; it contains no
staged payload.

Next authority is either (a) a user-managed reclamation of sufficient Fir
inodes followed by reauthorization, or (b) a named alternative durable DRAC
project path/cluster with adequate inode headroom. No redirection, cleanup of
user files, promotion, or release is authorized here.

## Read-only alternative-path reconnaissance

On 2026-09-09, the connected DRAC paths were checked read-only for project
`6098264`:

| Cluster | Project file slots used / limit | Verdict |
| --- | ---: | --- |
| Fir | 499,736 / 500,000 | blocked |
| Narval | 184,777 / 500,000 | viable: 315,223 slots remain; `/project/6098264/snakagaw` exists |
| Rorqual | 498,272 / 500,000 | not viable for this retained campaign |
| tamIA | no project allocation | unavailable |
| Nibi | non-Lustre quota response | not selected without a live storage contract |

## Narval routing amendment

The maintainer authorized a **source-inert** amendment to Narval at
`/project/6098264/snakagaw/hsq09-h1t-identified-s11-36ae0691/`. Only the
manifest route and sbatch metadata changed: `cluster = "narval"` and the
sbatch self-identifies Narval. The driver commit, runtime manifest, fixture,
seed window, estimands, task count, one-thread cap, and all promotion/release
fields are unchanged. The amended S11 manifest and sbatch hashes are,
respectively,
`118add7f907dd4807e932ac69cc732038f208fe60ef38ab92341a0e4623dfe29` and
`1284f1058734d034453deff44d8fc34495cf65d2de61eed31464ea492cdaa7da`.

The Narval manifest test (15/15), sbatch test (13/13), manifest mutation
validator, and shell syntax check all pass. At this amendment point, transfer
and submission were the next authorized actions; the completed two-wave run is
recorded below.

## Narval staging and scheduler submission — retained failure

The four authorized files were transferred to Narval and their remote SHA-256
values exactly matched the local sealed values. The bundle was cloned and
checked out at driver commit `36ae0691c9e4d30dda8947e162716ebaf30de762`;
the copied runtime manifest and driver hashes matched their manifest pins.
`julia/1.10.10` instantiated and precompiled into the dedicated Narval depot,
then `using HSquared` printed `H1T_S11_NARVAL_PRECOMPILE_OK`.

The exact authorized `sbatch --array=1-2000%100` submission was rejected
before a job was created with `AssocMaxSubmitJobLimit`. Read-only accounting
then reported `MaxSubmitJobs=1000` for `snakagaw|def-snakagaw_cpu` and zero
current jobs. That original one-array submission created no task, receipt,
log, result, promotion, or release. The 2,000-task protocol is intact, but
its one-array launch is incompatible with this live account limit.

The only compliant continuation is a separately authorized two-wave launch:
`--array=1-1000%100`, then `--array=1001-2000%100`, with the same sealed
driver, one task per seed, retained receipts, and no other scope change.

## Narval two-wave campaign — complete retained evidence only

The maintainer then authorized exactly the two sequential array waves named
above. Wave 1 was submitted as job `2734452` with `--array=1-1000%100`; only
after its terminal accounting and 1,000 receipt hashes passed was wave 2
submitted as job `2740214` with `--array=1001-2000%100`. The two job ranges
are disjoint and together cover the frozen 2,000-seed window.

### Scheduler and retained-artifact accounting

| Wave | Scheduler accounting | Final selected-task `seff` receipt |
| --- | --- | --- |
| `2734452` (1–1000) | 1,000 `COMPLETED`, each exit `0:0` | task `2734452_1000`: 1 core, 7 CPU seconds / 9 wall seconds, 311.01 MB of 2 GB |
| `2740214` (1001–2000) | 1,000 `COMPLETED`, each exit `0:0` | task `2740214_2000`: 1 core, 8 CPU seconds / 8 wall seconds, 311.03 MB of 2 GB |

`seff` reports the final selected array element above, not an aggregate
campaign resource total. The durable Narval project directory retains 2,000
atomic receipt TSVs, 2,000 SHA-256 sidecars, 2,000 stdout logs (each carrying
`H1T_S11_TASK_OK`), and 2,000 empty stderr logs. All remote sidecars verified
against their payloads; the locally retrieved evidence copy also verified all
2,000 digests. Because each sidecar names its Narval absolute path, the local
check removes only that frozen directory prefix before passing the digest/path
pairs to `sha256sum -c`; it does not alter a receipt or sidecar.

The local reconciler was run against the complete copied receipt inventory:

```text
H1T_S11_RECONCILE_OK requested=2000 rows=4000 interval_success=3950 covered=3833 coverage=0.970379746835443 mcse=0.00269753257002308 claim_eligible=false
```

The reconciler also proves the exact 2,000-seed × two-estimand inventory,
unique rows, fixed truth and level, valid successful intervals, retained
failures, and hard-false `claim_eligible`. The campaign driver on the
reconciliation checkout is byte-identical to the sealed driver source at
`36ae0691c9e4d30dda8947e162716ebaf30de762`.

### Per-estimand result and constrained interpretation

| Estimand | Scheduled | Interval-success denominator | Retained failure | Covered | Coverage | MCSE | Difference from 0.95 |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| `ratio1` | 2,000 | 1,952 | 48 `invalid_or_boundary_interval` | 1,895 | 0.970799 | 0.003811 | +5.46 MCSE |
| `ratio2` | 2,000 | 1,998 | 2 `invalid_or_boundary_interval` | 1,938 | 0.969970 | 0.003818 | +5.23 MCSE |

The pooled bookkeeping value is 3,833 / 3,950 = 0.970380 (MCSE 0.002698),
but it is **not** a pooled scientific label because the two ratio estimands are
distinct. Under the frozen H1 rule, over-coverage can support only a
`directional-conservative` description for each individual ratio at this
identified DGM; it can never support a point/calibrated statement. The
available A2 calibration band `[0.93, 0.97]` is also exceeded by the pooled
value, so this is not a `calibrated_candidate` even if that adjudicator is
later linked formally to this fixture.

The separate Fisher review confirms the per-ratio directional-conservative
reading and prohibits pooling the two estimands into one scientific claim. The
separate Rose audit accepts only the no-promotion boundary below. Neither review
is a capability flip or a maintainer release decision. See
`docs/dev-log/reviews/2026-09-09-h1two-identified-s11-fisher.md` and
`docs/dev-log/reviews/2026-09-09-h1two-identified-s11-rose.md`.

### Boundary held

The S11 manifest remains `claim_eligible = false`, and all promotion,
versioning, tag, registry, and release fields remain false. The isolated branch
has no `Project.toml` version change and no tag contains its candidate head;
the GitHub release query returned no rows. No capability-status or
public-claim row changed. This result is retained evidence for later Fisher,
Rose, and maintainer adjudication only; it does not authorize a release.
