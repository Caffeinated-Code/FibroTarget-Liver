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
10. Refined cluster labels against the published Ramachandran Seurat annotation object from Edinburgh DataShare.
11. Re-ran disease differential expression as donor-level pseudobulk models per refined cell state.
12. Ran focused GSE244832 validation for HSC/myofibroblast candidates.
13. Added public target evidence from Open Targets, ClinicalTrials.gov, ClinVar, UniProt, PubMed, and mouse orthology mapping.

## Key Findings

The required disease-relevant compartments were recovered across both healthy and cirrhotic donors. Marker validation supported the broad calls:

- Mesenchymal/HSC/myofibroblast-like cells expressed COL1A1, COL3A1, ACTA2, TAGLN, PDGFRB, LUM, DCN, RGS5, and PDGFRA.
- Macrophage/monocyte populations expressed CD9, SPP1, GPNMB, FABP5, CD63, LST1, and complement genes.
- Endothelial populations expressed ACKR1, PLVAP, VWF, PECAM1, KDR, RAMP2, and ENG.

The analysis reproduced major biology from the original fibrotic niche paper: scar-associated endothelial markers ACKR1 and PLVAP, collagen-rich mesenchymal programs, and macrophage-associated disease signals.

Top ranked candidates in this compact run included ACKR1, PLVAP, TIMP1, COL3A1, COL1A1, MMP2, SPP1, PDGFRA, VWF, THY1, DCN, CD9, LUM, ACTA2, PDGFRB, TREM2, SMOC2, SERPINE1, LOXL2, and GPNMB. The new donor-level pseudobulk module adds a stricter evidence layer and should be favored over cell-level DE when nominating targets.

## Interpretation

The strongest immediate biomarker signals are endothelial and matrix/stromal. ACKR1 and PLVAP are consistent with scar-associated endothelial remodeling in cirrhosis. COL1A1, COL3A1, TIMP1, LUM, DCN, and MMP2 reflect scar matrix and remodeling biology, but most are better positioned as tissue-state or pharmacodynamic markers than direct therapeutic targets.

The most plausible therapeutic target class in this compact analysis is receptor or enzyme biology connected to activated stromal states. PDGFRA and PDGFRB are biologically coherent, druggable receptor tyrosine kinases, but safety and vascular or broad mesenchymal effects would need careful review. LOXL2 is mechanistically attractive as a collagen crosslinking enzyme, although prior clinical fibrosis efforts make it a high-risk target rather than a simple win.

Macrophage candidates require more caution. SPP1 and CD9 have direct signal in the compact analysis. TREM2 and GPNMB are retained because of strong external and published disease-state evidence, but they did not receive direct compartment-matched DE support in this marker-score run. They should be considered macrophage-state biomarkers or validation priorities before being treated as target candidates.

SMOC2 is best treated as a translational biomarker candidate rather than a direct target at this stage. It was modest in the primary cirrhosis pseudobulk contrast, but the focused GSE244832 validation showed higher expression in HSC-like NASH clusters than normal HSC-like clusters. That pattern is consistent with the independent NAFLD/NASH literature and makes SMOC2 useful as a disease-state and pharmacodynamic readout.

## Completed Follow-Up Experiments

The requested follow-up experiments were implemented as pipeline modules:

- `workflow/07_refine_annotations.R`: loads the published `tissue.rdata` Seurat object and uses `annotation_lineage` and `annotation_indepth` as a reference for refined cluster labels.
- `workflow/08_pseudobulk_de.R`: aggregates counts by donor and refined cell state, then fits limma models for cirrhotic versus healthy liver.
- `workflow/09_gse244832_hsc_validation.R`: identifies HSC-like validation clusters and summarizes SMOC2, TIMP1, COL1A1, COL3A1, PDGFRA, and PDGFRB across NORMAL, NAFL, and NASH.
- `scripts/enrich_translational_evidence.py` and `workflow/10_merge_translational_evidence.R`: add protein localization, tissue specificity, PubMed perturbation signal, trial context, mouse orthology, safety notes, and translational nomination language.

Key donor-level pseudobulk signals:

- HSC/myofibroblast refined state: COL1A1, COL3A1, TIMP1, PDGFRA, PLVAP, and ACKR1 were higher in cirrhosis with donor-level support.
- Endothelial refined state: ACKR1 had strong donor-level support; PLVAP trended positive but was weaker after multiple testing.
- Macrophage refined states: macrophage markers remain biologically important, but target claims require more external validation and perturbation evidence.

PLVAP and ACKR1 appearing in the HSC/myofibroblast refined state should be interpreted carefully. In scar tissue, endothelial and stromal programs sit in the same niche, and single-cell clusters can carry ambient RNA, doublet remnants, or mixed transitional signal. These genes remain strongest as vascular niche markers until spatial or protein-level localization confirms the cellular source.

Key GSE244832 HSC-like validation signals:

- SMOC2, TIMP1, PDGFRA, and PDGFRB showed higher HSC-like expression in NASH than normal.
- COL1A1 and COL3A1 are strong matrix readouts, but the validation pattern reinforces them as fibrosis burden markers rather than direct therapeutic targets.
- The dataset labels use `NORMAL`, `NAFL`, and `NASH`; the report interprets `NASH` as the MASH-relevant steatohepatitis validation state.

## Pathway-Level Biology

Hallmark enrichment supported biologically plausible mechanisms:

- Mesenchymal/HSC/myofibroblast-like upregulated genes were enriched for epithelial-mesenchymal transition, coagulation, glycolysis, hypoxia, and apical junction programs.
- Endothelial upregulated genes showed junction, coagulation, cholesterol homeostasis, and vascular remodeling-related signals.
- Macrophage/monocyte upregulated genes showed metabolic and lipid-associated programs, including oxidative phosphorylation, fatty acid metabolism, adipogenesis, peroxisome, and cholesterol homeostasis.

These results should be interpreted as mechanism summaries, not proof of causality.

## Validation Strategy

GSE244832 is the highest-priority validation dataset because it is human, MASLD/MASH-focused, single-nucleus and multiomic, and centered on hepatic stellate cell activation. The processed hLIVER archive was downloaded and prepared locally as Matrix Market counts plus genes, cells, and metadata. Compact candidate-expression summaries were generated by condition, cluster, and sample.

GSE207310 is the strongest lightweight validation source for translational directionality because it is human liver biopsy bulk RNA-seq with NASH and no-NAFLD comparison and directly supports SMOC2 as a secreted HSC-linked biomarker. The files were downloaded and staged locally; computed symbol-level validation requires an Ensembl-to-symbol annotation step.

SCP2154 is most relevant for macrophage-state validation but is portal-dependent. It is best handled as an expansion module rather than a blocker for the primary analysis.

## Public Target Evidence

The enriched candidate table adds public evidence from MyGene.info, Open Targets, ClinicalTrials.gov, and ClinVar. These resources help flag tractability, clinical trial context, sponsors, trial phases, safety-liability annotations, and clinical variant knowledge.

These signals are treated as triage evidence. ClinicalTrials.gov matches are broad text-query matches and require manual review before making claims about a specific target-program relationship.

## Limitations

This compact analysis is designed for practical review and clear translational prioritization.

- Cell-level DE is exploratory because cells from the same donor are not independent biological replicates.
- Marker-score compartment calls recover the required broad compartments but do not replace full expert annotation.
- Cirrhosis and MASH fibrosis overlap biologically but are not identical disease contexts.
- Single-cell and single-nucleus validation datasets can differ in cell capture and expression profiles.
- Ligand-receptor and target claims require perturbational validation.

## Remaining Next Experiments

1. Extend GSE207310 validation with Ensembl-to-symbol annotation and phenotype mapping for bulk directionality.
2. Add SCP2154 or another macrophage-focused atlas for TREM2, CD9, SPP1, and GPNMB.
3. Add spatial validation for PLVAP, ACKR1, SMOC2, TIMP1, and collagen genes in scar-adjacent niches.
4. Move from prioritization to perturbation: HSC spheroid, precision-cut liver slice, or co-culture assays for PDGFRA/B and SMOC2/TIMP1 biomarker response.

## Key References

- Ramachandran et al. Resolving the fibrotic niche of human liver cirrhosis at single-cell level. Nature, 2019. https://www.nature.com/articles/s41586-019-1631-3
- Rinella et al. A multisociety Delphi consensus statement on new fatty liver disease nomenclature. Hepatology, 2023. https://pubmed.ncbi.nlm.nih.gov/37363821/
- FDA Drug Trials Snapshot: Rezdiffra, original approval March 14, 2024. https://www.fda.gov/drugs/drug-approvals-and-databases/drug-trials-snapshots-rezdiffra
- Ravnskjaer et al. Stellate cell expression of SMOC2 is associated with human NAFLD severity. Journal of Hepatology Reports, 2022. https://pmc.ncbi.nlm.nih.gov/articles/PMC9850195/
- GSE244832 GEO record. https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE244832
