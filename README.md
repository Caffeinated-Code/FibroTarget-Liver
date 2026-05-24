# Reproducible Single-Cell Pipeline for Human Liver Fibrosis

This repository is a compact, reproducible mini-pipeline for discovering and prioritizing cell-type-specific biomarkers and therapeutic targets in human liver fibrosis.

The primary discovery dataset is **GSE136103**, the Ramachandran et al. human liver cirrhosis single-cell RNA-seq study. The analysis is designed to demonstrate practical bioinformatics execution, biological judgment, and translational prioritization rather than a publication-scale reanalysis.

## Project Goals

- Curate and summarize public human liver fibrosis single-cell data.
- Reprocess public count matrices where feasible, using published objects as annotation references and quality checks.
- Identify fibrosis-associated cell populations and disease-linked transcriptional programs.
- Focus on disease-relevant compartments:
  - hepatic stellate, mesenchymal, and myofibroblast-like cells
  - macrophage and monocyte populations
  - endothelial cells
- Prioritize biomarkers and therapeutic target candidates with clear translational rationale.
- Validate high-priority candidates using external public datasets when practical.
- Deliver outputs as a reproducible analysis, concise report, and interactive dashboard.

## Analysis Strategy

The pipeline will use **R/Seurat** as the main analysis framework. The intended workflow is:

1. Dataset acquisition and metadata curation
2. QC and preprocessing
3. Cell-type annotation and marker validation
4. Compartment-specific disease association testing
5. Pathway and mechanism analysis
6. Biomarker and therapeutic target prioritization
7. External validation
8. Interactive dashboard generation
9. Executive summary and written interpretation

Differential expression will be donor-aware where metadata support pseudobulk testing. Cell-level testing, if used, will be treated as exploratory and interpreted with caution.

## Target Prioritization

Candidate biomarkers and targets will be scored using a transparent rule-based framework that considers:

- fibrosis association and effect size
- cell-type or cell-state specificity
- donor/sample consistency
- validation across external datasets
- pathway and mechanism support
- secreted, surface, or druggable protein status
- assayability as a diagnostic or pharmacodynamic biomarker
- conservation in model organisms relevant to preclinical studies
- translational risk, including tissue specificity and likely safety concerns

The output will separate diagnostic biomarkers, pharmacodynamic biomarkers, therapeutic targets, and mechanistic markers. The goal is to avoid overclaiming: a strong fibrosis marker is not automatically a good therapeutic target.

## Validation Datasets

Planned validation sources include:

- **GSE244832**: human MASLD/MASH single-nucleus and multiomic dataset focused on hepatic stellate cell activation and anti-fibrotic target discovery.
- **GSE207310**: human NAFLD/NASH liver biopsy bulk RNA-seq dataset suitable for translational directionality checks.
- **SCP2154**: human liver fibrosis macrophage atlas, used if access and runtime are practical.

If time or infrastructure limits full validation, GSE244832 will be prioritized because it is human, MASH-relevant, single-nucleus, fibrosis-centered, and directly informative for hepatic stellate cell and myofibroblast biology.

## Reproducibility

This repository will be developed as a scalable analysis project rather than a single-use notebook. Planned reproducibility features include:

- Git-based version control from project start
- Dockerized runtime
- `renv` package lockfile
- config-driven dataset and threshold settings
- modular scripts or Quarto notebooks
- stable output folders for figures, tables, logs, and dashboard-ready data
- README instructions for rerunning the workflow

Large raw data, generated single-cell objects, logs, caches, and private local notes are excluded from version control.

## Communication Principles

The final report will be concise, critical, and biologically grounded. Interpretation will emphasize what is supported by the data, what is uncertain, and what should be validated next. The target audience is an industry team evaluating single-cell analysis judgment, liver fibrosis biology, and translational prioritization.
