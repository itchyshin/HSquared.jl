# Check-log — Wave F production-scale sparse fitting evidence (2026-07-24)

Task: assemble + STAGE the production-scale sparse-fitting evidence for `fit_ai_reml`
(experimental, nothing promoted). Owner G10 decision (2026-07-24): **KEEP STAGED** (hold the flip
until the R bridge).

## Checks run + evidence
- `Pkg.test()` **GREEN** on this branch (local, julia 1.10.0) — F1 (O(n) inbreeding), F3 (#180),
  and #114/#182 boundary hardening all pass; nothing to port.
- **F0** scale benchmark (Totoro, julia 1.12.6): low-fill scales (q=300k / 2.3s, converged);
  adversarial high-fill **WALLS** (q=10k = 132s, fill 262; q=20k = 1529s, fill 471) —
  `sim/drac/results/f0_adv_q{10,20}k.tsv`. F6 deferred to the high-fill n>20k tail.
- **F5 gate v1** (frozen `77ecad3a`) → **GATE FAIL (banked negative)**: A/B/X PASS, Leg C 6/8
  (Leg-C test-design flaw, NOT a fitter defect) — `sim/drac/results/f5_gate_v1.log`.
- **F5 gate v2** (corrected, frozen `4fb6fb66`) → **GATE PASS**: recovery 0.19%/0.065% @ q=1e5
  (48/48), deep-15-gen unbiasedness (48/48), boundary 8/8, eigen≡AI 1.18e-7 —
  `sim/drac/results/f5_gate_v2.log`.
- **F8** direct `sommer`≡`fit_ai_reml` comparator → **AGREE 3.6e-5** (local R 4.6.0, sommer 4.4.5).
- **Rose G8** (package): CLEAR-WITH-CHANGES (applied). **Rose** (v1→v2 integrity): **LEGITIMATE
  CORRECTION**. Melissa plan-vs-actual: no unjustified drift.

## Fences (verified)
`public_covered_count` = 5 (unchanged); no capability-status row flipped to covered; no `src` logic
changed; the 4 foreign dirty files untouched; R twin not edited; D1 PAUSED (D-68); F6/GPU/MV deferred.

## Owner decisions (2026-07-24)
- G10: **KEEP STAGED.** Closing actions: deleted the 3 verified-stale branches
  (`phase5-sparse-aireml` + `v84-atscale` merged, `sparse-boundary-hardening` superseded);
  refreshed `status.json`.

See: `docs/dev-log/after-task/2026-07-24-wave-f-production-sparse-evidence.md` ·
`docs/dev-log/handover/2026-07-24-claude-wave-f-production-sparse-handover.md`.
