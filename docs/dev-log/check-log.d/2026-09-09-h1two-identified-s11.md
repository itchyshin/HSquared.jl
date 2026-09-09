# H1-two identified S11 — sealed local pre-submission receipt

Status: **LOCAL PRE-SUBMISSION PASS; FIR STAGING BLOCKED BY PROJECT INODE QUOTA.**

This receipt records only local sealing and read-only Fir discovery. It does
not report a submitted job, a received DRAC file, a coverage result, a
capability promotion, or a release action.

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

Narval is a concrete alternative but remains **unselected and unmodified**
until a new user authorization names its destination and submission route.
