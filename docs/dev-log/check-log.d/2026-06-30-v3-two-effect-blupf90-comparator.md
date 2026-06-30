# 2026-06-30 — V3-TWOEFFECT-REML BLUPF90 same-estimand REML comparator leg (Rose CLEAN)

- v0.3 (standard-QG) progress: added the external same-estimand REML comparator doc-18 named as owed for
  the two-effect kernel. New generator `comparator/prepare_blupf90_two_effect.jl` reconstructs the recovery
  harness's seed-20260618 dataset (`y = μ + u1[animal~A·σ1²] + u2[group~I·σ2²] + e`; q=860), fits the
  engine, and emits a correct BLUPF90 packet (2 random effects: animal `add_an_upginb`, group `diagonal`).
- Ran renumf90 1.166 + `blupf90+` 2.60 (Mac x86_64, MKL-free, Rosetta). NEUTRAL start (σe²=1.0, σ1²=0.5,
  σ2²=0.5) → independent convergence in 6 rounds to (σ1²,σ2²,σe²)=(1.1457,0.47933,0.88669) vs engine
  (1.14568,0.47933,0.88668) → ~1e-5 on all three (BLUPF90 5-sig-fig printout-limited).
- Fixed STALE src text (it claimed "no committed recovery test" / "σa² underestimated on a confounded
  design" — both outdated; the independent-group harness recovers all three 5/5). Now consistent across
  src + register:40 + capability:46.

## Checks

- `Pkg.test()` (julia 1.10.0) PASS; `validation_status()` = 48 rows (UNCHANGED), `V3-TWOEFFECT-REML` stays
  `partial`, covered unchanged. No V3 honesty-guard tests exist (only V4 has those), so the text edit is
  test-safe.
- **Real Rose audit (`rose-systems-auditor`) → CLEAN, no required edits.** Rose independently reproduced the
  engine target live and confirmed the generator rebuilds the harness DGP byte-for-byte (`y[1:3]`/`group[1:3]`
  match), the estimand matches (animal~A, group~I diagonal, residual σe²) in both the `renf90.par` encoding
  and the engine's marginal-V assembly, the neutral-start independence, and the agreement (max 1.94e-5).
- Generated packet git-ignored (`comparator/blupf90_two_effect/`); `git diff --check` clean; foreign files
  never staged.

## Claim audit

CLEAN (Rose). Additive "(point-estimate, single seed)" evidence on a PARTIAL row — NOT a covered promotion.
`V3-TWOEFFECT-REML` stays `partial`; a covered close still needs a PRE-DECLARED bias/MCSE recovery gate +
maintainer G10. Public-covered fitting = 1, count = 48 — both unchanged.
