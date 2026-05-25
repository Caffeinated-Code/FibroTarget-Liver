# Validation Dataset Preparation

External validation datasets are prepared locally and summarized into compact analysis tables. The excluded blood and mouse libraries from GSE136103 are also analyzed as secondary validation modules.

## GSE244832

Primary use: therapeutic target validation, especially HSC/myofibroblast candidates in MASLD/MASH.

Prepared local format:

```text
data/validation/GSE244832/
  hLIVER_counts.mtx.gz
  hLIVER_genes.csv
  hLIVER_cells.csv
  hLIVER_metadata.csv
```

Although the count file is named `.mtx.gz`, the extracted file is plain Matrix Market text. The validation prep script handles this mismatch.

Tracked summaries:

- `reports/tables/validation_gse244832_candidate_expression_by_condition.csv`
- `reports/tables/validation_gse244832_candidate_expression_by_cluster.csv`
- `reports/tables/validation_gse244832_candidate_expression_by_sample.csv`
- `reports/tables/gse244832_hsc_like_cluster_scores.csv`
- `reports/tables/gse244832_hsc_candidate_validation.csv`
- `reports/tables/gse244832_focused_object_candidate_summary.csv`
- `reports/tables/gse244832_focused_object_compartment_scores.csv`

These tables aggregate the ranked candidate genes across NORMAL, NAFL, and NASH cells. The focused HSC module identifies HSC-like clusters from collagen, stromal, and PDGFR marker expression, then evaluates SMOC2, TIMP1, COL1A1, COL3A1, PDGFRA, and PDGFRB in that compartment. A focused Seurat object module now extracts a candidate-gene matrix from the large source matrix and runs object-level validation locally.

## GSE207310

Primary use: biomarker directionality and SMOC2-related translational support.

Prepared local format:

```text
data/validation/GSE207310/
  GSM*.txt.gz
```

These files are per-sample bulk count tables using Ensembl IDs. The validation module parses GEO phenotype metadata, maps Ensembl IDs to gene symbols with `org.Hs.eg.db`, and tests candidate expression against NASH status and fibrosis grade.

Tracked summaries:

- `reports/tables/validation_gse207310_readiness.csv`
- `reports/tables/validation_gse207310_sample_metadata.csv`
- `reports/tables/validation_gse207310_candidate_expression_by_disease.csv`
- `reports/tables/validation_gse207310_candidate_lm_results.csv`

## Recreate Summaries

```bash
make validation
make hsc-validation
make gse244832-focused
make gse207310-validation
make secondary-validation
```

Large validation data are excluded from Git. The compact summaries and manifests are tracked.

## GSE136103 Blood And Mouse Secondary Validation

Primary use: marker specificity and preclinical conservation checks.

The primary disease contrast uses only human liver tissue. The GSE136103 blood libraries and mouse liver libraries are analyzed separately so they do not confound human liver fibrosis discovery.

Tracked summaries:

- `reports/tables/gse136103_blood_qc_summary.csv`
- `reports/tables/gse136103_blood_candidate_marker_summary.csv`
- `reports/tables/gse136103_blood_candidate_marker_role_summary.csv`
- `reports/tables/gse136103_mouse_qc_summary.csv`
- `reports/tables/gse136103_mouse_candidate_ortholog_map.csv`
- `reports/tables/gse136103_mouse_candidate_ortholog_expression.csv`
- `reports/tables/gse136103_mouse_candidate_ortholog_summary.csv`
- `reports/tables/gse136103_secondary_validation_summary.csv`
- `reports/figures/gse136103_blood_candidate_marker_heatmap.png`
- `reports/figures/gse136103_mouse_candidate_ortholog_heatmap.png`

Interpretation:

- Blood checks whether candidates are broad circulating markers. LST1 and TIMP1 are detectable, while most stromal, endothelial, and collagen candidates are low or absent.
- Mouse liver checks ortholog conservation. Fibrotic mouse liver shows strong directionality for macrophage-state orthologs. Stromal candidates are present but weaker in this two-sample screen.
