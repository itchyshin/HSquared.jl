# Handover — Wave F production-scale sparse fitting: evidence STAGED (owner G10 pending)

**2026-07-24 · branch `codex/2026-07-13-v07-performance-localization` @ `ccfc46b6` (pushed) ·
PR #274 (draft) · From: Claude (end-to-end, owner-directed ultra-plan `keen-orbiting-horizon`).**
Mode: landed — all evidence committed + pushed; working tree clean except the 4 pre-existing FOREIGN
files. Full detail: `docs/dev-log/after-task/2026-07-24-wave-f-production-sparse-evidence.md`.

## Bottom line
The production-scale sparse-fitting **evidence package for `fit_ai_reml` is assembled, Rose-audited,
and STAGED — NOTHING promoted.** `public_covered_count` stays **5**; the capability-status row stays
`experimental`. The headline science is strong, and after a corrected re-declaration the pre-declared
gate **PASSES** (v2) — so the package is complete and gate-supported, pending only the owner's G10 +
the R bridge. Two fresh spawned Rose audits back it: the package audit (CLEAR-WITH-CHANGES, applied)
and a dedicated **v1→v2 integrity audit** that returned **LEGITIMATE CORRECTION** (not a relaxation),
with 3 residual scope notes recorded for G10.

## What the owner (G10) is looking at — honest
- **Strong positive evidence:** `fit_ai_reml` recovers truth at **q=100,000 to 0.49%/0.05%** (F5 Leg
  A, 48/48, pre-declared + frozen `77ecad3a`); deep-15-generation **unbiasedness** `|bias|≤2·MCSE`
  (Leg B, 48/48); eigen≡AI-REML **3.4e-7** (Leg X); a DIRECT `sommer` same-estimand REML comparator
  **AGREES to 3.6e-5** (F8). Scale is honestly characterized (F0): the direct path scales on low-fill
  (q=300k/2.3s) and **walls on adversarial high-fill** (q=20k = 1529s, fill 471) — F6 (wire the
  existing PCG) is the DEFERRED high-fill-tail lever.
- **The v1→v2 story (fully documented):** v1's overall gate A∧B∧C∧X **FAILED** because Leg C got 6/8.
  **Diagnosed as a Leg-C test-design flaw, NOT a fitter defect** — near-constant y legitimately
  converges to a valid tiny σ²≈1e-14 (finite, non-throwing; the #182 contract holds), which v1's
  criterion wrongly rejected by demanding `converged=false`. v1 was **NOT relaxed** (it stays a banked
  negative; `2026-07-24-f5-scale-recovery-gate-result.md`). A corrected, freshly RE-DECLARED gate
  **v2** (frozen `4fb6fb66`, fresh seeds, Leg C testing the actual finite/non-throwing/non-negative
  #182 contract, recovery criteria UNCHANGED) then **PASSED all four legs**: recovery **0.19%/0.065%**
  @ q=1e5 (48/48), deep-15-gen unbiasedness (48/48), boundary **8/8** (4 converge-to-tiny-σ² / 4
  graceful-stop), eigen≡AI **1.18e-7** (`2026-07-24-f5-scale-recovery-gate-v2-result.md`).

## Next steps (owner + next session)
1. **Owner G10:** the pre-declared recovery-at-scale gate now **PASSES** (v2 corrected, `4fb6fb66`) —
   recovery 0.19%/0.065% @ q=1e5, deep unbiasedness, boundary 8/8, eigen≡AI 1.18e-7, + `sommer` AGREE
   3.6e-5. The production-default flip (F4b) is now **gate-supported** and owes only your G10 sign-off
   + the R bridge. Count stays 5 until you flip.
2. **R lane (separate repo):** expose the production-scale path via the R bridge.
3. **F6 follow-on (deferred):** wire the v0.8-S2 matrix-free PCG into the AI-REML fit loop for the
   high-fill n>20k tail if/when a real high-fill large pedigree needs it.
4. **Hygiene not done this session:** `check-log.d/` entry, `status.json` regen, phase-snapshot
   pointer refresh — light, for the next session. The 3 stale branches
   (`phase5-sparse-aireml`/`v84-atscale` merged; `sparse-boundary-hardening` superseded) are safe to
   `git push origin --delete` (owner call — outward action).

## Fences held
`public_covered_count`=5; no capability-status row flipped; no `src` logic changed (all F0/F5/F8 are
opt-in sims + comparators, not CI); the 4 FOREIGN dirty files untouched (`docs/dev-log/after-task/…retry5…`,
`docs/dev-log/check-log.d/…retry5…`, `docs/dev-log/2026-07-18-two-lever…`, `sim/phase2_v07_genomic_recovery_v3_downstream_replay.jl`);
R twin not edited; D1 genomic PAUSED (D-68); TMB deferred; F6/GPU/multivariate/APY deferred.

## Commit graph (this session)
`533cf0f8` F0 adversarial bench → `77ecad3a` FREEZE F5 gate → `514807a0` F8 sommer≡AI-REML AGREE →
`86a733b7` F0 finding+decision → `ccfc46b6` F5 result (banked negative) + staging + after-task.
Ledger: Julia #5/#6 ↔ R #2/#5.
