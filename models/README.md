# Model files

These are four calibrations of the same log-linear DSGE model. The
parameter `qq` is the share of bank loans used in production.

| File | Productive loan share (`qq`) |
| --- | ---: |
| [speculation_money_creation_q02.mod](speculation_money_creation_q02.mod) | 0.2 |
| [speculation_money_creation_q04.mod](speculation_money_creation_q04.mod) | 0.4 |
| [speculation_money_creation_q06.mod](speculation_money_creation_q06.mod) | 0.6 |
| [speculation_money_creation_q08.mod](speculation_money_creation_q08.mod) | 0.8 |

Use the file for the calibration you want to run. Besides `qq`, the
calibrations differ in steady-state values including `MSS`, `CSS`,
`ISSS`, `ASS`, `ITSS`, `ILSS`, `TSS`, `BSS`, and `GSS`.
The Git blob IDs for these files are in [SOURCE_BLOBS.sha1](SOURCE_BLOBS.sha1).

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

## Run an individual calibration

To run the original file in MATLAB R2017a with Dynare 4.6.4, start at the
repository root and choose the model file for the share you want.

~~~matlab
cd models
dynare speculation_money_creation_q02.mod
~~~

For MATLAB R2024b with Dynare 6.0, follow the steps in the
[reproduction guide](../docs/REPRODUCIBILITY.md).
