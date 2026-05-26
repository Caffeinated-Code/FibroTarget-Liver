# FibroTarget-Liver

**FibroTarget-Liver** is a reproducible single-cell workflow for human liver fibrosis, MASH, and cirrhosis target discovery. It starts from public count matrices, runs a Seurat-based analysis, validates priority candidates in orthogonal public data, enriches targets with public evidence, and packages the results as an executive report, ranked tables, figures, a Shiny dashboard, and a local/AWS Nextflow demo.

Primary discovery uses **GSE136103**, the Ramachandran et al. human cirrhosis scRNA-seq dataset. Validation uses **GSE244832** for MASH/HSC biology, **GSE207310** for bulk NAFLD/NASH directionality, and the excluded GSE136103 blood and mouse libraries for specificity and preclinical conservation checks.

## Read This First

1. [Executive summary](reports/executive_submission_summary.html): the short report, key results, translational interpretation, and next steps.
2. [Analysis walkthrough](docs/analysis_walkthrough.md): technical methods, why each choice was made, what was inferred, and where the caveats are.
3. [Written responses](reports/screening_responses/README.md): answers to the eight technical questions.
4. [Dashboard](dashboard/README.md): interactive UMAP, candidate table, scoring, DE, validation, and QC views.
5. [Nextflow demo](nextflow/fibrotarget_demo/README.md): local and AWS-ready reproducibility demo.

Supporting details are consolidated in [docs/technical_appendix.md](docs/technical_appendix.md).

## What This Answers

The analysis covers the requested outcomes:

| Outcome | Where to look |
|---|---|
| Dataset and metadata curation | `data/metadata/gse136103_sample_manifest.csv`, executive summary |
| QC and preprocessing choices | `workflow/03_compact_analysis.R`, analysis walkthrough |
| Major liver cell-type annotation | marker dot plot, refined labels, analysis walkthrough |
| Fibrosis/cirrhosis-associated genes and states | pseudobulk DE tables, executive summary |
| Pathway or mechanism analysis | Hallmark pathway table plus pathfindR Reactome active-subnetwork results from pseudobulk DE |
| Rule-based biomarker prioritization | scoring method and ranked candidate tables |
| Ranked 10-20 candidates | translational ranked candidate table and dashboard |
| Translational relevance | executive summary, written responses, evidence-enriched tables |
| Reproducibility | Makefile, `renv.lock`, Dockerfile, Nextflow demo |

## Main Results

The strongest fibrosis signal is a scar niche made of:

- activated stromal and HSC/myofibroblast-like cells
- scar-associated endothelial programs
- macrophage injury and repair states

The top candidates are best read by use case:

| Use case | Candidates | Interpretation |
|---|---|---|
| Fibrosis burden and pharmacodynamic readout | COL1A1, COL3A1, TIMP1 | Strong scar biology; collagens are markers, not direct targets |
| Secreted biomarker | SMOC2, TIMP1 | Practical assay potential; TIMP1 needs specificity checks |
| Scar vascular niche | ACKR1, PLVAP | Strong tissue-state markers; targeting needs vascular safety work |
| Therapeutic hypothesis | PDGFRA, PDGFRB | Druggable stromal receptor biology; safety window is central |
| Macrophage validation queue | TREM2, CD9, SPP1, GPNMB | Important disease-state biology; needs macrophage atlas and spatial validation |

The ranking intentionally separates biomarker value from therapeutic target value. A gene can be a strong fibrosis marker and still be a poor intervention point.

## Run Locally

Requirements:

- R 4.6.0
- Seurat 5.5.0
- `renv`
- Java and Nextflow for the demo workflow
- internet access for public GEO downloads if raw data are not already present

Run the full local workflow:

```bash
make all
```

Run the dashboard:

```bash
Rscript -e "shiny::runApp('dashboard')"
```

Run the standalone Nextflow demo:

```bash
make nextflow-demo
```

Validate the repo structure:

```bash
make validate-repo
```

## Key Files

```text
workflow/03_compact_analysis.R          Seurat preprocessing, clustering, UMAP, compartment calls
workflow/07_refine_annotations.R        Published-reference label refinement
workflow/08_pseudobulk_de.R             Donor-level pseudobulk DE
workflow/04_prioritize_targets.R        Candidate scoring and pathway enrichment
workflow/13_validate_blood_mouse_markers.R
                                        Blood specificity and mouse ortholog validation
reports/executive_submission_summary.Rmd
                                        Source for rendered executive summary
reports/tables/ranked_biomarker_target_candidates_translational.csv
                                        Final ranked candidate table
dashboard/app.R                         Shiny dashboard
nextflow/fibrotarget_demo/              Local/AWS demo pipeline
```

## Data Policy

Tracked:

- code and configuration
- metadata manifests
- demo data
- compact result tables and figures
- dashboard-ready CSVs
- reports and documentation

Not tracked:

- raw GEO archives
- extracted validation matrices
- large Seurat objects
- logs
- private notes

## References

- Ramachandran et al. Resolving the fibrotic niche of human liver cirrhosis at single-cell level. Nature, 2019.
- Rinella et al. Multisociety Delphi consensus statement on steatotic liver disease nomenclature. Hepatology, 2023.
- GSE136103, GSE244832, and GSE207310 GEO records.
