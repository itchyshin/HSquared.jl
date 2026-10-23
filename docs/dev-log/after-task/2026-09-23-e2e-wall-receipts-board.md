# After-task: 2026-09-23 e2e wall receipts for board H² `needs_run`

## Goal

Convert post-#371 kernel / post-fit wins into ≥5 end-to-end fit / post-fit wall
receipts that match `three-package-speed-board.md` HSquared cell_ids, on tip
`e05fcf0e`. Claim H² lease only; no DRM / GLLVM source edits.

## Outcome

Six cells banked in `sim/results/e2e_wall_receipts_e05fcf0e.tsv` via
`sim/e2e_wall_receipts.jl --core` (gene-drop halfsib DGP; converges).

| cell | kind | before (s) | after (s) | speedup | Totoro |
|---|---|---:|---:|---:|:---:|
| hsq-animal-fit-q500 | animal_REML | 0.0230† | 0.0049 | 4.7×† | N |
| hsq-animal-fit-q2000 | animal_REML | 0.0840† | 0.0098 | 8.6×† | N |
| hsq-pev-reliability-q500 | post_fit_uncertainty | 0.0125‡ | 0.0003 | 40.2× | N |
| hsq-multi-effect-K2-q500 | multi_effect | 2.5522 | 0.0036 | 702.2× | N |
| hsq-animal-fit-q10000 | animal_REML | n/a | 0.0312 | n/a | N |
| hsq-animal-fit-q20000-large | large_pedigree | n/a | 0.0402 | n/a | N |

† Soft context only: June 2026-06-20 `cpu_fit` walls used deterministic near-null
`y` (σ_a→0 / iteration_limit). This run uses gene-drop `y` (same pedigree
geometry). Not a same-DGP speedup claim.

‡ Dense PEV before = banked 2026-06-20 wall. Live dense MME inverse hung in
OpenBLAS `dgetrf_parallel` / `exec_blas_async` under `OPENBLAS_NUM_THREADS=1` on
this host; skipped. Selinv after is live median-of-3.

Multi-effect dense-vs-sparse confounds NelderMead vs AI-REML with linear algebra
(disclosed in TSV note).

## Board flip owed (GLLVM lane owns the board file)

`docs/dev-log/plans/2026-09-23-three-package-speed-board.md` H² rows
`hsq-animal-fit-q500` / `q2000` / `q10000` / `hsq-pev-reliability-q500` stay
`needs_run` until the board owner pastes after=`e05fcf0e` and flips to
`has_receipt`. This PR does not edit GLLVM.jl.

Sibling PR #378 banks 16 speed12 / projected / phase5 cells under different
cell_ids on `fc3fc938`. Complementary evidence; different cell_ids from this board fill.

## Checks

```sh
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=. sim/e2e_wall_receipts.jl --core
# -> Wrote sim/results/e2e_wall_receipts_e05fcf0e.tsv  (6 cells)
```

No `Pkg.test()`: measurement-only, no `src/` change. No public README/NEWS speed claim.

## Rose

OK for banking absolute walls + honest pair columns. Blockers for any public
headline: † soft hist, ‡ banked dense, multi-effect estimator confound, Mac-only
(Totoro = N).
