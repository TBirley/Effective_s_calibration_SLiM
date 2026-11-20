#!/usr/bin/env bash
set -euo pipefail
root=$(cd "${1:-results}" && pwd)
mkdir -p "${2:-analysis_results}"
out=$(cd "${2:-analysis_results}" && pwd)
cd "$(dirname "$0")"
for script in 0[1-7]_*.R; do Rscript "$script" "$root" "$out"; done
