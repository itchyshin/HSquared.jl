# After-task — v0.8-V8.4: external comparator for the matrix-free fit (2026-07-03)

**Owner:** Claude solo (Opus), autonomous. **Branch:** `feat/2026-07-03-v84-matfree-comparator` off
`main` @ `eef2b1f9` (V8.5 merged). **R twin:** untouched. **Counts:** `validation_status()` rows
**55 UNCHANGED**, covered **13** UNCHANGED, `public_covered_count` **5** UNCHANGED. NO covered flip.

## Headline

The matrix-free Monte-Carlo REML fit (`fit_multi_effect_mc_reml`) now has an **external
same-estimand comparator**: run live against `blupf90+` 2.60 AIREMLF90 on a shared K=3 fixture, the
matrix-free fit's across-seed mean reaches blupf90's optimum to **≤0.15%** within its Monte-Carlo
error band. This is the external-comparator ESTIMAND leg doc-25 named as owed for the matrix-free
path (V8.4) — at validation scale. The AT-SCALE (large-fixture, exact-infeasible) leg remains owed.

## What landed

- **`comparator/matfree_blupf90_neffect.jl`** (NEW, committed) — reconstructs the shared K=3 fixture
  (seed 20260800, q=860; animal ~ A + two independent env groups), writes the blupf90 packet, runs
  renumf90 → blupf90+ AIREMLF90 live (binaries in `comparator/bin/`), parses the VC estimates, runs
  the exact + 16 matrix-free fits (2 probe budgets × 8 seeds), and writes a comparison CSV.
- **`docs/dev-log/recovery-checkpoints/2026-07-03-v84-matfree-blupf90-comparator.md`** — banks the
  numbers.
- **Status surfaces (owed-note sweep, in place — NO new row):** `validation_status.jl`,
  `capability-status.md`, `validation-debt-register.md` all move the V8.4 comparator from *owed* to
  *delivered (validation-scale estimand leg)* and keep the *at-scale leg* + *coverage-calibrated
  intervals* owed. doc-25 V8.4 marked "ESTIMAND LEG DONE". check-log entry.

## Evidence (live blupf90 run)

- **Estimand:** exact `fit_multi_effect_reml` vs blupf90 → max abs diff **3.78e-5** (5-sig-fig floor).
- **Matrix-free vs blupf90** (8 seeds, `shared_probes`, NEUTRAL start): across-seed mean reaches
  blupf90's optimum to **≤0.15%** — nprobe=128 → 0.05% (worst 0.11·SD), nprobe=512 → 0.15% (worst
  0.48·SD); blupf90 within ≤0.5 across-seed SD of the matrix-free mean for every component.
- `Pkg.test()` count UNCHANGED (55); no `src/` change (comparator + evidence slice).

## Honesty pins

- ONE deterministic fixture, moderate scale (q=860, where blupf90 also runs) — validates the
  matrix-free ESTIMAND against an external tool, NOT coverage, NOT a recovery gate (that is the
  separate pre-declared 48-seed gate). NO covered flip; `V3-NEFFECT-MATFREE-FIT` stays `partial`.
  `public_covered_count` UNCHANGED.
- Owed (does NOT retire): COVERAGE-CALIBRATED intervals + the AT-SCALE (large-fixture,
  exact-infeasible) comparator leg (DRAC). doc-25 V8.4 is the estimand leg only.

## Next (doc-25)

With V8.4's estimand leg discharged, the remaining doc-25 items are all **compute-gated**: V8.4's
at-scale leg (DRAC), coverage-calibrated intervals, and the entire **V7 GPU stream** (G-B Float32,
G-A cross-device replicate, G-C real panel, G-D backend dispatcher [local], G-E close-out — DRAC
GPU). The engine-local matrix-free arc (V8.1–V8.5 + V8.4 estimand leg) is now complete; further
progress needs DRAC GPU/CPU time.
