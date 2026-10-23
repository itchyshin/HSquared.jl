# v0.7 genomic optimizer-localization discovery

**Outcome:** `BOUNDARY_POLICY_REQUIRED`; no optimizer policy selected, no
holdout opened, no capability/count/public-route change.

## Frozen execution

- Host: Totoro
- Julia: 1.10.10
- R: 4.5.3
- Julia execution commit: `5d14acd1023db8148fba1dbb0b2d0de17e04b363`
- Independent R oracle commit: `7e2680373df9ba4fea77b0b536aeb2e6789924e4`
- Exchange schema: `v07-genomic-localization-exchange-v1`
- Workers: 16; `JULIA_NUM_THREADS=1`; BLAS/OMP/vecLib threads 1
- Results root (local to Totoro):
  `/home/snakagaw/hsq_work/v07_localization_20260712/results/discovery-5d14acd1023d`

The campaign used the create-once launcher stages:

```sh
v07_genomic_optimizer_localization.sh discovery-manifest "$OUT"
v07_genomic_optimizer_localization.sh discovery-run "$OUT"
v07_genomic_optimizer_localization.sh discovery-datasets "$OUT"
v07_genomic_optimizer_localization.sh discovery-oracle "$OUT"
v07_genomic_optimizer_localization.sh discovery-summarize "$OUT"
```

## Denominators and integrity

- immutable arm rows: 928 = 58 datasets x 16 arms;
- raw arm files: 928;
- sealed dataset packets: 58;
- independent oracle outputs re-verified by Julia: 58;
- missing/replaced attempts: 0.

Artifact hashes:

```text
discovery_manifest.tsv c1f5e1a284ed815a4457ac214372fb37382ade07fef3eb4abce331343bdd820a
environment_manifest.tsv e8fa53cc1f8eed96a029ad01f6602eb24e9a299d4105f6771eae5a6d010361d0
candidate_seal.tsv 8a25266b4a89d26e7f26d060efb577c34c1af125c936e39d00175d4b7cb5a12a
discovery_digest 33c31a474fc2f0e996d3bd6489a53d055cc753727b69f0625fc30811777c7caf
```

## Independent-oracle result

At the oracle/tolerance contract frozen in docs 45a and 45b:

| Pilot role | Interior | Lower boundary | Upper boundary | Total datasets |
| --- | ---: | ---: | ---: | ---: |
| control | 29 | 0 | 0 | 29 |
| historical engine failure | 0 | 18 | 11 | 29 |

Every historical non-convergence was therefore consistent with a boundary
optimum under the frozen oracle. Longer caps, EM warm-up, and alternative
starts were not selected. The result is bounded to these 58 selected pilot
datasets and this numerical oracle; it is not a proof about all datasets or a
general optimizer.

Default-AI termination among the 29 boundary datasets was:

- 24 `iteration_limit` (14 lower, 10 upper);
- 5 `step_halving_exhausted` (4 lower, 1 upper).

All 29 controls converged under the unchanged default AI path (16 by score
tolerance, 13 by relative-change tolerance).

## Negative controls and neighbouring findings

- A full 16-arm cross-twin smoke was run first in a separate Totoro output:
  Julia raw arms -> sealed packet -> base-R oracle -> R sidecar verification ->
  Julia schema/order/hash verification. It passed.
- Before that smoke, live execution caught and repaired launcher/driver defects
  that unit self-tests had missed: argument-form mismatch, eager error
  evaluation, pilot-cell validation, generator sorting, packet-directory
  mismatch, and lexical versus preregistered arm ordering.
- Replaying the pilot on macOS reproduced marker and ID hashes but not the
  dense-kernel byte hash. The authoritative campaign therefore remained on the
  original Totoro platform; cross-platform bit identity is not claimed.

## Decision

The holdout remains sealed. A boundary-aware policy must be preregistered,
implemented, mutation-tested, and bound by a new create-once candidate seal
before any holdout seed is materialized. Default R genomic routing remains
held and `public_covered_count` remains 5.
