# H3 sealed smoke inputs — local-only receipt

## Sealed files

| File | SHA-256 | Status |
| --- | --- | --- |
| `/private/tmp/hsq09-h3-smoke-d7929613.bundle` | `9c433de38494f61bd0d42dfd3fbebfedc8c0f215623a3c3b7cd2934adc26a0dd` | `git bundle verify` passed; complete history through `d7929613` |
| `/private/tmp/hsq09-h3-smoke-d7929613-Manifest.toml` | `a3d4803f05af9738bc5796b1534bdb3249a263efb6c618cae6088d3f0c7ce221` | sealed ignored Julia environment lock |
| `sim/phase1_interval_coverage_ext.jl` | `6c1b74cc207247241e395bd78143c07f01b0091682d3049e57bfdbb1a8d0401d` | frozen H3 driver in bundle basis |

The bundle’s HEAD is `d7929613a2beec30d4f946fd32ce80ed0d3a7ce9` and
contains complete history.  The H3 computation source basis remains
`82f836f3`; later commits in the bundle are evidence records only.

## Boundary

These inputs are prepared locally only.  They have not been transferred,
unpacked, instantiated, precompiled, or run on Totoro.  No H3 smoke, DRAC
campaign, promotion, or release is authorized by this receipt.
