# Generated replication outputs

This directory is populated by `replication/run_all.m` and validated by
`replication/validate_outputs.m`.

Expected generated files:

- `runtime_workspace/`: disposable copies of the original `.mod` files used for execution. Only the Dynare 6 diagnostic syntax is adapted here; committed source model files are not modified.

- `irfs_q02.csv`, `irfs_q04.csv`, `irfs_q06.csv`, `irfs_q08.csv`:
  period-by-period responses to the speculative-return shock.
- `irf_impact_summary.csv`: signed responses at the first period (impact response); full 40-period paths remain in the IRF files.
- `runtime_manifest.txt`: MATLAB/Dynare runtime and simulation settings.
- `validation_report.txt`: independently recomputed numerical checks.

Generated outputs are ignored by Git and retained as GitHub Actions artifacts.
