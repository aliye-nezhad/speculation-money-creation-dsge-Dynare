# Speculation, Bank Money Creation, and Output in a DSGE Model

## Overview

This repository contains a calibrated, closed-economy cash-in-advance DSGE
model developed to study how speculative-return shocks interact with bank
credit allocation, money creation, inflation, and output. The model originates
from a master's-thesis project and a related research note focused on the
Iranian economy.

The project is presented as a Dynare and structural-macroeconomic modeling
sample. Its results are model-based implications under a particular
calibration; they are not causal estimates or a complete policy evaluation.

## Research question

How does a positive shock to the return on speculative activity affect bank
money creation, prices, inflation, and output when some bank lending can be
diverted away from productive use?

## Model and calibrations

The model contains a representative household, productive firms, a banking
sector, and a consolidated fiscal-monetary authority. Households supply labor
and capital and allocate wealth across money, deposits, and bonds. Productive
firms use capital, labor, and real lending. Banks accept demand and time
deposits, extend loans, and operate subject to reserve requirements.

The parameter qq represents the share of bank loans allocated to productive
activity. Four scenario-specific calibrations are retained:

| Model file | Productive loan share |
| --- | ---: |
| speculation_money_creation_q02.mod | 0.2 |
| speculation_money_creation_q04.mod | 0.4 |
| speculation_money_creation_q06.mod | 0.6 |
| speculation_money_creation_q08.mod | 0.8 |

The four cases preserve their own historical steady-state calibrations. They
are separate model files rather than a one-line parameter switch. See
models/README.md.

## Shocks and simulation

The model includes two exogenous innovations:

- EEPSILONA: technology shock;
- EEPSILONIS: speculative-return shock.

The equations are supplied to Dynare in log-linear form. Each model fixes the
random seed at 12345 and requests first-order stochastic simulation with
40-period impulse responses and 5,000 simulated periods.

## MATLAB-only replication workflow

The research computation, numerical export, figure generation, and output
validation are performed in MATLAB R2024b using the official Dynare 6.0 MATLAB
toolbox. The workflow does not install or invoke GNU Octave. No Python source
files, Python libraries, or Python commands are part of the project
replication pipeline. GitHub's hosted Ubuntu image may contain Python as a
general-purpose system utility; it is not a project dependency or execution
engine.

The .mod files are Dynare model specifications, not MATLAB source. GitHub
Linguist does not provide a Dynare language classifier, so .gitattributes
excludes .mod files from its language percentage rather than misclassifying
them as MATLAB or another language. The detected executable project scripts
are MATLAB.

## Repository structure

~~~text
├── .github/workflows/dynare-replication.yml
├── docs/
│   └── REPRODUCIBILITY.md
├── models/
│   ├── SOURCE_BLOBS.sha1
│   ├── README.md
│   └── speculation_money_creation_q{02,04,06,08}.mod
├── replication/
│   ├── run_all.m
│   ├── plot_irfs.m
│   └── validate_outputs.m
└── outputs/
    ├── figures/                 # Preserved historical reference figures
    ├── tables/
    │   └── historical_irf_summary.csv
    └── replication/             # Regenerated numerical and graphical outputs
~~~

## Automated reproducibility

The GitHub Actions workflow runs on Ubuntu 24.04 with MATLAB R2024b and
Dynare 6.0. It installs Dynare from the official MATLAB toolbox package rather
than the Ubuntu dynare package, because the latter pulls in GNU Octave as a
required dependency. The workflow explicitly fails if an Octave executable is
present.

The workflow:

1. Checks the four original .mod files against their preserved Git blob IDs.
2. Checks that no Python source files or Python commands are present in the
   project replication scripts or workflow.
3. Installs MATLAB R2024b and the official Dynare 6.0 MATLAB toolbox.
4. Runs all four scenario-specific calibrations in MATLAB.
5. Checks model dimensions, finite steady-state values, decision-rule
   matrices, and all 20 endogenous impulse responses over 40 periods.
6. Exports all 20 responses for each calibration to CSV.
7. Generates eight PNG figures in MATLAB: a 20-variable figure and a focused
   four-variable figure for each calibration.
8. Independently validates all 16 available historical impact-response
   comparisons.
9. Records source checksums, MATLAB/Dynare versions, the toolbox checksum,
   runner-image details, and installed system-package versions.
10. Uploads a 90-day GitHub Actions artifact and commits validated outputs to
    main after successful default-branch runs.

All GitHub Actions are pinned to immutable commit SHAs. Generated outputs are
stored in outputs/replication/, with additional execution details in
docs/REPRODUCIBILITY.md.

## Reproduction on a local MATLAB installation

Use MATLAB R2024b and Dynare 6.0. Install the official
dynare-6.0.mltbx toolbox through MATLAB's Add-On interface or from the MATLAB
command window. From the repository root, run:

~~~matlab
run('replication/run_all.m')
run('replication/plot_irfs.m')
run('replication/validate_outputs.m')
~~~

For a local run, MATLAB must have Dynare 6.0 on its path. The automated
workflow also installs the Linux plotting dependencies and configures the
system C++ runtime required by the Dynare preprocessor.

The original .mod files retain their historical diagnostic syntax. For
Dynare 6, run_all.m creates disposable copies and changes only
resid(1); to resid; in those copies. The committed model specifications
remain unchanged.

## Historical results and validation scope

The historical impact-response values are stored in
outputs/tables/historical_irf_summary.csv. The validator compares the
first-period response for money/liquidity, output, the price level, and
inflation across all four calibrations. The tolerance is 0.02 percentage
points because the historical table is rounded to four decimal places.

The workflow also checks all 20 endogenous responses over the full 40-period
horizon for every calibration and generates figures from those complete
paths. However, the historical source materials available in this repository
provide impact benchmarks, not independent historical values for every
period. The full 40-period paths can therefore be checked for completeness
and finiteness, but not claimed to be fully matched to historical paths.

The reported responses for q = 0.2, 0.4, and 0.6 are numerically identical,
while the q = 0.8 case differs modestly. This limited sensitivity is a feature
and limitation of the historical calibration; it should not be interpreted
as an empirical estimate of the productive-credit share.

## Limitations

- The model is calibrated rather than estimated.
- The economy is closed and omits exchange-rate and external-sector dynamics.
- The banking and fiscal-monetary blocks are stylized.
- The productive-credit share is imposed rather than estimated or endogenous.
- Historical reference values are available for impact responses, not full
  40-period paths.
- The original MATLAB R2017a / Dynare 4.6.4 environment is not recreated by the
  modern CI workflow; CI uses MATLAB R2024b / Dynare 6.0.
- GitHub-hosted Ubuntu 24.04 runner images and MATLAB update levels can evolve.
  The workflow records the actual runtime and package versions, but does not
  claim bit-for-bit identity across all future hosted-runner images.
- Policy conclusions are conditional on the equations and calibration.

## Skills demonstrated

- DSGE model construction and log-linear implementation;
- monetary and banking-sector modeling;
- steady-state calibration and sensitivity analysis;
- Dynare diagnostics and stochastic simulation;
- MATLAB-based replication, numerical validation, and figure generation;
- impulse-response interpretation; and
- transparent documentation of model limitations.

## Author

Aliye Nezhad

## License

The code and documentation are released under the MIT License. The research
note and historical output figures remain attributable to the author.
