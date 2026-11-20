#!/usr/bin/env bash
#SBATCH --job-name=HardSelection
#SBATCH --array=1-100
#SBATCH --mem=2G
#SBATCH --time=7-00:00:00
#SBATCH --output=%x-%A_%a.out
#SBATCH --error=%x-%A_%a.err
set -euo pipefail

# Override defaults using environment variables, e.g. K=100 Nc=500 sbatch ...
K=${K:-1000}
Nc=${Nc:-$((5*K))}
S=${S:--0.001}
H=${H:-0.5}
MU=${MU:-1e-5}
RHO=${RHO:-0.5}
L=${L:-1000}
GENERATIONS=${GENERATIONS:-30000}
TRACK_START=${TRACK_START:-10001}
TRACK_END=${TRACK_END:-15000}
SEED=${SEED:-${SLURM_ARRAY_TASK_ID:-1}}
SLIM_BIN=${SLIM_BIN:-slim}
# SLURM copies scripts to a spool directory; submit from the repository directory.
SCRIPT_DIR=${SCRIPT_DIR:-${SLURM_SUBMIT_DIR:-$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}}
OUT_ROOT=${OUT_ROOT:-$SCRIPT_DIR/results}
run_id="K${K}_Nc${Nc}_s${S}_h${H}_mu${MU}_rho${RHO}_L${L}_G${GENERATIONS}_T${TRACK_START}-${TRACK_END}_Seed${SEED}"
run_dir="$OUT_ROOT/HardSelection/$run_id"
mkdir -p "$(dirname "$run_dir")"
# Refuse to overwrite existing results, including partial runs.
mkdir "$run_dir" || { echo "Output already exists: $run_dir" >&2; exit 1; }
run_dir=$(cd "$run_dir" && pwd)
for folder in Output_Load Output_SFS Output_Vk Output_TMs_10-15k Output_MaxQ_10-15k; do
    mkdir -p "$run_dir/$folder"
done
"$SLIM_BIN" -s "$SEED" \
    -d "K=$K" -d "candidateNo=$Nc" -d "selCoeff=$S" -d "domCoeff=$H" \
    -d "Mu=$MU" -d "rho=$RHO" -d "chromLength=$L" \
    -d "generations=$GENERATIONS" -d "trackStart=$TRACK_START" -d "trackEnd=$TRACK_END" \
    -d "pathto=\"$run_dir\"" "$SCRIPT_DIR/HardSelection.slim"
