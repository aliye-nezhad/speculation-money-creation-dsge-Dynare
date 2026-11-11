# Generated replication outputs

This directory is populated by `replication/run_all.m` and validated by
`replication/validate_outputs.py`.

Expected generated files:

- `irfs_q02.csv`, `irfs_q04.csv`, `irfs_q06.csv`, `irfs_q08.csv`:
  period-by-period responses to the speculative-return shock.
- `irf_peak_summary.csv`: signed responses at the largest absolute value
  over the 40-period horizon.
- `runtime_manifest.txt`: Octave/Dynare runtime and simulation settings.
- `validation_report.txt`: independently recomputed numerical checks.

Generated outputs are ignored by Git and retained as GitHub Actions artifacts.
