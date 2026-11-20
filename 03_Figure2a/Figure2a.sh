#!/usr/bin/env bash
#SBATCH --job-name=Figure2a
#SBATCH --array=1-100
#SBATCH --mem=2G
#SBATCH --time=7-00:00:00
#SBATCH --output=%x-%A_%a.out
set -euo pipefail
K=${K:-1000}; Nc=${Nc:-$((5*K))}; S=${S:--0.0025}; H=${H:-0.5}
MU=${MU:-1e-5}; RHO=${RHO:-0.5}; L=${L:-1000}
R=${R:-1}; D=${D:-1}; ENV_SD=${ENV_SD:-0.25}; MODE=${MODE:-Bernoulli}
GENERATIONS=${GENERATIONS:-30000}; TRACK_START=${TRACK_START:-10001}; TRACK_END=${TRACK_END:-15000}
SEED=${SEED:-${SLURM_ARRAY_TASK_ID:-1}}
SCRIPT_DIR=${SCRIPT_DIR:-${SLURM_SUBMIT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}}
OUT_ROOT=${OUT_ROOT:-$SCRIPT_DIR/figure2a_results}
case "$MODE" in
 Bernoulli) rank=F;;
 Ranked) rank=T; D=0; R=1; ENV_SD=0;;
 *) echo 'MODE must be Bernoulli or Ranked' >&2; exit 1;;
esac
run="$OUT_ROOT/${MODE}_K${K}_Nc${Nc}_s${S}_h${H}_mu${MU}_rho${RHO}_L${L}_R${R}_D${D}_E${ENV_SD}_G${GENERATIONS}_T${TRACK_START}-${TRACK_END}_Seed${SEED}"
mkdir -p "$OUT_ROOT"; mkdir "$run"; run=$(cd "$run" && pwd)
"${SLIM_BIN:-slim}" -s "$SEED" -d "K=$K" -d "candidateNo=$Nc" -d "selCoeff=$S" -d "domCoeff=$H" -d "Mu=$MU" -d "rho=$RHO" -d "chromLength=$L" -d "Rf=$R" -d "Df=$D" -d "EnvSD=$ENV_SD" -d "rankMode=$rank" -d "generations=$GENERATIONS" -d "trackStart=$TRACK_START" -d "trackEnd=$TRACK_END" -d "pathto=\"$run\"" "$SCRIPT_DIR/Figure2a.slim"
