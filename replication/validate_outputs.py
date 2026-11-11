#!/usr/bin/env python3
"""Validate 40-period Dynare IRFs against historical period-1 impact responses.

The historical research note reports the impact response to a one-percent
speculative-return shock. This validator checks period 1, not the maximum
absolute response over the full IRF horizon. Standard library only.
"""
from __future__ import annotations

import csv
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GENERATED = ROOT / "outputs" / "replication"
HISTORICAL = ROOT / "outputs" / "tables" / "historical_irf_summary.csv"
TOLERANCE_PP = 0.02

SERIES = (
    ("M_EEPSILONIS", "impact_M_pct", "money_liquidity_response_pct"),
    ("Y_EEPSILONIS", "impact_Y_pct", "output_response_pct"),
    ("P_EEPSILONIS", "impact_P_pct", "price_response_pct"),
    ("PPI_EEPSILONIS", "impact_PPI_pct", "inflation_response_pct"),
)
Q_TAGS = {0.2: "q02", 0.4: "q04", 0.6: "q06", 0.8: "q08"}


def read_rows(path: Path) -> list[dict[str, str]]:
    if not path.is_file():
        raise AssertionError(f"Missing required file: {path.relative_to(ROOT)}")
    with path.open(newline="", encoding="utf-8-sig") as handle:
        return list(csv.DictReader(handle))


def number(value: str, label: str) -> float:
    try:
        result = float(value)
    except (TypeError, ValueError) as exc:
        raise AssertionError(f"{label} is not numeric: {value!r}") from exc
    if not math.isfinite(result):
        raise AssertionError(f"{label} is not finite: {value!r}")
    return result


def main() -> int:
    historical_rows = read_rows(HISTORICAL)
    historical = {
        round(number(row["productive_loan_share"], "historical q"), 1): row
        for row in historical_rows
    }
    summary_rows = read_rows(GENERATED / "irf_impact_summary.csv")
    summary = {round(number(row["q"], "summary q"), 1): row for row in summary_rows}

    expected_q = set(Q_TAGS)
    if set(historical) != expected_q:
        raise AssertionError(f"Historical table must contain exactly {sorted(expected_q)}.")
    if set(summary) != expected_q or len(summary_rows) != 4:
        raise AssertionError("Generated summary must contain exactly four unique q cases.")

    report: list[str] = []
    for q, tag in Q_TAGS.items():
        rows = read_rows(GENERATED / f"irfs_{tag}.csv")
        if len(rows) != 40:
            raise AssertionError(f"{tag}: expected 40 IRF rows, found {len(rows)}.")
        periods = [int(number(row["period"], f"{tag} period")) for row in rows]
        if periods != list(range(1, 41)):
            raise AssertionError(f"{tag}: periods must be exactly 1 through 40.")

        for series_name, summary_name, historical_name in SERIES:
            values = [number(row[series_name], f"{tag} {series_name}") for row in rows]
            impact = values[0] * 100.0
            stored_impact = number(summary[q][summary_name], f"{tag} {summary_name}")
            if abs(impact - stored_impact) > 1e-7:
                raise AssertionError(
                    f"{tag} {summary_name}: runner summary {stored_impact:.8f} "
                    f"does not match recomputed period-1 impact {impact:.8f}."
                )

            benchmark = number(historical[q][historical_name], f"historical {historical_name}")
            difference = abs(impact - benchmark)
            report.append(
                f"q={q:.1f} {series_name}: period-1 impact={impact:.4f}%, "
                f"historical={benchmark:.4f}%, difference={difference:.4f} pp"
            )
            if difference > TOLERANCE_PP:
                raise AssertionError(
                    f"Impact-response mismatch for q={q:.1f}, {series_name}: "
                    f"{impact:.4f}% vs {benchmark:.4f}% "
                    f"(tolerance {TOLERANCE_PP:.4f} pp)."
                )

    report.append(
        f"PASS: four calibrations; four finite 40-period IRFs per case; "
        f"runner summaries independently checked; historical period-1 impact "
        f"responses within {TOLERANCE_PP:.2f} percentage points."
    )
    output = GENERATED / "validation_report.txt"
    output.write_text("\n".join(report) + "\n", encoding="utf-8")
    print("\n".join(report))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"REPRODUCIBILITY VALIDATION FAILED: {exc}", file=sys.stderr)
        raise SystemExit(1)
