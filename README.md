# equativ-api-reporting
# Equativ API Reporting

Python and PowerShell scripts for testing Equativ API reporting access, exporting reporting data, and preparing API outputs for analysis.

This project was created to work with Equativ reporting endpoints, validate which metrics and dimensions are available under the current API credentials, and export performance data into structured files for further analysis in Excel, SQLite, Power BI, or Python.

---

## Project Purpose

The goal of this repository is to organize reusable scripts for:

- Requesting an OAuth access token from the Equativ API
- Querying reporting endpoints
- Testing available metrics and dimensions
- Exporting report results to CSV
- Preparing reporting data for future database storage or dashboarding

The scripts are read-only and are intended for reporting and analysis only.

They do not create, update, delete, pause, or modify campaigns, deals, pricing, or platform configuration.

---

## Files

### `reporte.py`

Main Python reporting script.

It connects to the Equativ `/report` endpoint, requests reporting data using selected metrics and dimensions, and exports the response to a CSV file.

Example metrics included:

- Impressions
- Clicks
- Buyer spend
- Click rate
- eCPC
- Gross eCPM
- Video completions
- Completion rate
- Viewability rate
- Viewable impressions

Example dimensions included:

- Country
- Creative size
- Device type
- DSP
- Environment type

Output file:

```text
reporte_equativ.csv
