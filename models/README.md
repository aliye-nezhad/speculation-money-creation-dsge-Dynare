# Model Files

## Purpose

This directory contains four versions of the same log-linear DSGE model. They
differ only in the productive loan-allocation case and the associated
historical steady-state calibration.

| File | `qq` | Interpretation |
| --- | ---: | --- |
| `speculation_money_creation_q02.mod` | 0.2 | 20% productive loan allocation |
| `speculation_money_creation_q04.mod` | 0.4 | 40% productive loan allocation |
| `speculation_money_creation_q06.mod` | 0.6 | 60% productive loan allocation |
| `speculation_money_creation_q08.mod` | 0.8 | 80% productive loan allocation |

## Important Calibration Note

Do not reproduce the four cases by changing only `qq` in one file. The source
materials assign different steady-state values to several parameters across
the four cases, including `MSS`, `CSS`, `ISSS`, `ASS`, `ITSS`, `ILSS`, `TSS`,
`BSS`, and `GSS`. Each `.mod` file preserves the complete calibration belonging
to that scenario.

The model equations, shock standard deviations, and simulation length are
otherwise preserved across cases.

## Variables

| Symbol | Description |
| --- | --- |
| `A` | Technology |
| `K` | Capital |
| `N` | Labor |
| `M` | Money/liquidity measure |
| `PPI` | Inflation |
| `W` | Wage |
| `C` | Consumption |
| `R` | Return on capital |
| `P` | Price level |
| `Y` | Output |
| `IS` | Speculative return |
| `IL` | Loan interest rate |
| `O` | Leisure |
| `T` | Transfers |
| `IIP` | Nominal interest rate |
| `II` | Investment |
| `IP` | Gross nominal interest |
| `B` | Bonds |
| `G` | Government spending |
| `IT` | Deposit interest rate |

## Running a Model

Start MATLAB or GNU Octave with Dynare available, set the repository root as
the working directory, and run one case:

```matlab
cd models
dynare speculation_money_creation_q02.mod
```

Alternatively, run all four cases from the repository root:

```matlab
run('replication/run_all.m')
```

## Minor Repository Edits

The repository files make only presentation and reproducibility changes:

- comments and formatting were standardized;
- scenario-specific filenames were introduced;
- `predetermined_variables M K;` uses the documented Dynare declaration form;
- the simulation order and IRF horizon are stated explicitly; and
- a fixed Dynare random seed was added for reproducible simulated moments.

No behavioral equation, calibration value, or shock standard deviation was
changed.
