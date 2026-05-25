# Karyon Bio Submission Summary

## Project

**FibroTarget-Liver** is a compact, reproducible single-cell workflow for discovering and prioritizing cell-type-specific biomarkers and therapeutic target candidates in human liver fibrosis. The primary analysis uses **GSE136103**, a human liver cirrhosis scRNA-seq dataset, and validates selected candidates with **GSE244832**, a MASLD/MASH hepatic stellate cell-focused dataset. GSE207310 is staged as a second validation source for SMOC2 and NAFLD/NASH biomarker directionality.

The repository is organized as an analysis pipeline with clear boundaries across `Makefile`, `renv.lock`, `Dockerfile`, `config/project.yaml`, `workflow/`, `scripts/`, `nextflow/`, `reports/`, and `dashboard/`. Raw data, large Seurat objects, validation matrices, private notes, and the assignment PDF are excluded from Git.

## What Was Done

The workflow starts from public GEO count matrices as the reproducible input. It curates GSE136103 metadata, excludes blood and mouse samples from the primary human liver contrast, builds Seurat objects, applies QC, normalizes, clusters, and generates UMAPs. Required disease-relevant compartments were recovered and marker-validated:

- **HSC/mesenchymal/myofibroblast-like cells:** COL1A1, COL3A1, ACTA2, TAGLN, PDGFRA, PDGFRB, LUM, DCN, RGS5
- **Macrophage/monocyte populations:** TREM2, CD9, SPP1, GPNMB, LST1, C1QA, C1QB, C1QC
- **Endothelial cells:** ACKR1, PLVAP, VWF, PECAM1, KDR, RAMP2, ENG

The published Ramachandran Seurat annotation object was then used as a reference layer. The workflow reads its `annotation_lineage` and `annotation_indepth` metadata and writes refined cluster labels while preserving GEO count matrices as the primary analysis input.

Differential expression is reported in two layers. Cell-level DE is kept as exploratory because cells are not independent biological replicates. Donor-level pseudobulk DE is the primary inferential layer and aggregates counts by donor and refined cell state before fitting limma models for cirrhotic versus healthy liver.

Pathway analysis summarizes fibrosis-relevant mechanisms, including extracellular matrix remodeling, endothelial remodeling, coagulation/junction programs, hypoxia, glycolysis, lipid metabolism, and macrophage-associated inflammatory or repair states.

## Candidate Prioritization

Candidate ranking uses a transparent rule-based score suited to the dataset size and donor structure. The score considers disease association, compartment specificity, donor-aware support, pathway support, external validation, protein modality, mouse conservation, tractability, and safety or specificity risk.

The strongest near-term translational candidates fall into distinct use cases:

- **SMOC2:** secreted HSC-associated biomarker candidate. Stronger as a diagnostic or pharmacodynamic marker before direct target nomination.
- **TIMP1:** secreted fibrosis and matrix-remodeling biomarker. Useful for pharmacodynamic monitoring, but broad injury biology limits specificity.
- **PDGFRA/PDGFRB:** druggable HSC/pericyte signaling axis with therapeutic plausibility. Safety-window and tissue-specific delivery questions are central.
- **PLVAP/ACKR1:** scar-associated endothelial markers. Strong vascular niche candidates; intervention requires caution because of vascular and immune-trafficking biology.
- **COL1A1/COL3A1:** excellent fibrosis burden and pharmacodynamic endpoints, but poor direct therapeutic targets because collagen biology is essential for normal tissue repair.
- **TREM2/CD9/SPP1/GPNMB:** macrophage-state candidates. These are important for disease-state validation and mechanism studies, but require macrophage-focused external validation before target nomination.

## Validation And Translational Evidence

GSE244832 was selected as the first validation dataset because it is human, MASLD/MASH-focused, and centered on HSC activation. The local module streams candidate summaries from the processed matrix, identifies HSC-like clusters using stromal and myofibroblast markers, and evaluates SMOC2, TIMP1, COL1A1, COL3A1, PDGFRA, and PDGFRB across NORMAL, NAFL, and NASH labels.

Key validation signal: SMOC2, TIMP1, PDGFRA, and PDGFRB show higher expression in HSC-like NASH clusters than normal HSC-like clusters. COL1A1 and COL3A1 remain strong fibrosis burden markers, but the validation pattern supports using them as endpoints rather than direct targets.

Public evidence enrichment adds UniProt localization and tissue comments, PubMed perturbation/safety signal, ClinicalTrials.gov context, Open Targets tractability/safety annotations, ClinVar counts, and mouse orthology through `babelgene`. These are triage layers, not proof of causality.

## What To Review

- Main README: `README.md`
- Written screening responses: `reports/screening_responses/README.md`
- Requirement traceability: `reports/requirement_traceability.md`
- Ranked translational candidates: `reports/tables/ranked_biomarker_target_candidates_translational.csv`
- Donor-level pseudobulk support: `reports/tables/pseudobulk_priority_gene_de.csv`
- GSE244832 HSC validation: `reports/tables/gse244832_hsc_candidate_validation.csv`
- Interactive dashboard: `Rscript -e "shiny::runApp('dashboard')"`

## Limitations And Next Steps

The compact workflow is designed to show scientific judgment and execution, not to claim a final therapeutic program. GSE207310 still needs symbol-level computed validation and phenotype mapping. Macrophage candidates need an additional macrophage-focused atlas such as SCP2154 or another accessible fibrosis atlas. PLVAP, ACKR1, SMOC2, TIMP1, and collagen candidates should be validated with spatial transcriptomics, immunostaining, or proteomics to confirm scar-niche localization. PDGFRA/B target nomination should move next into perturbation assays such as HSC spheroids, co-culture, or precision-cut liver slices.

No clarifying questions remain for the submitted compact assignment.
