# H3 S10 Totoro PATH_ONLY smoke — no-go receipt

- Authority: the explicit H3 `r_g` / `r_am` S10 authorization, scoped to one
  single-thread smoke with no promotion or release.  The sealed scientific
  candidate remains `82f836f368e37cf75609f721f7a03bde3113e10b`; the source-inert
  launcher correction is `1b5f60426413802def2764baf9fe9ec4413bd8db`.
- Exact transfer inputs were SHA-256 verified on Totoro: bundle
  `7304c83723b6203d6d20d938fa49f6863e8a033d38ab3ea5b0e3f5062792c051` and
  `Manifest.toml` `a3d4803f05af9738bc5796b1534bdb3249a263efb6c618cae6088d3f0c7ce221`.
- One actual run only: `h3_rg,h3_ram`, smoke mode, one replication per cell,
  seed `20260903`, `JULIA_NUM_THREADS=1`, `OPENBLAS_NUM_THREADS=1`.  The driver
  finished in 12.04 s (99% CPU; 631,556 KiB maximum RSS), then the validator
  rejected its output.
- `r_g`: fit returned an estimate but `fit_converged=false`, so no interval.
  `r_am`: fit failed because the REML information was not positive definite.
  Both cells have zero interval successes and `claim_eligible=false`.
- The complete retained failure directory is
  `/private/tmp/hsq09-h3-s10-1b5f6042-totoro/hsq09-h3-s10-20260909-1b5f6042-01.failed/`.
  Its `SHA256SUMS` file hashes the driver, validator, result rows, and resource
  receipt.  This is a PATH_ONLY no-go, not calibration evidence.
- S11 was not submitted: the S10 validity requirement failed.  No capability
  status, public/API/bridge surface, version, tag, registry, or release changed.
