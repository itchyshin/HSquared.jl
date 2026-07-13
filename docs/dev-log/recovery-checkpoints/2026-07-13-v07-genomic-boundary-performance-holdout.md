# v0.7 genomic boundary-performance holdout — PASS (2026-07-13)

## Decision

The separately preregistered boundary-performance candidate passed its fresh
five-cell holdout. It may advance to a new end-to-end public-formula recovery
pilot. This result does **not** activate the default R route, change a capability
row, or change `public_covered_count`.

The previous offset-5001 holdout remains an immutable runtime-gate failure. This
result uses the untouched offset-6001 block and adjudicates the revised
performance candidate only.

## Frozen candidate and execution

- Selected Julia implementation: `fc9d39df650b20aa09d769d9f9528eed1b606f1e`.
- Julia driver/execution commit: `fe5987c2dc5002d3b41910a0356554a8f4d7e359`.
- R bridge/oracle commit: `05ba8aed1c19a7971eeaaf3199fd1afe7d899561`.
- R oracle SHA256:
  `9034a3f6983e7db90f7ab26464b626b744b9f7d5e2ae2db54bbc2260241342d7`.
- Cross-twin exchange-schema SHA256:
  `2472abefc1323ac6cea778b7070f1e0a8e3a8860eeac2c6bddbe7ddf4e44c813`.
- Candidate-seal SHA256:
  `e82e023957514621083df6ea7424cc2d14159aa43e9b567122a6edf944cfb724`.
- Holdout-manifest SHA256:
  `02c5ec2640534f6f45f6243c81c9581c440ac4920d04ea73b428e0f5f523f48e`.
- Summary-gate SHA256:
  `5d60afc5df62706444149544d5c4aa2d0e1a684d213d594a44a1e7eea622d5c1`.
- Timing-summary SHA256:
  `098b02ae95083f793de5605c85dbba6db2126cbf1daf4c5d53891969afe8c097`.
- Summary-lock SHA256:
  `4f895bbaab54dd15781ac031de8e3053d1e02eabedbec7ae19da97dca6ee873a`.
- Host/toolchain: Totoro; Julia 1.10.10; 16 processes; Julia, BLAS,
  OMP, and vecLib threads fixed to one.
- Local-only results root:
  `/home/snakagaw/hsq_work/v07_boundary_performance_20260713/results/fresh-holdout-v2`.

The output root was absent when the 75-key create-once candidate seal was
written. The 240-row manifest was materialized only after sealing. All 240
attempt ledgers, 240 Julia packets, and 240 independent R oracle rows were
retained with sidecars; all 480 fit arms had `error_class = none`.

Compact corpus bindings use UTF-8 lines
`relative_path<TAB>sha256(primary bytes)<LF>`, bytewise sorted by path:

- attempt-primary aggregate:
  `84ac38a7ef54fc805089203d572f1d52a73867a25bd8bc513d4613ad3189dfff`;
- packet-lock aggregate:
  `6d1d7b3fafaea69456c80f03c6dba432a86acce9072950f3dee79374e7ca24fe`;
- oracle-primary aggregate:
  `1ed143447934fee1f11544a4caea9442204cf8543406ef0e67c9176c2f2d640e`.

## Scientific gate

| Quantity | Result |
| --- | ---: |
| attempted | 240 |
| candidate valid | 240 |
| candidate wins | 40 |
| candidate losses | 0 |
| discordant pairs | 40 |
| one-sided Clopper-Pearson lower bound | 0.9278424755 |
| net gain | 0.1666666667 |
| unresolved | 0 |
| candidate invalid | 0 |
| unchanged-interior errors | 0 |

The independent oracle classified 200 interiors, 25 lower endpoints, and 15
upper endpoints. Candidate wins by cell were 17, 5, 12, 5, and 1 in manifest
order; no cell contained a loss.

## Runtime gate

The frozen p95 rule was `sort(x)[ceil(0.95 * 48)]` after a non-holdout warm-up
and seed-parity method ordering.

| Cell | default p95 (s) | candidate p95 (s) | ratio | <= 3x |
| --- | ---: | ---: | ---: | :---: |
| `n120_m600_r020` | 0.258300 | 0.336911 | 1.304 | yes |
| `n120_m600_r050` | 0.235846 | 0.321027 | 1.361 | yes |
| `n120_m600_r080` | 0.245143 | 0.335931 | 1.370 | yes |
| `n300_m1000_r020` | 3.828286 | 3.967075 | 1.036 | yes |
| `n300_m1000_r080` | 0.581843 | 0.777675 | 1.337 | yes |

The first summary wrote `BOUNDARY_HOLDOUT_PASS`; an immediate resume recomputed
and byte-validated all summary semantics and returned
`resume: BOUNDARY_HOLDOUT_PASS`.

## Claim boundary and next gate

This is performance and closed-boundary evidence for the selected Julia
candidate linked to the explicit R genomic bridge. It is not nine-cell
known-truth recovery and does not repair the evidentiary limitation of the old
Julia-only diagnostic pilot. The next gate is a new, preregistered, fresh-seed
pilot that calls the public R formula with the explicit genomic target in one
R process per seed. Confirmation remains forbidden unless all nine pilot cells
meet the frozen convergence and precision rules. Independent cross-language
recomputation and final Fisher/Darwin/Grace/Rose audits are still outstanding.

