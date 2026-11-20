# Figure 2a: distinct rivals and population-wide ranking

Requires SLiM 4.3.0, Bash, and R with `data.table` and `ggplot2`. This module is separate from the main simulation/analysis pipeline. It records only mutation events required for Figure 2a, plus run metadata and a completion marker. No personal paths or scheduler account settings are included.

## Simulation

From this directory, submit the manuscript-caption treatments:

```bash
for d in 1 2 5 10 20 50 100; do
  S=-0.001 R=1 D=$d ENV_SD=0.25 sbatch Figure2a.sh
done
MODE=Ranked S=-0.001 sbatch Figure2a.sh
```

Each array uses seeds 1–100. For a local run replace `sbatch` with `bash` and set `SEED` as needed. The launcher refuses to overwrite existing run directories. `SLIM_BIN`, `SCRIPT_DIR` and `OUT_ROOT` can be overridden. Load SLiM using your own environment/module system before running. SLURM resource requests are editable.

Defaults: K=1000 founders, Nc=5K candidates, S=-0.001, H=0.5, MU=1e-5, RHO=0.5, L=1000, R=1, D=1, ENV_SD=0.25, GENERATIONS=30000, TRACK_START=10001, TRACK_END=15000. All are environment variables. Bernoulli mode requires even K and Nc, positive odd R and D smaller than both K and Nc (founders are also assessed). Ranked mode ignores R/D/noise and directly orders genetic fitness with random tie-breaking. Both use gamma prizes (mean 1, shape 0.245) and weighted outcrossing. The ranked branch is newly implemented from the manuscript description, not verified against an original ranked simulation script.

## Hard-selection calibration

Use the main repository's HardSelection scripts and `01_Process_simulations.R` to create `threshold_by_seed.csv`. Run a hard reference grid at identical K, Nc, h, mutation rate, recombination rate, length and biological tracking window. Include s=0 and enough negative s values to bracket all competitive probabilities (e.g. 0, -0.001, -0.0025, -0.005, -0.01, -0.05). Do not use the competitive data as its own reference.

```bash
Rscript Analyse_Figure2a.R figure2a_results ../analysis_results/threshold_by_seed.csv figure2a_analysis
```

The analysis counts distinct registered mutations with any recorded q >= 0.05, including fixation, and divides by the number registered, pooled across seeds. It uses a monotone isotonic hard reference and linear inverse interpolation, without extrapolation. It resamples whole replicate simulations independently within each treatment (2000 iterations by default, `N_BOOT` override); intervals require >=95% identifiable draws. Bars are pooled point estimates, not bootstrap means. No neutral normalisation is applied. Outputs: manifest, replicate counts, hard reference, calibration, plot data CSV, PDF and PNG. Missing categories, incomplete runs and unavailable intervals are reported. The hard reference is assumed to have been generated using the main pipeline's completed-run checks.

Plot defaults match the manuscript caption; override `PLOT_S`, `PLOT_H`, `PLOT_ENV_SD`, `PLOT_R`, `PLOT_K`, `PLOT_NC`, `PLOT_MU`, `PLOT_RHO`, `PLOT_L`, `PLOT_GENERATIONS`, `PLOT_TRACK_START`, `PLOT_TRACK_END` as needed. All non-neutral treatments are calibrated before plotting.

## Smoke test

```bash
K=20 Nc=100 L=100 MU=0.001 D=5 GENERATIONS=30 TRACK_START=5 TRACK_END=10 bash Figure2a.sh
```

For a full analysis smoke test, run matching hard references with the same short settings and set the corresponding PLOT variables. Small runs may not yield identifiable calibration, which is reported rather than extrapolated. Bash syntax checked; SLiM and R runtime testing remains necessary.
