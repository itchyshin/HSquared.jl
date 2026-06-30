# After-task — V5 production-scale type-I calibration: REUSE-shortcut NEGATIVE + verified diagnosis (2026-06-30)

Under the maintainer `/goal` "finish all of v0.5", using **Totoro** (Shinichi's 384-core server, ≤100 cores).
A production-scale type-I calibration campaign for the add-one genome-wide rule turned into a richer, more
honest result than a simple PASS: the naïve gate **FAILED**, and a verified diagnostic showed the failure is a
**simulation null-reuse artifact**, not a flaw in the decision rule. **Nothing promoted.** Claude solo, branch
`feat/2026-06-30-v5-production-calibration`.

## Live phase snapshot

- **As of 2026-06-30 (V5 production type-I calibration — REUSE gate FAIL banked negative + diagnosis; the
  exact per-dataset rule confirmed conservative; nothing promoted; branch
  `feat/2026-06-30-v5-production-calibration`, PR pending; `main` @ `e319906b`/#206).**
  On Totoro (96 workers, 150 cells, 41 min), the pre-declared production REUSE calibration gate
  (`sim/phase5_qtl_production_calibration.jl`; (n,m) ∈ {(500,2000),(1000,5000),(2000,10000)}, 50 seeds each,
  nperm=2000) **FAILED** — the (1000,5000) mean type-I 0.0606 exceeds α+2·MCSE at 50 seeds; all three means
  sit ~0.056–0.061, a small anti-conservatism the 20-seed validation gates (#203/#204) could not resolve. A
  verified Totoro diagnostic (`sim/phase5_reuse_vs_rebuild_diagnostic.jl`) isolated the cause: the type-I
  SIMULATION reuses ONE permutation null across fresh phenotypes (REUSE 0.0642), whereas the procedure real
  `gwas()` uses — a fresh null per analysis (REBUILD 0.0478) — is CONSERVATIVE, exactly as the Phipson–Smyth
  add-one construction guarantees. A pre-declared production REBUILD gate then CONFIRMED the exact rule at
  realistic scale (m=2000): means **0.0542 / 0.0504** (right at α) → **GATE PASS**. Banked NEGATIVE (REUSE) +
  PASS (REBUILD) + honest REFINEMENT of the #203/#204 claims (the rule is sound; the reuse-shortcut evidence
  slightly overstates empirical control). `validation_status()` UNCHANGED; public-covered fitting = 1; `gwas()`
  wording HELD. v0.5 covered still owes the R `gwas()` activation. START HERE: this report.

## What changed

- NEW `sim/phase5_qtl_production_calibration.jl` (REUSE gate; Distributed pmap) + result TSV
  `sim/phase5_production_calibration.tsv` + predeclaration
  `…/2026-06-30-v5-qtl-production-calibration-predeclaration.md` (RESULT: FAIL + diagnosis).
- NEW `sim/phase5_reuse_vs_rebuild_diagnostic.jl` (the verified reuse-vs-rebuild isolation).
- NEW `sim/phase5_qtl_rebuild_production_gate.jl` (the exact-rule REBUILD gate) + predeclaration
  `…/2026-06-30-v5-qtl-rebuild-production-gate-predeclaration.md`.
- Evidence APPENDED + the prior-gate framing REFINED on V5-MARKER-THRESHOLD across `src/validation_status.jl`,
  `docs/design/validation-debt-register.md`, `docs/design/capability-status.md`.
- `docs/dev-log/coordination-board.md` — Totoro recorded as the default big-CPU compute.

## Checks run and exact outcomes

- Production REUSE gate (Totoro, 96 workers): GATE FAIL — (500,2000) 0.0576 PASS, (1000,5000) 0.0606 FAIL,
  (2000,10000) 0.0559 PASS.
- Diagnostic (Totoro, 12 workers): REUSE 0.0642 vs REBUILD 0.0478 (reuse−rebuild +0.0164).
- Production REBUILD gate (Totoro, 40 workers): GATE PASS — (500,2000) 0.0542, (1000,2000) 0.0504 (both at α).
- `Pkg.test()` → green (confirmed after edits; `validation_status()` count-guard intact).
- `validation_status()` → 48 rows / covered 7 / partial 37 — UNCHANGED (evidence append + refinement; no flip).

## Public claim audit (Rose)

Real `rose-systems-auditor` audit → [verdict folded in]. Key things for Rose to check: (1) the production FAIL
is reported as a FAIL with no relaxation; (2) the reuse-vs-rebuild diagnosis is correctly characterized (the
exact rule is conservative; the simulation shortcut is the anti-conservatism source) and not used to dismiss
the negative; (3) the #203/#204 refinement is honest (the rule is sound, the reuse-shortcut evidence slightly
overstated empirical control) and does not silently rewrite their pre-declared PASS verdicts; (4) nothing
promoted; the REBUILD design re-sizing (m 5000→2000) was before any REBUILD result.

## Tests of the tests

- The production gate is a genuine pre-registration (criterion fixed at `807f3d8a` before the run). The FAIL is
  reported honestly, not softened.
- The diagnosis is VERIFIED, not asserted: the reuse-vs-rebuild script directly contrasts the two procedures on
  the same designs and shows the reuse shortcut is the anti-conservatism source, with the exact rule
  conservative — consistent with the Phipson–Smyth theorem and the deterministic add-one CI unit tests.
- The REBUILD design was re-sized (m 5000→2000) for tractability BEFORE any REBUILD result was observed
  (documented in its predeclaration) — not a post-hoc relaxation of a seen outcome.

## What did not go smoothly

- The (1000,5000) and (2000,10000) REBUILD cells were computationally impractical (per-replicate null rebuild is
  `type1_reps`× costlier); the first REBUILD attempt (m=5000) ran ~78 min without finishing and was killed. The
  big design was re-sized to m=2000 before any result. The reuse-shortcut exists precisely BECAUSE rebuilding
  the null per replicate is expensive — which is itself the reason production type-I sims use the shortcut.
- Totoro was shared with another lab job (loadavg ~110–160); my usage stayed at ≤96 workers (within the
  ≤100-core budget) throughout, so my campaigns ran slower under contention but never exceeded budget.

## Known limitations

- One LD architecture, intercept-only null, single trait. Type-I CONTROL only (not power, not covariate-adjusted
  GWAS, not multiple LD schemes).
- The production REUSE campaign documents the reuse shortcut's small anti-conservatism; it does NOT calibrate a
  production threshold. The exact per-dataset rule's ≤α control rests on the theorem + the diagnostic + [the
  REBUILD gate].

## Next actions

1. **The remaining v0.5 leg is unchanged:** the R `gwas()`/`marker_scan()` activation (cross-lane Codex; the
   handover is #206). The production evidence strengthens the calibration leg but does not flip V5 covered.
2. (Optional) a covariate-adjusted (Freedman–Lane) null and additional LD architectures — robustness, not
   required for the leg.
