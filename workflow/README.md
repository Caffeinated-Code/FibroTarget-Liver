# Workflow Scripts

These scripts are ordered pipeline stages. They are not exploratory notebooks.

| Step | Script | Purpose |
|---|---|---|
| 00 | `00_setup.R` | Validate runtime and create expected folders |
| 01 | `01_fetch_data.R` | Download or verify primary GEO input |
| 02 | `02_curate_metadata.R` | Build sample manifest and inclusion/exclusion table |
| 03 | `03_compact_analysis.R` | Run Seurat QC, clustering, marker validation, exploratory DE |
| 04 | `04_prioritize_targets.R` | Score biomarker and target candidates |
| 05 | `05_prepare_dashboard_data.R` | Copy compact outputs into dashboard-ready files |
| 06 | `06_write_reports.R` | Check final report artifacts |

Run through `make` rather than executing scripts manually.
