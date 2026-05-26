# Executive Submission Summary

FibroTarget-Liver is a reproducible single-cell workflow for human liver fibrosis, MASH, and cirrhosis target discovery. The analysis starts from public count matrices, uses Seurat for the local single-cell workflow, validates priority candidates in external public data, and separates diagnostic, pharmacodynamic, therapeutic, and future-validation use cases.

The full interactive report is rendered at [executive_submission_summary.html](executive_submission_summary.html). This Markdown file is a compact companion for quick review.

## TLDR

Primary discovery used GSE136103 human liver tissue. Blood and mouse libraries from the same study were excluded from the main contrast to avoid tissue and species confounding, then analyzed separately for marker specificity and preclinical conservation.

The main biological signal is a scar niche involving:

- activated stromal and HSC/myofibroblast-like cells
- scar-associated endothelial remodeling
- macrophage injury and repair states

The strongest translational point is that fibrosis markers and therapeutic targets are not the same thing. COL1A1, COL3A1, and TIMP1 are strong scar-burden readouts. PDGFRA and PDGFRB are more plausible perturbation hypotheses, but safety and tissue selectivity are central. TREM2, CD9, SPP1, and GPNMB stay in the macrophage validation queue until spatial and macrophage-atlas evidence is stronger.

## Analysis Outcomes

| Requested outcome | Status | Where to inspect |
|---|---|---|
| Dataset and metadata curation | Complete | `data/metadata/gse136103_sample_manifest.csv` |
| QC and preprocessing | Complete | `workflow/03_compact_analysis.R`, `reports/tables/qc_decision_log.csv` |
| Major liver cell-type annotation | Complete | `reports/figures/required_compartment_marker_dotplot.png`, `docs/analysis_walkthrough.md` |
| Fibrosis/cirrhosis-associated genes and states | Complete | `reports/tables/compartment_de_cell_level_exploratory.csv`, `reports/tables/pseudobulk_de_by_refined_state.csv` |
| Pathway or mechanism analysis | Complete | `reports/tables/hallmark_pathway_enrichment.csv`, pathway figures |
| Biomarker and target prioritization score | Complete | `reports/tables/target_prioritization_scoring_method.csv`, `reports/tables/target_prioritization_scoring_components.csv` |
| Ranked 10-20 candidates | Complete | `reports/tables/ranked_biomarker_target_candidates_translational.csv` |
| Translational interpretation | Complete | HTML report, dashboard, evidence-enriched target tables |
| Reproducibility | Complete | Makefile, `renv.lock`, Dockerfile, Nextflow demo |

## Methods In One Pass

The workflow curates GEO metadata, loads GSE136103 matrices, applies conservative QC, normalizes and clusters the human liver cells in Seurat, visualizes cells with UMAP, and assigns required disease compartments using marker programs.

The UMAP is a visual map of transcriptomic similarity, not a statistical test. Nearby cells have similar expression profiles in the reduced-dimensional Seurat space. Overlap between labels can reflect real biology, such as continuous HSC activation or shared wound-healing programs, but it can also reflect broad labels, mixed states, or imperfect reference transfer. Discrepant labels are handled conservatively: marker scoring, cluster context, and published-reference support must agree before a fine label is used. Otherwise the state stays broad or unresolved.

The published Ramachandran Seurat object is used as an annotation reference layer, not as the primary input. The analysis is rebuilt from GEO matrices, then the published `annotation_lineage` and `annotation_indepth` fields are used to refine cluster interpretation.

Cell-level DE is retained as an exploratory screen. Donor-level pseudobulk DE is the main inferential layer because donor, not cell, is the biological replicate.

Pathway analysis summarizes disease-up programs by compartment. The report includes Hallmark enrichment and a pathfindR Reactome active-subnetwork analysis from donor-level pseudobulk DE. pathfindR was added because it asks whether disease-up genes form connected protein-interaction modules before pathway enrichment, which is more useful for mechanism and target prioritization than a flat gene-list overlap alone.

The pathfindR module ran on HSC/myofibroblast and endothelial pseudobulk states. HSC/myofibroblast terms were dominated by extracellular matrix organization, collagen formation, elastic fiber biology, collagen crosslinking, extracellular matrix degradation, and integrin interactions. Endothelial terms were also generated where donor-supported signal was sufficient. Macrophage states were not forced through pathfindR because the compact pseudobulk run did not produce enough cirrhosis-up macrophage genes at FDR < 0.05.

## Candidate Classes

| Class | Example candidates | Interpretation |
|---|---|---|
| Diagnostic biomarker | SMOC2, TIMP1, ACKR1, PLVAP | useful for disease-state or scar-niche detection |
| Pharmacodynamic biomarker | COL1A1, COL3A1, TIMP1 | useful as burden or response readouts |
| Therapeutic hypothesis | PDGFRA, PDGFRB | plausible intervention biology, needs safety and perturbation evidence |
| Future validation marker | TREM2, CD9, SPP1, GPNMB | compelling biology, not ready for nomination without deeper validation |

## Validation

GSE244832 was used as the first external MASH/HSC validation module. Candidate genes were harmonized by gene symbol, HSC-like clusters were summarized, and expression was compared across source conditions. The HTML report now uses the NORMAL to NAFL to NASH line plot as the primary view because it is easier to interpret than the heatmap for directionality.

GSE207310 was used for independent bulk NAFLD/NASH directionality after mapping Ensembl IDs to gene symbols. The bar plot is the primary view because it shows the NASH versus NAFL direction directly. This supports directionality but cannot prove cell of origin.

GSE136103 blood libraries were used to flag broad circulating expression. GSE136103 mouse libraries were used as an ortholog conservation screen. The mouse module is useful for directionality, not powered preclinical DE, because the compact screen has one healthy and one fibrotic mouse sample.

## Reproducibility

The repo includes:

- `Makefile` targets for local execution
- `renv.lock` for R package pinning
- `Dockerfile` for a containerized R runtime
- `scripts/validate_repo_structure.py` for repo hygiene checks
- `dashboard/app.R` for interactive review
- `nextflow/fibrotarget_demo/` for a local and AWS-ready workflow contract test

The Nextflow demo reads a tracked 10x-style toy dataset, attaches metadata, computes QC and candidate-gene summaries, and writes expected outputs. It proves pipeline wiring and I/O behavior. It does not yet replace the full Seurat analysis.

## Most Useful Next Steps

1. Spatial and protein validation for SMOC2, TIMP1, PLVAP, ACKR1, PDGFRA/B, and macrophage-state markers.
2. Full all-gene GSE244832 reanalysis on AWS.
3. Macrophage-focused external atlas validation for TREM2, CD9, SPP1, and GPNMB.
4. full pathfindR term clustering and ReactomePA comparison module.
5. LIANA, NicheNet, or CellChat communication analysis with donor, receiver-response, and pathfindR-supported pathway filters.
6. Perturbation assays before nominating therapeutic programs.
