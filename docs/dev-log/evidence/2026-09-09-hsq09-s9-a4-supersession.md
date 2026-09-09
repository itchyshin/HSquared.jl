# S9-A4 supersession receipt — 2026-09-09

## Decision

`HSQ09-S9-A4` supersedes `HSQ09-S9` **only as the source-inert provenance
record for the approved A4 candidate pair**.  It does not alter, erase, or
reinterpret the historical S9 record.

| Record | Julia basis | R basis | Status |
| --- | --- | --- | --- |
| historical S9 | `1dbf8b97a3b28f814e3418239ac1658acbbc19bb` | `e6a1ce4e8a691795487420668b349fb9e2670059` | immutable historical receipt |
| S9-A4 | `4d4a55c14c9234270979a76c53888d65634a6eaf` | `fd2825795d3d481311912d29f3c377f2897d321d` | current source-inert candidate receipt |

The historical manifest is recovered from Git object `dd1bfa77` at
`docs/dev-log/evidence/2026-09-07-hsq09-s9-evidence-manifest.toml`.  Its
SHA-256 is pinned as
`066a74087dffa0a56e008495345bf0c446455d3cd0c8af04740c3a7b8e2fedd2` and
validated by the new checker.

## What changed

Only two of the eleven governed source inputs changed at the A4 Julia candidate:

- `sim/phase1_interval_coverage_ext.jl` →
  `d6a8d307881b58e44b024562232b6dd638e4feaae4785aa99ea6897a79973002`
- `test/test_phase1_interval_coverage_ext.jl` →
  `726aa8f918efb54bdc66d2adacfb5f170ab66a3207810368ca836fb565a5c5a2`

The remaining nine governed hashes are retained exactly.  This receipt does
not convert the A4 private Binomial observation-scale implementation into an
interval, calibration, public-interface, or release claim.

## Fence

Every authorization and result-import field remains `false`; the retained
sbatch state is `armed = false`, `effective_exit_code = 78`, and
`execution = "refusal_only"`.  No S10/S11, Totoro/DRAC, smoke, campaign,
promotion, version/tag/registry action, or release is authorized by this file.
