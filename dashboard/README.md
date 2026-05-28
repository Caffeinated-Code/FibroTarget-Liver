# Interactive Dashboard

The dashboard is a Shiny app for reviewing the compact analysis outputs with a cleaner, submission-facing view of the UMAP, target shortlist, scoring evidence, validation tables, pathway results, and QC decisions.

Run from the repository root:

```bash
Rscript -e "shiny::runApp('dashboard')"
```

Main views:

- overview UMAP colored by disease state, donor, fraction, compartment, or refined label
- ranked candidate table with class and use-case filters
- scoring components and scoring method
- donor-level pseudobulk priority-gene DE
- GSE244832 HSC validation
- blood and mouse secondary validation
- reference-supported labels with cluster cell counts and disease composition
- cell-level exploratory DE
- Hallmark enrichment and pathfindR pseudobulk pathway outputs
- QC decision, filter, and metric summaries

The app reads precomputed CSVs from `dashboard/data/`. It does not rerun the full Seurat workflow.
