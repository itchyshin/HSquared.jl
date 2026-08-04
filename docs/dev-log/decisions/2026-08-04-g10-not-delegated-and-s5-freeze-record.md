# 2026-08-04 — G10 delegation answered (NOT delegated) + S5 freeze hash recorded

## Decision — G10 stays with Shinichi

**G10 (maintainer sign-off for any `experimental` → `covered` capability flip, per
`docs/design/16-promotion-gate-predicates.md:30`) is NOT delegated to Szymek. It stays with
Shinichi, confirmed 2026-08-04.**

This question was first raised in the 2026-07-24 Szymek onboarding note
(`docs/dev-log/handover/2026-07-24-szymek-onboarding.md:68-71`): *"Clarify with him whether he's
delegating G10 to you — if yes, you own it (and should still run the Rose audit first)."* It went
unanswered through two subsequent handovers that both flagged it explicitly:

- `docs/dev-log/coordination-board.md` (F6 section, 2026-07-28): *"the never-answered question of
  whether G10 is delegated to Szymek."*
- `docs/dev-log/handover/2026-08-04-shinichi-handover.md:35-38` (REQUIRED SIGN-OFF LEDGER, S1/S2
  rows): *"Owner (Shinichi, delegation unconfirmed)."*

**Practical effect: none of the standing sign-off rows change.** Every agent had already been
correctly treating all three G10s (S1 `fit_eigen_reml`, S2 `fit_ai_reml`, S3
`fit_matrix_free_reml`) as Shinichi's by default in the absence of an answer — the decision
confirms the default rather than overturning it. `public_covered_count` stays **5**; no capability
row flips as a result of this entry. This closes the standing ambiguity, not a capability gap.

## Freeze record — S5 tail-scale known-truth recovery gate

**Frozen at commit `33ab68f6` (2026-08-04). STATUS: NOT RUN.**

Following the convention used for prior gates in this repo:

- F5 v2 gate for `fit_ai_reml` — frozen `4fb6fb66` (`docs/dev-log/recovery-checkpoints/2026-07-24-f5-scale-recovery-gate-v2-result.md`).
- v08 `fit_multi_effect_mc_reml` recovery+scale gate — PREDECL `66ac9521` BEFORE the run
  (`docs/dev-log/recovery-checkpoints/2026-07-02-v08-s2fit-recovery-scale-result.md`).
- **S5, `fit_matrix_free_reml` tail-scale gate — PREDECL `33ab68f6` BEFORE the run.** Pre-declaration:
  `docs/dev-log/recovery-checkpoints/2026-08-04-f6-matfree-tail-recovery-predeclaration.md`.
  Implementing script (committed at the same hash, run in SMOKE mode only so far):
  `sim/phase_s5_matfree_tail_recovery_gate.jl`.

The full 48(Leg A)+8(Leg X)-seed campaign has **not** been run. A single-seed feasibility probe
(`q=25,000`, Totoro, converged in 59 iterations, 54.26 s single-core) and a SMOKE-mode plumbing
check are the only executions against this script; neither consumes a pre-declared seed or touches
a pass criterion (see the pre-declaration's own "Freeze-then-run is satisfied" note). Per this
repo's freeze-then-run doctrine (`docs/dev-log/decisions/2026-06-14-calibration-failure-response.md`),
running the full gate, reading its result, and recording that result are separate, later actions —
not performed by this entry. **A PASS or FAIL at this gate does not, by itself, flip
`V1-MATFREE-REML`** — it still owes S6 (at-scale external comparator), S4/G8 (a fresh
promote-specific Rose), S3/G10 (this decision keeps that sign-off with Shinichi), and S7 (the R
bridge).

## Current claim

> G10 for all three staged fitters (`fit_eigen_reml`, `fit_ai_reml`, `fit_matrix_free_reml`) is
> Shinichi's alone, confirmed 2026-08-04 — not delegated to any collaborator. The S5 tail-scale
> recovery gate for `fit_matrix_free_reml` is frozen at `33ab68f6` and has not been run.
> `public_covered_count` stays 5.
