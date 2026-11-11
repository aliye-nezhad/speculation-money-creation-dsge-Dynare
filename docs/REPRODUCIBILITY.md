# Reproducibility

## Scope and execution environment

The automated workflow runs the four committed Dynare model specifications
on a GitHub-hosted Ubuntu 24.04 runner using MATLAB R2024b and the official
Dynare 6.0 MATLAB toolbox (dynare-6.0.mltbx).

The workflow deliberately downloads and installs the Dynare MATLAB toolbox
rather than installing Ubuntu's dynare package. On Ubuntu 24.04, the
distribution dynare package depends on GNU Octave. That dependency is not
needed for this MATLAB project. The workflow checks that no Octave executable
is installed before and after setup and fails if one is found.

All research computation, numerical export, figure generation, and
validation scripts are MATLAB. The repository contains no Python source or
bytecode files, and the workflow checks that no Python command is invoked by
the project scripts or workflow. A GitHub-hosted Ubuntu image may have a
system Python installation for unrelated operating-system tasks; that is not
a project dependency and is not used to execute the model.

The .mod files are Dynare's domain-specific model language, not MATLAB
source. GitHub Linguist does not provide a Dynare classifier. The repository
therefore excludes .mod files from Linguist's language percentage instead
of misclassifying them as MATLAB or AMPL. This is a transparent statistics
choice, not a claim that the .mod syntax is MATLAB.

## Workflow steps

The workflow:

1. Checks each committed .mod file against its preserved Git blob ID in
   models/SOURCE_BLOBS.sha1. A changed model file fails CI until the source
   baseline is deliberately updated.
2. Checks that the repository contains no .py or .pyc files and that no
   Python command is used in .github/workflows or replication.
3. Checks that Octave is not installed.
4. Installs plotting and MATLAB runtime system dependencies.
5. Sets up MATLAB R2024b.
6. Downloads the official Dynare 6.0 MATLAB toolbox from
   https://www.dynare.org/release/matlab-online/dynare-6.0.mltbx, verifies
   that the package is a readable archive, verifies it against the reviewed
   SHA-256 checksum `2b09418d141ba3fd077cf2cb97f3aa478a4adf60db11f1ff3f9ec5840da6903f`,
   and records the checksum in the runtime manifest.
7. Installs the toolbox into MATLAB, checks the Dynare MATLAB path,
   processor-count routine and generalized Schur routine, and then verifies
   the preprocessor by successfully executing all four model files.
8. Runs replication/run_all.m to execute the four calibrations.
9. Exports all 20 endogenous responses to the speculative-return shock for
   periods 1–40 in each calibration.
10. Runs replication/plot_irfs.m to generate a comprehensive 20-variable
    figure and a focused four-variable figure for each calibration.
11. Runs replication/validate_outputs.m to check the generated data, figures,
    source checksums, runtime manifests, and historical impact responses.
12. Uploads a 90-day workflow artifact and commits successful outputs to
    main when the workflow runs on the default branch.

GitHub Actions dependencies are pinned to immutable commit SHAs in the
workflow. The workflow records the actual MATLAB version and release, Dynare
toolbox checksum, Ubuntu runner image, installed system-package versions,
source commit, and SHA-256 checksums of the four model files.

## Model-source preservation and compatibility

The four committed .mod files are preserved byte-for-byte. Their Git blob
object IDs are recorded in models/SOURCE_BLOBS.sha1; CI verifies the files
with git hash-object before execution.

The original files use the legacy diagnostic command resid(1);. Dynare 6
does not support that numeric option. replication/run_all.m therefore
creates disposable copies under
outputs/replication/runtime_workspace/ and replaces only resid(1); with
resid; in those copies. No model equation, calibration value, shock
standard deviation, or simulation option is changed. The runtime workspace
is ignored by Git and is not committed.

## MATLAB toolbox compatibility warnings

The official Dynare 6.0 MATLAB toolbox installs and executes in the CI
environment, but MATLAB R2024b's Add-On manager emits a warning that the
toolbox metadata does not mark it as supported for this MATLAB release or
platform. The same run proceeds to execute Dynare 6.0 successfully for all
four calibrations, and the independent numerical and figure validators pass.
This is evidence of successful execution in the tested environment; it is
not a claim that the Add-On manager's vendor-compatibility warning has been
formally cleared.

Dynare 6.0 also places legacy helper names on the MATLAB path that overlap
with newer MATLAB built-ins (notably contains, and a datetime class/function
name). MATLAB reports path-precedence warnings. They did not prevent the
models or plotting scripts from completing in the verified run. They are
recorded as compatibility caveats rather than suppressed or hidden.

## Numerical checks

For each calibration, the runner checks:

- 20 endogenous variables, 20 equations, and 2 exogenous shocks;
- finite steady-state values;
- a nonempty generalized-eigenvalue vector with no NaN values and at least
  one finite value (valid infinite generalized roots are not rejected by
  themselves);
- finite decision-rule matrices;
- exactly 20 responses to EEPSILONIS;
- exactly 40 finite observations for every response; and
- first-period impact responses for the four historically benchmarked series.

The separate MATLAB validator independently recomputes the four first-period
impact responses for each calibration from the exported IRFs. It checks the
runner's summary table and compares the results with
outputs/tables/historical_irf_summary.csv. The tolerance is 0.02 percentage
points because the historical reference values are rounded to four decimals.

## Limits of historical validation

The historical source table provides impact-response benchmarks for four
variables and four calibrations. It does not provide an independent historical
40-period path for every endogenous variable. Consequently:

- all 20 generated responses are checked for completeness and finite values
  over all 40 periods;
- the four available historical series are compared with the historical
  impact values at period 1; and
- the repository does not claim full 40-period historical path matching.

A failed impact comparison is reported as a numerical discrepancy. It is not
automatically evidence of a code defect. Shock normalization, variable units,
sign convention, model version, and historical source calculations must be
investigated before changing equations or calibration values.

## Figure generation

replication/plot_irfs.m reads the exported CSVs and creates eight PNG files
under outputs/replication/figures/:

- one 4-by-5 panel containing all 20 endogenous responses for each q; and
- one 2-by-2 panel containing money/liquidity, output, the price level, and
  inflation for each q.

The historical figures under outputs/figures/ are retained as reference
materials and are not overwritten by the generated figures.

## Runtime and dependency limits

The workflow pins the major MATLAB release to R2024b, the Dynare toolbox to
6.0, and GitHub Actions to immutable commit SHAs. It records the actual
MATLAB patch/version and installed Ubuntu package versions for each run.

GitHub-hosted ubuntu-24.04 images are maintained by GitHub and can change
over time. MATLAB setup for a named release can also receive update-level
changes. The recorded manifests make those changes auditable, but the hosted
runner is not a bit-for-bit frozen virtual machine. The workflow therefore
claims a pinned and documented execution stack, not identical machine state
forever.

## Local reproduction

Use MATLAB R2024b and install the official Dynare 6.0 MATLAB toolbox
(dynare-6.0.mltbx) through MATLAB's Add-On interface or the MATLAB command
window. In an interactive MATLAB session, the toolbox can also be installed
with:

~~~matlab
matlab.addons.install('dynare-6.0.mltbx')
~~~

Then run the following from the repository root:

~~~matlab
run('replication/run_all.m')
run('replication/plot_irfs.m')
run('replication/validate_outputs.m')
~~~

The automated Linux workflow also installs gnuplot-nox, Ghostscript, X13,
and the required MATLAB runtime libraries. It configures the system C++
runtime for the Dynare preprocessor before launching MATLAB.

## What a successful run establishes

A successful run establishes that all four committed model specifications
execute under the documented MATLAB/Dynare environment, produce 20 finite
40-period responses per calibration, generate the eight figures, and
reproduce the 16 available historical impact-response values within the
stated tolerance.

It does not establish that the economic assumptions or calibration are
correct, that the model is empirically estimated, that the full historical
40-period paths have been matched, or that the modern environment is
bit-for-bit identical to the historical MATLAB R2017a / Dynare 4.6.4 setup.
