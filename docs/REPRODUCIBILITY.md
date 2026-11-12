# Reproducing the thesis results

## MATLAB and Dynare

The results in this repository were produced on Ubuntu 24.04 with MATLAB
R2024b and the official Dynare 6.0 MATLAB toolbox. Install
`dynare-6.0.mltbx` through MATLAB's Add-On interface or call
`matlab.addons.install('dynare-6.0.mltbx')` from the folder containing the
download. [Dynare 6.0 toolbox](https://www.dynare.org/release/matlab-online/dynare-6.0.mltbx)

The recorded SHA-256 for the toolbox is
`2b09418d141ba3fd077cf2cb97f3aa478a4adf60db11f1ff3f9ec5840da6903f`.
The Ubuntu setup includes `gnuplot-nox`, Ghostscript, and X13. The
preprocessor uses the system C++ library at
`/lib/x86_64-linux-gnu/libstdc++.so.6`. The environment record lists
the exact software and package versions.
[Environment record](../outputs/replication/environment_manifest.txt)

MATLAB R2024b can warn about the toolbox's Add-On compatibility metadata
and overlapping names on the MATLAB path, including `contains` and
`datetime`. Both warnings appeared in the recorded run, which completed
all four calibrations.

## Run the four calibrations

Make sure Dynare is on the MATLAB path. In the Ubuntu setup above, set
the C++ library path in MATLAB before you run Dynare.

~~~matlab
setenv('LD_PRELOAD', '/lib/x86_64-linux-gnu/libstdc++.so.6')
~~~

From the repository root, run the model and plot the responses.

~~~matlab
run('replication/run_all.m')
run('replication/plot_irfs.m')
~~~

The thesis used MATLAB R2017a and Dynare 4.6.4. For Dynare 6.0,
`run_all.m` uses `resid;` in place of `resid(1);` in temporary copies
under `outputs/replication/runtime_workspace/`. This is the only edit
to those copies. The original Git blob IDs are listed in
[models/SOURCE_BLOBS.sha1](../models/SOURCE_BLOBS.sha1).

Each calibration produces a CSV with 40 observations for each of the 20
responses to the speculative-return shock. There are two figures for each
calibration. One shows all 20 responses and the other shows money/liquidity,
output, the price level, and inflation. The thesis figures are in
[outputs/figures](../outputs/figures).

## Compare the first-period responses

The thesis table reports first-period values for four series in each
calibration. Compare the first observation of each series multiplied by 100
with its historical value. The comparison uses a tolerance of 0.02
percentage points. The historical table gives values to four decimal
places. [Historical responses](../outputs/tables/historical_irf_summary.csv)

To run the comparison in MATLAB after a fresh run, record the source
hashes and the environment first. From the repository root in an Ubuntu
terminal, enter the following.

~~~bash
sha256sum models/speculation_money_creation_q{02,04,06,08}.mod \
  > outputs/replication/source_model_sha256.txt

{
  . /etc/os-release
  printf 'Operating system: %s\n' "$PRETTY_NAME"
  printf 'Kernel: %s\n' "$(uname -sr)"
  cat outputs/replication/runtime_manifest.txt
} > outputs/replication/environment_manifest.txt
~~~

Then return to MATLAB and run the comparison.

~~~matlab
run('replication/validate_outputs.m')
~~~

The report lists the difference for each of the 16 values and summarizes
the checks of the response files and figures. The historical table covers
period one. For periods 2 through 40, the checks cover completeness and
finite values. [Comparison report](../outputs/replication/validation_report.txt)

## Model diagnostics

Each calibration has 20 equations, 20 endogenous variables, and two
exogenous shocks. The steady state and decision-rule matrices must be
finite. The generalized eigenvalues must include at least one finite
value and contain no NaNs. An infinite generalized eigenvalue is
possible when the denominator of the generalized Schur pair is zero.

If an impact differs from the thesis table, check the shock size,
variable units, sign convention, and model version before changing an
equation or calibration.
