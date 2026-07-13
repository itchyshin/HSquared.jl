# v0.7 genomic closed-boundary holdout — runtime-gate STOP (2026-07-13)

## Decision

**STOP; do not activate the default R genomic route and do not run the nine-cell
recovery campaign.**

The preregistered closed-boundary candidate resolved every sealed holdout
dataset and strictly improved 30 default-AI failures without losing any valid
default fit. It nevertheless failed the frozen per-cell runtime gate because
one cell exceeded the allowed 3x p95 runtime ratio. The scientific and runtime
gates were conjunctive, so the overall result is `BOUNDARY_HOLDOUT_FAIL`.
No seed, threshold, cell, or timing record was changed after opening the
holdout.

## Frozen candidate and execution

- Contract: `docs/design/46-v07-genomic-boundary-resolution.md`
- Frozen Julia core: `ecc058f380be71058c9cfde373c345ab7a2f6aba`
- Sealed Julia execution commit: `d89100cd93a33d42cbaf50737d60a08f95e0658f`
- Frozen R bridge/oracle commit: `68e2bd06be0bcc85e9a832e3c0c327bcdc53d3a1`
- Independent R oracle SHA256:
  `121f0cac1d2ec677ec3eee32ff3049dc477d5e98d2dde1b900460877bbef921f`
- Candidate-seal SHA256:
  `66aadd1ec9482b8cbe874abc8f905967711f95704ebdbc956bac226fec4f70c7`
- Holdout-manifest SHA256:
  `4ca4fecc8454ef5d9b79c63b87302213129a49c3c4e969b665343270eff614f3`
- Summary-gate SHA256:
  `4c280fcf424d0c9387ff85629e2ffac6e257c90146a6139b0864ccad3aec5bab`
- Pair-summary SHA256:
  `8e3e7ea4214ea0230d1d1e2eef1ba8271215c71550092c000b1187b31fecc360`
- Host/toolchain: Totoro; Julia 1.10.10; R 4.5.3; 96 processes;
  Julia/BLAS/OMP/vecLib threads fixed to one.
- Local-only results root:
  `/home/snakagaw/hsq_work/v07_boundary_holdout_20260713/results/holdout-d89100cd93a3`

The candidate was sealed while that output directory was absent. The manifest
then materialized exactly 240 frozen datasets (five cells x 48 seeds). All 240
Julia packets and all 240 independent base-R oracle outputs have checksum
sidecars. No attempt was replaced. The packet run took 66.2 elapsed seconds.

## Scientific result

| Quantity | Result |
| --- | ---: |
| attempted | 240 |
| candidate valid | 240 |
| default valid | 210 |
| candidate wins | 30 |
| candidate losses | 0 |
| discordant pairs | 30 |
| one-sided Clopper-Pearson lower bound | 0.904966 |
| unresolved | 0 |
| unchanged-interior errors | 0 |

| Cell | attempted | wins | losses |
| --- | ---: | ---: | ---: |
| `n120_m600_r020` | 48 | 11 | 0 |
| `n120_m600_r050` | 48 | 2 | 0 |
| `n120_m600_r080` | 48 | 11 | 0 |
| `n300_m1000_r020` | 48 | 6 | 0 |
| `n300_m1000_r080` | 48 | 0 | 0 |

The frozen paired net gain was `(wins - losses) / attempted = (30 - 0) / 240 =
0.125`.

The independent oracle classified 210 interiors, 17 lower endpoints, and 13
upper endpoints. Candidate results matched all 240 classifications. The 30
wins were exactly the 30 endpoint datasets missed by default AI-REML. The
frozen per-cell interior-validity rate gate passed.

## Runtime gate

The p95 rule is the preregistered order statistic
`sort(x)[ceil(0.95 * 48)]`. Timed method order was balanced by seed parity
after a fixed non-holdout compilation warm-up.

| Cell | default p95 (s) | candidate p95 (s) | ratio | <= 3x |
| --- | ---: | ---: | ---: | :---: |
| `n120_m600_r020` | 0.264685 | 0.705285 | 2.665 | yes |
| `n120_m600_r050` | 0.085202 | 0.510423 | **5.991** | **no** |
| `n120_m600_r080` | 0.663781 | 1.611859 | 2.428 | yes |
| `n300_m1000_r020` | 8.701199 | 7.007636 | 0.805 | yes |
| `n300_m1000_r080` | 1.463573 | 2.627787 | 1.795 | yes |

An independent base-R aggregation reproduced all denominators, win/loss
counts, classifications, p95 values, and the single failing cell.

## Execution incident and test-of-the-test

The first R-oracle fan-out produced zero oracle files because the shell launcher
passed a literal `{}` to `bash -c` instead of the xargs packet argument. The
sealed Julia packets were unaffected. The same frozen oracle was rerun against
the same packets with corrected argument positions; no scientific code,
threshold, seed, or packet changed. Commit `75279136` fixes the launcher and
adds a synthetic xargs argument-wiring self-test that fails under the original
command. This post-seal orchestration repair is not part of the sealed candidate
implementation.

## Claim boundary and next experiment

Nothing is promoted. `V2-GREML` remains covered only for the existing supplied-
precision estimator. `V2-GRM` and `V2-GINV` remain partial. The R marker route
remains explicit/experimental and held from default routing.
`public_covered_count` remains **5**.

The next discriminating experiment is a fresh, separately preregistered
performance-localization candidate. It should profile allocation and repeated
linear-algebra cost in the exact closed-domain likelihood evaluator on the
already-open discovery seeds, preserve the doc-46 likelihood/classification
contract and independent dense oracle, and use a new untouched holdout seed
block. These 240 seeds are spent and must never adjudicate a revised candidate.
