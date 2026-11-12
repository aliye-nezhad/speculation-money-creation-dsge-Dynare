# Speculation and Bank Money Creation

I built this model for my master's thesis to study what happens when returns
to speculation rise and borrowers can divert some bank credit away from
production. The model is a closed-economy, cash-in-advance DSGE calibrated
to Iran. The research note explains the mechanism and calibration.
[Research note](docs/speculation_money_creation_research_note.pdf)

## Model and results

Households supply labor and capital and hold money, deposits, and bonds.
Firms use capital, labor, and bank loans in production. Banks accept demand
and time deposits, extend loans, and face reserve requirements. The model
combines the fiscal and monetary authorities.

The parameter `qq` is the share of bank loans used in production. Each of
the four values, 0.2, 0.4, 0.6, and 0.8, has its own steady-state calibration.
See the [model files](models/README.md) for the variables and calibrations.

The log-linear model has a technology shock (`EEPSILONA`) and a
speculative-return shock (`EEPSILONIS`). Dynare solves it at first order,
with 40 periods of impulse responses, 5,000 simulated periods, and a fixed
random seed of 12345.

These are the period-one responses to a 1% rise in speculative returns,
in percent deviations from steady state.

| Productive loan share | Money/liquidity | Output | Price level | Inflation |
| --- | ---: | ---: | ---: | ---: |
| 0.2, 0.4, 0.6 | +2.0733 | −0.1345 | +1.1345 | +1.1345 |
| 0.8 | +2.0625 | −0.1841 | +1.5525 | +1.5525 |

The first three calibrations give the same impact responses. Output
falls more at `qq = 0.8`, even though money rises slightly less. The
loan share is set in each calibration, so these comparisons describe
the model's response under those assumptions.
[Historical table](outputs/tables/historical_irf_summary.csv) ·
[Full impulse responses](outputs/replication/README.md)

## Run the model

Use MATLAB R2024b with the official Dynare 6.0 MATLAB toolbox on the MATLAB
path. From the repository root, run the following.

~~~matlab
run('replication/run_all.m')
run('replication/plot_irfs.m')
~~~

For toolbox setup and instructions to compare the results with the thesis,
see the [reproduction guide](docs/REPRODUCIBILITY.md).

## Repository structure

~~~text
├── docs/
│   ├── REPRODUCIBILITY.md
│   └── speculation_money_creation_research_note.pdf
├── models/
│   ├── README.md
│   ├── SOURCE_BLOBS.sha1
│   └── speculation_money_creation_q{02,04,06,08}.mod
├── replication/
│   ├── run_all.m
│   ├── plot_irfs.m
│   └── validate_outputs.m
└── outputs/
    ├── figures/                 # Historical figures
    ├── tables/
    │   └── historical_irf_summary.csv
    └── replication/
        ├── README.md
        ├── irfs_q{02,04,06,08}.csv
        ├── irf_impact_summary.csv
        ├── figures/
        ├── validation_report.txt
        ├── runtime_manifest.txt
        ├── environment_manifest.txt
        └── source_model_sha256.txt
~~~

## Author

Aliye Nezhad

## License

The code and documentation are released under the MIT License. The research
note and historical output figures remain attributable to the author.
