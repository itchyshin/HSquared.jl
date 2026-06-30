# After-task — V5 QTL threshold calibration gate: FAIL, banked negative (2026-06-30)

Per the maintainer's `/goal` (finish v0.5, auto-merge): ran the pre-declared genome-wide threshold
calibration gate. **GATE FAILED (anti-conservative). Banked as an honest NEGATIVE; nothing promoted.**
This finishes the v0.5 calibration-gate LEG — it does not reach v0.5 covered (which also needs an external
comparator + the R activation). Claude solo, branch `feat/2026-06-30-v5-qtl-threshold-calibration`.

## Live phase snapshot

- **As of 2026-06-30 (V5 threshold calibration gate FAIL — banked negative; branch `feat/2026-06-30-v5-qtl-threshold-calibration`, auto-merge; `main` @ `9705e25d`/#201).**
  Followed the genomic-REML covered close. A PRE-DECLARED type-I calibration gate
  (`sim/phase5_qtl_threshold_gate.jl`; predeclaration committed `55acc6ef` BEFORE the run) tested the
  LD-aware permutation genome-wide threshold: 20 seeds (n=300/m=200, nperm=2000, α=0.05) → mean empirical
  type-I **0.069** vs α 0.05 (bias +0.019 = **2.42·MCSE**), **GATE FAIL** in the ANTI-CONSERVATIVE
  direction. The `(1−α)` empirical-quantile threshold is too permissive at finite nperm — the calibrated
  path is the conservative add-one `genome_wide_pvalue` rule (exact) and/or larger nperm. Banked NEGATIVE:
  V5-MARKER-THRESHOLD stays `partial`/`experimental`, `gwas()` wording stays held, NOTHING promoted;
  `validation_status()` = 48 rows / covered = 7 UNCHANGED; public-covered FITTING = 1. **NEXT: a calibrated
  add-one-rule threshold gate + an external comparator (PLINK max(T)); v0.4 broader-DGP MV.** START HERE:
  this report.

## What changed

- NEW `sim/phase5_qtl_threshold_gate.jl` + `...-v5-qtl-threshold-gate-predeclaration.md` (predeclaration +
  FAIL result) — committed `55acc6ef` (predeclaration) → this slice (result + status edits).
- Evidence APPENDED (status UNCHANGED) to V5-MARKER-THRESHOLD across `validation_status.jl`,
  `validation-debt-register.md`, `capability-status.md`.

## Checks run and exact outcomes

- Gate: `julia sim/phase5_qtl_threshold_gate.jl` → 20/20 runs, GATE FAIL (mean type-I 0.069, 2.42·MCSE).
- `Pkg.test()` → **"Testing HSquared tests passed"** (exit 0); `validation_status()` = 48 rows / covered 7 /
  partial 37 — UNCHANGED (evidence-string append, no status flip); count-guard green.
- Documenter: unaffected (no `docs/src/` change).

## Public claim audit (Rose)

Real `rose-systems-auditor` audit → **PROMOTE** (clean banked negative; nothing to fix to merge). Verified
INDEPENDENTLY: (a) the failure is honestly recorded (FAIL/anti-conservative/type-I 0.069 stated plainly,
not softened); (b) the pre-registration is genuine — at commit `55acc6ef` the RESULT read "PENDING" and the
harness was fixed in the same commit; Rose **re-ran the harness** and reproduced the FAIL to the digit
(mean 0.0689, 2.42·MCSE); (c) NO status flip — `validation_status()` independently = 48 rows, V5-MARKER-THRESHOLD
stays `partial`/`experimental`, every owed item preserved, zero overclaim tokens; (d) honesty pins intact
(covered = 7 UNCHANGED, public-covered fitting = 1, `gwas()` held). The "add-one rule is the
calibrated/conservative path" claim was verified accurate (Phipson–Smyth exact permutation p, `src/genomic.jl:2424`).

## Tests of the tests

The gate is a genuine pre-registration (criteria fixed in `55acc6ef` before any seed ran; no relaxation).
The FAIL is in the EXPECTED direction (anti-conservative quantile at finite nperm) — a low-power result is
not at risk here: the bias is 2.42·MCSE, a clear signal, not a borderline non-rejection.

## What did not go smoothly

- The gate FAILED — but this is the designed-for outcome of a real test, not a process failure. A PASS would
  have been a (mildly surprising) green light; the FAIL correctly catches a known anti-conservatism.

## Known limitations

- One design point (n=300, m=200, one LD scheme), intercept-only null. The FAIL is specific to the
  `(1−α)` quantile rule at nperm=2000; it does NOT condemn the add-one rule (exact by construction).
- v0.5 covered remains owed: a calibrated threshold gate (add-one / higher-nperm), an external comparator
  (PLINK max(T)/GenABEL), and the R `marker_scan()`/`gwas()` activation (R-lane).

## Next actions

1. A pre-declared calibration gate on the conservative add-one `genome_wide_pvalue` decision rule (expected
   to control type-I at ≤ α by construction) — the constructive follow-up to this negative.
2. v0.4 broader-DGP MV recovery + the in-suite `sommer` test (alternative next slice).
