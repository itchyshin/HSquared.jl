# #366 S5 launch menu — N=2000 authorized (2026-09-25 overnight)

**Status:** Totoro and DRAC N=2000 interior + main_rest **banked**
2026-09-25 evening (`…-totoro-n2000*` and `…-drac-n2000*`). Narval
4003782/4003783 COMPLETED. Stay 0.9.0 / count 7; no flip. Claim class
stays **directional-conservative-bank**.

**Cells:** sparse — interior `(0.3,0.2,0.5)`; `main_rest` =
`low_pe,near_pe,near_va`. N=2000 filenames use `2026-09-26-…-n2000-…`.

**Safety:** every script exits unless `K366_S5_GO=1` is set in the environment.

## Ready-to-fire combos

| Combo | Script | One-liner (after owner yes) |
| --- | --- | --- |
| Totoro N=500 | `sim/k366_totoro_n500.sh` | `K366_S5_GO=1 bash sim/k366_totoro_n500.sh` |
| Totoro N=2000 interior | `sim/k366_totoro_n2000.sh` | `K366_S5_GO=1 bash sim/k366_totoro_n2000.sh` |
| Totoro N=2000 main_rest | `sim/k366_totoro_n2000_nearbound.sh` | `K366_S5_GO=1 bash sim/k366_totoro_n2000_nearbound.sh` |
| DRAC N=500 | `sim/drac/k366_coverage_n500.sbatch` | `K366_S5_GO=1 sbatch --export=ALL,K366_S5_GO=1 sim/drac/k366_coverage_n500.sbatch` |
| DRAC N=2000 interior | `sim/drac/k366_coverage_n2000.sbatch` | `K366_S5_GO=1 K366_REPO_ROOT=$HOME/projects/def-snakagaw/HSquared.jl-coverage-366-n2000 sbatch --export=ALL,K366_S5_GO=1,K366_REPO_ROOT sim/drac/k366_coverage_n2000.sbatch` |
| DRAC N=2000 main_rest | `sim/drac/k366_coverage_n2000_nearbound.sbatch` | same env + `sbatch …/k366_coverage_n2000_nearbound.sbatch` |

Harness CLI (all four call this):

```sh
OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 \
  julia --project=. sim/phase3_k_effect_coverage.jl \
  --mode=main --host=<Totoro|DRAC> --reps=<500|2000> --cell=interior --resume=true \
  --out=docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-s5-<host>-n<N>-replicates.tsv \
  --summary=docs/dev-log/recovery-checkpoints/2026-09-24-k-effect-coverage-366-s5-<host>-n<N>-summary.tsv
```

## Wall-clock estimates (AGENT-INFERRED from smoke)

Smoke evidence (Totoro, N=50, interior, OPENBLAS=1, serial):

- Wall START→END: **82 s** (2026-09-24T10:58:34 → 10:59:56 MDT)
- Package precompile: **~40 s** (one-time cold)
- Remaining after precompile: **~42 s / 50 reps ≈ 0.84 s/rep** (includes
  first-rep JIT ~6.4 s; most later reps print `0.0s` at `%.1f` so true
  steady-state is likely faster than 0.84 s — treat 0.84 as a **conservative
  serial budget**, not a precision timer)

| Combo | AGENT-INFERRED serial wall (warm) | With cold precompile | Notes |
| --- | ---: | ---: | --- |
| Totoro N=500 | ~7 min | ~8–12 min | interactive; no queue |
| Totoro N=2000 | ~28 min | ~30–45 min | still Totoro-class (≪150 cores) |
| DRAC N=500 | ~7–15 min compute | + queue wait | single task; `--time=1:00:00` |
| DRAC N=2000 | ~30–60 min compute | + queue wait | single task; `--time=2:00:00` |

Playbook routing (`COMPUTE-PLAYBOOK`): Totoro = fast CPU ≤150 cores now; DRAC =
replicated multi-seed / provenance. This S5 cell is **one cell × N serial
fits** — Totoro is enough on wall-clock; DRAC is for queue provenance if the
owner prefers it.

**Fences:** no covered flip · no version bump · `public_covered_count` stays 7.
#388/#394 already merged (N=500). This menu is the N=2000 bank.
