# Run Notes And Self-Review

## Local Runtime

- R version: 4.6.0
- Main analysis package: Seurat 5.5.0
- Package lock: `renv.lock`
- Primary input: `data/raw/GSE136103_RAW.tar`
- Main workflow: `make check`, `make curate`, `make analyze`, `make refine-labels`, `make pseudobulk`, `make prioritize`, `make validation`, `make hsc-validation`, `make evidence`, `make translational-evidence`, `make dashboard`

## Decisions Made

- Used GEO count matrices as the reproducible input.
- Used GEO count matrices as the primary reproducible input and the published Seurat object as an annotation reference.
- Excluded blood and mouse samples from the primary human liver discovery contrast.
- Used marker-supported compartment calls for the required compartments and kept labels conservative.
- Labeled Seurat cell-level DE as exploratory and added donor-level pseudobulk DE as the primary inferential layer.
- Kept validation modular. GSE244832 was prepared and summarized for HSC/MASH validation, GSE207310 was staged for biomarker directionality, and SCP2154 remains a macrophage expansion path.
- Added public target evidence from Open Targets, ClinicalTrials.gov, ClinVar, MyGene.info, UniProt, PubMed, and mouse orthology mapping.

## Difficulties

- Seurat was not installed initially. It was installed locally and verified before analysis.
- Seurat v5 uses layered assays after merge. The workflow now calls `JoinLayers()` explicitly before marker scoring.
- `renv` initially saw an empty project library. I hydrated it from the local R library and then wrote the lockfile.
- Full object-level validation with GSE244832 was not run locally because the count matrix is large. Instead, the validation scripts stream compact candidate summaries and run a focused HSC-like cluster module.
- GSE244832 uses `NASH` in the processed metadata, while the current field commonly uses MASH. The report preserves the source label and interprets it as the MASH-relevant steatohepatitis state.
- The published reference object is an older Seurat object. The workflow reads the stored normalized matrix and metadata directly, then writes compact reference-informed outputs.

## Quality Checks Completed

- Confirmed 26 GEO libraries in the primary archive.
- Confirmed 20 primary human liver libraries were included.
- Confirmed 5 healthy and 5 cirrhotic donors were represented after inclusion.
- Checked required compartment recovery across disease states.
- Reviewed UMAP and marker dot plot figures.
- Corrected target scoring so curated macrophage genes do not borrow mesenchymal DE evidence.
- Confirmed dashboard data files were generated.
- Confirmed GSE244832 candidate-expression validation summaries were generated.
- Confirmed enriched candidate evidence table was generated.
- Confirmed published reference annotation summaries and refined cluster labels were generated.
- Confirmed donor-level pseudobulk DE generated priority-gene support tables.
- Confirmed focused GSE244832 HSC-like validation generated cluster scores and candidate summaries.
- Confirmed translational evidence and mouse orthology tables were generated.

## Highest-Value Improvements

1. Complete symbol-level GSE207310 validation with phenotype mapping.
2. Add a macrophage-specific public atlas module for TREM2, CD9, SPP1, and GPNMB.
3. Add spatial transcriptomics or spatial proteomics support for scar-niche localization.
4. Add perturbation assay templates for HSC spheroids, precision-cut liver slices, and co-culture readouts.
5. Improve cell annotation beyond three required compartments by adding hepatocyte, cholangiocyte, T/NK, B/plasma, mast, cycling, and ambiguous categories.
6. Convert markdown reports into a polished DOCX/PDF packet once the final README is rewritten.
