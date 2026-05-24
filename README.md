# Human Liver Fibrosis Single-Cell Target Discovery

This repository develops a reproducible workflow for identifying cell-type-specific biomarkers and therapeutic target candidates in human liver fibrosis. The analysis centers on the Ramachandran et al. cirrhosis single-cell RNA-seq dataset (**GSE136103**) and is structured to support practical target triage in a translational R&D setting.

Liver fibrosis is not a single-cell-type problem. Activated mesenchymal cells produce and remodel scar, macrophage states shape inflammatory and tissue-repair programs, and endothelial remodeling changes the fibrotic niche. This project uses single-cell data to connect those disease-associated cell states to candidate biomarkers and targets that can be evaluated for diagnostic, pharmacodynamic, or therapeutic use.

## Scientific Focus

The primary analysis asks four questions:

1. Which liver cell populations and states are enriched or transcriptionally remodeled in cirrhosis?
2. Which genes are disease-associated within stellate/mesenchymal, macrophage/monocyte, and endothelial compartments?
3. Which signals are supported by fibrosis biology, pathway context, and external datasets?
4. Which candidates are most plausible for translation into assays, perturbation studies, or therapeutic programs?

The goal is not to generate a long marker list. The goal is to produce a defensible short list with clear evidence, caveats, and next-step experiments.

## Approach

The workflow uses **R/Seurat** for core single-cell analysis and is organized as a modular, reproducible pipeline:

1. Curate dataset metadata and sample-level disease labels.
2. Ingest public count matrices where available, using the published object as an annotation and QC reference.
3. Perform QC with attention to liver disease biology, avoiding removal of stressed but biologically meaningful cells.
4. Validate major liver compartments using canonical and disease-state markers.
5. Test disease association within key compartments, using donor-aware approaches where metadata permit.
6. Summarize mechanisms through pathway and gene-set analysis.
7. Prioritize candidates using biological, statistical, translational, and preclinical evidence.
8. Present results in static reports and an interactive dashboard.

Cell-level findings are interpreted cautiously because cells from the same donor are not independent biological replicates. Where possible, donor/sample-level aggregation is used to support disease-associated signals.

## Prioritization Framework

Candidate ranking integrates multiple evidence layers:

- strength and consistency of disease association
- compartment or cell-state specificity
- pathway support and fit to known fibrosis mechanisms
- external validation in public MASLD/MASH or fibrosis datasets
- secreted, surface, or druggable protein status
- feasibility as a diagnostic or pharmacodynamic biomarker
- conservation in model organisms used for preclinical studies
- translational risk, including broad tissue expression or likely safety concerns

Candidates are grouped by likely use case: diagnostic biomarker, pharmacodynamic biomarker, therapeutic target, or mechanistic marker. This distinction matters because a robust disease marker is not automatically a safe or actionable drug target.

## External Validation

Validation is designed to be pragmatic and evidence-weighted:

- **GSE244832**: human MASLD/MASH single-nucleus and multiomic data, prioritized for stellate cell and myofibroblast validation.
- **GSE207310**: human NAFLD/NASH liver biopsy bulk RNA-seq, used for directionality checks in translational tissue data.
- **SCP2154**: human liver fibrosis macrophage atlas, used if access and runtime allow focused macrophage validation.

If compute or access constraints limit validation, the workflow prioritizes the dataset that best matches the biological question rather than treating all public datasets as equally informative.

## Reproducibility

The project is built to be rerun and reviewed:

- version-controlled analysis code
- Dockerized runtime
- `renv` package lockfile
- config-driven dataset paths and thresholds
- modular scripts or Quarto notebooks
- stable output directories for figures, tables, logs, and dashboard inputs
- generated single-cell objects and raw data excluded from Git

The intended final deliverables are a reproducible analysis repository, ranked candidate table, pathway summaries, validation evidence, an interactive dashboard, and a concise executive summary suitable for review by computational, biology, and translational stakeholders.
