# Plan / receipt bank: speed12 end-of-arc e2e walls

Date: 2026-09-23
Lane: `claude/lane-speed12-20260919` @ `fc3fc938`
Script: `sim/e2e_wall_receipts.jl`
TSV: `sim/results/e2e_wall_receipts_fc3fc938.tsv`

## Goal

Attest ≥5 (aim 10) before/after walls across kinds, converting S1/S2 kernel
wins into fit / post-fit receipts where a full wired SelectedInversion path
does not yet exist in `src/`.

## Before/after pairs (column `pair`)

| pair | meaning |
|---|---|
| historical_vs_now | 2026-06-20 cpu_fit baseline vs this-run |
| dense_vs_selinv | dense PEV vs selinv PEV |
| kernel_a_vs_c | Takahashi arm a vs SelectedInversion arm c (S2) |
| dense_vs_sparse_me | dense NelderMead multi-effect vs sparse AI-REML |
| projected_selinv | measured / S1 fit proxy × S2 S_c (src/ NOT wired) |
| measured_after_only | after wall only (no paired before) |
| measured_now | current wall; speedup 1.0 by construction |

## Cell table

| cell | kind | before (s) | after (s) | speedup | Totoro |
|---|---|---:|---:|---:|:---:|
| animal_reml_halfsib_q500 | animal_REML | 0.0230 | 0.0415 | 0.6× | N |
| animal_reml_halfsib_q2000 | animal_REML | 0.0840 | 0.1245 | 0.7× | N |
| animal_reml_halfsib_q8000 | animal_REML | 0.3340 | 0.4141 | 0.8× | N |
| postfit_pev_q500 | post_fit_uncertainty | 0.0125 | 0.0005 | 27.1× | N |
| postfit_pev_q500_selinv_vs_hist | post_fit_uncertainty | 0.0002 | 0.0005 | 0.4× | N |
| multi_effect_K2_q500_sparse_mac | multi_effect | n/a | 0.0077 | n/a | N |
| multi_effect_K3_q1000_sparse_mac | multi_effect | n/a | 0.0554 | n/a | N |
| animal_reml_halfsib_q20000_large | large_pedigree | 0.1275 | 0.1275 | 1.0× | N |
| animal_reml_f0adv_q5000_fill150_projected | animal_REML | 27.948 | 0.293 | 95.3× | N |
| selinv_kernel_mac_f0adv_q20k_fill150 | sparse_selinv | 236.894 | 0.833 | 284.4× | N |
| selinv_kernel_totoro_f0adv_q20k_fill471 | sparse_selinv | 1211.638 | 4.030 | 300.6× | Y |
| animal_reml_f0adv_q20k_fill471_projected | large_pedigree | 1211.638 | 4.030 | 300.6× | Y |
| multi_effect_K3_q1000_totoro | multi_effect | 26.928 | 0.0409 | 658.4× | Y |
| multi_effect_K3_q5000_totoro_sparse | multi_effect | n/a | 1.833 | n/a | Y |
| large_pedigree_K1_q20000_totoro | large_pedigree | n/a | 0.0859 | n/a | Y |
| large_pedigree_K1_q50000_totoro | large_pedigree | n/a | 0.301 | n/a | Y |

16 attested cells. Kinds covered: animal_REML, sparse_selinv, post_fit_uncertainty,
multi_effect, large_pedigree.

## Honesty fences

- Historical animal REML "speedups" <1× are host/noise (2026-06-20 laptop vs this
  Mac). Not a regression claim.
- Projected_selinv rows assume SelectedInversion replaces the selinv section
  only; `src/` is unchanged; package Project.toml untouched (G2.3).
- High-fill wins (95×–300×) apply only where selinv dominates (S1 share ≈99%).
  On benign halfsib (share ≈12%, S2 S_c ≪ 1) SelectedInversion is a loss.
- Multi-effect Totoro dense-vs-sparse confounds optimizer (NelderMead vs AI)
  with linear algebra; disclosed in phase5 predeclaration.
- Live q=20k halfsib fit segfaulted once this session; S1 instrumented proxy used.

## Twin R (`hsquared`)

No parallel wall-receipt script under `hsquared/sim` or `hsquared/bench`.
R lane holds live-parity scripts only. Honest: **no R twin before/after walls**.

## SHA pins

| artifact | SHA |
|---|---|
| this TSV / script tip | fc3fc938 |
| S1 sections TSV | c8cf8e05 |
| S2 Mac selinv grid | 9be11566 |
| S2 Totoro fill471 | b68bde5a |
| phase5 sparse/dense | 2026-07-02 Totoro run (committed TSV) |
| cpu_fit historical | 2026-06-20 baseline note |

## Run

```sh
env JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 \
  julia --project=. sim/e2e_wall_receipts.jl
```
