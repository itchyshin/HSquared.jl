# H² twin A07 — S5 frozen gate run on Totoro — 2026-09-01

Runs the frozen S5 `fit_matrix_free_reml` tail-scale known-truth recovery gate, which
had been pre-declared and frozen but never executed. Result document:
`docs/dev-log/recovery-checkpoints/2026-09-01-f6-matfree-tail-recovery-result.md`.

## Command (evidence of record — Julia 1.10.10)

```sh
cd ~/hsq_work/h2-a07-s5-20260901
export OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1
julia --project=. sim/phase_s5_matfree_tail_recovery_gate.jl a07_s5_recovery.tsv
```

- Host Totoro, single-core (384 available; D-143 ≤150 cap not approached)
- `julia=1.10.10 threads=1 OPENBLAS_NUM_THREADS=1 SMOKE=false`
- START 17:42:28 −0600 → END 18:27:07 −0600 (**44 min 39 s**)
- Compute approval: G0 blanket proceed (D-139), `~/local-scratch/h2-twin-g0-approval.md`

Outcome: **OVERALL GATE PASS** (`LegA=true LegX=true`), exit 0.

| Leg | Criterion | Bound | Observed | Verdict |
|-----|-----------|-------|----------|---------|
| A | A1 mean rel.err vs truth (both components) | ≤ 0.05 | 0.0016 / 0.0007 | PASS |
| A | A2 NON_GRACEFUL | 0/48 | 0/48 | PASS |
| A | A3 CAP_EXHAUSTED | ≤ 4/48 | 0/48 | PASS |
| X | mean \|reldiff\| vs exact at nprobe=64 | ≤ 0.05 | 0.0090 / 0.0052 | PASS |

Buckets: CONVERGED 48, CAP_EXHAUSTED 0, NON_GRACEFUL 0, ANOMALY_ITER_MISMATCH 0.
Iterations 52–62 against a cap of 200. Fill mean 582.4.

## Independent replication (same interpreter)

A second, concurrently launched invocation of the same frozen script on Julia 1.10.10
wrote `~/hsq_work/results/h2-a07-s5-20260901/s5_recovery.tsv`.

```sh
diff <(grep -E '^  (A|X) ' R1.log | sed 's/wall=[0-9.]*s//') \
     <(grep -E '^  (A|X) ' R2.log | sed 's/wall=[0-9.]*s//')
```

Outcome: **empty diff — all 56 per-seed rows identical**; the two `GATE_JSON` strings
are byte-equal. Same-version determinism confirmed, not assumed.

## Cross-version arm (NOT the verdict)

A third concurrent invocation on **Julia 1.12.6** produces different per-seed draws
(e.g. dgp 20269500: `sigma_a2` 1.0286 vs 0.9890; fill 582.5 vs 580.2). Expected —
`MersenneTwister` streams are not version-portable for this fixture, as the script's
own manifest states. Tracked as a cross-version robustness arm, excluded from the
pre-declared verdict. Adjudication: `~/local-scratch/h2-a07-s5-run-adjudication.md`.

## Artifacts

- In repo: `sim/drac/results/s5_matfree_tail_recovery_20260901.tsv`
- Off repo: `~/local-scratch/receipts/h2-a07-s5-20260901/` (both logs, both TSVs)
- On Totoro: `~/hsq_work/h2-a07-s5-20260901/`, `~/hsq_work/results/h2-a07-s5-20260901/`

## Claim boundary

Promotes nothing. `public_covered_count` stays **5**. No `validation_status` row flips.
G10 S3 stays unsigned — Shinichi signs. Discharges validation-debt item (1) for
`V1-MATFREE-REML`; narrows item (3) at q = 25,000 only; S6 and S7 remain open.
