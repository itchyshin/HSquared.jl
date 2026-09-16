# 2026-09-03 — 0.8 S1 d3-contrast Totoro RESULT

**Not a covered flip.** `V4-FA` stays partial. Count stays **7**.

## Command (Totoro, Julia 1.10.0, 1 thread, pid 1720691)

```sh
~/hsq_work/julia-1.10.0/bin/julia --project=. sim/v08_fa_s1_diagnose.jl \
  --mode=fit --cell=d3-contrast
```

**exit 0** in ~31 s. TSV banked:
`docs/dev-log/recovery-checkpoints/2026-09-03-v08-s1-d3-contrast.tsv`

## Outcome

| seed | class | Δℓ | min(ψ̂) |
|---|---|---:|---:|
| 20260616 | heywood_boundary | +7.51 | 2.52e-7 |
| 20260619 | heywood_boundary | +10.52 | 1.47e-7 |
| 20260614 | ok_recovery (heywood_flag still true) | +7.31 | 5.37e-8 |

Zero `optimizer_miss`. Banked iteration counts reproduced (2151 / 2226 / 2362).
Write-up: `docs/dev-log/recovery-checkpoints/2026-09-03-v08-s1-d3-contrast.md`
