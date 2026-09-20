"""
fix_dimdates.py
===============
Fixes and enriches a DimDates CSV file by:

  1. Recalculating FiscalDay, FiscalWeek, FiscalDayInWeek  (were -1)
  2. Adding:
        IsFirstDayOfWeek   – 1 if Monday  (CalendarDayInWeek == 1)
        IsLastDayOfWeek    – 1 if Sunday  (CalendarDayInWeek == 7)
        IsFirstDayOfMonth  – 1 if day == 1st of calendar month
        IsLastDayOfMonth   – 1 if day == last day of calendar month
        IsFirstDayOfYear   – 1 if day == Jan 1 of calendar year
        IsLastDayOfYear    – 1 if day == Dec 31 of calendar year
        IsWeekend          – 1 if Saturday or Sunday
        IsLeapYear         – 1 if the calendar year is a leap year

Assumptions / conventions
--------------------------
• CalendarDayInWeek uses ISO convention: 1 = Monday … 7 = Sunday.
• The fiscal year is assumed to start on FISCAL_START_MONTH/FISCAL_START_DAY
  each year (default: January 1, so FiscalYear == CalendarYear).
  FiscalDay  – ordinal day within the fiscal year (1-based).
  FiscalWeek – sequential week block within the fiscal year
               (week 1 = fiscal days 1-7, week 2 = fiscal days 8-14, …).
  FiscalDayInWeek – position within that fiscal week block (1-7).
• IsHoliday uses the 'holidays' library. Change COUNTRY / SUBDIV as needed.
  Supported country codes: https://python-holidays.readthedocs.io/en/latest/

Usage
-----
    python fix_dimdates.py                          # uses defaults
    python fix_dimdates.py my_dates.csv             # custom input
    python fix_dimdates.py my_dates.csv out.csv     # custom input + output
"""

import sys
import calendar
from pathlib import Path

import pandas as pd

# CONFIGURATION

INPUT_CSV  = "dimdates.csv"         # path to the original file
OUTPUT_CSV = "dimdates_fixed.csv"   # path for the corrected output

FISCAL_START_MONTH = 1              # month the fiscal year begins (1=January)
FISCAL_START_DAY   = 1             # day of that month (usually 1)

# HELPER FUNCTIONS

def fiscal_start_for(date: "pd.Timestamp", start_month: int, start_day: int) -> "pd.Timestamp":
    """Return the fiscal-year start date that governs *date*."""
    candidate = pd.Timestamp(date.year, start_month, start_day)
    if date < candidate:
        # Fiscal year started in the previous calendar year
        candidate = pd.Timestamp(date.year - 1, start_month, start_day)
    return candidate


def is_leap_year(year: int) -> bool:
    return calendar.isleap(year)


def last_day_of_month(date: "pd.Timestamp") -> int:
    return calendar.monthrange(date.year, date.month)[1]


# MAIN

def main() -> None:
    # Allow overriding paths from the command line
    args     = sys.argv[1:]
    in_path  = Path(args[0]) if len(args) > 0 else Path(INPUT_CSV)
    out_path = Path(args[1]) if len(args) > 1 else Path(OUTPUT_CSV)

    print(f"Reading  : {in_path}")
    df = pd.read_csv(in_path, parse_dates=["Date"])
    print(f"  Rows   : {len(df)}")
    print(f"  Range  : {df['Date'].min().date()} → {df['Date'].max().date()}")

    # 1. Vectorised column derivation
    dt = df["Date"].dt  # DatetimeProperties accessor

    # Fiscal columns
    # Fiscal-year start for each date (as a Timestamp series)
    fiscal_starts = df["Date"].apply(
        fiscal_start_for,
        start_month=FISCAL_START_MONTH,
        start_day=FISCAL_START_DAY,
    )

    fiscal_day_0based = (df["Date"] - fiscal_starts).dt.days   # 0-based

    df["FiscalDay"]       = fiscal_day_0based + 1              # 1-based day
    df["FiscalWeek"]      = (fiscal_day_0based // 7) + 1       # week 1, 2, 3…
    df["FiscalDayInWeek"] = (fiscal_day_0based % 7)  + 1       # 1–7 within that week

    # Boolean / flag columns (stored as 0 / 1 integers)
    df["IsFirstDayOfWeek"]  = (df["CalendarDayInWeek"] == 1).astype(int)
    df["IsLastDayOfWeek"]   = (df["CalendarDayInWeek"] == 7).astype(int)

    df["IsFirstDayOfMonth"] = (dt.day == 1).astype(int)
    df["IsLastDayOfMonth"]  = (dt.day == df["Date"].apply(last_day_of_month)).astype(int)

    # First / last day of calendar year
    df["IsFirstDayOfYear"]  = ((dt.month == 1)  & (dt.day == 1)).astype(int)
    df["IsLastDayOfYear"]   = ((dt.month == 12) & (dt.day == 31)).astype(int)

    # Weekend: Saturday (6) or Sunday (7) using the existing CalendarDayInWeek
    df["IsWeekend"]  = (df["CalendarDayInWeek"] >= 6).astype(int)

    df["IsLeapYear"] = dt.year.apply(is_leap_year).astype(int)

    # 2. Save result
    df.to_csv(out_path, index=False, date_format="%Y-%m-%d")
    print(f"\nSaved to : {out_path}")

    print("\nDone.")


if __name__ == "__main__":
    main()
