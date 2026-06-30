# 2026-06-30 — V3-TWOEFFECT-REML covered-READY (gate PASS + comparator; Rose CLEAN)

- Pre-declared the two-effect bias/MCSE recovery gate (`sim/phase3_two_effect_bias_mcse.jl` +
  `…recovery-gate-predeclaration.md`), committed `41bd18f6` BEFORE running (no post-hoc relaxation; unseen
  seeds 20260700..747 disjoint from the harness's).
- Ran it: **48/48 converged; all three `|bias| ≤ 2·MCSE` → GATE PASS** (σ1² −2.15%/0.57·MCSE the largest,
  σ2² 1.20·MCSE, σe² 0.33·MCSE). Read as NO DETECTABLE bias, never "unbiased".
- With the executed BLUPF90 same-estimand comparator (PR #195), `V3-TWOEFFECT-REML` now has BOTH doc-33
  path-(b) pieces → **COVERED-READY**. Updated all three surfaces to "covered-ready pending G10"; status
  kept `partial` (the partial→covered flip is the maintainer's non-delegable, atomic G10).

## Checks

- `Pkg.test()` (julia 1.10.0) PASS after the edits; `validation_status()` = 48 rows UNCHANGED,
  V3-TWOEFFECT-REML still `partial`, covered-class 8 unchanged, public-covered fitting = 1.
- **Real Rose audit (`rose-systems-auditor`) → CLEAN.** Rose did git forensics (predeclaration `41bd18f6`
  has ZERO result leakage; harness byte-identical to its frozen form; criteria match code; seeds unseen +
  disjoint; DGP character-for-character identical to the recovery harness) AND **independently reproduced
  the 48-seed gate result from scratch** (matches the recorded table). Verdict: a legitimate covered-promotion
  CANDIDATE on the same doc-33 path-(b) precedent as V4-MV-REML; keeping `partial` is the correct disposition.

## Claim audit

CLEAN (Rose). "COVERED-READY" claims candidacy, NOT covered status — the correct altitude. No autonomous
promotion: 48 rows, `partial`, covered-class 8, public fitting 1 — all unchanged. Covered close = this
candidate + maintainer **G10** (atomic promotion PR). Still owed even after covered: ratio (σ1/σ2)
intervals, correlated direct–maternal genetic (2×2 G), the R-facing model-spec.
