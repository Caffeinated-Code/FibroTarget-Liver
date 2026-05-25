# Written Screening Responses

## 01. Dataset Curation And Fibrosis-Stage Harmonization

I would start by separating clinical harmonization from computational integration. Each dataset gets a sample manifest with donor ID, tissue source, assay type, species, disease label, fibrosis label, histology system, biopsy source, sequencing chemistry, and available covariates. I would preserve the original labels and add a harmonized label rather than overwriting source metadata.

For fibrosis, I would map labels into two levels. The first is a coarse label suitable for robust analysis: no or mild fibrosis, significant fibrosis, advanced fibrosis, and cirrhosis. The second is the original study-specific label, such as METAVIR, Kleiner, cirrhosis/non-cirrhosis, MASL, MASH, or NAFLD/NASH. I would not force all studies into a fake F0-F4 scale if the source metadata do not support it.

Before biomarker discovery, I would check whether disease labels track expected biology: collagen programs in stromal cells, macrophage activation states, endothelial remodeling, ductular reaction, and hepatocyte stress. If a dataset label does not align with biology or metadata, I would flag it for sensitivity analysis rather than excluding it silently.

## 02. QC And Preprocessing For Liver scRNA-seq/snRNA-seq

QC should remove technical failures without deleting disease biology. I would inspect nUMI, nGene, mitochondrial fraction, ribosomal fraction, ambient RNA, doublet probability, and per-sample cell yield. Thresholds should be sample-aware because cirrhotic tissue and nuclei data can look different from healthy tissue.

For scRNA-seq, high mitochondrial fraction can indicate dying cells, but in injured liver it can also track stressed biology. I would avoid one hard universal cutoff. For snRNA-seq, mitochondrial thresholds are less informative, and intronic reads and nuclear gene capture matter more.

I would use doublet detection and ambient RNA correction where possible, then check whether key populations disappear after filtering. If a fibrosis-associated macrophage or activated stellate population is removed mainly because it is stressed, that is a red flag. The QC report should show before/after plots by donor and disease state.

## 03. Integration Without Erasing Fibrosis Biology

The main risk in integration is correcting away the disease signal. I would first analyze each dataset separately and confirm expected biology before integration. Then I would integrate using methods such as Seurat integration, Harmony, or scVI, but evaluate whether known fibrosis programs remain visible after correction.

I would avoid using fibrosis stage itself as a batch variable. I would check UMAPs and PCA loadings by donor, assay, chemistry, and disease. I would also compare differential expression before and after integration. If integration removes COL1A1/COL3A1 stromal programs, TREM2/CD9 macrophage states, or PLVAP/ACKR1 endothelial remodeling, it is too aggressive.

For discovery, I prefer integration for visualization and annotation, but donor-aware testing on raw or normalized counts within cell types for inference.

## 04. Fibroblast Cluster Validation

A cluster expressing COL1A1, COL3A1, ACTA2, TAGLN, PDGFRB, LUM, and DCN and enriched in F3/F4 samples is clearly fibrogenic, but I would not immediately call it one pure cell type. It could include activated hepatic stellate cells, portal fibroblasts, vascular mural cells, or myofibroblast-like states.

I would validate it by checking:

- quiescent HSC markers and vitamin A-associated genes
- portal fibroblast-associated markers such as THY1 and elastin/matrix programs
- pericyte and vascular mural markers such as RGS5 and MCAM
- activated myofibroblast markers such as ACTA2, TAGLN, COL1A1, and TIMP1
- donor distribution and whether the cluster is present across multiple F3/F4 donors
- spatial or histology evidence if available

My label would likely be conservative: activated mesenchymal or myofibroblast-like stromal state, with subannotation after deeper validation.

## 05. Donor-Aware Differential Expression

Simple cell-level DE is dangerous because cells are not independent replicates. A dataset with thousands of cells from one donor can dominate the p-value and create false confidence. This is pseudoreplication.

I would use pseudobulk differential expression when donor/sample metadata support it. Cells are aggregated by donor, condition, and cell type or cell state. Then a bulk RNA-seq model such as edgeR, DESeq2, or limma-voom can test disease effects using donor-level replication.

If donor count is small, I would report effect sizes, donor consistency, and confidence intervals rather than overemphasizing adjusted p-values. Cell-level DE can still help generate hypotheses, but it should not be the sole basis for target nomination.

## 06. AI/ML-Based Biomarker Prioritization

With 300 candidate genes and limited donors, I would start with a transparent scoring model because it is interpretable, auditable, and easier to defend biologically.

The model would score each candidate across disease effect size, donor consistency, cell-type specificity, pathway support, validation in external datasets, secreted or surface protein status, druggability, assayability, mouse conservation, and safety risk. Literature and public resources can add evidence, but they should not override weak primary data without being labeled as external support.

If enough validation datasets are available, I would use ML for ranking stability or feature weighting. For example, one could train models to distinguish fibrosis stage using pseudobulk cell-type signatures, then ask which genes consistently contribute across folds and datasets. The final list should still be reviewed biologically.

## 07. Cell-Cell Communication And Mechanism Discovery

I would analyze ligand-receptor communication among scar-associated macrophages, activated mesenchymal cells, endothelial cells, cholangiocytes, and injured hepatocytes. Tools such as CellPhoneDB, NicheNet, LIANA, or CellChat can generate hypotheses.

The pitfall is overinterpretation. Ligand-receptor tools infer possible communication from expression. They do not prove contact, directionality, protein abundance, or functional effect.

I would prioritize interactions only if:

- the sender and receiver cell states are disease-enriched
- ligand and receptor are expressed in enough donors
- the interaction fits pathway evidence
- target genes in the receiver support the mechanism
- the interaction is supported by spatial, perturbation, or literature evidence

For this project, macrophage-to-stellate and endothelial-to-immune trafficking hypotheses are useful, but they should be presented as mechanisms to validate.

## 08. Reproducible Pipeline And Delivery Plan

For a 12-16 week project, I would structure the work as a production-style analysis program:

1. Weeks 1-2: dataset inventory, metadata harmonization, access checks, and pipeline skeleton.
2. Weeks 3-4: QC, preprocessing, doublet and ambient RNA handling, and sample-level reports.
3. Weeks 5-6: annotation, reference mapping, marker validation, and disease compartment review.
4. Weeks 7-8: donor-aware DE, pathway analysis, and mechanism analysis.
5. Weeks 9-10: external validation across MASH, fibrosis, and macrophage datasets.
6. Weeks 11-12: target scoring, druggability, conservation, and safety triage.
7. Weeks 13-14: dashboard, reproducible reports, and stakeholder review.
8. Weeks 15-16: final documentation, handoff, and next-experiment plan.

The repository should include Docker, `renv`, config files, modular scripts, small reviewable outputs, dashboard-ready files, and clear run instructions. Large data and derived single-cell objects should live in object storage, not Git. In AWS, I would map the same steps to S3, ECR, AWS Batch or ECS, Step Functions, and CloudWatch logs.
