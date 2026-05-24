# Executive Summary

## Objective

This project uses the Ramachandran et al. human liver cirrhosis single-cell RNA-seq dataset, GSE136103, to identify fibrosis-associated cell states and prioritize a short list of cell-type-linked biomarker and therapeutic target candidates.

The analysis focuses on three disease-relevant compartments:

- hepatic stellate, mesenchymal, and myofibroblast-like cells
- macrophage and monocyte populations
- endothelial cells

## What Was Run

The local pipeline uses R and Seurat 5.5.0. Public GEO count matrices were used as the reproducible input. The analysis included 20 primary human liver libraries from 5 healthy and 5 cirrhotic donors. Blood and mouse samples in the GEO archive were excluded from the primary human tissue contrast and documented in the metadata manifest.

Major steps:

1. Curated sample-level metadata from the GEO archive.
2. Built Seurat objects per library and merged the primary human liver samples.
3. Applied conservative QC using gene counts and mitochondrial fraction.
4. Normalized, selected variable genes, scaled, ran PCA, clustered, and generated UMAP embeddings.
5. Used marker programs to recover required macrophage, endothelial, and mesenchymal compartments.
6. Ran exploratory compartment-level cirrhotic versus healthy differential expression.
7. Ran Hallmark pathway enrichment on compartment-specific upregulated genes.
8. Built a transparent target prioritization score using data support, biology, validation evidence, modality, conservation, and translational risk.
9. Prepared dashboard-ready files for interactive review.

## Key Findings

The required disease-relevant compartments were recovered across both healthy and cirrhotic donors. Marker validation supported the broad calls:

- Mesenchymal/HSC/myofibroblast-like cells expressed COL1A1, COL3A1, ACTA2, TAGLN, PDGFRB, LUM, DCN, RGS5, and PDGFRA.
- Macrophage/monocyte populations expressed CD9, SPP1, GPNMB, FABP5, CD63, LST1, and complement genes.
- Endothelial populations expressed ACKR1, PLVAP, VWF, PECAM1, KDR, RAMP2, and ENG.

The analysis reproduced major biology from the original fibrotic niche paper: scar-associated endothelial markers ACKR1 and PLVAP, collagen-rich mesenchymal programs, and macrophage-associated disease signals.

Top ranked candidates in this compact run included ACKR1, PLVAP, TIMP1, COL3A1, COL1A1, MMP2, SPP1, PDGFRA, VWF, THY1, DCN, CD9, LUM, ACTA2, PDGFRB, TREM2, SMOC2, SERPINE1, LOXL2, and GPNMB.

## Interpretation

The strongest immediate biomarker signals are endothelial and matrix/stromal. ACKR1 and PLVAP are consistent with scar-associated endothelial remodeling in cirrhosis. COL1A1, COL3A1, TIMP1, LUM, DCN, and MMP2 reflect scar matrix and remodeling biology, but most are better positioned as tissue-state or pharmacodynamic markers than direct therapeutic targets.

The most plausible therapeutic target class in this compact analysis is receptor or enzyme biology connected to activated stromal states. PDGFRA and PDGFRB are biologically coherent, druggable receptor tyrosine kinases, but safety and vascular or broad mesenchymal effects would need careful review. LOXL2 is mechanistically attractive as a collagen crosslinking enzyme, although prior clinical fibrosis efforts make it a high-risk target rather than a simple win.

Macrophage candidates require more caution. SPP1 and CD9 have direct signal in the compact analysis. TREM2 and GPNMB are retained because of strong external and published disease-state evidence, but they did not receive direct compartment-matched DE support in this marker-score run. They should be considered macrophage-state biomarkers or validation priorities before being treated as target candidates.

SMOC2 is a strong translational biomarker candidate despite modest signal in the cirrhosis single-cell analysis. GSE207310 and the associated publication support SMOC2 as an HSC-linked secreted marker associated with human NAFLD/NASH severity and plasma detection.

## Pathway-Level Biology

Hallmark enrichment supported biologically plausible mechanisms:

- Mesenchymal/HSC/myofibroblast-like upregulated genes were enriched for epithelial-mesenchymal transition, coagulation, glycolysis, hypoxia, and apical junction programs.
- Endothelial upregulated genes showed junction, coagulation, cholesterol homeostasis, and vascular remodeling-related signals.
- Macrophage/monocyte upregulated genes showed metabolic and lipid-associated programs, including oxidative phosphorylation, fatty acid metabolism, adipogenesis, peroxisome, and cholesterol homeostasis.

These results should be interpreted as mechanism summaries, not proof of causality.

## Validation Strategy

GSE244832 is the highest-priority validation dataset because it is human, MASLD/MASH-focused, single-nucleus and multiomic, and centered on hepatic stellate cell activation. It is also large, with a processed archive around 693 MB, so it should be run as a separate validation job when time and compute allow.

GSE207310 is the strongest lightweight validation source for translational directionality because it is human liver biopsy bulk RNA-seq with NASH and no-NAFLD comparison and directly supports SMOC2 as a secreted HSC-linked biomarker.

SCP2154 is most relevant for macrophage-state validation but is portal-dependent. It is best handled as an expansion module rather than a blocker for the primary analysis.

## Limitations

This is a compact analysis, not a full production-grade discovery program.

- Cell-level DE is exploratory because cells from the same donor are not independent biological replicates.
- Marker-score compartment calls recover the required broad compartments but do not replace full expert annotation.
- Cirrhosis and MASH fibrosis overlap biologically but are not identical disease contexts.
- Single-cell and single-nucleus validation datasets can differ in cell capture and expression profiles.
- Ligand-receptor and target claims require perturbational validation.

## Recommended Next Experiments

1. Re-run differential expression with donor-level pseudobulk models per refined cell state.
2. Use the published Seurat annotation object as a reference to refine cluster labels.
3. Run GSE244832 as the first external validation module, focused on HSC/myofibroblast candidates.
4. Validate SMOC2, TIMP1, PLVAP, ACKR1, COL1A1/COL3A1, PDGFRA/B, and macrophage-state candidates against orthogonal public data.
5. For target candidates, add protein localization, tissue specificity, mouse conservation, safety, and perturbation evidence before nominating a therapeutic program.

## Key References

- Ramachandran et al. Resolving the fibrotic niche of human liver cirrhosis at single-cell level. Nature, 2019. https://www.nature.com/articles/s41586-019-1631-3
- Rinella et al. A multisociety Delphi consensus statement on new fatty liver disease nomenclature. Hepatology, 2023. https://pubmed.ncbi.nlm.nih.gov/37363821/
- FDA Drug Trials Snapshot: Rezdiffra, original approval March 14, 2024. https://www.fda.gov/drugs/drug-approvals-and-databases/drug-trials-snapshots-rezdiffra
- Ravnskjaer et al. Stellate cell expression of SMOC2 is associated with human NAFLD severity. Journal of Hepatology Reports, 2022. https://pmc.ncbi.nlm.nih.gov/articles/PMC9850195/
- GSE244832 GEO record. https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE244832
