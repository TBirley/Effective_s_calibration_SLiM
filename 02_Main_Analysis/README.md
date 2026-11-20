# Analysis of hard and competitive selection simulations

These scripts read the parameter manifests and tab-separated outputs of the consolidated SLiM 4.3.0 simulation package. They generate CSV plot data rather than attempting to reproduce the exact graphical layout. No personal paths or cluster settings are required.

## Usage

Install R and `install.packages("data.table")`. From this directory run:

```sh
bash run_all.sh ../results ../analysis_results
```

Or run individual scripts from this directory, in numerical order:

```sh
Rscript 01_Process_simulations.R ../results ../analysis_results
N_BOOT=2000 Rscript 02_Effective_selection.R ../results ../analysis_results
```

The first two positional arguments are the raw results root and output directory. Defaults are `results` and `analysis_results`. `SFS_GENERATION` defaults to 30000; `MAXQ_BIN_WIDTH` defaults to 0.005. All files are CSV. Scripts 03–06 may run independently after 01; 07 requires their outputs and 02. For smoke tests run individual stages, with `SFS_GENERATION` set to the test endpoint. The manuscript export is intentionally restricted to manuscript settings.


## Outputs and methods

- 01: manifest, observed replicate coverage and threshold counts per seed. Completed runs only; checks that every registered ID has exactly one MaxQ terminal record. Counts initial frequencies and fixation through MaxQ. No mutation-level pooling across seeds before counting. Missing runs are not zeros. Compare coverage against your intended parameter grid (normally 100 seeds); the script cannot infer absent treatments.
- 02: pooled crossing probabilities and raw/neutral-normalised calibration. Separate reference for each K, Nc, Mu, rho, chromosome length, h and observation window. Hard curve is decreasing isotonic regression followed by linear interpolation (plateaus averaged); no extrapolation. Independent replicate-level resampling within each treatment, including neutral controls; hard neutral bootstrap is shared with its reference curve. Percentile 95% intervals only when >=95% of draws are identifiable. Missing neutral controls leave adjusted results NA. Report n_valid and n_boot. A full hard reference grid including neutral and sufficiently strong deleterious s is required. The same reference is reused across competition regimes in a group. No CIs for differences between regimes are implied.
- 03: all load observations and replicate means/t intervals at each generation and stage. Fig1b uses mean_ind_relzLoad post-selection, not total potential load. Competition post-selection is weighted by realised gametic contributions in the next generation, as in the supplied simulation. Hard post-selection is the surviving cohort.
- 04: final pre-selection candidate SFS; 200 bins of width .005, last includes q=1. Zero bins retained for observed snapshots. Missing snapshots are warned and excluded; check replicate counts. Neutral control defaults to hard selection in 07.
- 05: raw Vk, per-seed time means, then treatment means and t intervals. Uses supplied Ne_from_Vk, not a new estimator. Table S2 averages treatment means equally. Check coverage, especially if some treatments have fewer seeds.
- 06: per-seed MaxQ histograms and mean density with t intervals. Zero bins retained; zero-mutation replicates have undefined density and are excluded. Log plotting should omit zero densities, not add an arbitrary pseudocount. These are histogram densities, not necessarily the exact smoothing of the archived figures.
- 07: manuscript CSV subsets, named by figure/panel/table. Inspect empty files and coverage before plotting. Fig S1 requires varying K at fixed Nc=5000. Fig S2 exports calibrated hard-reference requests and available distributions; a nearest available hard s is a diagnostic only, not a calibrated match. Run hard simulations at the requested s (or the archived rounded reference s) and select their distributions for final plotting. Fig S3 defaults to s=-.0025 and D1/R9; verify the intended hard reference and assigned s against archived runs. Fig S7 uses raw Nc=25000 and adjusted smaller sizes in panel c, with both methods in a/b. Table S3 and S4 use raw R1/D5 at s=-.0025, varying Mu or rho respectively. Table S1 uses R1/D5 neutral controls. Table S2 uses h=.5 and R1/D5; adjust if your intended treatment grid differs.
