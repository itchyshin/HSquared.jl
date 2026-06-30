#!/bin/bash
# Investigation: is the ~5% sigma_a2 (G[1,1]) downward bias seen in W1 Campaign 2 SYSTEMATIC
# (n-invariant -> an estimator concern) or small-sample (shrinks with n -> a validation-scale
# caveat that vanishes at production scale)? Base DGP G0=[1 .35;.35 .7] R0=[.8 .2;.2 .55],
# cold-start, swept over design size + one high-iterations variant. Reports the G[1,1]
# bias/MCSE per point. TRIAGE; informs the V4 scoped-finish decision (no promotion).
#SBATCH --account=def-snakagaw_cpu
#SBATCH --job-name=w1_sa2bias
#SBATCH --time=5:00:00
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --output=/home/snakagaw/projects/def-snakagaw/HSquared.jl/sim/drac/results/%x_%j.out
set -uo pipefail
export JULIA_DEPOT_PATH=$HOME/projects/def-snakagaw/julia_depot
export OPENBLAS_NUM_THREADS=2 OMP_NUM_THREADS=2 JULIA_NUM_THREADS=1
module load julia/1.10.10
cd $HOME/projects/def-snakagaw/HSquared.jl
mkdir -p sim/drac/results/w1_sa2bias

# point: label nsire ndam noffspring iterations nseeds
POINTS=(
  "n80_it5k 8 16 56 5000 30"
  "n160_it5k 16 32 112 5000 30"
  "n400_it5k 40 80 280 5000 30"
  "n800_it5k 80 160 560 5000 20"
  "n400_it20k 40 80 280 20000 20"
)
echo "# sigma_a2 (G[1,1]) bias vs design size + iterations (base DGP, cold-start)"
for p in "${POINTS[@]}"; do
  set -- $p; LBL=$1; NS=$2; ND=$3; NO=$4; IT=$5; NSEED=$6
  SEEDS=$(seq -s, 20260629 $((20260629 + NSEED - 1)))
  OUT=sim/drac/results/w1_sa2bias/${LBL}.out
  julia --project=. sim/phase4_multivariate_reml_recovery.jl --seeds=$SEEDS \
    --nsire=$NS --ndam=$ND --noffspring=$NO --records=3 --iterations=$IT \
    --cold-start=true --gate=aggregate --cell=$LBL > "$OUT" 2>&1 || true
  Q=$((NS + ND + NO))
  echo "$LBL q=$Q it=$IT seeds=$NSEED :: $(grep -E '^  G\[1,1\]' "$OUT" | head -1) :: $(grep -E '^  converged=' "$OUT" | head -1)"
done
echo "SA2BIAS DONE"
