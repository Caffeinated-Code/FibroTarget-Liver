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
2. Read the [executive summary](../reports/executive_summary/README.md).
3. Inspect the ranked table:
   - [ranked_biomarker_target_candidates_enriched.csv](../reports/tables/ranked_biomarker_target_candidates_enriched.csv)
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

- The workflow starts from GEO count matrices, not a hidden Seurat object.
- Metadata curation explicitly excludes blood and mouse samples from the primary human liver analysis.
- Required fibrosis-relevant compartments are marker-validated.
- Differential expression is labeled as exploratory because cell-level tests can inflate confidence.
- Target prioritization separates biomarker value from therapeutic target plausibility.
- Validation and public target evidence are modular and reproducible.
- Large raw and derived data are excluded from Git; compact outputs are tracked for review.

## Known Limitations

- Donor-aware pseudobulk DE is the most important next statistical improvement.
- GSE244832 is prepared and summarized for candidate validation, but full object-level reanalysis is a future module.
- GSE207310 is staged, but symbol-level computed validation still needs Ensembl-to-symbol annotation.
- The Nextflow layer is a scaffold. Java was not available locally, so it was not executed on this machine.
