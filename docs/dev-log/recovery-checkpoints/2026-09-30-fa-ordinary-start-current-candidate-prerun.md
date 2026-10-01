# FA ordinary-start pre-run on the current candidate

## Purpose

Verify the frozen ordinary-start FA recovery driver on the exact current Julia source before requesting approval for its 200-seed primary campaign. This one development seed is excluded from the frozen primary stream `20261200:20261399`.

## Frozen cell and result

The run used the existing T4/K1 Gaussian FA cell: 60 pedigree animals, 3 complete records per animal, trait intercepts, pedigree relationship, estimated unstructured residual covariance, no supplied initial values, and a 5,000-iteration limit. The existing recovery rules and seed stream were unchanged.

- Seed `20261407`: **nonconverged**, retained as a non-recovery after both default and balanced starts reached 5,000 iterations.
- Relative `G` error: `0.35082096`; relative `R` error: `0.21577141`; minimum uniqueness: `0.00194756`; truth-objective difference: `13.32952`.
- Elapsed fit time: `162.803` seconds on the local Mac, Julia 1.10.0, 4 Julia threads, 1 BLAS thread.
- Source tree SHA-256: `d3c2de8d7f0a1a86918f15938264bbdc892a7303b5ddd488553ac923f073ad0a`.
- Driver SHA-256: `2161449e2e320a6d56bf5b71b1927e18b3d3b4dd60704d30bae5aaafbf057e9b`.
- Output SHA-256: `d7b72e2475d8bbcd14af17d70efa60bd10cb372d5865706eae27320ec8cd31b4`.

The retained raw row is `2026-09-30-fa-ordinary-start-current-candidate-prerun.tsv`; the original tool output is `/private/tmp/fa-ordinary-start-current-candidate-20260930.tsv`. This is a one-seed driver and failure-retention check. It estimates no recovery rate and does not change the acceptance rules.

## Primary-run estimate and approval gate

The primary run contains 200 attempted seeds and uses the existing 5,000-iteration cap. Extrapolating the current 162.8-second fit time gives about 9.0 hours serially; a twofold allowance for seed variation, startup, and overhead gives a conservative estimate of **about 18 hours**. Historical Totoro development runs were faster, but they used an earlier source-tree hash, so they do not justify lowering this current-candidate estimate. The primary run should use Totoro CPU with `JULIA_NUM_THREADS=4`, `OPENBLAS_NUM_THREADS=1`, retain every failed seed, and stop to re-estimate if it exceeds the estimate. No GPU is involved.

The complete campaign remains **not started** pending Shinichi's explicit approval. On approval, use the frozen primary seed range and output path recorded in the execution receipt; do not tune thresholds or replace failed seeds.
