# Interviewer Guide

This guide is the fastest way to review the repository.

## What This Is

**FibroTarget-Liver** is a reproducible liver fibrosis target-discovery workflow. It combines a Seurat-based single-cell analysis, validation summaries from public MASH/NAFLD datasets, target evidence enrichment, an interactive dashboard, and an AWS/Nextflow production scaffold.

The repository is intentionally split into four layers:

1. **Analysis code**: reusable R and Python scripts in `workflow/`, `src/`, and `scripts/`.
2. **Reproducible pipelines**: `Makefile`, `config/project.yaml`, `Dockerfile`, `renv.lock`, and `nextflow/`.
3. **Demo and validation data products**: small tracked demo data and compact validation summaries.
4. **Review artifacts**: executive summary, figures, tables, dashboard, and written responses.

## Suggested Review Path

1. Start with [README.md](../README.md) for the project identity and key outputs.
2. Read the concise [Karyon submission summary](../reports/karyon_submission_summary.md).
3. Inspect the ranked table:
   - [ranked_biomarker_target_candidates_translational.csv](../reports/tables/ranked_biomarker_target_candidates_translational.csv)
4. Review the marker validation figure:
   - [required_compartment_marker_dotplot.png](../reports/figures/required_compartment_marker_dotplot.png)
5. Open the dashboard locally:

```bash
Rscript -e "shiny::runApp('dashboard')"
```

6. Review production readiness:
   - [architecture.md](architecture.md)
   - [io_contract.md](io_contract.md)
   - [reproducibility.md](reproducibility.md)
   - [nextflow/README.md](../nextflow/README.md)

## What To Look For

- The workflow starts from GEO count matrices as the reproducible primary input.
- Metadata curation explicitly excludes blood and mouse samples from the primary human liver analysis.
- Required fibrosis-relevant compartments are marker-validated.
- Donor-level pseudobulk DE is available and should be favored over exploratory cell-level DE.
- Target prioritization separates biomarker value from therapeutic target plausibility.
- Validation and public target evidence are modular and reproducible.
- Large raw and derived data are excluded from Git; compact outputs are tracked for review.

## Known Limitations

- GSE244832 is prepared and summarized for candidate validation, including focused HSC-like cluster validation; full object-level reanalysis is a future module.
- GSE207310 is staged, but symbol-level computed validation still needs Ensembl-to-symbol annotation.
- The Nextflow layer is a scaffold. Java was not available locally, so it was not executed on this machine.
