# v0.7 genomic closed-boundary holdout

**Outcome:** `BOUNDARY_HOLDOUT_FAIL`; scientific resolution passed, the
preregistered per-cell runtime gate failed, and default/public activation stays
held.

## Evidence

- Frozen Julia core `ecc058f380be71058c9cfde373c345ab7a2f6aba`;
  sealed execution `d89100cd93a33d42cbaf50737d60a08f95e0658f`.
- Frozen R bridge/oracle `68e2bd06be0bcc85e9a832e3c0c327bcdc53d3a1`.
- Candidate seal `66aadd1ec9482b8cbe874abc8f905967711f95704ebdbc956bac226fec4f70c7`.
- Manifest `4ca4fecc8454ef5d9b79c63b87302213129a49c3c4e969b665343270eff614f3`:
  240 datasets, 240 sealed packets, 240 independent R oracles, no replacement.
- Summary gate `4c280fcf424d0c9387ff85629e2ffac6e257c90146a6139b0864ccad3aec5bab`.
- Result: 30 wins, 0 losses, 0 unresolved, 0 invalid, Clopper-Pearson lower
  bound 0.904966, interior-rate gate green.
- Paired results by cell (attempted/wins/losses): `n120_m600_r020` 48/11/0;
  `n120_m600_r050` 48/2/0; `n120_m600_r080` 48/11/0;
  `n300_m1000_r020` 48/6/0; `n300_m1000_r080` 48/0/0. Net gain
  `(30 - 0) / 240 = 0.125`.
- Runtime: four cells green; `n120_m600_r050` failed at 0.510423 / 0.085202 =
  5.991x versus the frozen 3x cap.
- Independent base-R aggregation reproduced the counts, classifications, and
  all five per-cell p95 ratios.

## Checks

- Julia boundary testset: 72/72.
- Full Julia `Pkg.test()`: green.
- Full R engine-free suite at the frozen R commit: 1,896 pass, 0 fail, 0 warn,
  68 ordinary toolchain/dependency skips.
- Commit-pinned live genomic R-Julia suite: 265 pass, 0 fail, 0 warn, 0 skip.
- Holdout harness self-test and Totoro launcher syntax: green.
- Independent adversarial core review: `CLEAN` after two fail-closed repairs.
- Launcher negative control: the synthetic xargs wiring test fails under the
  original literal-`{}` command and passes at `75279136`. That commit is a
  post-seal orchestration-only repair; it is not part of the sealed candidate.
- Final negative-endpoint docs: Julia Documenter/Vitepress build green;
  `bash tools/preamble_cap.sh` green; `git diff --check` green; close-out
  compiler green. The R twin regenerated roxygen, completed its full suite
  without failure/warning, passed pkgdown, and passed repaired `R CMD check
  --no-manual` with 0 errors / 0 warnings / 0 notes.
- PR #273 Julia 1.10/Linux CI then exposed a version-specific fail-closed gap:
  default `rank(X)` classified an exactly duplicated fixed-effect column as
  full rank and CHOLMOD threw before the wrapper could return
  `rank_deficient_X`. The precheck now uses explicit conservative
  `rtol = sqrt(eps(Float64))`; the existing duplicate-column negative control
  is portable again. Full local Julia 1.10 `Pkg.test()` passes, including the
  boundary block 72/72. Independent numerical/Julia review: `CLEAN` (the
  downstream normal equations square `cond(X)`, so the conservative cutoff is
  appropriate). CI rerun is required before merge.

Full evidence and limitations:
[`2026-07-13-v07-genomic-boundary-holdout.md`](../recovery-checkpoints/2026-07-13-v07-genomic-boundary-holdout.md).

No capability row, public count, release, or G10 state changed.
