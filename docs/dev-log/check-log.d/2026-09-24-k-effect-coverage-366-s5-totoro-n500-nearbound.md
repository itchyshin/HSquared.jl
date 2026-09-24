# Check-log: 2026-09-24 #366 Totoro S5 near-boundary N=500

## Commands

```sh
# Contention check (Totoro): no prior phase3_k_effect / k366 jobs
pgrep -af 'phase3_k_effect|k366' || true

# Rsync harness + launcher → Totoro, then:
cd /home/snakagaw/hsq_work/HSquared-coverage-366
export K366_S5_GO=1 JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1
export JULIA_BIN=/home/snakagaw/.juliaup/bin/julia
taskset -c 0-3 env K366_S5_GO=1 JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 JULIA_BIN="$JULIA_BIN" \
  bash sim/k366_totoro_n500_nearbound.sh
# outcome: START 2026-09-24T11:44:10 → END 11:46:16 MDT (126 s wall)
# affinity: taskset -c 0-3; julia current affinity list 0-3
# cells: low_pe,near_pe,near_va via --cell=main_rest
```

## Artifacts

- Summary: `docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-s5-totoro-n500-nearbound-summary.tsv`
- Combined (interior+rest): `...-s5-totoro-n500-combined-summary.tsv`
- Replicates: `...-s5-totoro-n500-nearbound-replicates.tsv` (1500 data rows + header)
- Receipt: `...-s5-totoro-n500-nearbound-receipt.md`
- Log: `...-s5-totoro-n500-nearbound.log`

## Notes

Owner authorized Totoro · N=500 triage. Near-boundary refusal rates reported
(near_pe 0.458, near_va 0.468). STOP held: no N=2000, no DRAC.
Fences: experimental 0.9.0; `public_covered_count` stays 7; no covered flip.
Claim class: directional-conservative-bank.
