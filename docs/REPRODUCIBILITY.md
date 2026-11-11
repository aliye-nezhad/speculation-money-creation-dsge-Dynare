# Reproducibility

## What the automated check does

The GitHub Actions workflow executes the four committed Dynare model files in
a clean Ubuntu 24.04 environment using the Ubuntu `dynare=6.0-1` package and
GNU Octave. It does not claim to recreate the original MATLAB R2017a / Dynare
4.6.4 environment.

The workflow:

1. Installs the pinned Ubuntu Dynare package and headless plotting tools.
2. Records the Octave and Dynare versions.
3. Runs all four scenario-specific model files.
4. Checks that each model has 20 endogenous variables and 20 equations,
   finite steady-state values, finite decision-rule eigenvalues, and all four
   required 40-period impulse responses.
5. Exports the four period-by-period IRF tables and signed peak-response
   summary.
6. Independently recomputes the signed peaks from the exported IRFs and
   compares them with the historical summary table.
7. Uploads generated outputs and logs as a GitHub Actions artifact.

## Run locally on Ubuntu 24.04

```bash
sudo apt-get update
sudo apt-get install --yes dynare=6.0-1 gnuplot-nox ghostscript
DYNARE_PATH="$(dpkg -L dynare | grep '/matlab$' | head -n 1)"
octave-cli --no-gui --quiet --eval "addpath('$DYNARE_PATH'); graphics_toolkit('gnuplot'); set(0, 'defaultfigurevisible', 'off'); run('replication/run_all.m');"
python3 replication/validate_outputs.py
```

## Historical benchmark interpretation

The repository README describes the values in
`outputs/tables/historical_irf_summary.csv` as historical **peak** percentage
responses. The validator therefore identifies the signed response at the
largest absolute value over periods 1–40. It does not compare period-1 impact
responses with these benchmarks.

The tolerance is 0.02 percentage points because the historical table is
rounded to four decimal places. A failed comparison is reported as a
numerical discrepancy; it is not automatically evidence of a code defect.
The shock normalization, variable units, sign convention, model version, and
historical source calculation must be investigated before changing equations
or calibration values.

## What a successful run establishes

A successful run establishes that the four model files execute in the stated
modern Linux/Octave environment, generate finite outputs, and reproduce the
selected historical peak responses within the stated tolerance.

It does not establish that the economic assumptions or calibration are
correct, that the model is empirically estimated, or that the modern runtime
is numerically identical to the historical MATLAB/Dynare environment.
