# Reproducibility

## What the automated check does

The GitHub Actions workflow executes the four committed Dynare model files in
a clean Ubuntu 24.04 environment using MATLAB R2024b and the Ubuntu
`dynare=6.0-1` package. It does not claim to recreate the original MATLAB
R2017a / Dynare 4.6.4 environment. All automated model execution is
performed in MATLAB R2024b.

The workflow installs the Ubuntu `dynare=6.0-1` package and
headless plotting tools. The package includes the MATLAB source directory
and Dynare preprocessor. The workflow adds the packaged MATLAB directory to
MATLAB R2024b's path and adds Dynare's MATLAB fallback routines under `missing/mex`, because
the Ubuntu package does not provide a MATLAB-compiled MEX directory for
this runner. All model execution takes place in MATLAB R2024b.

The workflow:

1. Verifies with Git that no committed `.mod` file differs from `main`.
2. Installs the pinned Ubuntu Dynare package and headless plotting tools.
3. Records the MATLAB and Dynare versions.
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

## MATLAB and the Dynare preprocessor runtime

The GitHub Actions job runs MATLAB R2024b on Ubuntu 24.04. The Ubuntu
Dynare 6.0-1 preprocessor is linked against a newer GNU C++ runtime than the
older `libstdc++.so.6` bundled with MATLAB R2024b. The workflow therefore
locates the system `libstdc++.so.6`, verifies that it provides
`GLIBCXX_3.4.32`, and sets it as `LD_PRELOAD` from inside MATLAB before
Dynare is launched. This environment setting is inherited by the Dynare
preprocessor subprocess; it does not change the model files or MATLAB source.

## Dynare 6 diagnostic compatibility

The original committed model files use `resid(1);` and remain byte-for-byte unchanged. Dynare 6 no longer supports that legacy numeric option. At runtime, the runner creates disposable copies and substitutes only that diagnostic command with `resid;`, which requests the static-equation residual display without an option. This deliberately avoids relying on `non_zero`, an option introduced in a later Dynare release. The temporary substitution does not alter any behavioral equation, calibration value, shock standard deviation, or simulation setting in the committed research sources.

## Run locally with MATLAB

Install a MATLAB release compatible with Dynare 6.0 and install Dynare 6.0.
Add the `matlab` subdirectory of the Dynare installation to the MATLAB path,
then run the following from the repository root:

```matlab
addpath('PATH_TO_DYNARE_6_0/matlab');
run('replication/run_all.m');
```

After the MATLAB run completes, validate the exported files with Python:

```bash
python replication/validate_outputs.py
```

For the historical environment, use MATLAB R2017a with Dynare 4.6.4 and
execute the original model files directly. The automated MATLAB R2024b /
Dynare 6.0 workflow is a modern execution check, not a claim of bit-for-bit
identity with the historical software environment.

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
modern Linux/MATLAB environment, generate finite outputs, and reproduce the
selected historical impact responses within the stated tolerance.

It does not establish that the economic assumptions or calibration are
correct, that the model is empirically estimated, or that the modern runtime
is numerically identical to the historical MATLAB/Dynare environment.
