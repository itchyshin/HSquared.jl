# After-task: 2026-09-23 Totoro e2e large walls (q10k + q20k)

## Goal

Re-time the two scale cells that #379 banked Mac-only
(`hsq-animal-fit-q10000`, `hsq-animal-fit-q20000-large`) on Totoro after
#378/#379. Board matrix already `has_receipt`; gap was Totoro=Y absolute walls.
Fence projected SelectedInversion (#378): still unwired in `src/`.

## Outcome

Two cells on tip `101aa483` (post-#379 merge), Totoro host, Julia 1.10.12,
`JULIA_NUM_THREADS=1` / `OPENBLAS_NUM_THREADS=1`, `taskset -c 0-15`.

| cell | Mac #379 after (s) | Totoro after (s) | Totoro |
|---|---:|---:|:---:|
| hsq-animal-fit-q10000 | 0.0312 | 0.0345 | Y |
| hsq-animal-fit-q20000-large | 0.0402 | 0.0477 | Y |

Absolute after only (same gene-drop DGP as #379). Not a Mac↔Totoro speedup
column: hosts differ (board §4.8). Soft hist † from #379 stays soft.

Evidence: `sim/results/e2e_wall_receipts_101aa483.tsv` (+ log twin under
`docs/dev-log/evidence/2026-09-23-totoro-e2e-large/`).

## Not run

- Projected SelectedInversion rows (`*_projected` in
  `e2e_wall_receipts_fc3fc938.tsv`): still unwired; fence holds.
- Smaller Mac-only #379 cells (q500/q2000/PEV/multi-effect): optional later;
  scale cells were the Totoro-preferred debt.

## Checks

```sh
# Totoro
taskset -c 0-15 env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia-1.10.12 --project=. sim/e2e_wall_receipts.jl --large
# Wrote sim/results/e2e_wall_receipts_101aa483.tsv  (2 cells)
```

No `src/` change. No public README/NEWS speed claim.

## Rose

OK to bank Totoro absolute walls beside Mac #379. Do not headline a cross-host
ratio. Projected selinv remains non-claim.
