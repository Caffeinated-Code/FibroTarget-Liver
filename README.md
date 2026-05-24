# Human Liver Fibrosis Single-Cell Target Discovery

This repository analyzes public human liver single-cell RNA-seq data to identify fibrosis-associated cell states and prioritize biomarker or therapeutic target candidates with translational rationale.

The primary discovery dataset is **GSE136103**, the Ramachandran et al. human cirrhosis single-cell RNA-seq study. The local workflow uses **R/Seurat** and starts from the public GEO count matrices. The analysis focuses on three compartments central to liver fibrosis biology: activated mesenchymal and myofibroblast-like cells, macrophage and monocyte populations, and endothelial cells.

## Key Outputs

- Executive summary: [reports/executive_summary/README.md](reports/executive_summary/README.md)
- Written screening responses: [reports/screening_responses/README.md](reports/screening_responses/README.md)
- Biology primer: [docs/biology_primer_liver_fibrosis.docx](docs/biology_primer_liver_fibrosis.docx)
- Ranked candidates: [reports/tables/ranked_biomarker_target_candidates.csv](reports/tables/ranked_biomarker_target_candidates.csv)
- Pathway enrichment: [reports/tables/hallmark_pathway_enrichment.csv](reports/tables/hallmark_pathway_enrichment.csv)
- Validation feasibility: [reports/tables/validation_dataset_feasibility.csv](reports/tables/validation_dataset_feasibility.csv)
- Interactive dashboard: [dashboard/app.R](dashboard/app.R)
- AWS production notes: [docs/aws_production_notes.md](docs/aws_production_notes.md)

## Main Findings

The compact Seurat analysis recovered the required disease-relevant compartments across healthy and cirrhotic donors. Marker validation supported broad mesenchymal/HSC/myofibroblast-like, macrophage/monocyte, and endothelial calls.

The highest ranked candidates include scar-associated endothelial markers **ACKR1** and **PLVAP**, stromal and matrix remodeling markers **TIMP1**, **COL3A1**, **COL1A1**, **MMP2**, **PDGFRA**, **THY1**, **DCN**, and **LUM**, and macrophage-associated candidates **SPP1** and **CD9**. **TREM2**, **GPNMB**, **SMOC2**, **LOXL2**, **SERPINE1**, and **PDGFRB** are retained as biologically important validation or translational candidates, with explicit caveats in the ranked table and executive summary.

The main biological interpretation is that strong fibrosis readouts are not automatically strong drug targets. Matrix genes are useful biomarkers and pharmacodynamic markers, while receptor, surface, secreted, or enzyme candidates require additional validation for specificity, safety, conservation, and perturbation response.

## Reproduce Locally

Requirements:

- R 4.6.0
- Seurat 5.5.0
- `renv`
- internet access for public GEO downloads if raw data are not already present

Run:

```bash
make check
make fetch-data
make curate
make analyze
make prioritize
make dashboard
make report
```

To launch the dashboard:

```bash
Rscript -e "shiny::runApp('dashboard')"
```

Large raw files and Seurat objects are not committed to Git. The repository tracks the code, configuration, small metadata tables, final review tables, figures, reports, dashboard app, and reproducibility files.

## Repository Structure

```text
config/                 Pipeline and AWS-ready configuration
workflow/               Modular R workflow steps
src/R/                  Shared R utilities
reports/                Figures, tables, executive summary, written responses
dashboard/              Shiny dashboard and dashboard-ready data
docs/                   Biology primer and AWS production notes
data/metadata/          Small curated metadata manifests
```

## Validation Strategy

The project records three validation paths:

- **GSE244832** for human MASLD/MASH stellate cell and myofibroblast validation
- **GSE207310** for human NAFLD/NASH bulk liver directionality, especially SMOC2
- **SCP2154** for macrophage-state validation when portal access and export format are practical

GSE244832 is the highest-priority next validation module because it is human, MASH-relevant, single-nucleus and multiomic, and focused on hepatic stellate cell activation.

## Important Caveats

The current differential expression is exploratory cell-level DE. Cells from the same donor are not independent biological replicates, so donor-aware pseudobulk testing is the next highest-value improvement. The current compartment labels are marker-supported broad calls, not a final expert cell atlas annotation.

References and interpretation details are included in the executive summary.
