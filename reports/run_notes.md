# Run Notes And Self-Review

## Local Runtime

- R version: 4.6.0
- Main analysis package: Seurat 5.5.0
- Package lock: `renv.lock`
- Primary input: `data/raw/GSE136103_RAW.tar`
- Main workflow: `make check`, `make curate`, `make analyze`, `make prioritize`, `make dashboard`

## Decisions Made

- Used GEO count matrices as the reproducible input.
- Kept the published Seurat object as a reference concept, not a dependency, because the assignment asks for QC and preprocessing choices.
- Excluded blood and mouse samples from the primary human liver discovery contrast.
- Used marker-supported compartment calls for the required compartments rather than overclaiming full cell-type annotation.
- Labeled Seurat cell-level DE as exploratory because donor-level pseudobulk is the better inferential strategy.
- Kept validation modular. GSE244832 is prioritized for future HSC/MASH validation, GSE207310 supports SMOC2 translational evidence, and SCP2154 is a macrophage expansion path.

## Difficulties

- Seurat was not installed initially. It was installed locally and verified before analysis.
- Seurat v5 uses layered assays after merge. The workflow now calls `JoinLayers()` explicitly before marker scoring.
- `renv` initially saw an empty project library. I hydrated it from the local R library and then wrote the lockfile.
- Full validation with GSE244832 was not run locally because the processed archive is large and should be treated as a separate validation job. The pipeline is structured so that module can be added cleanly.
- The current DE is exploratory cell-level DE. A donor-aware pseudobulk module is the most important next improvement.

## Quality Checks Completed

- Confirmed 26 GEO libraries in the primary archive.
- Confirmed 20 primary human liver libraries were included.
- Confirmed 5 healthy and 5 cirrhotic donors were represented after inclusion.
- Checked required compartment recovery across disease states.
- Reviewed UMAP and marker dot plot figures.
- Corrected target scoring so curated macrophage genes do not borrow mesenchymal DE evidence.
- Confirmed dashboard data files were generated.

## Highest-Value Improvements

1. Add donor-aware pseudobulk DE per refined cell state.
2. Incorporate the authors' released annotation object for reference mapping and label refinement.
3. Run focused GSE244832 validation for HSC/myofibroblast candidates.
4. Add a small public-resource annotation layer for protein class, Human Protein Atlas tissue specificity, Open Targets or ChEMBL druggability, and formal human-mouse orthology.
5. Improve cell annotation beyond three required compartments by adding hepatocyte, cholangiocyte, T/NK, B/plasma, mast, cycling, and ambiguous categories.
6. Convert markdown reports into a polished DOCX/PDF packet once the final README is rewritten.
