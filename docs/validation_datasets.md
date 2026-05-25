# Validation Dataset Preparation

Two validation datasets are prepared locally and summarized into compact review tables.

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

These tables aggregate the ranked candidate genes across NORMAL, NAFL, and NASH cells without loading the full object into memory. The focused HSC module identifies HSC-like clusters from collagen, stromal, and PDGFR marker expression, then evaluates SMOC2, TIMP1, COL1A1, COL3A1, PDGFRA, and PDGFRB in that compartment.

## GSE207310

Primary use: biomarker directionality and SMOC2-related translational support.

Prepared local format:

```text
data/validation/GSE207310/
  GSM*.txt.gz
```

These files are per-sample bulk count tables using Ensembl IDs. The repository currently tracks a readiness table and leaves symbol-level validation as a follow-up annotation module.

Tracked summary:

- `reports/tables/validation_gse207310_readiness.csv`

## Recreate Summaries

```bash
make validation
make hsc-validation
```

Large validation data are excluded from Git. The compact summaries and manifests are tracked.
