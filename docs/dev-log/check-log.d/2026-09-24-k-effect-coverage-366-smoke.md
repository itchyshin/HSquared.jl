# Check-log — 2026-09-24 #366 Totoro smoke

## Commands

```sh
# Local (Mac) dry-run 1-rep
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
  julia --project=. sim/phase3_k_effect_coverage.jl --mode=smoke --host=local-dry --reps=1 \
  --out=/tmp/k366-dry-reps.tsv --summary=/tmp/k366-dry-sum.tsv --resume=false
# outcome: fit=1 se=1 cover_t=1 (~1.5s after precompile)

# Totoro smoke N=50 (host choice: Totoro)
bash /home/snakagaw/hsq_work/run_k366_smoke.sh
# log: docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-smoke.log
# outcome: 50 reps complete; summary TSV written; see smoke-receipt.md
```

## Artifacts

- `docs/design/58-k-effect-coverage-predeclaration.md` @ commit `f046c228`
- replicates / summary / receipt under `docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-smoke-*`

## Notes

Manifest on Totoro warned Julia 1.10 → 1.12; instantiate + precompile succeeded. Resolve Manifest before any heavy campaign if staying on 1.12.
