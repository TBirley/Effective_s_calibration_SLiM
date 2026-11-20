# Hard and competitive selection simulations

Consolidated simulation scripts for SLiM **4.3.0** (nonWF). These generate raw data, not the downstream R calibration, bootstrap or plotting analyses. They are derived from the supplied tracked-mutation and maximum-frequency models.

## Running

Install SLiM 4.3.0 and make `slim` available on PATH (or set `SLIM_BIN`). Run from this directory. On a cluster, load the appropriate module yourself before submission; no institution-specific paths or email settings are included.

```bash
# One replicate locally (seed 1)
bash HardSelection.sh
bash CompetitiveSelection.sh

# 100 replicates, one parameter combination per submission
S=-0.005 H=0.5 K=1000 Nc=5000 sbatch HardSelection.sh
S=-0.005 H=0.5 K=1000 Nc=5000 R=9 D=10 sbatch CompetitiveSelection.sh

# Short smoke tests; not manuscript parameterisations
K=20 Nc=100 L=100 MU=0.001 GENERATIONS=30 TRACK_START=5 TRACK_END=10 bash HardSelection.sh
K=20 Nc=100 L=100 MU=0.001 GENERATIONS=30 TRACK_START=5 TRACK_END=10 bash CompetitiveSelection.sh
```

The launchers use the SLURM array task ID as seed (1–100); outside SLURM, set `SEED` explicitly. `OUT_ROOT` changes the results directory. Existing run directories are not overwritten. Adjust SLURM resource requests for your system. To run a parameter grid, submit each combination separately; do not mix unrelated hard-selection reference curves when calibrating effective selection.

| Bash variable | SLiM constant | Default | Meaning |
|---|---|---:|---|
| K | K | 1000 | Hard-selection adult cap; competition founder size |
| Nc | candidateNo | 5K | Number of offspring per reproductive generation |
| S | selCoeff | -0.001 | Signed assigned selection coefficient (0 for neutral control) |
| H | domCoeff | 0.5 | Dominance coefficient |
| MU | Mu | 1e-5 | Per-base mutation rate per generation |
| RHO | rho | 0.5 | Per-base recombination probability |
| L | chromLength | 1000 | Model chromosome length in bases |
| R | Rf | 1 | Contest rounds per rival, positive odd integer (competition only) |
| D | Df | 5 | Distinct rivals per candidate (competition only) |
| GENERATIONS | generations | 30000 | Last mutation-tracking generation |
| TRACK_START | trackStart | 10001 | First generation of mutation registration |
| TRACK_END | trackEnd | 15000 | Last generation of mutation registration |

Competition requires even K and Nc and D smaller than both (the founders also enter contests). K is not a cap on the competitive population; all candidates are retained and reproductive weights are ranked gamma prizes (mean 1, shape 0.245). Hard selection uses monogamous pairs, viability selection and random culling to K. The original two-cycle hard-selection and one-cycle competition clocks are retained. The competition script runs one additional cycle to measure realised reproductive contributions of the final cohort.

## Outputs

Each run has its own directory and parameter/seed-specific filenames. All data are tab-separated.

- `Output_TMs_10-15k`: mutation registration, upward/downward threshold events (0.05, 0.1, 0.2, 0.5), fixation, loss and right-censoring. Registration is pre-selection; subsequent observations are in the post-regulation hard-selection cohort or the full competitive cohort. Count distinct IDs within each seed, not event rows. For ever reaching a threshold, include initial frequencies and fixation events as appropriate.
- `Output_MaxQ_10-15k`: one row per tracked mutation resolved by loss, fixation or end-of-run censoring, including initial, maximum and final q. Maximum includes entry frequency and subsequent observations, not unobserved intermediate stages. The folder suffix denotes the default registration window even if overridden.
- `Output_SFS`: mutation frequencies in candidate offspring at the original sampling schedule (hard: generations 1, 1001, 2001, ...; competition: 1000, 2000, ...). Fixed mutations are retained. A header has been added to the previously headerless frequency file. No unused legacy SFS placeholder is generated.
- `Output_Load`: pre-selection and post-selection load, including total, expected realised, genotype-based realised, homozygous, heterozygous, masked and fixed load, and cached fitness summaries. Competition post-selection values use actual gametic contributions in the following generation; hard-selection values use the surviving adult cohort. Original estimators retained.
- `Output_Vk`: potential breeders, recruits, mean gametic contribution, Vk and the original Ne_from_Vk estimator. Hard selection counts surviving recruits; competition counts offspring. A missing hard-selection header has been added. The original estimator is retained for manuscript comparability, not independently validated for arbitrary demographies.
- `*_parameters.txt` and `*_status.txt`: parameters and completion/extinction status. Extinct or interrupted runs may have incomplete tracking records; do not treat missing terminal records as ordinary loss or completed follow-up. Extinction status reports the SLiM cycle, completion status the biological generation.
