# Plan-vs-actual reconcile (Melissa, light) — Wave F production-sparse fitting

**2026-07-24 · plan `keen-orbiting-horizon` · executor Claude (end-to-end).** Material deviations
only (scope · evidence · routing · gates · claims · handoff); cosmetic changes ignored. Tags:
**adaptive** (justified + recorded) · **drift** (unjustified) · **unclear**.

| # | Axis | Plan | Actual | Tag |
|---|---|---|---|---|
| 1 | scope/S1 | "reconcile 3 un-merged branches (cherry-pick)" | Phase-2 review found they're already-merged / superseded → **close stale**, not reconcile; deletion left to owner (outward) | **adaptive** (evidence corrected the scout) |
| 2 | scope/S2 | "build a bench harness from scratch" | F0 baseline + `f0_scale_benchmark` already existed in `sim/drac/`; added only the adversarial high-fill leg (the review's gap) | **adaptive** (reuse-before-build) |
| 3 | scope/S4 | "wire sparse AI-REML behind the default" | the path already exists + is reachable; S4 collapsed to confirmation, the flip is F4b (staged for G10) | **adaptive** |
| 4 | evidence/S5 | a passing recovery-at-scale gate | Leg A/B/X PASS but **Leg C boundary FAILED 6/8 → gate BANKED NEGATIVE** (test-design flaw, diagnosed, NOT relaxed) | **adaptive** (honest negative; gate did its job; no relaxation) |
| 5 | gates/S5 | Leg A `|bias|≤2·MCSE` (predeclaration draft) | revised to `:relative` recovery ≤5% (smoke caught bias/MCSE is pathological at q=1e5); frozen-header erratum records the residual stale copy | **adaptive** (pre-freeze, recorded) |
| 6 | scope/F6 | deferred, gated on F0 | F0 confirmed the high-fill wall (q20k=1529s) → F6 is the identified, still-deferred lever | **adaptive** |
| 7 | routing | S1 recon Haiku · Rose G8 Opus · Claude-driven compute (owner end-to-end) | as planned (Haiku scouts, Opus Rose G8, Claude drove Totoro/local R) | none |
| 8 | claims/fences | count 5, no flip, foreign files untouched | all held; Rose G8 fence-check CLEAR | none |

**Verdict: no unjustified drift.** Every deviation is adaptive (evidence- or smoke-driven) and
recorded. The single load-bearing outcome — the **banked-negative gate** — is honest and un-relaxed;
the corrective (a re-declared boundary leg) is named as future work, routed to owner G10. Rose G8
(real spawned `rose-systems-auditor`, CLEAR-WITH-CHANGES) caught the F0 wording + F5 header issues,
all applied. Nothing routed to Rose as open drift.
