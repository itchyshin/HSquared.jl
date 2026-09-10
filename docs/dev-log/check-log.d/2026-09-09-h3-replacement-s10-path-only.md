# H3 replacement S10 — retained PATH_ONLY receipt

- Authority: the maintainer's 2026-09-09 `Proceed`, interpreted and recorded
  as exactly two one-thread Totoro S10 smokes: `r_g` seed `2026090901` and
  `r_am` seed `2026090902`.  It did not authorize S11, promotion, versioning,
  tags, registry action, or release.
- Source basis: materialization `46232fbc`; sealed S10 infrastructure
  `dd7eeb60c53913d2c2ae1acb5f79cf434514c8f9`.  `git diff 46232fbc -- src`
  was empty at launch.  Bundle SHA-256:
  `1e228b646a21ddbbd9a32bedbb0b1c36dc8e5cb37400ce17266e1aa92085dc83`;
  lock SHA-256:
  `a3d4803f05af9738bc5796b1534bdb3249a263efb6c618cae6088d3f0c7ce221`.
  Both matched after transfer to the isolated Totoro checkout.
- Environment: Totoro, one Julia thread and one OpenBLAS thread, Julia
  `~/hsq_work/julia-1.10.0/bin/julia`; isolated root
  `~/hsq_work/hsq09-h3-replacement-s10-dd7eeb60/`.  Precompile completed.
- `r_g`: q=80, n=240, 5,000 iterations, cold `initial=nothing`; converged.
  Delta-SE/Fisher-z endpoint interval: estimate `0.6217340539`, 95% CI
  `[0.3911262838, 0.7788830913]`; truth contained. Wall time `8.15 s`, peak
  RSS `490292 kB`.  Receipt SHA-256:
  `0c6bb55ee0a9c8188f01a0c1fe7f8ae3a2adb45ed4ad478aba24ee439be09ca9`.
- `r_am`: q=996, n=960, 200 iterations, neutral `G_dm=I2, sigma_e2=1.0`;
  converged with positive-definite information. Fisher-z interval: estimate
  `-0.6241042677`, 95% CI `[-0.8259696967, -0.2803679914]`; truth contained.
  Wall time `43.26 s`, peak RSS `679856 kB`.  Receipt SHA-256:
  `79e657ce01fefa24bb1564ebe2aeb9e2301e31a80ee66e6e6b53ab36c4725a26`.
- The paired receipt validator emitted `H3_REPLACEMENT_S10_RECEIPTS_OK` on
  Totoro and again against the local copied raw receipts.  Each raw directory
  retains config, candidate, source-diff, driver, validator, resource, receipt,
  and checksum files separately.  No cells were pooled and no failures were
  discarded (none occurred).
- Integrity finding: the original `SHA256SUMS` inventories included their own
  checksum line, which is stale after writing.  The raw evidence was not
  modified.  Independent `sha256sum -c` / `shasum -a 256 -c` verification of
  every non-self payload entry passed for both directories.  A test-first,
  source-inert launcher fix excludes `SHA256SUMS` from future inventories; it
  does not change these executed inputs or results.
- Classification: two numerical smoke successes only.  They are PATH_ONLY,
  `claim_eligible=false`, and establish neither calibration nor coverage.
  S11, capability/public-status promotion, versioning, tags, registry, and
  release remain held.
