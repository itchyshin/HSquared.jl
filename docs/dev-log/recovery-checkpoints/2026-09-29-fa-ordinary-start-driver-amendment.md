# FA ordinary-start driver amendment

Date: 2026-09-29

This additive amendment records a driver-only repair and a new development seed. The Gaussian FA estimator, DGP, 5,000-iteration per-start cap, recovery criteria, primary seed range (`20261200:20261399`), and ordinary-start call remain unchanged. The primary run has not started and remains held for explicit approval.

## Provenance reconciliation

The earlier preregistration's `21712ec…` value identifies a source archive; `d96640d…` identifies its driver. The historical `68f1ec…` value in the exact-source comparator log identifies the then-current `src/multivariate.jl` file. The current file hash is `a28d88c349412d08d480c505032201dcde5c0b8ab237bf819dbf07ad692cb474`. Each hash belongs to its named artifact and timepoint, so the values alone do not establish source drift.

For this amended run, the deterministic `src/` tree SHA-256 is `75b3a76d324476bf01aca3a8fc34c5ab951f6d209fdeac37a2d61448bf430f3c`; the driver SHA-256 is `2161449e2e320a6d56bf5b71b1927e18b3d3b4dd60704d30bae5aaafbf057e9b`. The transferred bundle was checked against these files. macOS `._*` metadata sidecars appeared in the first Totoro extraction and were removed from the isolated copy; the underlying source files matched the local bundle. A Julia 1.12.6 exploratory execution was superseded and is not used here. The retained pre-run uses Julia 1.10.12, four Julia threads, one BLAS thread, and CPU only.

## Driver changes

- Serialize `nothing` diagnostics as `NA`, so an absent objective range cannot turn a valid fit into a false exception row.
- Catch simulation and truth-objective errors and retain them as failed seed rows; fit elapsed time is `NA` when fitting never began.
- Retain uniqueness-floor distance, near-floor flag, genetic/residual disagreement across starts, better-nonconverged-start flag, per-start status, and fit-only elapsed time.
- Record separately named source-tree and driver hashes.

These changes affect failure retention, diagnostics, and provenance only. They do not change the fitted objective, data generation, primary method, seed stream, iteration cap, thresholds, or acceptance estimand.

## Development pre-run

Development seed `20261406` was run on Totoro with the frozen 5,000-iteration cap. Both default and balanced starts converged; the balanced start was selected. The fit met the frozen diagnostic criteria with relative G error `0.3767708`, relative R error `0.2093658`, objective difference `8.32515`, and minimum uniqueness `0.1476362`. Fit time was `49.6087` seconds. The row is preserved in `2026-09-29-fa-ordinary-start-driver-prerun.tsv` (SHA-256 `9979e3f8105521f1fa9c59ed147ddba7fe6cc9fcec036383ac812ec8e59c1b15`). This one development seed validates the corrected driver path only; it is not a recovery-rate estimate or evidence of broad FA reliability.

The original six development fits averaged `75.91` fit seconds. Including this seventh Julia 1.10-series fit gives `72.15` seconds per fit. A conservative 2x allowance for 200 seeds is therefore about `8.1` hours plus startup. Both starts are already included in each fit time. The 200-seed run remains approval-gated and has not started.

## Checks and status

On the current Julia candidate, focused driver tests passed 16/16. Full `Pkg.test()` passed with the new test-only `Sockets` dependency and its Julia 1.10 compatibility entry, ending `Testing HSquared tests passed`. The earlier failed full run exposed that missing test-target dependency and is not counted as a passing run. No capability row or public fitted-model claim changes here.
