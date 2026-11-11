# Reproducibility

## What the automated check does

The GitHub Actions workflow executes the four committed Dynare model files in
a clean Ubuntu 24.04 environment using the Ubuntu `dynare=6.0-1` package and
GNU Octave. It does not claim to recreate the original MATLAB R2017a / Dynare
4.6.4 environment.

The workflow:

1. Verifies with Git that no committed `.mod` file differs from `main`.
2. Installs the pinned Ubuntu Dynare package and headless plotting tools.
3. Records the Octave and Dynare versions.
4. Runs `replication/run_all.m`. The runner creates disposable copies of the
   four committed `.mod` files in
   `outputs/replication/runtime_workspace/` and applies the single Dynare 6
   diagnostic compatibility substitution, `resid(1);` to `resid;`, only to
   those copies. The committed research source files remain unchanged.
5. Executes all four scenario-specific calibrations and checks that each model
   has 20 endogenous variables and 20 equations, finite steady-state values,
   finite decision-rule eigenvalues, and all four required 40-period impulse
   responses.
6. Exports the four period-by-period IRF tables and first-period impact-response
   summary.
7. Independently recomputes the period-1 impact responses from the exported IRFs
   and compares them with the historical summary table.
8. Uploads generated outputs and logs as a GitHub Actions artifact.

## Dynare 6 diagnostic compatibility

The original committed model files use `resid(1);` and remain byte-for-byte unchanged. Dynare 6 no longer supports that legacy numeric option. At runtime, the runner creates disposable copies and substitutes only that diagnostic command with `resid;`, which requests the static-equation residual display without an option. This deliberately avoids relying on `non_zero`, an option introduced in a later Dynare release. The temporary substitution does not alter any behavioral equation, calibration value, shock standard deviation, or simulation setting in the committed research sources.

## Run locally on Ubuntu 24.04

```bash
sudo apt-get update
sudo apt-get install --yes dynare=6.0-1 gnuplot-nox ghostscript
DYNARE_PATH="$(dpkg -L dynare | grep '/matlab$' | head -n 1)"
octave-cli --no-gui --quiet --eval "addpath('$DYNARE_PATH'); graphics_toolkit('gnuplot'); set(0, 'defaultfigurevisible', 'off'); run('replication/run_all.m');"
python3 replication/validate_outputs.py
```

## Historical benchmark interpretation

The research note describes the experiment as a one-percent positive
speculative-return shock and reports the responses reproduced in
`outputs/tables/historical_irf_summary.csv`. Comparing those values with the
regenerated period-by-period IRFs shows that they correspond to the **first
period (impact) responses**, not the largest absolute responses over the full
40-period horizon. For example, at q=0.2 the price-level response is 1.1346%
in period 1 and reaches 1.9171% in period 2. The historical table reports
1.1345%, which is the period-1 value.

The validator therefore compares period 1 only. It still exports the complete
40-period paths so the dynamic response can be inspected separately. The
tolerance is 0.02 percentage points because the historical table is rounded
to four decimal places. A failed comparison is reported as a numerical
discrepancy; it is not automatically evidence of a code defect. Shock
normalization, variable units, sign convention, model version, and historical
source calculation must be investigated before changing equations or
calibration values.

## What a successful run establishes

A successful run establishes that the four model files execute in the stated
modern Linux/Octave environment, generate finite outputs, and reproduce the
selected historical impact responses within the stated tolerance.

It does not establish that the economic assumptions or calibration are
correct, that the model is empirically estimated, or that the modern runtime
is numerically identical to the historical MATLAB/Dynare environment.
