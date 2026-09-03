#!/bin/bash
# NOT ARMED — template only. Do not sbatch until a later G0 names a SHA,
# a fir window, and a --time from a Totoro/fir 1-task seff.
# C1-ext H1/H3 coverage (doc-34 §10). NEW TSV. Does not mutate C1.
#
#SBATCH --job-name=c1ext-h1h3
#SBATCH --account=def-snakagaw_cpu
#SBATCH --time=8:00:00
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --array=1-20
#SBATCH --output=sim/drac/results/c1ext_%A_%a.out
#
# Frozen (must match the ADEMP predeclaration):
#   seed stride = 40009
#   module load julia/1.10.10
#   OPENBLAS_NUM_THREADS=1
#   --mode=confirm --reps=100  (20 tasks × 100 = 2000/cell target)
#
# Submit only after smoke + seff. Never on GitHub Actions.

set -euo pipefail
echo "REFUSING: this sbatch is NOT ARMED (2026-09-03 C1-ext scaffold)."
echo "See docs/dev-log/recovery-checkpoints/2026-09-03-c1-ext-h1-h3-ademp-predeclaration.md"
exit 78
