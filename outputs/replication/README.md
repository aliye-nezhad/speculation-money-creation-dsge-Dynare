# Replication results

The files here cover the four productive loan shares, 0.2, 0.4, 0.6,
and 0.8, following a 1% shock to speculative returns.

- `irfs_q02.csv`, `irfs_q04.csv`, `irfs_q06.csv`, and `irfs_q08.csv`
  give the 40-period paths for all 20 endogenous responses.
- `irf_impact_summary.csv` gives the period-one responses for
  money/liquidity, output, the price level, and inflation.
- `figures/` contains a 20-variable plot and a four-variable plot for
  each calibration. The thesis figures are in [outputs/figures](../figures).
- `validation_report.txt` gives the differences from the thesis impact
  values. [Historical table](../tables/historical_irf_summary.csv)
- `runtime_manifest.txt` and `environment_manifest.txt` record the
  software versions, source revision, and simulation settings.
  `source_model_sha256.txt` lists the hashes of the four model files.
