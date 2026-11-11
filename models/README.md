# Model Files

## Purpose

This directory contains four versions of the same log-linear DSGE model. They
differ in the productive loan-allocation case and the associated historical
steady-state calibration.

| File | qq | Interpretation |
| --- | ---: | --- |
| speculation_money_creation_q02.mod | 0.2 | 20% productive loan allocation |
| speculation_money_creation_q04.mod | 0.4 | 40% productive loan allocation |
| speculation_money_creation_q06.mod | 0.6 | 60% productive loan allocation |
| speculation_money_creation_q08.mod | 0.8 | 80% productive loan allocation |

## Important calibration note

Do not reproduce the four cases by changing only qq in one file. The source
materials assign different steady-state values to several parameters across
the four cases, including MSS, CSS, ISSS, ASS, ITSS, ILSS, TSS, BSS, and GSS.
Each .mod file preserves the complete calibration belonging to that scenario.

The model equations, shock standard deviations, and simulation length are
otherwise preserved across cases.

## Variables

| Symbol | Description |
| --- | --- |
| A | Technology |
| K | Capital |
| N | Labor |
| M | Money/liquidity measure |
| PPI | Inflation |
| W | Wage |
| C | Consumption |
| R | Return on capital |
| P | Price level |
| Y | Output |
| IS | Speculative return |
| IL | Loan interest rate |
| O | Leisure |
| T | Transfers |
| IIP | Nominal interest rate |
| II | Investment |
| IP | Gross nominal interest |
| B | Bonds |
| G | Government spending |
| IT | Deposit interest rate |

## Source integrity

The four .mod files are preserved research inputs. Their Git blob object IDs
are recorded in SOURCE_BLOBS.sha1. The automated workflow checks each file
against that manifest before running the model. A change to a model file
therefore fails CI until the source change and its updated baseline are
deliberately reviewed together.

The model files are Dynare's domain-specific model language, not MATLAB
source files. The MATLAB scripts call Dynare to parse and execute them.

## Running the models

The original .mod files retain their historical Dynare 4.6.4 diagnostic
syntax. To run one original model file directly, use the historical
MATLAB R2017a / Dynare 4.6.4 environment:

~~~matlab
cd models
dynare speculation_money_creation_q02.mod
~~~

For the documented modern environment, install the official Dynare 6.0 MATLAB
toolbox and run the repository-level scripts from the repository root:

~~~matlab
run('replication/run_all.m')
run('replication/plot_irfs.m')
run('replication/validate_outputs.m')
~~~

The runner creates disposable copies under
outputs/replication/runtime_workspace/ and applies the diagnostic-only
compatibility substitution to those copies. It never edits the committed
model files.

## Runtime compatibility edit

In each disposable copy only, the Dynare 6-incompatible diagnostic
resid(1); is replaced with resid;. No behavioral equation, calibration
value, shock standard deviation, or simulation setting is changed by this
compatibility step.
