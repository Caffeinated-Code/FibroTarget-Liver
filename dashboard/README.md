# Interactive Dashboard

The dashboard is a Shiny app for reviewing the compact analysis outputs.

Run from the repository root:

```bash
Rscript -e "shiny::runApp('dashboard')"
```

Views:

- UMAP colored by disease state, donor, fraction, or compartment
- ranked candidate table
- exploratory differential expression table
- pathway enrichment table
- QC summary

The app reads precomputed CSVs from `dashboard/data/`. It does not rerun the full Seurat workflow.
