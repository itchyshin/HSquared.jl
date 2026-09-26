# Check-log: 2026-09-26 #366 Totoro S5 N=2000 bank

## Goal

Bank design-58 sparse K-effect / summed-ratio coverage at N=2000
(interior + low_pe + near_pe + near_va) under the overnight fence:
no covered flip, no version bump, `public_covered_count` stays 7,
claim class directional-conservative-bank.

## Commands

```sh
# Lane: ~/local-scratch/lanes/HSquared.jl-coverage-366-n2000
# rsync → totoro:~/hsq_work/HSquared-coverage-366-n2000
# rsync → narval:~/projects/def-snakagaw/HSquared.jl-coverage-366-n2000
# instantiate both remotes; Totoro needed Optim (first launch failed)

# Totoro (completed)
export K366_S5_GO=1 JULIA_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
bash sim/k366_totoro_n2000.sh
# START 2026-09-25T18:13:15 → END 18:13:37 MDT; 2001 replicate lines
bash sim/k366_totoro_n2000_nearbound.sh
# START 18:13:37 → END 18:14:39 MDT; 6001 replicate lines

# DRAC Narval (submitted; still PENDING Priority at bank)
K366_S5_GO=1 K366_REPO_ROOT=$HOME/projects/def-snakagaw/HSquared.jl-coverage-366-n2000 \
  sbatch --export=ALL,K366_S5_GO=1,K366_REPO_ROOT sim/drac/k366_coverage_n2000.sbatch
# job 4003782
K366_S5_GO=1 K366_REPO_ROOT=$HOME/projects/def-snakagaw/HSquared.jl-coverage-366-n2000 \
  sbatch --export=ALL,K366_S5_GO=1,K366_REPO_ROOT sim/drac/k366_coverage_n2000_nearbound.sbatch
# job 4003783

# local rsync of Totoro artifacts (quote the remote glob)
rsync -az 'totoro:~/hsq_work/HSquared-coverage-366-n2000/docs/dev-log/recovery-checkpoints/2026-09-26-k-effect-coverage-366-s5-totoro-n2000*' \
  docs/dev-log/recovery-checkpoints/
```

## Artifacts

- Combined summary: `docs/dev-log/recovery-checkpoints/2026-09-26-k-effect-coverage-366-s5-totoro-n2000-combined-summary.tsv`
- Receipt: `…-s5-totoro-n2000-receipt.md`
- Interior + nearbound summary / replicates / logs

## Claim boundary

Host of record is Totoro. DRAC is submitted provenance, not yet a completed
bank. Status stays experimental 0.9.0. No nominal calibration claim.
