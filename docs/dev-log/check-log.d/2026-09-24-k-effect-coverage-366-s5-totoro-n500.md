# Check-log: 2026-09-24 #366 Totoro S5 triage N=500

## Commands

```sh
# Contention check (Totoro): no phase3_k_effect / k366 jobs from us
pgrep -af 'phase3_k_effect|k366' || true

# Rsync lane → Totoro, then:
cd /home/snakagaw/hsq_work/HSquared-coverage-366
export K366_S5_GO=1 JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1
export JULIA_BIN=/home/snakagaw/.juliaup/bin/julia
taskset -c 0-3 env K366_S5_GO=1 JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 JULIA_BIN="$JULIA_BIN" \
  bash sim/k366_totoro_n500.sh
# outcome: START 2026-09-24T11:31:07 → END 11:32:08 MDT (61 s wall)
# affinity at launch: julia current affinity list 0-3; PSR in 0–3
# summary + replicates written under docs/dev-log/recovery-checkpoints/
```

## Artifacts

- Summary: `docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-s5-totoro-n500-summary.tsv`
- Replicates: `...-s5-totoro-n500-replicates.tsv` (500 data rows + header)
- Receipt: `...-s5-totoro-n500-receipt.md`
- Log: `...-s5-totoro-n500.log`

## Notes

Owner authorized Totoro · N=500 triage only. STOP held: no N=2000, no DRAC.
Fences: experimental 0.9.0; `public_covered_count` stays 7; no covered flip.
