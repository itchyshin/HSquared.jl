# S5 — `fit_matrix_free_reml` tail-scale known-truth recovery gate — RESULT

**Run date:** 2026-09-01 (Totoro) · **Arc:** H² twin Block 1, A07 · **Verdict: GATE PASS**

Result document for the predeclaration in
`docs/dev-log/recovery-checkpoints/2026-08-04-f6-matfree-tail-recovery-predeclaration.md`.
The gate was frozen (script + predeclaration) on codex `33ab68f6` and had **never
been run**; the phase snapshot recorded it as "FROZEN, NOT RUN". This is the run.

**Promotes nothing.** `public_covered_count` stays **5**. No `validation_status` row
flips here. G10 S3 remains unsigned — Shinichi signs (G0 Q3).

---

## Provenance

| Item | Value |
|------|-------|
| Script | `sim/phase_s5_matfree_tail_recovery_gate.jl`, ported at `a0ffb86a` from codex `33ab68f6`; `fit_matrix_free_reml` ported at `f261165e` |
| Threshold | `A3_MAX_CAP_EXHAUSTED = 4`, fixed **blind and pre-run** at `4ad2c87b` (A08, G0 Q2) |
| Compute approval | G0 blanket proceed, `~/local-scratch/h2-twin-g0-approval.md` (D-139) |
| Host | Totoro, single-core, `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1` (D-143 cap not approached) |
| Interpreter | **Julia 1.10.10** — evidence of record |
| Artifact | `sim/drac/results/s5_matfree_tail_recovery_20260901.tsv` |
| Wall clock | Leg A 48 seeds ≈ 41 min (≈51 s/seed); + Leg X; end 18:27:07 −0600 |

No tuning: `nprobe`, `tol`, `pcg_tol`, `pcg_maxiter`, `iterations` left at
`fit_matrix_free_reml` defaults throughout, as the predeclaration requires.

## Leg A — tail-scale recovery (PRIMARY), q = 25,000, 48 seeds

```
bucket counts: CONVERGED=48  CAP_EXHAUSTED=0  NON_GRACEFUL=0  ANOMALY_ITER_MISMATCH=0  (of 48)
  sigma_a2   n=48  mean=1.0016 truth=1.00 bias=+0.0016 MCSE=0.0041 rel.err=0.0016
  sigma_e2   n=48  mean=1.0007 truth=1.00 bias=+0.0007 MCSE=0.0031 rel.err=0.0007
```

| Criterion | Bound | Observed | Verdict |
|-----------|-------|----------|---------|
| **A1** mean rel.err vs truth, graceful subset, both components | ≤ 0.05 | `sigma_a2` **0.0016**, `sigma_e2` **0.0007** | **PASS** |
| **A2** NON_GRACEFUL count | 0/48 | **0/48** | **PASS** |
| **A3** CAP_EXHAUSTED count | ≤ 4/48 | **0/48** | **PASS** |

**Leg A GATE (A1 ∧ A2 ∧ A3): PASS.**

Secondary, informational:

- Iterations to outcome: min 52, median 57, max 62 — against a cap of 200. The cap
  was never approached, let alone exhausted.
- Fill (nnz(L)/n): mean 582.4, min 571.4, max 596.5 — matches the August single-seed
  probe (583.3), so the adversarial generator reproduced its intended high-fill regime.
- Bias is **+0.0016 (0.39 MCSE)** and **+0.0007 (0.24 MCSE)**. At n = 48 the estimator's
  bias at this scale is not distinguishable from zero. On this realization the A1 margin
  is a factor of ~30 on `sigma_a2`; see the cross-version section below before quoting
  that margin, because it is realization-specific.
- The converged-only subset equals the graceful subset (all 48 converged), so the two
  A1 computations coincide — the taxonomy's (a)/(b) split never had to be exercised.
- `capreset(iterations=1000)` re-fit arm: not triggered (no CAP_EXHAUSTED seeds).
- `ANOMALY_ITER_MISMATCH`: **0**. The unanticipated fourth bucket the script was written
  to catch did not fire at this scale. That is a measurement, not proof it cannot fire.

## Leg X — estimator-agreement anchor, q = 2,000, 8 seeds

Mean `|signed relative difference|` of `fit_matrix_free_reml` against exact
`fit_ai_reml` on the same dataset per seed:

| Arm | `sigma_a2` | `sigma_e2` | Gates? |
|-----|-----------|-----------|--------|
| **nprobe = 64** (function default) | **0.0090** (sd 0.0118, max 0.0185) | **0.0052** (sd 0.0069, max 0.0120) | **yes — PASS** (≤ 0.05) |
| nprobe = 256 | 0.0062 | 0.0035 | no — informational |

All 8 seeds CONVERGED on both arms; 0 excluded, so no seed's reldiff was NaN-guarded
away. Iterations: nprobe=64 min 58 / median 61 / max 71; nprobe=256 min 57 / median 61
/ max 70.

The nprobe=256 arm is tighter than nprobe=64 on both components, in the direction
expected if the residual gap is Hutchinson probe noise rather than estimator bias.
This is consistent with that reading; it is not a test of it.

**Leg X GATE: PASS.**

## OVERALL GATE: PASS (Leg A ∧ Leg X)

```
GATE_JSON {"gate_pass":true,"version":"s5-draft-v2","smoke":false,...
  "A":{"pass":true,"pass_A1":true,"pass_A2":true,"pass_A3":true,"n_converged":48,
       "n_cap_exhausted":0,"n_non_graceful":0,"n_anomaly_iter_mismatch":0,
       "rel_sa":0.001552,"rel_se":0.000734,"q":25000,"fill_measured":582.36},
  "X":{"pass":true,"n":8,"nprobe":64,"mean_reldiff_sa":0.009,"mean_reldiff_se":0.005207}}
```

Full JSON in the TSV artifact's final line and in the run log.

## Determinism receipt (unplanned, retained)

Three agents independently launched this gate; adjudicated in
`~/local-scratch/h2-a07-s5-run-adjudication.md`. Two of the three used Julia 1.10.10
and their outputs are **byte-identical**: all 56 per-seed rows (48 Leg A + 8 Leg X)
match field-for-field with wall clock stripped, and the two `GATE_JSON` strings are
byte-equal. That is a stronger reproducibility statement than the predeclaration asked
for, obtained by accident and kept.

The third run used Julia 1.12.6 and diverges per seed, exactly as this fixture's own
manifest line predicts (`MersenneTwister` streams are not version-portable). It is a
**different realized fixture**, tracked separately as a cross-version robustness arm,
and is **not** part of this verdict. It is reported next, because it completed.

## Cross-version robustness arm — Julia 1.12.6 — also PASS (informational)

Same frozen script, same seeds, same defaults; different interpreter, therefore a
different realized fixture. Completed 2026-09-01 on Totoro.
Artifacts: `~/local-scratch/receipts/h2-a07-s5-20260901/R3-julia1.12.6-*`.

| Criterion | Bound | Julia 1.10.10 (record) | Julia 1.12.6 (arm) |
|-----------|-------|------------------------|--------------------|
| A1 rel.err `sigma_a2` | ≤ 0.05 | 0.0016 | **0.0142** |
| A1 rel.err `sigma_e2` | ≤ 0.05 | 0.0007 | **0.0020** |
| A2 NON_GRACEFUL | 0/48 | 0/48 | **0/48** |
| A3 CAP_EXHAUSTED | ≤ 4/48 | 0/48 | **0/48** |
| Leg X mean \|reldiff\| `sigma_a2` / `sigma_e2` | ≤ 0.05 | 0.0090 / 0.0052 | **0.0097 / 0.0050** |
| Buckets | — | 48 CONVERGED, 0 / 0 / 0 | **48 CONVERGED, 0 / 0 / 0** |
| Verdict | — | PASS | **PASS** |

**Two readings, and the honest one matters.**

The verdict is **robust to the RNG realization**: every criterion passes on both
interpreters, and the qualitative picture — all 48 seeds converge, nothing exhausts the
cap, nothing fails gracelessly — is identical. That is meaningfully stronger evidence
than one realization.

But the **A1 margin is not stable**: `sigma_a2` relative error is **0.0016 on one
realization and 0.0142 on the other, a factor of ~9**. Both are inside the 0.05 bound,
so the honest statement of margin across the two realizations we have is **~3.5×, not
~30×**. Anyone quoting the 1.10.10 number alone as "recovery to within 0.2%" would be
over-claiming a single fixture draw as an estimator property. Leg X, by contrast, is
stable across interpreters (0.0090 vs 0.0097), consistent with its residual being probe
noise rather than fixture-dependent.

This arm was not pre-declared and does not gate. It is recorded because it was measured,
and because it constrains the language the campaign may use about A1's margin.

## What this discharges, and what it does not

- **Discharges** `docs/design/validation-debt-register.md` item (1) for
  `V1-MATFREE-REML`: known-truth recovery in the high-fill, n-past-dense-eigen-cap
  regime, which had only ever been compared estimator-to-estimator.
- **Narrows** item (3) **at q = 25,000 only**. Nothing is shown above that scale.
- **Does not** discharge S6 (at-scale external comparator) or S7 (R bridge). S3's
  G10 evidence remains incomplete without them.
- **Does not** promote `fit_matrix_free_reml`. It stays experimental.
- **Does not** address interval coverage — this gate is point-estimate recovery only.

## Follow-up owed (not fixed here)

The frozen gate **records** its interpreter version but does not **pin** it. Three
agents reading the same frozen script reached for three different `julia` binaries and
two versions. Recommend an interpreter-version assertion in the script, or a required
version stated in the predeclaration. Not changed in this pass: editing a frozen gate
after its run is the "no post-hoc relaxation" violation the predeclaration forbids.
Owner call.
