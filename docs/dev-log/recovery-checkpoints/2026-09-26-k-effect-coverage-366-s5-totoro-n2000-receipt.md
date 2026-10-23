# #366 K-effect coverage: Totoro N=2000 bank receipt

Date: 2026-09-25 (evening America/Denver; filenames 2026-09-26)  
Host of record: **Totoro** (completed). DRAC Narval jobs 4003782 (interior) and
4003783 (main_rest) were submitted the same evening and were still PENDING
Priority at bank time. Do not cancel them.  
Cores: `JULIA_NUM_THREADS=1` · `OPENBLAS_NUM_THREADS=1` · serial reps  
Julia: 1.12.6 (`~/.juliaup/bin/julia`) after `Pkg.instantiate()` on the
rsync tree `~/hsq_work/HSquared-coverage-366-n2000`.

## Command

```sh
# Totoro after rsync + instantiate
export K366_S5_GO=1 JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1
export JULIA_BIN=/home/snakagaw/.juliaup/bin/julia
nohup bash -lc 'K366_S5_GO=1 bash sim/k366_totoro_n2000.sh &&
  K366_S5_GO=1 bash sim/k366_totoro_n2000_nearbound.sh' \
  > docs/dev-log/recovery-checkpoints/2026-09-26-k-effect-coverage-366-s5-totoro-n2000-wrapper.nohup.out 2>&1 &
```

Interior wall: 2026-09-25T18:13:15 → 18:13:37 MDT (22 s after instantiate).  
Near-boundary wall: 2026-09-25T18:13:37 → 18:14:39 MDT (62 s).  
Wrapper end: 2026-09-25T18:14:39-06:00.

## Predeclaration / SHA

- Design: `docs/design/58-k-effect-coverage-predeclaration.md`
- Branch tip at launch: `3426dd56` (`origin/main`)
- Seeds: `20260924001`…`20260926000` from the frozen seed lock
- Route: sparse `fit_multi_effect(:auto)` only · design 15/30/200×2
- Cells: interior `(0.3,0.2,0.5)`; `main_rest` =
  `low_pe` `(0.3,0.05,0.65)`, `near_pe` `(0.3,0.01,0.69)`,
  `near_va` `(0.01,0.3,0.69)`

## Coverage table (level 0.95)

| cell | target | n_eval | coverage | MCSE | n_refuse | refusal_rate |
| --- | --- | ---: | ---: | ---: | ---: | ---: |
| interior | Va | 1931 | 0.903 | 0.007 | 69 | 0.0345 |
| interior | Vpe | 1931 | 0.968 | 0.004 | 69 | 0.0345 |
| interior | Ve | 1931 | 0.940 | 0.005 | 69 | 0.0345 |
| interior | h2 | 1931 | 0.998 | 0.001 | 69 | 0.0345 |
| interior | t | 1931 | 0.954 | 0.005 | 69 | 0.0345 |
| low_pe | Va | 1423 | 0.869 | 0.009 | 577 | 0.2885 |
| low_pe | Vpe | 1423 | 0.963 | 0.005 | 577 | 0.2885 |
| low_pe | Ve | 1423 | 0.935 | 0.007 | 577 | 0.2885 |
| low_pe | h2 | 1423 | 1.000 | 0.000 | 577 | 0.2885 |
| low_pe | t | 1423 | 0.957 | 0.005 | 577 | 0.2885 |
| near_pe | Va | 1109 | 0.843 | 0.011 | 891 | 0.4455 |
| near_pe | Vpe | 1109 | 0.953 | 0.006 | 891 | 0.4455 |
| near_pe | Ve | 1109 | 0.928 | 0.008 | 891 | 0.4455 |
| near_pe | h2 | 1109 | 1.000 | 0.000 | 891 | 0.4455 |
| near_pe | t | 1109 | 0.959 | 0.006 | 891 | 0.4455 |
| near_va | Va | 1072 | 0.999 | 0.001 | 928 | 0.4640 |
| near_va | Vpe | 1072 | 0.949 | 0.007 | 928 | 0.4640 |
| near_va | Ve | 1072 | 0.950 | 0.007 | 928 | 0.4640 |
| near_va | h2 | 1072 | 0.762 | 0.013 | 928 | 0.4640 |
| near_va | t | 1072 | 0.964 | 0.006 | 928 | 0.4640 |

fit_ok = 2000/2000 on every cell. Claim class: **directional-conservative-bank**.
Interior Va is the softest interior point (0.903). Near-boundary refusal stays
first-class (near_pe 0.446, near_va 0.464). Near_va h2 stays 0.762 when formed.

N=500 precursor (same cells, same seeds prefix) is unchanged and still banked.

## Artifacts

- Combined: `2026-09-26-k-effect-coverage-366-s5-totoro-n2000-combined-summary.tsv`
- Interior summary / replicates / log
- Near-boundary summary / replicates / log
- Replicate row counts: interior 2000 + header; main_rest 6000 + header

## Fences held

- No version bump (stays 0.9.0); `public_covered_count` stays 7; no covered flip
- Claim class stays directional-conservative-bank; NOT nominal ~95% calibration
- Campaigns on Totoro / DRAC only (D-50); never GitHub Actions
- Clean local-scratch worktree only
